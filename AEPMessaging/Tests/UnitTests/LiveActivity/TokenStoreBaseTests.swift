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

import XCTest

import AEPServices
import AEPTestUtils

@testable import AEPMessaging

final class TokenStoreBaseTests: XCTestCase {
    let STORE_KEY = "store-key"
    private var mockDataStore: MockDataStore!
    private var store: MockTokenStore!

    override func setUp() {
        super.setUp()
        mockDataStore = MockDataStore()
        ServiceProvider.shared.namedKeyValueService = mockDataStore
        store = MockTokenStore(storeKey: STORE_KEY)
    }

    func test_allReturnsEmptyMapWhenNoDataOnDisk() {
        // Given: No data has been persisted in the underlying data store
        // When: The store is queried for all tokens
        let actual = store.all()

        // Then: It should return a default, empty token map
        XCTAssertEqual(MockTokenMap(), actual)
    }

    func test_putPersistsSerializedDictionary() {
        // Given: A key-value pair to insert into the store
        // When: The key-value pair is set
        store.set(key: "key", value: "value")

        // Then: The serialized dictionary should be written to the data store under the correct key
        let actual = mockDataStore.get(collectionName: MessagingConstants.DATA_STORE_NAME, key: STORE_KEY) as? [String: Any]
        XCTAssertEqual(["values": ["key": "value"]] as NSDictionary, actual as NSDictionary?)
    }

    func test_loadReadsBackPreviouslyPersistedData() {
        // Given: A key-value pair is stored by one instance
        store.set(key: "key", value: "value")

        // When: A new instance is created with the same store key and loads the persisted data
        let rehydrated = MockTokenStore(storeKey: STORE_KEY).all()

        // Then: The new instance should read back the previously persisted token map
        let expected = MockTokenMap(values: ["key": "value"])
        XCTAssertEqual(expected, rehydrated)
    }

    func test_allUsesInMemoryCacheAfterFirstLoad() {
        // Given: A fresh store
        // CountingDataStore used to monitor the number of get calls on the underlying datastore
        let countingStore = CountingDataStore()
        ServiceProvider.shared.namedKeyValueService = countingStore
        let newStore = MockTokenStore(storeKey: STORE_KEY)

        // When: The .all() method is called multiple times
        _ = newStore.all()
        _ = newStore.all()

        // Then: The underlying get method should have been called only once due to in-memory caching
        XCTAssertEqual(1, countingStore.getCalls)
    }
}
