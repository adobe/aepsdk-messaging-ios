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

final class PushToStartTokenStoreTests: XCTestCase {
    private var mockDataStore: MockDataStore!
    private var store: PushToStartTokenStore!

    private let ATTRIBUTE = "testAttribute1"
    private let ATTRIBUTE_2 = "testAttribute2"

    override func setUp() {
        super.setUp()
        mockDataStore = MockDataStore()
        ServiceProvider.shared.namedKeyValueService = mockDataStore
        store = PushToStartTokenStore()
    }

    func testSet_storesTokenAtAttribute() {
        // Given: A new token to store for an attribute
        let issuedDate = Date()
        let tokenToStore = token("token", date: issuedDate)

        // When: The token is set
        let changed = store.set(tokenToStore, attribute: ATTRIBUTE)

        // Then: It should return true, and the token should be stored correctly
        XCTAssertTrue(changed)
        let allTokens = store.all().tokens
        XCTAssertEqual(1, allTokens.count)
        XCTAssertEqual("token", allTokens[ATTRIBUTE]?.token)
        XCTAssertEqual(issuedDate, allTokens[ATTRIBUTE]?.tokenFirstIssued)
    }

    func testSet_sameTokenReturnsFalseAndNoop() {
        // Given: A token is already set at an attribute
        let initialDate = Date()
        let originalToken = token("token", date: initialDate)
        store.set(originalToken, attribute: ATTRIBUTE)

        // When: The same token is set again with a later timestamp
        let laterDate = initialDate.addingTimeInterval(10)
        let changed = store.set(token("token", date: laterDate), attribute: ATTRIBUTE)

        // Then: It should return false, and no changes should be made to the store
        XCTAssertFalse(changed)
        let allTokens = store.all().tokens
        XCTAssertEqual(1, allTokens.count)
        XCTAssertEqual("token", allTokens[ATTRIBUTE]?.token)
        XCTAssertEqual(initialDate, allTokens[ATTRIBUTE]?.tokenFirstIssued)
    }

    func testGet_returnsPreviouslySetToken() {
        // Given: A token stored at an attribute
        let issuedDate = Date()
        let expectedToken = token("token", date: issuedDate)
        store.set(expectedToken, attribute: ATTRIBUTE)

        // When: Retrieving the token for that attribute
        let retrieved = store.token(for: ATTRIBUTE)

        // Then: The token and issue date should match what was stored
        XCTAssertEqual("token", retrieved?.token)
        XCTAssertEqual(issuedDate, retrieved?.tokenFirstIssued)
    }

    func testSet_overwritesExistingTokenAndReturnsTrueIfChanged() {
        // Given: A token is already set for a specific attribute
        let initialDate = Date()
        let firstToken = token("token1", date: initialDate)
        store.set(firstToken, attribute: ATTRIBUTE)

        // When: A different token is set for the same attribute
        let newDate = initialDate.addingTimeInterval(10)
        let changed = store.set(token("token2", date: newDate), attribute: ATTRIBUTE)

        // Then: It should return true, and the new token should overwrite the previous one
        XCTAssertTrue(changed)
        let allTokens = store.all().tokens
        XCTAssertEqual(1, allTokens.count)
        XCTAssertEqual("token2", allTokens[ATTRIBUTE]?.token)
        XCTAssertEqual(newDate, allTokens[ATTRIBUTE]?.tokenFirstIssued)
    }

    func testSet_createsSeparateEntriesForDifferentAttributes() {
        // Given: Two different tokens to be stored under different attributes
        store.set(token("token1"), attribute: ATTRIBUTE)
        store.set(token("token2"), attribute: ATTRIBUTE_2)

        // When: Retrieving all stored tokens
        let allTokens = store.all().tokens

        // Then: Each token should be stored under its respective attribute
        XCTAssertEqual(2, allTokens.count)
        XCTAssertEqual("token1", allTokens[ATTRIBUTE]?.token)
        XCTAssertEqual("token2", allTokens[ATTRIBUTE_2]?.token)
    }

    func testRemove_deletesTokenAndReturnsTrue() {
        // Given: A token stored under a specific attribute
        store.set(token("token"), attribute: ATTRIBUTE)

        // When: The token is removed
        let removed = store.remove(attribute: ATTRIBUTE)

        // Then: It should return true, and the token should no longer exist in the store
        XCTAssertTrue(removed)
        XCTAssertNil(store.token(for: ATTRIBUTE))
        XCTAssertTrue(store.all().tokens.isEmpty)
    }

    func testRemove_nonExistingAttribute_returnsFalse() {
        // Given: No token exists for the attribute (store is empty)
        // When: Attempting to remove a token for the non-existent attribute
        let removed = store.remove(attribute: ATTRIBUTE)

        // Then: It should return false, and the store should remain empty
        XCTAssertFalse(removed)
        XCTAssertTrue(store.all().tokens.isEmpty)
    }

    func testPersistenceAcrossInstances() {
        // Given: A token is stored in one instance of the store
        let issuedDate = Date()
        store.set(token("token", date: issuedDate), attribute: ATTRIBUTE)

        // When: A new store instance is created
        let second = PushToStartTokenStore()

        // Then: The new instance should still have access to the original token
        XCTAssertEqual("token", second.token(for: ATTRIBUTE)?.token)
        XCTAssertEqual(issuedDate, second.token(for: ATTRIBUTE)?.tokenFirstIssued)
    }

    // MARK: - Private helpers
    private func token(_ s: String, date: Date = Date()) -> LiveActivity.Token {
        LiveActivity.Token(token: s, tokenFirstIssued: date)
    }
}
