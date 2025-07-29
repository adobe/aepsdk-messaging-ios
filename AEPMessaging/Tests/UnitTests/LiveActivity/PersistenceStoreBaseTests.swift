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

typealias TestMap = TestMapBase<TestElement>

class PersistenceStoreBaseTests: XCTestCase {
    private var store: PersistenceStoreBase<TestMap>!
    private var mockDataStore: MockDataStore!

    private let COLLECTION = MessagingConstants.DATA_STORE_NAME
    private let STORE_KEY = "store-key"
    private let TTL = MessagingConstants.LiveActivity.UPDATE_TOKEN_MAX_TTL
    private let ID = "id_1"
    private let ID_2 = "id_2"

    override func setUp() {
        super.setUp()
        mockDataStore = MockDataStore()
        ServiceProvider.shared.namedKeyValueService = mockDataStore
        store = PersistenceStoreBase<TestMap>(storeKey: STORE_KEY, ttl: TTL)
    }

    // MARK: - Persistence tests

    func test_allReturnsEmptyMapWhenNoDataInPersistence() {
        // Given: No data has been persisted in the underlying data store
        // When: The store is queried for all tokens
        let actual = store.all()

        // Then: It should return the default, empty token map
        XCTAssertTrue(actual.isEmpty)
    }

    func test_putPersistsSerializedDictionary() {
        // Given: A key-value pair to insert into the store
        // When: The key-value pair is set
        let element = createElement("value")
        store.set(element, id: ID)

        // Then: The serialized dictionary should be written to the data store under the correct key
        let actual = mockDataStore.get(collectionName: COLLECTION, key: STORE_KEY) as? [String: Any]
        let expected = ["storage": [ID: element.asDictionary()!]] as NSDictionary
        XCTAssertEqual(expected, actual as NSDictionary?)
    }

    func test_loadReadsBackPreviouslyPersistedData() {
        // Given: A key-value pair is stored by one instance
        let element = createElement("value")
        store.set(element, id: ID)

        // When: A new instance is created with the same store key and loads the persisted data
        let rehydrated = PersistenceStoreBase<TestMap>(storeKey: STORE_KEY).all()

        // Then: The new instance should read back the previously persisted token map
        let expected = [ID: element]
        XCTAssertEqual(expected, rehydrated)
    }

    func test_allUsesInMemoryCacheAfterFirstLoad() {
        // CountingDataStore used to monitor the number of get calls on the underlying datastore
        let countingStore = CountingDataStore()
        ServiceProvider.shared.namedKeyValueService = countingStore

        // Given: A fresh store
        let newStore = PersistenceStoreBase<TestMap>(storeKey: STORE_KEY)

        // When: The .all() method is called multiple times
        _ = newStore.all()
        _ = newStore.all()

        // Then: The underlying persistence get method should have been called only once due to in-memory caching
        XCTAssertEqual(1, countingStore.getCalls)
    }

    // MARK: - Public API tests

    func testSet_storesElementAtID() {
        // Given: A new element with a current (non-expired) timestamp
        let issued = Date()
        let element = createElement("value", date: issued)

        // When: The element is set into the store
        let changed = store.set(element, id: ID)

        // Then: It should return true, and the element should be retrievable via both accessors
        XCTAssertTrue(changed)

        // Validate via `all()` and `value(for:)`
        XCTAssertEqual(1, store.all().count)
        XCTAssertEqual(element, store.all()[ID])
        XCTAssertEqual(element, store.value(for: ID))
    }

    func testSet_doesNotStoreExpiredElement() {
        // Given: An expired element, based on TTL
        let expiredDate = Date().addingTimeInterval(-(TTL + 1))
        let expiredElement = createElement("expired", date: expiredDate)

        // When: Attempting to store the expired element
        let result = store.set(expiredElement, id: ID)

        // Then: It should return false, and the element should not be persisted in the store
        XCTAssertFalse(result)
        XCTAssertNil(store.value(for: ID))
        XCTAssertTrue(store.all().isEmpty)
    }

