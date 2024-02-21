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
import AEPTestUtils
import WebKit

class MessageTests: XCTestCase {
    let ASYNC_TIMEOUT = 5.0
    var mockMessaging: MockMessaging!
    var mockRuntime: TestableExtensionRuntime!
    var mockEvent: Event!
    var mockEventData: [String: Any]?
    let mockAssetString = "https://blog.adobe.com/en/publish/2020/05/28/media_1cc0fcc19cf0e64decbceb3a606707a3ad23f51dd.png"
    let mockMessageId = "552"
    var mockInAppItemData: [String: Any]!
    var mockPropositionItem: PropositionItem!
    var mockPropositionInfo: PropositionInfo!
    let mockPropId = "1337"
    let mockPropScope = "mobileapp://com.apple.dt.xctest.tool"
    let mockPropScopeDetails: [String: AnyCodable] = ["activity":["id":"1337"]]
    var onShowExpectation: XCTestExpectation?
    var onDismissExpectation: XCTestExpectation?
    var handleJavascriptMessageExpectation: XCTestExpectation?
        
    override func setUp() {
        mockInAppItemData = JSONFileLoader.getRulesJsonFromFile("mockPropositionItem")
        
        mockRuntime = TestableExtensionRuntime()
        mockMessaging = MockMessaging(runtime: mockRuntime)

        mockEventData = [
            MessagingConstants.Event.Data.Key.TRIGGERED_CONSEQUENCE: [
                MessagingConstants.Event.Data.Key.ID: mockMessageId,
                MessagingConstants.Event.Data.Key.DETAIL: [
                    MessagingConstants.Event.Data.Key.IAM.REMOTE_ASSETS: [mockAssetString],
                    "mobileParameters": TestableMobileParameters.mobileParameters
                ]
            ]
        ]
        
        mockEvent = Event(name: "Message Test", type: "type", source: "source", data: mockEventData)
        mockPropositionInfo = PropositionInfo(id: mockPropId, scope: mockPropScope, scopeDetails: mockPropScopeDetails)
    }

    func testCreateFromPropositionItemHappy() throws {
        // setup
        mockPropositionItem = PropositionItem(itemId: "itemId", schema: .inapp, itemData: mockInAppItemData)
        let cache = Cache(name: MessagingConstants.Caches.CACHE_NAME)
        try cache.set(key: mockAssetString, entry: CacheEntry(data: mockAssetString.data(using: .utf8)!, expiry: .never, metadata: nil))

        // test
        guard let message = Message.fromPropositionItem(mockPropositionItem, with: mockMessaging, triggeringEvent: mockEvent) else {
            XCTFail("failed to create message from convenience constructor.")
            return
        }

        // verify
        XCTAssertEqual(mockMessaging, message.parent)
        XCTAssertEqual(mockEvent, message.triggeringEvent)
        XCTAssertEqual("itemId", message.id)
        XCTAssertNotNil(message.fullscreenMessage)
        XCTAssertNotNil(message.assets)
        XCTAssertEqual(1, message.assets?.count)

        // cleanup
        try cache.remove(key: mockAssetString)
    }
    
    func testCreateFromPropositionItemAssetNotInCache() throws {
        // setup
        mockPropositionItem = PropositionItem(itemId: "itemId", schema: .inapp, itemData: mockInAppItemData)

        // test
        guard let message = Message.fromPropositionItem(mockPropositionItem, with: mockMessaging, triggeringEvent: mockEvent) else {
            XCTFail("failed to create message from convenience constructor.")
            return
        }

        // verify
        XCTAssertEqual(mockMessaging, message.parent)
        XCTAssertEqual(mockEvent, message.triggeringEvent)
        XCTAssertEqual("itemId", message.id)
        XCTAssertNotNil(message.fullscreenMessage)
        XCTAssertNotNil(message.assets)
        XCTAssertEqual(0, message.assets?.count)
    }
    
