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

class UpdateTokenStoreTests: XCTestCase {
    var mockDataStore: MockDataStore!
    var store: UpdateTokenStore!

    let TTL = MessagingConstants.LiveActivity.UPDATE_TOKEN_MAX_TTL
    let ATTRIBUTE = "testAttribute"
    let ID = "test_id_1"
    let ID_2 = "test_id_2"

    override func setUp() {
        super.setUp()
        mockDataStore = MockDataStore()
        ServiceProvider.shared.namedKeyValueService = mockDataStore
        store = UpdateTokenStore()
    }

    func testSet_storesTokenAtAttributeAndId() {
        // Given: A new token to store for a unique (attribute, id) pair
        let issuedDate = Date()
        let tokenToStore = token("token", date: issuedDate)

        // When: The token is set
        let success = store.set(tokenToStore, attribute: ATTRIBUTE, id: ID)

        // Then: It should return true, and the token should be stored at the correct location
        XCTAssertTrue(success)
        let allTokens = store.all().tokens
        XCTAssertEqual(1, allTokens.count)
        XCTAssertEqual(1, allTokens[ATTRIBUTE]?.count)
        XCTAssertEqual("token", allTokens[ATTRIBUTE]?[ID]?.token)
        XCTAssertEqual(issuedDate, allTokens[ATTRIBUTE]?[ID]?.tokenFirstIssued)
    }

    func testSet_sameTokenReturnsFalseAndNoop() {
        // Given: A token is already set at (attribute, id)
        let initialDate = Date()
        store.set(token("token", date: initialDate), attribute: ATTRIBUTE, id: ID)

        // When: The same token is set again
        let laterDate = initialDate.addingTimeInterval(10)
        let changed = store.set(token("token", date: laterDate), attribute: ATTRIBUTE, id: ID)

        // Then: It should return false, and no changes should be made to the store
        XCTAssertFalse(changed)
        let allTokens = store.all().tokens
        XCTAssertEqual(1, allTokens[ATTRIBUTE]?.count)
        XCTAssertEqual("token", allTokens[ATTRIBUTE]?[ID]?.token)
        XCTAssertEqual(initialDate, allTokens[ATTRIBUTE]?[ID]?.tokenFirstIssued)
    }

    func testGet_returnsPreviouslySetToken() {
        // Given: A token was previously set for (attribute, id)
        let issuedDate = Date()
        store.set(token("token", date: issuedDate), attribute: ATTRIBUTE, id: ID)

        // When: Retrieving the token using the same (attribute, id)
        let retrieved = store.token(for: ATTRIBUTE, id: ID)

        // Then: The correct token should be returned
        XCTAssertEqual("token", retrieved?.token)
        XCTAssertEqual(issuedDate, retrieved?.tokenFirstIssued)
    }

    func testSet_overwritesExistingTokenAndReturnsTrueIfChanged() {
        // Given: A token is already stored at (attribute, id)
        let initialDate = Date()
        store.set(token("token1", date: initialDate), attribute: ATTRIBUTE, id: ID)

        // When: A different token is set at the same (attribute, id)
        let newDate = initialDate.addingTimeInterval(10)
        let changed = store.set(token("token2", date: newDate), attribute: ATTRIBUTE, id: ID)

        // Then: It should return true, and overwrite the existing token
        XCTAssertTrue(changed)
        let stored = store.token(for: ATTRIBUTE, id: ID)
        XCTAssertEqual("token2", stored?.token)
        XCTAssertEqual(newDate, stored?.tokenFirstIssued)
        XCTAssertEqual(1, store.all().tokens[ATTRIBUTE]?.count)
    }

    func testSet_multipleIdsCreatesSingleAttributeEntry() {
        // Given: Two tokens for the same attribute, but different IDs
        let date1 = Date()
        let date2 = date1.addingTimeInterval(5)
        store.set(token("token1", date: date1), attribute: ATTRIBUTE, id: ID)
        store.set(token("token2", date: date2), attribute: ATTRIBUTE, id: ID_2)

        // When: Fetching the internal token map
        let allTokens = store.all().tokens

        // Then: One attribute entry should exist with two token entries
        XCTAssertNotNil(allTokens[ATTRIBUTE])
        XCTAssertEqual(2, allTokens[ATTRIBUTE]?.count)
        XCTAssertEqual(date1, allTokens[ATTRIBUTE]?[ID]?.tokenFirstIssued)
        XCTAssertEqual(date2, allTokens[ATTRIBUTE]?[ID_2]?.tokenFirstIssued)
    }

    func testSet_createsSeparateEntriesForDifferentAttributes() {
        // Given: Two tokens with different attribute names
        let secondAttribute = "different_attribute"
        let date1 = Date()
        let date2 = date1.addingTimeInterval(5)
        store.set(token("token1", date: date1), attribute: ATTRIBUTE, id: ID)
        store.set(token("token2", date: date2), attribute: secondAttribute, id: ID_2)

        // When: Fetching the internal token map
        let allTokens = store.all().tokens

        // Then: Two separate attribute entries should exist, each with one token
        XCTAssertEqual(2, allTokens.count)
        XCTAssertEqual("token1", allTokens[ATTRIBUTE]?[ID]?.token)
        XCTAssertEqual(date1, allTokens[ATTRIBUTE]?[ID]?.tokenFirstIssued)

        XCTAssertEqual("token2", allTokens[secondAttribute]?[ID_2]?.token)
        XCTAssertEqual(date2, allTokens[secondAttribute]?[ID_2]?.tokenFirstIssued)
    }

