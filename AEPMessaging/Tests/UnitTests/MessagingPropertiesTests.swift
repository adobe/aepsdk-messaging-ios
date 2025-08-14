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
@testable import AEPMessaging
import AEPServices

class MessagingPropertiesTests: XCTestCase {
    var messagingProperties: MessagingProperties!
    var mockNamedKeyValueService: MockNamedKeyValueService!

    override func setUp() {
        super.setUp()
        mockNamedKeyValueService = MockNamedKeyValueService()
        ServiceProvider.shared.namedKeyValueService = mockNamedKeyValueService
        messagingProperties = MessagingProperties()
    }

    override func tearDown() {
        messagingProperties = nil
        mockNamedKeyValueService = nil
        super.tearDown()
    }

    // MARK: - Push Identifier Tests
    func testGetPushIdentifierWhenNotSet() {
        // Test
        let result = messagingProperties.pushIdentifier

        // Verify
        XCTAssertNil(result)
        XCTAssertTrue(mockNamedKeyValueService.getCalled)
        XCTAssertEqual(mockNamedKeyValueService.getCollectionName, MessagingConstants.DATA_STORE_NAME)
        XCTAssertEqual(mockNamedKeyValueService.getKey, MessagingConstants.NamedCollectionKeys.PUSH_IDENTIFIER)
    }

    func testGetPushIdentifierWhenSet() {
        // Setup
        let expectedIdentifier = "test-push-token"
        mockNamedKeyValueService.mockValue = expectedIdentifier

        // Test
        let result = messagingProperties.pushIdentifier

        // Verify
        XCTAssertEqual(result, expectedIdentifier)
        XCTAssertTrue(mockNamedKeyValueService.getCalled)
        XCTAssertEqual(mockNamedKeyValueService.getCollectionName, MessagingConstants.DATA_STORE_NAME)
        XCTAssertEqual(mockNamedKeyValueService.getKey, MessagingConstants.NamedCollectionKeys.PUSH_IDENTIFIER)
    }

    func testSetValidPushIdentifier() {
        // Setup
        let testIdentifier = "test-push-token"

        // Test
        messagingProperties.pushIdentifier = testIdentifier

        // Verify
        XCTAssertTrue(mockNamedKeyValueService.setCalled)
        XCTAssertEqual(mockNamedKeyValueService.setCollectionName, MessagingConstants.DATA_STORE_NAME)
        XCTAssertEqual(mockNamedKeyValueService.setKey, MessagingConstants.NamedCollectionKeys.PUSH_IDENTIFIER)
        XCTAssertEqual(mockNamedKeyValueService.setValue as? String, testIdentifier)
    }

    func testSetEmptyPushIdentifier() {
        // Test
        messagingProperties.pushIdentifier = ""

        // Verify
        XCTAssertTrue(mockNamedKeyValueService.removeCalled)
        XCTAssertEqual(mockNamedKeyValueService.removeCollectionName, MessagingConstants.DATA_STORE_NAME)
        XCTAssertEqual(mockNamedKeyValueService.removeKey, MessagingConstants.NamedCollectionKeys.PUSH_IDENTIFIER)
    }

    func testSetNilPushIdentifier() {
        // Test
        messagingProperties.pushIdentifier = nil

        // Verify
        XCTAssertTrue(mockNamedKeyValueService.removeCalled)
        XCTAssertEqual(mockNamedKeyValueService.removeCollectionName, MessagingConstants.DATA_STORE_NAME)
        XCTAssertEqual(mockNamedKeyValueService.removeKey, MessagingConstants.NamedCollectionKeys.PUSH_IDENTIFIER)
    }

    func testSetThenGetNewPushIdentifier() {
        // Setup
        let testIdentifier = "test-push-token"
        let newIdentifier = "new-push-token"

        // Test
        messagingProperties.pushIdentifier = testIdentifier

        // Verify
        XCTAssertTrue(mockNamedKeyValueService.setCalled)
        XCTAssertEqual(mockNamedKeyValueService.setCollectionName, MessagingConstants.DATA_STORE_NAME)
        XCTAssertEqual(mockNamedKeyValueService.setKey, MessagingConstants.NamedCollectionKeys.PUSH_IDENTIFIER)
        XCTAssertEqual(mockNamedKeyValueService.setValue as? String, testIdentifier)

        // Test with new identifier
        messagingProperties.pushIdentifier = newIdentifier
        let result = messagingProperties.pushIdentifier

        // Verify
        XCTAssertTrue(mockNamedKeyValueService.setCalled)
        XCTAssertEqual(mockNamedKeyValueService.setCollectionName, MessagingConstants.DATA_STORE_NAME)
        XCTAssertEqual(mockNamedKeyValueService.setKey, MessagingConstants.NamedCollectionKeys.PUSH_IDENTIFIER)
        XCTAssertEqual(mockNamedKeyValueService.setValue as? String, newIdentifier)
        XCTAssertEqual(result, newIdentifier)
    }
}
