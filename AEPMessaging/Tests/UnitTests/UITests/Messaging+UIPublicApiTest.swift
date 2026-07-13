/*
 Copyright 2026 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

@testable import AEPCore
@testable import AEPMessaging
import AEPTestUtils
import XCTest

@available(iOS 15.0, *)
class MessagingUIPublicApiTest: XCTestCase {

    let ASYNC_TIMEOUT = 2.0
    let surface = Surface(uri: "mobileapp://com.adobe.ajo.e2eTestApp/promos/feed1")

    override func setUp() {
        EventHub.shared.start()
        registerMockExtension(MockExtension.self)
    }

    override func tearDown() {
        MobileCore.resetSDK()
    }

    private func registerMockExtension<T: Extension>(_ type: T.Type) {
        let semaphore = DispatchSemaphore(value: 0)
        EventHub.shared.registerExtension(type) { _ in
            semaphore.signal()
        }
        semaphore.wait()
    }

    func testGetContentCardsUIDefaultDoesNotSetPersistedFlag() {
        let eventExpectation = expectation(description: "get propositions event")
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(
            type: EventType.messaging,
            source: EventSource.requestContent
        ) { event in
            XCTAssertNil(event.data?[MessagingConstants.Event.Data.Key.USE_PERSISTED_CONTENT_CARDS] as? Bool)
            eventExpectation.fulfill()
            let responseEvent = event.createResponseEvent(
                name: "name", type: "type", source: "source", data: ["propositions": []]
            )
            MobileCore.dispatch(event: responseEvent)
        }

        let completionExpectation = expectation(description: "completion")
        Messaging.getContentCardsUI(for: surface) { _ in
            completionExpectation.fulfill()
        }

        wait(for: [completionExpectation, eventExpectation], timeout: ASYNC_TIMEOUT)
    }

    func testGetContentCardsUIUsePersistedContentCardsSetsFlag() {
        let eventExpectation = expectation(description: "get propositions event")
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(
            type: EventType.messaging,
            source: EventSource.requestContent
        ) { event in
            XCTAssertEqual(true, event.data?[MessagingConstants.Event.Data.Key.USE_PERSISTED_CONTENT_CARDS] as? Bool)
            eventExpectation.fulfill()
            let responseEvent = event.createResponseEvent(
                name: "name", type: "type", source: "source", data: ["propositions": []]
            )
            MobileCore.dispatch(event: responseEvent)
        }

        let completionExpectation = expectation(description: "completion")
        Messaging.getContentCardsUI(for: surface, usePersistedContentCards: true) { _ in
            completionExpectation.fulfill()
        }

        wait(for: [completionExpectation, eventExpectation], timeout: ASYNC_TIMEOUT)
    }
}
