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

@available(iOS 15.0, *)
class InboxErrorTests: XCTestCase {

    // MARK: - Raw values

    func testDataUnavailableRawValue() {
        XCTAssertEqual(InboxError.dataUnavailable.rawValue, 1)
    }

    func testInboxSchemaDataNotFoundRawValue() {
        XCTAssertEqual(InboxError.inboxSchemaDataNotFound.rawValue, 2)
    }

    func testInvalidInboxSchemaDataRawValue() {
        XCTAssertEqual(InboxError.invalidInboxSchemaData.rawValue, 3)
    }

    func testInboxCreationFailedRawValue() {
        XCTAssertEqual(InboxError.inboxCreationFailed.rawValue, 4)
    }

    func testInitFromRawValue() {
        XCTAssertEqual(InboxError(rawValue: 1), .dataUnavailable)
        XCTAssertEqual(InboxError(rawValue: 2), .inboxSchemaDataNotFound)
        XCTAssertEqual(InboxError(rawValue: 3), .invalidInboxSchemaData)
        XCTAssertEqual(InboxError(rawValue: 4), .inboxCreationFailed)
        XCTAssertNil(InboxError(rawValue: 99))
    }

    // MARK: - errorDescription

    func testDataUnavailableErrorDescription() {
        XCTAssertEqual(InboxError.dataUnavailable.errorDescription,
                       "No propositions available for the specified surface")
    }

    func testInboxSchemaDataNotFoundErrorDescription() {
        XCTAssertEqual(InboxError.inboxSchemaDataNotFound.errorDescription,
                       "InboxSchemaData not found in propositions")
    }

    func testInvalidInboxSchemaDataErrorDescription() {
        XCTAssertEqual(InboxError.invalidInboxSchemaData.errorDescription,
                       "Invalid inboxSchemaData schema or parsing failed")
    }

    func testInboxCreationFailedErrorDescription() {
        XCTAssertEqual(InboxError.inboxCreationFailed.errorDescription,
                       "Inbox creation failed due to internal error")
    }

    // MARK: - failureReason

    func testDataUnavailableFailureReason() {
        XCTAssertEqual(InboxError.dataUnavailable.failureReason,
                       "The surface may not be configured or no campaigns are targeting it")
    }

    func testInboxSchemaDataNotFoundFailureReason() {
        XCTAssertEqual(InboxError.inboxSchemaDataNotFound.failureReason,
                       "The propositions do not contain valid InboxSchemaData")
    }

    func testInvalidInboxSchemaDataFailureReason() {
        XCTAssertEqual(InboxError.invalidInboxSchemaData.failureReason,
                       "The inboxSchemaData is malformed or incompatible")
    }

    func testInboxCreationFailedFailureReason() {
        XCTAssertEqual(InboxError.inboxCreationFailed.failureReason,
                       "An internal error occurred while creating the InboxUI")
    }

    // MARK: - recoverySuggestion

    func testDataUnavailableRecoverySuggestion() {
        XCTAssertEqual(InboxError.dataUnavailable.recoverySuggestion,
                       "Verify the surface configuration and ensure campaigns are active")
    }

    func testInboxSchemaDataNotFoundRecoverySuggestion() {
        XCTAssertEqual(InboxError.inboxSchemaDataNotFound.recoverySuggestion,
                       "Check that the proposition contains inboxSchemaData in the expected format")
    }

    func testInvalidInboxSchemaDataRecoverySuggestion() {
        XCTAssertEqual(InboxError.invalidInboxSchemaData.recoverySuggestion,
                       "Validate the InboxSchemaData JSON against the expected schema")
    }

    func testInboxCreationFailedRecoverySuggestion() {
        XCTAssertEqual(InboxError.inboxCreationFailed.recoverySuggestion,
                       "Check logs for additional error details and retry the operation")
    }

    // MARK: - Error conformance

    func testCanBeThrownAndCaughtAsError() {
        func throwingFunc() throws { throw InboxError.dataUnavailable }
        XCTAssertThrowsError(try throwingFunc()) { error in
            XCTAssertTrue(error is InboxError)
        }
    }

    func testCaughtErrorMatchesOriginalCase() {
        func throwingFunc() throws { throw InboxError.inboxCreationFailed }
        XCTAssertThrowsError(try throwingFunc()) { error in
            XCTAssertEqual(error as? InboxError, .inboxCreationFailed)
        }
    }
}