    func testCreateFromPropositionItemNoAssets() throws {
        // setup
        mockInAppItemData?.removeValue(forKey: "remoteAssets")
        mockPropositionItem = PropositionItem(itemId: "itemId", schema: .inapp, itemData: mockInAppItemData)
        let cache = Cache(name: MessagingConstants.Caches.CACHE_NAME)
        try cache.set(key: mockAssetString, entry: CacheEntry(data: mockAssetString.data(using: .utf8)!, expiry: .never, metadata: nil))

        // test
        guard let message = Message.fromPropositionItem(mockPropositionItem, with: mockMessaging, triggeringEvent: mockEvent) else {
            XCTFail("failed to create message from convenience constructor.")
            return
        }

        // verify
        XCTAssertEqual(mockMessaging, message.parent)
        XCTAssertEqual(mockEvent, message.triggeringEvent)
        XCTAssertEqual("itemId", message.id)
        XCTAssertNotNil(message.fullscreenMessage)
        XCTAssertNil(message.assets)

        // cleanup
        try cache.remove(key: mockAssetString)
    }
    
    func testCreateFromPropositionItemNotIamSchemaData() throws {
        // setup
        mockPropositionItem = PropositionItem(itemId: "itemId", schema: .htmlContent, itemData: [:])

        // test
        let message = Message.fromPropositionItem(mockPropositionItem, with: mockMessaging, triggeringEvent: mockEvent)
        
        // verify
        XCTAssertNil(message)
    }
    
    func testWKWebViewIsGettable() throws {
        // setup
        mockPropositionItem = PropositionItem(itemId: "itemId", schema: .inapp, itemData: mockInAppItemData)
        onShowExpectation = XCTestExpectation(description: "onShow called")
        
        // test
        guard let message = Message.fromPropositionItem(mockPropositionItem, with: mockMessaging, triggeringEvent: mockEvent) else {
            XCTFail("failed to create message from convenience constructor.")
            return
        }
        message.fullscreenMessage?.listener = self
        message.show()
        wait(for: [onShowExpectation!], timeout: ASYNC_TIMEOUT)
        
        // test
        let webView = message.view as? WKWebView

        // verify
        XCTAssertNotNil(webView)
        
        // cleanup
        message.dismiss()
    }
    
    func testShow() throws {
        // setup
        mockPropositionItem = PropositionItem(itemId: "itemId", schema: .inapp, itemData: mockInAppItemData)
        onShowExpectation = XCTestExpectation(description: "onShow called")
        
        // test
        guard let message = Message.fromPropositionItem(mockPropositionItem, with: mockMessaging, triggeringEvent: mockEvent) else {
            XCTFail("failed to create message from convenience constructor.")
            return
        }
        message.fullscreenMessage?.listener = self

        // test
        message.show()

        // verify
        wait(for: [onShowExpectation!], timeout: ASYNC_TIMEOUT)
        
        // cleanup
        message.dismiss()
    }
    
    func testDismiss() throws {
        // setup
        mockPropositionItem = PropositionItem(itemId: "itemId", schema: .inapp, itemData: mockInAppItemData)
        onDismissExpectation = XCTestExpectation(description: "onDismiss called")
        guard let message = Message.fromPropositionItem(mockPropositionItem, with: mockMessaging, triggeringEvent: mockEvent) else {
            XCTFail("failed to create message from convenience constructor.")
            return
        }
        message.fullscreenMessage?.listener = self
        
        // onDismiss will not get called if the message isn't currently being shown
        onShowExpectation = XCTestExpectation(description: "onShow called")
        message.show()
        wait(for: [onShowExpectation!], timeout: ASYNC_TIMEOUT)

        // test
        message.dismiss()

        // verify
        wait(for: [onDismissExpectation!], timeout: ASYNC_TIMEOUT)
    }
    
    func testTrackInteraction() throws {
        // setup
        mockPropositionItem = PropositionItem(itemId: "itemId", schema: .inapp, itemData: mockInAppItemData)
        guard let message = Message.fromPropositionItem(mockPropositionItem, with: mockMessaging, triggeringEvent: mockEvent) else {
            XCTFail("failed to create message from convenience constructor.")
            return
        }
        message.propositionInfo = mockPropositionInfo

        // test
        message.track("mockInteraction", withEdgeEventType: .interact)

        // verify
        XCTAssertEqual(1, mockMessaging.testableRuntime.dispatchedEvents.count)
    }
    