    func testValueFor_removesExpiredElementOnAccess() {
        // Given: An expired element in the store
        insertExpiredElement()

        // Confirm given: it is present in the store
        XCTAssertEqual(1, store.persistedMapForTesting.storage.count)

        // When: The element is accessed using `value(for:)`
        let result = store.value(for: ID)

        // Then: It should return nil and remove the expired entry from the store
        XCTAssertNil(result)
        XCTAssertNil(store.all()[ID])
    }

    func testAll_removesExpiredElementsOnAccess() {
        // Given: A mix of expired and valid elements in the store
        insertExpiredElement()

        let validDate = Date()
        let validElement = createElement("valid", date: validDate)
        store.persistedMapForTesting.storage.updateValue(validElement, forKey: ID_2)

        // Confirm given: both elements are present in store
        XCTAssertEqual(2, store.persistedMapForTesting.storage.count)

        // When: Calling `all()` to retrieve elements
        let result = store.all()

        // Then: Expired elements should be removed, and valid ones returned
        XCTAssertNil(result[ID])
        XCTAssertEqual(1, result.count)
        XCTAssertEqual(validElement, result[ID_2])
    }

    func testSet_sameElementReturnsTrue_whenNoCustomEquivalence() {
        // Given: An element is stored with a specific value and timestamp
        let issued = Date()
        let element = createElement("value", date: issued)
        XCTAssertTrue(store.set(element, id: ID))

        // When: An identical element is set again
        let changed = store.set(element, id: ID)

        // Then: It should unconditionally set the value, returning true
        XCTAssertTrue(changed)
        XCTAssertEqual(1, store.all().count)
        XCTAssertEqual(element, store.value(for: ID))
    }

    func testSet_sameValueDifferentDateReturnsTrue() {
        // Given: An element is stored with a given value and timestamp
        let first = Date()
        store.set(createElement("same", date: first), id: ID)

        // When: A new element with the same value but a later timestamp
        let secondDate = first.addingTimeInterval(1)
        let secondElement = createElement("same", date: secondDate)
        let changed = store.set(secondElement, id: ID)

        // Then: It should return true and update the stored element
        XCTAssertTrue(changed)
        XCTAssertEqual(1, store.all().count)
        XCTAssertEqual(secondElement, store.value(for: ID))
    }

    func testSet_overwritesExistingElementAndReturnsTrue() {
        // Given: An element is stored under a specific ID
        let firstDate = Date()
        store.set(createElement("initial", date: firstDate), id: ID)

        // When: A different element is set under the same ID
        let secondDate = firstDate.addingTimeInterval(1)
        let secondElement = createElement("different", date: secondDate)
        let changed = store.set(secondElement, id: ID)

        // Then: It should return true and update the value under the ID
        XCTAssertTrue(changed)
        XCTAssertEqual(1, store.all().count)
        XCTAssertEqual(secondElement, store.value(for: ID))
    }

    func testRemove_deletesElementAndReturnsTrue() {
        // Given: An element is stored at a specific ID
        store.set(createElement("value"), id: ID)

        // When: The element is removed using `remove(id:)`
        let removed = store.remove(id: ID)

        // Then: It should return true, and the element should be removed
        XCTAssertTrue(removed)
        XCTAssertNil(store.value(for: ID))
        XCTAssertTrue(store.all().isEmpty)
    }

    func testRemove_nonExistingId_returnsFalse() {
        // Given: No element exists at the specified ID in the store
        // When: Attempting to remove an element by that ID
        let removed = store.remove(id: ID)

        // Then: It should return false
        XCTAssertFalse(removed)
        XCTAssertNil(store.value(for: ID))
        XCTAssertTrue(store.all().isEmpty)
    }

    func testTTLExpiry_removesExpiredElementsOnInit() {
        // Given: An expired element in the store
        insertExpiredElement()

        // Confirm given: it is present in the store
        XCTAssertEqual(1, store.persistedMapForTesting.storage.count)

        // When: A new instance of the store is initialized with the same storeKey
        let newStore = PersistenceStoreBase<TestMap>(storeKey: STORE_KEY, ttl: TTL)

        // Then: The expired element should be removed in the init process
        XCTAssertNil(newStore.value(for: ID))
        XCTAssertTrue(newStore.all().isEmpty)
    }

