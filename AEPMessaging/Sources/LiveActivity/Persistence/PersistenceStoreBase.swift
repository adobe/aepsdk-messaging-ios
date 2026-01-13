/*
 Copyright 2025 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

import AEPServices

/// Abstract base class for persistence and caching of Live Activity related element maps.
///
/// This class is thread-safe: all public methods synchronize access to the underlying storage
/// using a serial dispatch queue.
///
/// > Important:  Subclass this base class with a concrete `Map` type conforming to:
/// > `Codable`, `LiveActivity.DefaultInitializable`, and `LiveActivity.DictionaryBacked`
class PersistenceStoreBase<Map: Codable & LiveActivity.DefaultInitializable & LiveActivity.DictionaryBacked> {
    // MARK: Type aliases

    public typealias Element = Map.Element
    public typealias Key = LiveActivity.ID
    /// An equivalence predicate used to determine whether a new element meaningfully differs from a previously stored one.
    ///
    /// This closure should return `true` if the new element should be considered equal to the old one, and `false` if the elements
    /// should be considered different.
    public typealias Equivalence = (_ old: Element, _ new: Element) -> Bool

    /// Serial queue for synchronizing access to the backing storage.
    /// Ensures thread-safe reads and writes from multiple queues.
    private let accessQueue: DispatchQueue

    // MARK: Persistence configuration

    private let datastoreName = MessagingConstants.DATA_STORE_NAME
    private let storeKey: String

    // MARK: Behaviour configuration

    /// An optional predicate that defines custom equivalence logic between stored and incoming elements.
    /// - SeeAlso: ``Equivalence``
    private let customEquivalence: Equivalence?
    /// The time-to-live (TTL) duration used to determine when an element is considered expired.
    /// If not set, expiration logic will not be applied to store elements.
    private let ttl: TimeInterval?

    // MARK: Backing storage

    /// The cached element map, loaded from disk on first access.
    ///
    /// Lazily loads the map in persistence if it exists, or starts with a fresh one.
    private lazy var _cache: Map = Self.load(datastoreName: datastoreName, key: storeKey) ?? Map()

    /// Provides access to the in-memory element map with automatic persistence on update.
    private var _persistedMap: Map {
        get { _cache }
        set {
            _cache = newValue
            persist()
        }
    }

    #if DEBUG
        /// For test/debug use only: directly access the backing store.
        var persistedMapForTesting: Map {
            get { _persistedMap }
            set { _persistedMap = newValue }
        }
    #endif

    // MARK: Initialization

    /// Initializes a new store with the given persistence key, optional expiration time-to-live, and optional custom equivalence logic.
    ///
    /// This initializer automatically performs an initial cleanup of expired entries after loading persisted data.
    ///
    /// - Parameters:
    ///   - storeKey: The key used to identify the persisted store in the backing storage.
    ///   - ttl: The optional time-to-live (TTL) interval used to determine when elements expire. If `nil`, expiration logic will not be applied.
    ///   - customEquivalence: An optional predicate that determines whether a new element meaningfully differs
    ///     from a previously stored one. If `nil`, all non-expired values are stored unconditionally.
    init(
        storeKey: String,
        ttl: TimeInterval? = nil,
        customEquivalence: Equivalence? = nil
    ) {
        self.storeKey = storeKey
        self.ttl = ttl
        self.customEquivalence = customEquivalence
        self.accessQueue = DispatchQueue(label: "com.adobe.messaging.persistenceStore.\(storeKey)")
        removeExpiredEntriesIfNeeded()
    }

    // MARK: Public API

    /// Returns the current contents of the store after removing any expired entries (if TTL was provided).
    ///
    /// - Returns: A `Map` containing only non-expired entries.
    func all() -> [Key: Element] {
        accessQueue.sync {
            removeExpiredEntriesIfNeeded()
            return _persistedMap.storage
        }
    }

    /// Returns the element associated with the specified ID, if it exists and has not expired (if TTL was provided).
    ///
    /// If the element is expired, it is opportunistically removed from the store.
    ///
    /// - Parameter id: The ID whose associated element should be retrieved.
    /// - Returns: The associated element if it exists and is not expired; `nil` otherwise.
    func value(for id: Key) -> Element? {
        accessQueue.sync {
            guard let element = _persistedMap.storage[id] else { return nil }
            guard !isExpired(element) else {
                _persistedMap.storage.removeValue(forKey: id)
                return nil
            }
            return element
        }
    }

    /// Sets or updates the value for the specified ID, unless the element has expired.
    ///
    /// If a custom equivalence predicate is set for the store, it is used to determine whether the new element
    /// should replace the existing one. If no predicate is set for the store, non-expired values are stored unconditionally.
    ///
    /// - Parameters:
    ///   - element: The value to store.
    ///   - id: The ID to associate with the element.
    /// - Returns: `true` if the element was stored or replaced; `false` if it was expired or unchanged.
    @discardableResult
    func set(_ element: Element, id: Key) -> Bool {
        accessQueue.sync {
            guard !isExpired(element) else { return false }

            var working = _persistedMap
            let previous = working.storage.updateValue(element, forKey: id)

            let didChange: Bool
            // If there is a previously stored value, and a custom equivalence closure was set, apply it
            // to determine if the new element should be saved
            if let prev = previous, let customEquivalence = customEquivalence {
                didChange = !customEquivalence(prev, element)
            } else {
                // If no previous entry or no custom equivalence logic is set, save new element
                didChange = previous == nil || customEquivalence == nil
            }

            if didChange { _persistedMap = working }
            return didChange
        }
    }

    /// Removes the element associated with the specified ID, if it exists.
    ///
    /// - Parameter id: The ID whose associated element should be removed.
    /// - Returns: `true` if an element was removed; `false` if no entry existed for the given ID.
    @discardableResult
    func remove(id: Key) -> Bool {
        accessQueue.sync {
            var working = _persistedMap
            guard working.storage.removeValue(forKey: id) != nil else {
                return false
            }
            _persistedMap = working
            return true
        }
    }

    // MARK: Persistence helpers

    /// Persists the current in‑memory element map to the named key‑value service.
    ///
    /// If serialization fails, the method exits early without writing anything to disk.
    private func persist() {
        guard let dict = _cache.asDictionary() else {
            return
        }
        ServiceProvider
            .shared
            .namedKeyValueService
            .set(collectionName: datastoreName, key: storeKey, value: dict)
    }

    /// Loads a persisted element map from the named key‑value service.
    ///
    /// - Parameters:
    ///   - datastoreName: The top‑level datastore name in the named key‑value store.
    ///   - key: The specific key under which the element map is stored.
    /// - Returns: A fully decoded `Map` on success, or `nil` if no valid data existed.
    private static func load(datastoreName: String, key: String) -> Map? {
        let persistence = ServiceProvider.shared.namedKeyValueService
        guard let dict = persistence.get(collectionName: datastoreName, key: key) as? [String: Any] else {
            return nil
        }
        return Map.fromDictionary(dict)
    }
}

// MARK: – Expiry helpers (private)

private extension PersistenceStoreBase {
    /// Checks whether the given element should be considered expired based on its reference date
    /// and the store’s configured TTL. If no TTL is set or the element doesn’t support expiration,
    /// it is treated as non-expired.
    ///
    /// - Parameters:
    ///   - element: The element to check.
    ///   - referenceDate: The time to compare against. Defaults to `Date()`.
    /// - Returns: `true` if expired; otherwise, `false`.
    func isExpired(_ element: Element, referenceDate: Date = Date()) -> Bool {
        guard let ttl, let expirable = element as? any LiveActivity.Expirable else {
            return false
        }

        return referenceDate.timeIntervalSince(expirable.referenceDate) > ttl
    }

    /// Removes expired elements from the store based on their reference dates and the configured TTL.
    /// If no TTL is set, nothing is removed. Changes are persisted if any entries are removed.
    func removeExpiredEntriesIfNeeded() {
        guard ttl != nil else { return }
        let now = Date()
        _persistedMap.storage = _persistedMap.storage.filter { _, element in
            !isExpired(element)
        }
    }
}
