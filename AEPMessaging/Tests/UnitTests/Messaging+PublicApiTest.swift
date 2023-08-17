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
        expectation.isInverted = true

        EventHub.shared.getExtensionContainer(MockExtension.self)?.eventListeners.clear()

        
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent) { event in
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
        wait(for: [expectation], timeout: 1)
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
}