    func testRemove_deletesTokenAndReturnsTrue() {
        // Given: A token is stored at a known (attribute, id) pair
        store.set(token("token"), attribute: ATTRIBUTE, id: ID)

        // When: The token is removed
        let removed = store.remove(attribute: ATTRIBUTE, id: ID)

        // Then: The method returns true, and both the token and attribute are removed
        XCTAssertTrue(removed)
        XCTAssertNil(store.token(for: ATTRIBUTE, id: ID))
        XCTAssertNil(store.all().tokens[ATTRIBUTE])
    }

    func testRemove_fromNonExistingAttribute_returnsFalse() {
        // Given: The store is empty and no tokens have been set

        // When: Attempting to remove a token from a non-existent attribute
        let removed = store.remove(attribute: ATTRIBUTE, id: ID)

        // Then: The method returns false and the store remains empty
        XCTAssertFalse(removed)
        XCTAssertTrue(store.all().tokens.isEmpty)
    }

    func testRemove_fromExistingAttributeWithUnknownId_returnsFalse() {
        // Given: A token is stored under an attribute for TEST_ID_1
        store.set(token("token"), attribute: ATTRIBUTE, id: ID)

        // When: Attempting to remove a different ID under the same attribute
        let removed = store.remove(attribute: ATTRIBUTE, id: ID_2)

        // Then: The removal returns false, and the original token remains
        XCTAssertFalse(removed)
        XCTAssertEqual(1, store.all().tokens[ATTRIBUTE]?.count)
        XCTAssertEqual("token", store.token(for: ATTRIBUTE, id: ID)?.token)
    }

    func testRemove_oneOfMultipleIds_keepsAttributeAndOtherToken() {
        // Given: Two tokens stored under the same attribute with different IDs
        store.set(token("token1"), attribute: ATTRIBUTE, id: ID)
        store.set(token("token2"), attribute: ATTRIBUTE, id: ID_2)

        // When: Removing only one of the IDs
        store.remove(attribute: ATTRIBUTE, id: ID)

        // Then: The attribute remains, and the other token is still present
        let tokens = store.all().tokens
        XCTAssertNotNil(tokens[ATTRIBUTE])
        XCTAssertEqual(1, tokens[ATTRIBUTE]?.count)
        XCTAssertEqual("token2", tokens[ATTRIBUTE]?[ID_2]?.token)
    }

    func testRemoveCleansUpEmptyAttribute() {
        // Given: Two tokens under the same attribute
        store.set(token("token1"), attribute: ATTRIBUTE, id: ID)
        store.set(token("token2"), attribute: ATTRIBUTE, id: ID_2)

        // When: Both tokens are removed
        store.remove(attribute: ATTRIBUTE, id: ID)
        store.remove(attribute: ATTRIBUTE, id: ID_2)

        // Then: The attribute itself should also be removed from the map
        XCTAssertNil(store.all().tokens[ATTRIBUTE])
    }

    func testTTLExpiry_removesExpiredTokensOnInit() {
        // Given: A token issued beyond the TTL is stored
        let expiredDate = Date().addingTimeInterval(-(TTL + 10))
        let oldToken = token("expired_token", date: expiredDate)
        store.set(oldToken, attribute: ATTRIBUTE, id: ID)

        // When: A new UpdateTokenStore instance is initialized (triggers expiry check)
        let second = UpdateTokenStore()

        // Then: The expired token should be removed during initialization
        XCTAssertNil(second.token(for: ATTRIBUTE, id: ID))
    }

    func testTTLExpiry_removesOnlyExpiredTokensAndKeepsValidOnes() {
        // Given: One expired and one valid token stored under the same attribute
        let expiredDate = Date().addingTimeInterval(-(TTL + 10))
        let expired = token("expired_token", date: expiredDate)
        store.set(expired, attribute: ATTRIBUTE, id: ID)

        let valid = token("valid_token", date: Date())
        store.set(valid, attribute: ATTRIBUTE, id: ID_2)

        // When: A new UpdateTokenStore instance is initialized (triggers expiry check)
        let second = UpdateTokenStore()

        // Then: The expired token should be removed, and the valid token should remain
        XCTAssertNil(second.token(for: ATTRIBUTE, id: ID))
        XCTAssertEqual("valid_token", second.token(for: ATTRIBUTE, id: ID_2)?.token)
        XCTAssertEqual(1, second.all().tokens[ATTRIBUTE]?.count)
    }

    func testPersistenceAcrossInstances() {
        // Given: A token is stored under an attribute and ID
        let issuedDate = Date()
        store.set(token("token", date: issuedDate), attribute: ATTRIBUTE, id: ID)

        // When: A new UpdateTokenStore instance is initialized
        let second = UpdateTokenStore()

        // Then: The token should persist and be retrievable
        let persisted = second.token(for: ATTRIBUTE, id: ID)
        XCTAssertEqual("token", persisted?.token)
        XCTAssertEqual(issuedDate, persisted?.tokenFirstIssued)
    }

    // MARK: Private helpers

    private func token(_ s: String, date: Date = Date()) -> LiveActivity.Token {
        LiveActivity.Token(token: s, tokenFirstIssued: date)
    }
}