    func testTTLExpiry_keepsValidElements() {
        // Given: Expired and valid elements are in the store
        insertExpiredElement()

        let validDate = Date()
        let validElement = createElement("valid", date: validDate)
        store.set(validElement, id: ID_2)

        // Confirm given: both are present in the store
        XCTAssertEqual(2, store.persistedMapForTesting.storage.count)

        // When: A new store instance is initialized with the same storeKey and TTL
        let newStore = PersistenceStoreBase<TestMap>(storeKey: STORE_KEY, ttl: TTL)

        // Then: Only the valid element should persist
        XCTAssertNil(newStore.value(for: ID))
        XCTAssertEqual(1, newStore.all().count)
        XCTAssertEqual(validElement, newStore.all()[ID_2])
    }

    func testPersistenceAcrossInstances() {
        // Given: An element is stored in an instance of the store
        let issued = Date()
        let originalElement = createElement("value", date: issued)
        store.set(originalElement, id: ID)

        // When: A second instance is created using the same store key and TTL
        let newStore = PersistenceStoreBase<TestMap>(storeKey: STORE_KEY, ttl: TTL)

        // Then: The element should persist across instances
        let all = newStore.all()
        XCTAssertEqual(1, all.count)
        XCTAssertEqual(originalElement, all[ID])
    }

    // MARK: Custom equivalence predicate tests

    func testCustomEquivalencePredicate_setReturnsFalseWhenElementsAreEqual() {
        // Given: A store with a custom equivalence predicate that compares only the `value` field
        let customStore = PersistenceStoreBase<TestMap>(storeKey: STORE_KEY, ttl: TTL) { old, new in
            old.value == new.value
        }

        // And: An element is stored
        let firstDate = Date()
        let firstElement = createElement("same", date: firstDate)
        XCTAssertTrue(customStore.set(firstElement, id: ID))

        // When: A new element with the same value but a later timestamp is set
        let secondDate = firstDate.addingTimeInterval(1)
        let changed = customStore.set(createElement("same", date: secondDate), id: ID)

        // Then: It should return false, and the new element should not be saved
        // since the custom predicate says the elements are equal
        XCTAssertFalse(changed)
        XCTAssertEqual(1, customStore.all().count)
        XCTAssertEqual(firstElement, customStore.all()[ID])
    }

    func testCustomEquivalencePredicate_setReturnsTrueWhenElementsAreDifferent() {
        // Given: A store with a custom predicate that compares only the `value` field
        let customStore = PersistenceStoreBase<TestMap>(storeKey: STORE_KEY, ttl: TTL) { old, new in
            old.value == new.value
        }

        // And: An element is stored
        let firstDate = Date()
        XCTAssertTrue(customStore.set(createElement("initial", date: firstDate), id: ID))

        // When: A new element with a different `value` but same ID is set
        let differentDate = firstDate.addingTimeInterval(1)
        let differentElement = createElement("different", date: differentDate)
        let changed = customStore.set(differentElement, id: ID)

        // Then: It should return true and overwrite the original element
        XCTAssertTrue(changed)
        XCTAssertEqual(1, customStore.all().count)
        XCTAssertEqual(differentElement, customStore.all()[ID])
    }

    // MARK: - PushToStartTokenStore tests

    func testPushToStartTokenStore_sameValueDifferentTimestamp_returnsFalse() {
        // Given: A store with a custom predicate that ignores timestamps
        let store = PushToStartTokenStore()

        let initialDate = Date()
        let token = LiveActivity.PushToStartToken(firstIssued: initialDate, token: "same")
        XCTAssertTrue(store.set(token, id: ID))

        // When: Setting a token with same value and attributeType, but a different timestamp
        let laterDate = initialDate.addingTimeInterval(1)
        let sameTokenLater = LiveActivity.PushToStartToken(firstIssued: laterDate, token: "same")
        let changed = store.set(sameTokenLater, id: ID)

        // Then: It should return false due, since only timestamp is different
        XCTAssertFalse(changed)
    }