    func testTrackDisplay() throws {
        // setup
        mockPropositionItem = PropositionItem(itemId: "itemId", schema: .inapp, itemData: mockInAppItemData)
        guard let message = Message.fromPropositionItem(mockPropositionItem, with: mockMessaging, triggeringEvent: mockEvent) else {
            XCTFail("failed to create message from convenience constructor.")
            return
        }
        message.propositionInfo = mockPropositionInfo

        // test
        message.track(nil, withEdgeEventType: .display)

        // verify
        XCTAssertEqual(1, mockMessaging.testableRuntime.dispatchedEvents.count)
    }
    
    func testTrackNoPropositionInfo() throws {
        // setup
        mockPropositionItem = PropositionItem(itemId: "itemId", schema: .inapp, itemData: mockInAppItemData)
        guard let message = Message.fromPropositionItem(mockPropositionItem, with: mockMessaging, triggeringEvent: mockEvent) else {
            XCTFail("failed to create message from convenience constructor.")
            return
        }

        // test
        message.track("mockInteraction", withEdgeEventType: .interact)

        // verify
        XCTAssertEqual(0, mockMessaging.testableRuntime.dispatchedEvents.count)
    }

    func testHandleJavascriptMessage() throws {
        // setup
        mockPropositionItem = PropositionItem(itemId: "itemId", schema: .inapp, itemData: mockInAppItemData)
        guard let message = Message.fromPropositionItem(mockPropositionItem, with: mockMessaging, triggeringEvent: mockEvent) else {
            XCTFail("failed to create message from convenience constructor.")
            return
        }
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

    func testTriggerableWithAutoTrack() throws {
        // setup
        mockPropositionItem = PropositionItem(itemId: "itemId", schema: .inapp, itemData: mockInAppItemData)
        guard let message = Message.fromPropositionItem(mockPropositionItem, with: mockMessaging, triggeringEvent: mockEvent) else {
            XCTFail("failed to create message from convenience constructor.")
            return
        }
        message.propositionInfo = mockPropositionInfo

        // test
        message.trigger()

        // verify
        XCTAssertEqual(2, mockMessaging.testableRuntime.dispatchedEvents.count)
        let trackEvent = mockMessaging.testableRuntime.firstEvent
        XCTAssertEqual("Messaging interaction event", trackEvent?.name)
        let eventHistoryEvent = mockMessaging.testableRuntime.secondEvent
        XCTAssertEqual("Write IAM event to history", eventHistoryEvent?.name)
    }
    
    func testTriggerableNoAutoTrack() throws {
        // setup
        mockPropositionItem = PropositionItem(itemId: "itemId", schema: .inapp, itemData: mockInAppItemData)
        guard let message = Message.fromPropositionItem(mockPropositionItem, with: mockMessaging, triggeringEvent: mockEvent) else {
            XCTFail("failed to create message from convenience constructor.")
            return
        }
        message.propositionInfo = mockPropositionInfo
        message.autoTrack = false

        // test
        message.trigger()

        // verify
        XCTAssertEqual(1, mockMessaging.testableRuntime.dispatchedEvents.count)
        let eventHistoryEvent = mockMessaging.testableRuntime.firstEvent
        XCTAssertEqual("Write IAM event to history", eventHistoryEvent?.name)
    }
    
    func testRecordEventHistoryHappy() throws {
        // setup
        mockPropositionItem = PropositionItem(itemId: "itemId", schema: .inapp, itemData: mockInAppItemData)
        guard let message = Message.fromPropositionItem(mockPropositionItem, with: mockMessaging, triggeringEvent: mockEvent) else {
            XCTFail("failed to create message from convenience constructor.")
            return
        }
        message.propositionInfo = mockPropositionInfo

        // test
        message.recordEventHistory(eventType: .display, interaction: "interaction")

        // verify
        XCTAssertEqual(1, mockMessaging.testableRuntime.dispatchedEvents.count)
        let eventHistoryEvent = mockMessaging.testableRuntime.firstEvent
        XCTAssertEqual(EventType.messaging, eventHistoryEvent?.type)
        XCTAssertEqual(MessagingConstants.Event.Source.EVENT_HISTORY_WRITE, eventHistoryEvent?.source)
        let eventData = eventHistoryEvent?.data
        XCTAssertEqual(1, eventData?.count)
        let iamMap = try XCTUnwrap(eventData?["iam"] as? [String: Any])
        XCTAssertEqual(3, iamMap.count)
        let iamEventType = try XCTUnwrap(iamMap["eventType"] as? String)
        XCTAssertEqual("display", iamEventType)
        let iamMessageId = try XCTUnwrap(iamMap["id"] as? String)
        XCTAssertEqual(mockPropId, iamMessageId)
        let iamAction = try XCTUnwrap(iamMap["action"] as? String)
        XCTAssertEqual("interaction", iamAction)
        XCTAssertNotNil(eventHistoryEvent?.mask)
        XCTAssertEqual(3, eventHistoryEvent?.mask?.count)
        XCTAssertEqual("iam.eventType", eventHistoryEvent?.mask?[0])
        XCTAssertEqual("iam.id", eventHistoryEvent?.mask?[1])
        XCTAssertEqual("iam.action", eventHistoryEvent?.mask?[2])
    }
    
    func testRecordEventHistoryNoPropInfo() throws {
        // setup
        mockPropositionItem = PropositionItem(itemId: "itemId", schema: .inapp, itemData: mockInAppItemData)
        guard let message = Message.fromPropositionItem(mockPropositionItem, with: mockMessaging, triggeringEvent: mockEvent) else {
            XCTFail("failed to create message from convenience constructor.")
            return
        }

        // test
        message.recordEventHistory(eventType: .display, interaction: "interaction")

        // verify
        XCTAssertEqual(0, mockMessaging.testableRuntime.dispatchedEvents.count)
    }
    
    func testRecordEventHistoryNoInteraction() throws {
        // setup
        mockPropositionItem = PropositionItem(itemId: "itemId", schema: .inapp, itemData: mockInAppItemData)
        guard let message = Message.fromPropositionItem(mockPropositionItem, with: mockMessaging, triggeringEvent: mockEvent) else {
            XCTFail("failed to create message from convenience constructor.")
            return
        }
        message.propositionInfo = mockPropositionInfo

        // test
        message.recordEventHistory(eventType: .display, interaction: nil)

        // verify
        XCTAssertEqual(1, mockMessaging.testableRuntime.dispatchedEvents.count)
        let eventHistoryEvent = mockMessaging.testableRuntime.firstEvent
        XCTAssertEqual(EventType.messaging, eventHistoryEvent?.type)
        XCTAssertEqual(MessagingConstants.Event.Source.EVENT_HISTORY_WRITE, eventHistoryEvent?.source)
        let eventData = eventHistoryEvent?.data
        XCTAssertEqual(1, eventData?.count)
        let iamMap = try XCTUnwrap(eventData?["iam"] as? [String: Any])
        XCTAssertEqual(3, iamMap.count)
        let iamEventType = try XCTUnwrap(iamMap["eventType"] as? String)
        XCTAssertEqual("display", iamEventType)
        let iamMessageId = try XCTUnwrap(iamMap["id"] as? String)
        XCTAssertEqual(mockPropId, iamMessageId)
        let iamAction = try XCTUnwrap(iamMap["action"] as? String)
        XCTAssertEqual("", iamAction)
        XCTAssertNotNil(eventHistoryEvent?.mask)
        XCTAssertEqual(3, eventHistoryEvent?.mask?.count)
        XCTAssertEqual("iam.eventType", eventHistoryEvent?.mask?[0])
        XCTAssertEqual("iam.id", eventHistoryEvent?.mask?[1])
        XCTAssertEqual("iam.action", eventHistoryEvent?.mask?[2])
    }
}

extension MessageTests: FullscreenMessageDelegate {
    public func onShow(message: FullscreenMessage) {
        onShowExpectation?.fulfill()
    }

    public func onShowFailure() {}

    public func onDismiss(message: FullscreenMessage) {
        onDismissExpectation?.fulfill()
    }

    public func overrideUrlLoad(message _: FullscreenMessage, url _: String?) -> Bool {
        true
    }
}
