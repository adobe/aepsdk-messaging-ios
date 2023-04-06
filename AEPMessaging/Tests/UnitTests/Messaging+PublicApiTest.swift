//
// Copyright 2021 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

@testable import AEPCore
@testable import AEPServices
@testable import AEPMessaging
import UserNotifications
import XCTest

class MessagingPublicApiTest: XCTestCase {
    let ASYNC_TIMEOUT = 2.0
    var mockXdmData: [String: Any] = ["somekey": "somedata"]
    var notificationContent: [AnyHashable: Any] = [:]
    override func setUp() {
        notificationContent = [MessagingConstants.XDM.AdobeKeys._XDM: mockXdmData]
        MockExtension.reset()
        EventHub.shared.start()
        registerMockExtension(MockExtension.self)
    }

    private func registerMockExtension<T: Extension>(_ type: T.Type) {
        let semaphore = DispatchSemaphore(value: 0)
        EventHub.shared.registerExtension(type) { _ in
            semaphore.signal()
        }

        semaphore.wait()
    }

    func testHandleNotificationResponse() {
        let expectation = XCTestExpectation(description: "Messaging request event")
        let mockCustomActionId = "mockCustomActionId"
        let mockIdentifier = "mockIdentifier"
        expectation.assertForOverFulfill = true

        EventHub.shared.getExtensionContainer(MockExtension.self)?.eventListeners.clear()

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent) { event in
            XCTAssertEqual(MessagingConstants.Event.Name.PUSH_NOTIFICATION_INTERACTION, event.name)
            XCTAssertEqual(MessagingConstants.Event.EventType.messaging, event.type)
            XCTAssertEqual(EventSource.requestContent, event.source)

            guard let eventData = event.data,
                  let applicationOpened = eventData[MessagingConstants.Event.Data.Key.APPLICATION_OPENED] as? Bool,
                  let eventDataType = eventData[MessagingConstants.Event.Data.Key.EVENT_TYPE] as? String,
                  let actionId = eventData[MessagingConstants.Event.Data.Key.ACTION_ID] as? String,
                  let messageId = eventData[MessagingConstants.Event.Data.Key.MESSAGE_ID] as? String,
                  let xdm = eventData[MessagingConstants.Event.Data.Key.ADOBE_XDM] as? [String: Any]
            else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertTrue(applicationOpened)
            XCTAssertEqual(MessagingConstants.XDM.Push.EventType.CUSTOM_ACTION, eventDataType)
            XCTAssertEqual(actionId, mockCustomActionId)
            XCTAssertEqual(messageId, mockIdentifier)
            XCTAssertNotNil(xdm)
            XCTAssertEqual(xdm.count, 1)
            XCTAssertEqual(xdm["somekey"] as? String, "somedata")

            expectation.fulfill()
        }

