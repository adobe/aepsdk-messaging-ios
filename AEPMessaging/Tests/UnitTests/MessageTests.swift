/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation
import XCTest

@testable import AEPCore
@testable import AEPMessaging
@testable import AEPServices
import WebKit

class MessageTests: XCTestCase, FullscreenMessageDelegate {
    let ASYNC_TIMEOUT = 2.0
    var mockMessaging: MockMessaging!
    var mockRuntime = TestableExtensionRuntime()
    var mockEvent: Event!
    var mockEventData: [String: Any]?
    let mockAssetString = "https://blog.adobe.com/en/publish/2020/05/28/media_1cc0fcc19cf0e64decbceb3a606707a3ad23f51dd.png"
    let mockMessageId = "552"
    var onShowExpectation: XCTestExpectation?
    var onDismissExpectation: XCTestExpectation?
    var handleJavascriptMessageExpectation: XCTestExpectation?

    override func setUp() {
        mockMessaging = MockMessaging(runtime: mockRuntime)

        mockEventData = [
            MessagingConstants.Event.Data.Key.TRIGGERED_CONSEQUENCE: [
                MessagingConstants.Event.Data.Key.DETAIL: [
                    MessagingConstants.Event.Data.Key.IAM.REMOTE_ASSETS: [mockAssetString],
                    MessagingConstants.Event.Data.Key.IAM.MOBILE_PARAMETERS: TestableMobileParameters.mobileParameters,
                    MessagingConstants.Event.Data.Key.Personalization.ID: mockMessageId,
                    MessagingConstants.Event.Data.Key.Personalization.SCOPE: "mobileapp://com.apple.dt.xctest.tool",
                    MessagingConstants.Event.Data.Key.Personalization.SCOPE_DETAILS: [
                        "akey": "avalue"
                    ]
                ]
            ]
        ]

        mockEvent = Event(name: "Message Test", type: "type", source: "source", data: mockEventData)
    }

    func testMessageInitHappy() throws {
        // setup
        let cache = Cache(name: MessagingConstants.Caches.CACHE_NAME)
        try cache.set(key: mockAssetString, entry: CacheEntry(data: mockAssetString.data(using: .utf8)!, expiry: .never, metadata: nil))

        // test
        let message = Message(parent: mockMessaging, event: mockEvent)

        // verify
        XCTAssertEqual(mockMessaging, message.parent)
        XCTAssertEqual(mockEvent, message.triggeringEvent)
        XCTAssertEqual(mockMessageId, message.id)        
        XCTAssertNotNil(message.fullscreenMessage)
        XCTAssertNotNil(message.assets)
        XCTAssertEqual(1, message.assets?.count)
        XCTAssertEqual(true, message.fullscreenMessage?.isLocalImageUsed)

        // cleanup
        try cache.remove(key: mockAssetString)
    }

    func testMessageInitUsingDefaultValues() throws {
        // test
        mockEventData = [
            MessagingConstants.Event.Data.Key.TRIGGERED_CONSEQUENCE: [
                MessagingConstants.Event.Data.Key.DETAIL: [:]
            ]
        ]
        mockEvent = Event(name: "Message Test", type: "type", source: "source", data: mockEventData)
        let message = Message(parent: mockMessaging, event: mockEvent)

        // verify
        XCTAssertEqual(mockMessaging, message.parent)
        XCTAssertEqual(mockEvent, message.triggeringEvent)
        XCTAssertEqual("", message.id)
        XCTAssertEqual(0, message.experienceInfo.count)
        XCTAssertNotNil(message.fullscreenMessage)
        XCTAssertNil(message.assets)
        XCTAssertEqual(false, message.fullscreenMessage?.isLocalImageUsed)
    }

    func testShow() throws {
        // setup
        let message = Message(parent: mockMessaging, event: mockEvent)
        message.fullscreenMessage?.listener = self
        onShowExpectation = XCTestExpectation(description: "onShow called")

        // test
        message.show()

        // verify
        wait(for: [onShowExpectation!], timeout: ASYNC_TIMEOUT)
    }

    func testDismiss() throws {
        // setup
        let message = Message(parent: mockMessaging, event: mockEvent)
        message.show() // onDismiss will not get called if the message isn't currently being shown
        message.fullscreenMessage?.listener = self
        onDismissExpectation = XCTestExpectation(description: "onDismiss called")

        // test
        message.dismiss()

        // verify
        wait(for: [onDismissExpectation!], timeout: ASYNC_TIMEOUT)
    }

    func testHandleJavascriptMessage() throws {
        // setup
        let message = Message(parent: mockMessaging, event: mockEvent)
        let mockFullscreenMessage = MockFullscreenMessage(parent: message)
        mockFullscreenMessage.paramJavascriptHandlerReturnValue = "abc"
        message.fullscreenMessage = mockFullscreenMessage
        handleJavascriptMessageExpectation = XCTestExpectation(description: "jsHandler called")

        // test
        message.handleJavascriptMessage("test") { body in
            XCTAssertEqual("abc", body as? String)
            self.handleJavascriptMessageExpectation?.fulfill()
        }

        // verify
        wait(for: [handleJavascriptMessageExpectation!], timeout: ASYNC_TIMEOUT)
        XCTAssertTrue(mockFullscreenMessage.handleJavascriptMessageCalled)
        XCTAssertEqual("test", mockFullscreenMessage.paramJavascriptMessage)
    }

    func testViewAccess() throws {
        // setup
        let message = Message(parent: mockMessaging, event: mockEvent)
        let mockFullscreenMessage = MockFullscreenMessage(parent: message)
        message.fullscreenMessage = mockFullscreenMessage

        // verify
        XCTAssertNotNil(message.view)
        XCTAssertTrue(message.view is WKWebView)
    }

    func testTriggerable() throws {
        // setup
        let message = Message(parent: mockMessaging, event: mockEvent)

        // verify
        message.trigger()
    }

    // MARK: - FullscreenMessageDelegate

    public func onShow(message _: FullscreenMessage) {
        onShowExpectation?.fulfill()
    }

    public func onShowFailure() {}

    public func onDismiss(message _: FullscreenMessage) {
        onDismissExpectation?.fulfill()
    }

    public func overrideUrlLoad(message _: FullscreenMessage, url _: String?) -> Bool {
        true
    }
}
