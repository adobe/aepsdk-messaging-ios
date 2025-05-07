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

import AEPServices

class TokenStoreBase<TokenMap: Codable> {

    private let datastoreName = MessagingConstants.DATA_STORE_NAME
    private let storeKey: String

    /// `nil` until first load or write
    private lazy var _cache: TokenMap? = {
        Self.load(datastoreName: datastoreName, key: storeKey)
    }()

    /// Returns the cached map or `nil` if the store is still empty
    func all() -> TokenMap? { _cache }

    /// Read / write wrapper for subclasses
    var _persistedMap: TokenMap? {
        get { _cache }
        set {
            _cache = newValue
            persist()
        }
    }

    init(storeKey: String) {
        self.storeKey = storeKey
    }

    private func persist() {
        guard
            let map = _cache,
            let dict = map.asDictionary()
        else { return }

        ServiceProvider.shared.namedKeyValueService.set(
            collectionName: datastoreName,
            key: storeKey,
            value: dict
        )
    }

    private static func load(datastoreName: String,
                             key: String) -> TokenMap? {
        let persistence = ServiceProvider.shared.namedKeyValueService
        guard let dict = persistence.get(collectionName: datastoreName,
                                         key: key) as? [String: Any]
        else { return nil }
        return TokenMap.from(dict)
    }
}


///// Abstract base class for caching and persistence of Live Activity token maps.
/////
///// > Important:  Subclass this base class with a concrete `TokenMap` type and provide
///// > your own mutator methods for reading and writing specific tokens.
//class TokenStoreBase<TokenMap: Codable & LiveActivity.DefaultInitializable> {
//    private let datastoreName = MessagingConstants.DATA_STORE_NAME
//    private let storeKey: String
//
//    /// The cached token map, loaded from disk on first access.
//    ///
//    /// This property attempts to load the persisted token map from the named key-value service
//    /// using the provided `collectionName` and `storeKey`. If no persisted data is found,
//    /// it initializes an empty default `Map` instance.
//    private lazy var _cache: TokenMap = {
//        Self.load(datastoreName: datastoreName, key: storeKey) ?? TokenMap()
//    }()
//
//    /// Provides access to the in-memory token map with automatic persistence on update.
//    ///
//    /// Subclasses can use this property to read the current token map or assign a new one.
//    /// Assigning a new value automatically updates the internal cache and persists the change
//    /// to the underlying key-value store.
//    ///
//    /// - Note: Setting this property triggers a disk write via `persist()`.
//    /// > Warning: Do not expose this outside subclasses.
//    var _persistedMap: TokenMap {
//        get { _cache }
//        set {
//            _cache = newValue
//            persist()
//        }
//    }
//
//    init(storeKey: String) {
//        self.storeKey = storeKey
//    }
//
//    /// Returns the full token map.
//    ///
//    /// - Returns: The current token map.
//    func all() -> TokenMap { _cache }
//
//    /// Persists the current in‑memory token map to the named key‑value service.
//    ///
//    /// If serialization fails, the method exits early without writing anything to disk.
//    private func persist() {
//        guard let dict = _cache.asDictionary() else {
//            return
//        }
//        let persistence = ServiceProvider.shared.namedKeyValueService
//        persistence.set(collectionName: datastoreName, key: storeKey, value: dict)
//    }
//
//    /// Loads a persisted token map from the named key‑value service.
//    ///
//    /// - Parameters:
//    ///   - datastoreName: The top‑level datastore name in the named key‑value store.
//    ///   - key: The specific key under which the token map is stored.
//    /// - Returns: A fully decoded `Map` on success, or `nil` if no valid data existed.
//    private static func load(datastoreName: String, key: String) -> TokenMap? {
//        let persistence = ServiceProvider.shared.namedKeyValueService
//        guard let dict = persistence.get(collectionName: datastoreName, key: key) as? [String: Any] else {
//            return nil
//        }
//        return TokenMap.from(dict)
//    }
//}