        let dateInfo = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: false)
        let notificationContent = UNMutableNotificationContent()
        notificationContent.userInfo = self.notificationContent

        let request = UNNotificationRequest(identifier: mockIdentifier, content: notificationContent, trigger: trigger)
        guard let response = UNNotificationResponse(coder: MockNotificationResponseCoder(with: request)) else {
            XCTFail()
            return
        }

        Messaging.handleNotificationResponse(response, applicationOpened: true, customActionId: mockCustomActionId)
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
    }

    func testHandleNotificationResponse_whenApplicationOpenedFalse_AndNilCustomActionID() {
        let expectation = XCTestExpectation(description: "Messaging request event")
        expectation.assertForOverFulfill = true

        EventHub.shared.getExtensionContainer(MockExtension.self)?.eventListeners.clear()
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent) { event in
            XCTAssertEqual(MessagingConstants.Event.Name.PUSH_NOTIFICATION_INTERACTION, event.name)
            XCTAssertEqual(MessagingConstants.Event.EventType.messaging, event.type)
            XCTAssertEqual(EventSource.requestContent, event.source)

            guard let eventData = event.data else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertFalse(eventData[MessagingConstants.Event.Data.Key.APPLICATION_OPENED] as? Bool ?? true)
            XCTAssertNil(eventData[MessagingConstants.Event.Data.Key.ACTION_ID] as? String)
            expectation.fulfill()
        }

        let dateInfo = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: false)
        let notificationContent = UNMutableNotificationContent()
        notificationContent.userInfo = self.notificationContent

        let request = UNNotificationRequest(identifier: "mockIdentifier", content: notificationContent, trigger: trigger)
        guard let response = UNNotificationResponse(coder: MockNotificationResponseCoder(with: request)) else {
            XCTFail()
            return
        }
        Messaging.handleNotificationResponse(response, applicationOpened: false, customActionId: nil)
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
    }

    func testHandleNotificationResponseNoXdmInNotification() {
        let expectation = XCTestExpectation(description: "Messaging request event")
        let mockCustomActionId = "mockCustomActionId"
        let mockIdentifier = "mockIdentifier"
        expectation.assertForOverFulfill = true

        EventHub.shared.getExtensionContainer(MockExtension.self)?.eventListeners.clear()

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent) { event in
            XCTAssertEqual(MessagingConstants.Event.Name.PUSH_NOTIFICATION_INTERACTION, event.name)
            XCTAssertEqual(MessagingConstants.Event.EventType.messaging, event.type)
            XCTAssertEqual(EventSource.requestContent, event.source)

            guard let eventData = event.data,
                  let applicationOpened = eventData[MessagingConstants.Event.Data.Key.APPLICATION_OPENED] as? Bool,
                  let eventDataType = eventData[MessagingConstants.Event.Data.Key.EVENT_TYPE] as? String,
                  let actionId = eventData[MessagingConstants.Event.Data.Key.ACTION_ID] as? String,
                  let messageId = eventData[MessagingConstants.Event.Data.Key.MESSAGE_ID] as? String,
                  let xdm = eventData[MessagingConstants.Event.Data.Key.ADOBE_XDM] as? [String: Any]
            else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertTrue(applicationOpened)
            XCTAssertEqual(MessagingConstants.XDM.Push.EventType.CUSTOM_ACTION, eventDataType)
            XCTAssertEqual(actionId, mockCustomActionId)
            XCTAssertEqual(messageId, mockIdentifier)
            XCTAssertEqual(0, xdm.count)

            expectation.fulfill()
        }

        let dateInfo = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: false)
        let notificationContent = UNMutableNotificationContent()

        let request = UNNotificationRequest(identifier: mockIdentifier, content: notificationContent, trigger: trigger)
        guard let response = UNNotificationResponse(coder: MockNotificationResponseCoder(with: request)) else {
            XCTFail()
            return
        }

        Messaging.handleNotificationResponse(response, applicationOpened: true, customActionId: mockCustomActionId)
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
    }

    func testHandleNotificationResponseEmptyMessageId() {
        let expectation = XCTestExpectation(description: "Messaging request event")
        let mockCustomActionId = "mockCustomActionId"
        let mockIdentifier = ""
        expectation.assertForOverFulfill = true
        expectation.isInverted = true

        EventHub.shared.getExtensionContainer(MockExtension.self)?.eventListeners.clear()
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent) { _ in
            XCTFail()
            expectation.fulfill()
        }

        let dateInfo = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: false)
        let notificationContent = UNMutableNotificationContent()

        let request = UNNotificationRequest(identifier: mockIdentifier, content: notificationContent, trigger: trigger)
        guard let response = UNNotificationResponse(coder: MockNotificationResponseCoder(with: request)) else {
            XCTFail()
            return
        }

        Messaging.handleNotificationResponse(response, applicationOpened: true, customActionId: mockCustomActionId)
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
    }

    func testRefreshInAppMessages() throws {
        // setup
        let expectation = XCTestExpectation(description: "Refresh In app messages event")
        expectation.assertForOverFulfill = true

        EventHub.shared.getExtensionContainer(MockExtension.self)?.eventListeners.clear()
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent) { event in
            XCTAssertEqual(MessagingConstants.Event.Name.REFRESH_MESSAGES, event.name)
            XCTAssertEqual(MessagingConstants.Event.EventType.messaging, event.type)
            XCTAssertEqual(EventSource.requestContent, event.source)

            guard let eventData = event.data else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertTrue(eventData[MessagingConstants.Event.Data.Key.REFRESH_MESSAGES] as? Bool ?? false)
            expectation.fulfill()
        }

        // test
        Messaging.refreshInAppMessages()

        // verify
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
    }
    
    // MARK: Message Feed Tests
    
    func testUpdateFeedsForSurfacePaths() throws {
        // setup
        let expectation = XCTestExpectation(description: "updateFeedsforSurfacePaths should dispatch an event with expected data.")
        expectation.assertForOverFulfill = true

        let testEvent = Event(name: "Update message feeds",
                              type: "com.adobe.eventType.messaging",
                              source: "com.adobe.eventSource.requestContent",
                              data: [
                                "updatefeeds": true,
                                "surfaces": [
                                    "promos/feed1",
                                    "promos/feed2"
                                ]
                              ])

        
        EventHub.shared.getExtensionContainer(MockExtension.self)?.eventListeners.clear()
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(
            type: testEvent.type,
            source: testEvent.source) { event in
            
            XCTAssertEqual(testEvent.name, event.name)
            XCTAssertNotNil(event.data)
            XCTAssertEqual(true, event.data?["updatefeeds"] as? Bool)
            guard let surfaces = event.data?["surfaces"] as? [String], !surfaces.isEmpty else {
                XCTFail("Surface path strings array should be valid.")
                return
            }
            XCTAssertEqual(2, surfaces.count)
            XCTAssertEqual("promos/feed1", surfaces[0])
            XCTAssertEqual("promos/feed2", surfaces[1])

            expectation.fulfill()
        }

        // test
        Messaging.updateFeedsForSurfacePaths(["promos/feed1", "promos/feed2"])

        // verify
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
    }
    
    func testUpdateFeedsForSurfacePaths_whenValidAndEmptySurfacesInArray() throws {
        // setup
        let expectation = XCTestExpectation(description: "updateFeedsforSurfacePaths should dispatch an event with expected data.")
        expectation.assertForOverFulfill = true

        let testEvent = Event(name: "Update message feeds",
                              type: "com.adobe.eventType.messaging",
                              source: "com.adobe.eventSource.requestContent",
                              data: [
                                "updatefeeds": true,
                                "surfaces": [
                                    "",
                                    "promos/feed2"
                                ]
                              ])

        
        EventHub.shared.getExtensionContainer(MockExtension.self)?.eventListeners.clear()
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(
            type: testEvent.type,
            source: testEvent.source) { event in
            
            XCTAssertEqual(testEvent.name, event.name)
            XCTAssertNotNil(event.data)
            XCTAssertEqual(true, event.data?["updatefeeds"] as? Bool)
            guard let surfaces = event.data?["surfaces"] as? [String], !surfaces.isEmpty else {
                XCTFail("Surface path strings array should be valid.")
                return
            }
            XCTAssertEqual(1, surfaces.count)
            XCTAssertEqual("promos/feed2", surfaces[0])

            expectation.fulfill()
        }

        // test
        Messaging.updateFeedsForSurfacePaths(["", "promos/feed2"])

        // verify
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
    }
    
    func testUpdateFeedsForSurfacePaths_whenEmptySurfaceInArray() {
        // setup
        let expectation = XCTestExpectation(description: "updateFeedsforSurfacePaths should not dispatch an event.")
        expectation.isInverted = true

        // test
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(
            type: "com.adobe.eventType.messaging",
            source: "com.adobe.eventSource.requestContent") { _ in
            expectation.fulfill()
        }

        // test
        Messaging.updateFeedsForSurfacePaths([""])

        // verify
        wait(for: [expectation], timeout: 1)
    }
    
    func testUpdateFeedsForSurfacePaths_whenEmptySurfacesArray() {
        // setup
        let expectation = XCTestExpectation(description: "updateFeedsforSurfacePaths should not dispatch an event.")
        expectation.isInverted = true

        // test
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(
            type: "com.adobe.eventType.messaging",
            source: "com.adobe.eventSource.requestContent") { _ in
            expectation.fulfill()
        }

        // test
        Messaging.updateFeedsForSurfacePaths([])

        // verify
        wait(for: [expectation], timeout: 1)
    }
    
    func testSetFeedsHandler() {
        // setup
        let expectation = XCTestExpectation(description: "setFeedsHandler should be called with response event upon personalization notification.")
        expectation.assertForOverFulfill = true

        let testEvent = Event(name: "Message feeds notification",
                              type: "com.adobe.eventType.messaging",
                              source: "com.adobe.eventSource.notification",
                              data: [
                                "feeds": [
                                    "promos/feed1": [
                                        "surfaceUri": "promos/feed1",
                                        "name": "Promos feed",
                                        "items": [
                                            [
                                                "id": "5c2ec561-49dd-4c8d-80bb-1fd67f6fca5d",
                                                "title": "Flash sale!",
                                                "body": "All winter gear is now up to 30% off at checkout.",
                                                "imageUrl": "https://luma.com/wintersale.png",
                                                "actionUrl": "https://luma.com/sale",
                                                "actionTitle": "Shop the sale!",
                                                "publishedDate": 1677190552,
                                                "expiryDate": 1677243235,
                                                "meta": [
                                                    "feedName": "Winter Promo"
                                                ],
                                                "scopeDetails": [
                                                    "someInnerKey": "someInnerValue"
                                                ]
                                            ]
                                        ]
                                    ]
                                ]
                              ])

        // test
        Messaging.setFeedsHandler { feedsDictionary in
            XCTAssertEqual(1, feedsDictionary.count)
            let feed = feedsDictionary["promos/feed1"]
            XCTAssertNotNil(feed)
            XCTAssertEqual("Promos feed", feed?.name)
            XCTAssertEqual("promos/feed1", feed?.surfaceUri)
            XCTAssertNotNil(feed?.items)
            XCTAssertEqual(1, feed?.items.count)
            let feedItem = feed?.items.first
            XCTAssertEqual("Flash sale!", feedItem?.title)
            XCTAssertEqual("All winter gear is now up to 30% off at checkout.", feedItem?.body)
            XCTAssertEqual("https://luma.com/wintersale.png", feedItem?.imageUrl)
            XCTAssertEqual("https://luma.com/sale", feedItem?.actionUrl)
            XCTAssertEqual("Shop the sale!", feedItem?.actionTitle)
            XCTAssertEqual(1677190552, feedItem?.publishedDate)
            XCTAssertEqual(1677243235, feedItem?.expiryDate)
            XCTAssertNotNil(feedItem?.meta)
            XCTAssertEqual(1, feedItem?.meta?.count)
            XCTAssertEqual("Winter Promo", feedItem?.meta?["feedName"] as? String)
            XCTAssertNotNil(feedItem?.details)
            XCTAssertEqual(1, feedItem?.details.count)
            XCTAssertEqual("someInnerValue", feedItem?.details["someInnerKey"] as? String)
            expectation.fulfill()
        }

        EventHub.shared.dispatch(event: testEvent)

        // verify
        wait(for: [expectation], timeout: 2)
    }
    
    func testSetFeedsHandler_emptyFeeds() {
        // setup
        let expectation = XCTestExpectation(description: "setFeedsHandler should not be called for empty feeds in personalization notification response.")
        expectation.isInverted = true

        let testEvent = Event(name: "Message feeds notification",
                              type: "com.adobe.eventType.messaging",
                              source: "com.adobe.eventSource.notification",
                              data: [
                                "feeds": []
                              ])

        // test
        Messaging.setFeedsHandler { _ in
            expectation.fulfill()
        }

        EventHub.shared.dispatch(event: testEvent)

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testSetFeedsHandler_noFeeds() {
        // setup
        let expectation = XCTestExpectation(description: "setFeedsHandler should not be called for no feeds in personalization notification response.")
        expectation.isInverted = true
        let testEvent = Event(name: "Meesage feeds notification",
                              type: "com.adobe.eventType.messaging",
                              source: "com.adobe.eventSource.notification",
                              data: [:])

        // test
        Messaging.setFeedsHandler { _ in
            expectation.fulfill()
        }

        EventHub.shared.dispatch(event: testEvent)

        // verify
        wait(for: [expectation], timeout: 1)
    }
    
    func testSetFeedsHandler_nilEventData() {
        // setup
        let expectation = XCTestExpectation(description: "setFeedsHandler should not be called for nil event data in personalization notification response.")
        expectation.isInverted = true
        let testEvent = Event(name: "Meesage feeds notification",
                              type: "com.adobe.eventType.messaging",
                              source: "com.adobe.eventSource.notification",
                              data: nil)

        // test
        Messaging.setFeedsHandler { _ in
            expectation.fulfill()
        }

        EventHub.shared.dispatch(event: testEvent)

        // verify
        wait(for: [expectation], timeout: 1)
    }
}