    func testPushToStartTokenStore_differentValue_returnsTrue() {
        // Given: A store with a custom predicate that ignores timestamps
        let store = PushToStartTokenStore()

        let issued = Date()
        let token = LiveActivity.PushToStartToken(firstIssued: issued, token: "initial")
        XCTAssertTrue(store.set(token, id: ID))

        // When: Setting a token with a different value
        let differentToken = LiveActivity.PushToStartToken(firstIssued: issued, token: "different")
        let changed = store.set(differentToken, id: ID)

        // Then: It should return true, since value is different
        XCTAssertTrue(changed)
    }

    // MARK: - UpdateTokenStore tests

    func testUpdateTokenStore_sameValueDifferentTimestamp_returnsFalse() {
        // Given: A store with a custom predicate that ignores timestamps
        let store = UpdateTokenStore()
        let ATTRIBUTE = "attribute"

        let initialDate = Date()
        let token = LiveActivity.UpdateToken(attributeType: ATTRIBUTE, firstIssued: initialDate, token: "same")
        XCTAssertTrue(store.set(token, id: ID))

        // When: Setting a token with same value and attributeType, but a different timestamp
        let laterDate = initialDate.addingTimeInterval(1)
        let sameTokenLater = LiveActivity.UpdateToken(attributeType: ATTRIBUTE, firstIssued: laterDate, token: "same")
        let changed = store.set(sameTokenLater, id: ID)

        // Then: It should return false due, since only timestamp is different
        XCTAssertFalse(changed)
    }

    func testUpdateTokenStore_differentValue_returnsTrue() {
        // Given: A store with a custom predicate that ignores timestamps
        let store = UpdateTokenStore()
        let attribute = "attribute"
        let issued = Date()

        let token = LiveActivity.UpdateToken(attributeType: attribute, firstIssued: issued, token: "initial")
        XCTAssertTrue(store.set(token, id: ID))

        // When: Setting a token with a different value
        let differentToken = LiveActivity.UpdateToken(attributeType: attribute, firstIssued: issued, token: "different")
        let changed = store.set(differentToken, id: ID)

        // Then: It should return true, since value is different
        XCTAssertTrue(changed)
    }

    func testUpdateTokenStore_differentAttributeSameValue_returnsTrue() {
        // Given: A store with a custom predicate that ignores timestamps
        let store = UpdateTokenStore()
        let issued = Date()

        let token = LiveActivity.UpdateToken(attributeType: "attribute_1", firstIssued: issued, token: "same")
        XCTAssertTrue(store.set(token, id: ID))

        // When: Setting a token with a different attribute type
        let differentAttributeToken = LiveActivity.UpdateToken(attributeType: "attribute_2", firstIssued: issued, token: "same")
        let changed = store.set(differentAttributeToken, id: ID)

        // Then: It should return true, since attribute type is different
        XCTAssertTrue(changed)
    }

    // Note: ChannelActivityStore doesn't currently need tests here since it doesn't use a custom
    // equivalence predicate for its elements

    // MARK: - Private helpers

    private func createElement(_ value: String, date: Date = Date()) -> TestElement {
        TestElement(value: value, date: date)
    }

    /// Inserts an expired element directly into the store's backing map, bypassing the
    /// `set` API, which rejects expired elements.
    ///
    /// - Parameters:
    ///   - name: The `value` string of the test element. Defaults to `"expired"`.
    ///   - id: The identifier under which the element should be stored. Defaults to `"id_1"`.
    /// - Returns: The expired `TestElement` that was inserted.
    @discardableResult
    private func insertExpiredElement(
        named name: String = "expired",
        for id: LiveActivity.ID = "id_1"
    ) -> TestElement {
        let expiredDate = Date().addingTimeInterval(-(TTL + 1))
        let expired = createElement(name, date: expiredDate)
        store.persistedMapForTesting.storage.updateValue(expired, forKey: id)
        return expired
    }
}
