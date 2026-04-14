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
class DefaultErrorViewTests: XCTestCase {

    // MARK: - Initialisation

    func testCanBeCreatedWithInboxError() {
        let view = DefaultErrorView(error: InboxError.dataUnavailable, onRetry: {})
        XCTAssertNotNil(view)
    }

    func testCanBeCreatedWithGenericError() {
        let error = NSError(domain: "test", code: 1, userInfo: nil)
        let view = DefaultErrorView(error: error, onRetry: {})
        XCTAssertNotNil(view)
    }

    // MARK: - Stored error

    func testInboxErrorIsStored() {
        let view = DefaultErrorView(error: InboxError.inboxCreationFailed, onRetry: {})
        XCTAssertEqual(view.error as? InboxError, .inboxCreationFailed)
    }

    func testGenericErrorIsStored() {
        let error = NSError(domain: "com.test", code: 42, userInfo: nil)
        let view = DefaultErrorView(error: error, onRetry: {})
        XCTAssertEqual((view.error as NSError).code, 42)
    }

    // MARK: - onRetry callback

    func testOnRetryCallbackCanBeInvoked() {
        var retryCalled = false
        let view = DefaultErrorView(error: InboxError.dataUnavailable, onRetry: { retryCalled = true })
        view.onRetry()
        XCTAssertTrue(retryCalled)
    }

    func testOnRetryCallbackIsCalledOnce() {
        var count = 0
        let view = DefaultErrorView(error: InboxError.dataUnavailable, onRetry: { count += 1 })
        view.onRetry()
        XCTAssertEqual(count, 1)
    }

    func testOnRetryCallbackCanBeCalledMultipleTimes() {
        var count = 0
        let view = DefaultErrorView(error: InboxError.dataUnavailable, onRetry: { count += 1 })
        view.onRetry()
        view.onRetry()
        XCTAssertEqual(count, 2)
    }

    // MARK: - Default style constants

    func testErrorTitleIsNotEmpty() {
        XCTAssertFalse(UIConstants.Inbox.DefaultStyle.ErrorView.TITLE.isEmpty)
    }

    func testRetryButtonTitleIsNotEmpty() {
        XCTAssertFalse(UIConstants.Inbox.DefaultStyle.ErrorView.BUTTON_TITLE.isEmpty)
    }

    func testRetryButtonTitleEqualsExpected() {
        XCTAssertEqual(UIConstants.Inbox.DefaultStyle.ErrorView.BUTTON_TITLE, "Try Again")
    }

    func testVerticalSpacingIsPositive() {
        XCTAssertGreaterThan(UIConstants.Inbox.DefaultStyle.ErrorView.VERTICAL_SPACING, 0)
    }
}
