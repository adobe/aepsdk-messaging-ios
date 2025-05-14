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

    private let TEST_ATTRIBUTE = "testAttribute1"
    private let TEST_ATTRIBUTE_2 = "testAttribute2"

    override func setUp() {
        super.setUp()
        mockDataStore = MockDataStore()
        ServiceProvider.shared.namedKeyValueService = mockDataStore
        store = PushToStartTokenStore()
    }

    func testSet_storesTokenAtAttribute() {
        let issuedDate = Date()
        let tokenToStore = token("token", date: issuedDate)
        let changed = store.set(tokenToStore, attribute: TEST_ATTRIBUTE)

        XCTAssertTrue(changed)
        let allTokens = store.all().tokens
        XCTAssertEqual(1, allTokens.count)
        XCTAssertEqual("token", allTokens[TEST_ATTRIBUTE]?.token)
        XCTAssertEqual(issuedDate, allTokens[TEST_ATTRIBUTE]?.tokenFirstIssued)
    }

    func testSet_sameTokenReturnsFalseAndNoop() {
        // Given
        let initialDate = Date()
        let originalToken = token("token", date: initialDate)
        store.set(originalToken, attribute: TEST_ATTRIBUTE)

        // When
        let laterDate = initialDate.addingTimeInterval(10)
        let changed = store.set(token("token", date: laterDate), attribute: TEST_ATTRIBUTE)

        // Then
        XCTAssertFalse(changed)
        let allTokens = store.all().tokens
        XCTAssertEqual(1, allTokens.count)
        XCTAssertEqual("token", allTokens[TEST_ATTRIBUTE]?.token)
        XCTAssertEqual(initialDate, allTokens[TEST_ATTRIBUTE]?.tokenFirstIssued)
    }

    func testGet_returnsPreviouslySetToken() {
        // Given
        let issuedDate = Date()
        let expectedToken = token("token", date: issuedDate)
        store.set(expectedToken, attribute: TEST_ATTRIBUTE)

        // When
        let retrieved = store.token(for: TEST_ATTRIBUTE)

        // Then
        XCTAssertEqual("token", retrieved?.token)
        XCTAssertEqual(issuedDate, retrieved?.tokenFirstIssued)
    }

    func testSet_overwritesExistingTokenAndReturnsTrueIfChanged() {
        // Given
        let initialDate = Date()
        let firstToken = token("token1", date: initialDate)
        store.set(firstToken, attribute: TEST_ATTRIBUTE)

        // When
        let newDate = initialDate.addingTimeInterval(10)
        let changed = store.set(token("token2", date: newDate), attribute: TEST_ATTRIBUTE)

        // Then
        XCTAssertTrue(changed)
        let allTokens = store.all().tokens
        XCTAssertEqual(1, allTokens.count)
        XCTAssertEqual("token2", allTokens[TEST_ATTRIBUTE]?.token)
        XCTAssertEqual(newDate, allTokens[TEST_ATTRIBUTE]?.tokenFirstIssued)
    }

    func testSet_createsSeparateEntriesForDifferentAttributes() {
        store.set(token("token1"), attribute: TEST_ATTRIBUTE)
        store.set(token("token2"), attribute: TEST_ATTRIBUTE_2)

        let allTokens = store.all().tokens

        XCTAssertEqual(2, allTokens.count)
        XCTAssertEqual("token1", allTokens[TEST_ATTRIBUTE]?.token)
        XCTAssertEqual("token2", allTokens[TEST_ATTRIBUTE_2]?.token)
    }

    func testRemove_deletesTokenAndReturnsTrue() {
        store.set(token("token"), attribute: TEST_ATTRIBUTE)

        let removed = store.remove(attribute: TEST_ATTRIBUTE)

        XCTAssertTrue(removed)
        XCTAssertNil(store.token(for: TEST_ATTRIBUTE))
        XCTAssertTrue(store.all().tokens.isEmpty)
    }

    func testRemove_nonExistingAttribute_returnsFalse() {
        let removed = store.remove(attribute: TEST_ATTRIBUTE)

        XCTAssertFalse(removed)
        XCTAssertTrue(store.all().tokens.isEmpty)
    }

    func testPersistenceAcrossInstances() {
        let issuedDate = Date()
        store.set(token("token", date: issuedDate), attribute: TEST_ATTRIBUTE)

        let second = PushToStartTokenStore()

        XCTAssertEqual("token", second.token(for: TEST_ATTRIBUTE)?.token)
        XCTAssertEqual(issuedDate, second.token(for: TEST_ATTRIBUTE)?.tokenFirstIssued)
    }

    // MARK: - Private helpers
    private func token(_ s: String, date: Date = Date()) -> LiveActivity.Token {
        LiveActivity.Token(token: s, tokenFirstIssued: date)
    }
}
