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

final class ExpirableStore<Map: LiveActivity.DictionaryBacked>: PersistenceStoreBase<Map> where Map.Element: LiveActivity.Expirable {
    /// A predicate used to determine whether a new element meaningfully differs from a previously stored one.
    ///
    /// This closure returns `true` if the new element should replace the old one, and `false` if the update
    /// should be considered redundant.
    typealias Equivalence = (_ old: Element, _ new: Element) -> Bool

    /// The time-to-live (TTL) duration used to determine when an element is considered expired.
    private let ttl: TimeInterval
    /// An optional predicate that defines custom equivalence logic between stored and incoming elements.
    private let customEquivalence: Equivalence?

    /// Initializes a new store with the given persistence key, expiration time-to-live, and optional custom equivalence logic.
    ///
    /// This initializer automatically performs an initial cleanup of expired entries after loading persisted data.
    ///
    /// - Parameters:
    ///   - storeKey: The key used to identify the persisted store in the backing storage.
    ///   - ttl: The time-to-live (TTL) interval used to determine when elements expire.
    ///   - customEquivalence: An optional predicate that determines whether a new element meaningfully differs
    ///     from a previously stored one. If `nil`, all non-expired values are stored unconditionally.
    init(storeKey: String, ttl: TimeInterval, customEquivalence: Equivalence? = nil) {
        self.ttl = ttl
        self.customEquivalence = customEquivalence
        super.init(storeKey: storeKey)
        removeExpiredEntries()
    }

    /// Returns the current contents of the store after removing any expired entries.
    ///
    /// - Returns: A `Map` containing only non-expired entries.
    override func all() -> [LiveActivity.ID: Element] {
        removeExpiredEntries()
        return _persistedMap.storage
    }

    /// Returns the element associated with the specified ID, if it exists and has not expired.
    ///
    /// If the element is expired, it is opportunistically removed from the store.
    ///
    /// - Parameter id: The ID whose associated element should be retrieved.
    /// - Returns: The associated element if it exists and is not expired; `nil` otherwise.
    func value(for id: LiveActivity.ID) -> Element? {
        guard let element = _persistedMap.storage[id] else {
            return nil
        }

        guard !isExpired(element) else {
            // Remove expired value from the store
            _persistedMap.storage.removeValue(forKey: id)
            return nil
        }

        return element
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
    func set(_ element: Element, id: LiveActivity.ID) -> Bool {
        guard !isExpired(element) else {
            return false
        }

        var workingMap = _persistedMap
        let previous = workingMap.storage.updateValue(element, forKey: id)
        let changed: Bool

        // If there is a previously stored value, and a custom equivalence closure was set, apply it
        // to determine if the new element should be saved
        if let previous = previous, let customEquivalence = customEquivalence {
            changed = customEquivalence(previous, element)
        } else {
            // If no previous entry or no custom equivalence logic is set, save new element
            changed = previous == nil || customEquivalence == nil
        }

        if changed {
            _persistedMap = workingMap
        }

        return changed
    }

    /// Removes the element associated with the specified ID, if it exists.
    ///
    /// - Parameter id: The ID whose associated element should be removed.
    /// - Returns: `true` if an element was removed; `false` if no entry existed for the given ID.
    @discardableResult
    func remove(id: LiveActivity.ID) -> Bool {
        var working = _persistedMap
        guard working.storage.removeValue(forKey: id) != nil else {
            return false
        }
        _persistedMap = working
        return true
    }

    // MARK: - Private helpers

    /// Determines whether the given element is expired based on the configured TTL and reference time.
    ///
    /// - Parameters:
    ///   - element: The element to evaluate for expiration.
    ///   - now: The reference time used for comparison. Defaults to the current time.
    /// - Returns: `true` if the element is expired; `false` otherwise.
    private func isExpired(_ element: Element, referenceDate: Date = Date()) -> Bool {
        referenceDate.timeIntervalSince(element.referenceDate) > ttl
    }

    /// Removes all entries from the store whose elements have expired based on their `referenceDate`.
    /// If any entries are removed, the changes are persisted.
    ///
    /// The TTL is defined by ``ttl``.
    private func removeExpiredEntries() {
        let now = Date()
        let filtered = _persistedMap.storage.filter { _, element in
            !isExpired(element, referenceDate: now)
        }
        if filtered.count != _persistedMap.storage.count {
            _persistedMap.storage = filtered
        }
    }
}
