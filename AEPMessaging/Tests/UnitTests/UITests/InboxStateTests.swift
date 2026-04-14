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
class InboxStateTests: XCTestCase {

    // MARK: - .loading

    func testLoadingCasePatternMatches() {
        let state = InboxState.loading
        if case .loading = state {
            // passes
        } else {
            XCTFail("Expected .loading case")
        }
    }

    func testLoadingIsNotLoaded() {
        let state = InboxState.loading
        if case .loaded = state {
            XCTFail("Expected .loading, not .loaded")
        }
    }

    func testLoadingIsNotError() {
        let state = InboxState.loading
        if case .error = state {
            XCTFail("Expected .loading, not .error")
        }
    }

    // MARK: - .loaded

    func testLoadedCaseWithEmptyArray() {
        let state = InboxState.loaded([])
        if case .loaded(let cards) = state {
            XCTAssertTrue(cards.isEmpty)
        } else {
            XCTFail("Expected .loaded case")
        }
    }

    func testLoadedIsNotLoading() {
        let state = InboxState.loaded([])
        if case .loading = state {
            XCTFail("Expected .loaded, not .loading")
        }
    }

    func testLoadedIsNotError() {
        let state = InboxState.loaded([])
        if case .error = state {
            XCTFail("Expected .loaded, not .error")
        }
    }

    // MARK: - .error

    func testErrorCaseStoresError() {
        let expectedError = InboxError.dataUnavailable
        let state = InboxState.error(expectedError)
        if case .error(let error) = state {
            XCTAssertEqual(error as? InboxError, expectedError)
        } else {
            XCTFail("Expected .error case")
        }
    }

    func testErrorCaseWithInboxSchemaDataNotFound() {
        let state = InboxState.error(InboxError.inboxSchemaDataNotFound)
        if case .error(let error) = state {
            XCTAssertEqual(error as? InboxError, .inboxSchemaDataNotFound)
        } else {
            XCTFail("Expected .error case")
        }
    }

    func testErrorCaseWithGenericError() {
        let genericError = NSError(domain: "test", code: 42, userInfo: nil)
        let state = InboxState.error(genericError)
        if case .error(let error) = state {
            XCTAssertEqual((error as NSError).code, 42)
        } else {
            XCTFail("Expected .error case")
        }
    }

    func testErrorIsNotLoading() {
        let state = InboxState.error(InboxError.inboxCreationFailed)
        if case .loading = state {
            XCTFail("Expected .error, not .loading")
        }
    }

    func testErrorIsNotLoaded() {
        let state = InboxState.error(InboxError.inboxCreationFailed)
        if case .loaded = state {
            XCTFail("Expected .error, not .loaded")
        }
    }
}
