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
    var mockXdmData: [String: Any] = ["somekey": "somedata"]
    var notificationContent: [AnyHashable: Any] = [:]
    override func setUp() {
        notificationContent = [MessagingConstants.AdobeTrackingKeys._XDM: mockXdmData]
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
        let mockCustomActinoId = "mockCustomActionId"
        let mockIdentifier = "mockIdentifier"
        expectation.assertForOverFulfill = true

        EventHub.shared.getExtensionContainer(MockExtension.self)?.eventListeners.clear()
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: MessagingConstants.EventType.messaging, source: EventSource.requestContent) { event in
            XCTAssertEqual(MessagingConstants.EventName.PUSH_NOTIFICATION_INTERACTION, event.name)
            XCTAssertEqual(MessagingConstants.EventType.messaging, event.type)
            XCTAssertEqual(EventSource.requestContent, event.source)

            guard let eventData = event.data,
                let applicationOpened = eventData[MessagingConstants.EventDataKeys.APPLICATION_OPENED] as? Bool,
                let eventDataType = eventData[MessagingConstants.EventDataKeys.EVENT_TYPE] as? String,
                let actionId = eventData[MessagingConstants.EventDataKeys.ACTION_ID] as? String,
                let messageId = eventData[MessagingConstants.EventDataKeys.MESSAGE_ID] as? String,
                let xdm = eventData[MessagingConstants.EventDataKeys.ADOBE_XDM] as? [String: Any]
                else {
                    XCTFail()
                    expectation.fulfill()
                    return
            }

            XCTAssertTrue(applicationOpened)
            XCTAssertEqual(MessagingConstants.EventDataValue.PUSH_TRACKING_CUSTOM_ACTION, eventDataType)
            XCTAssertEqual(actionId, mockCustomActinoId)
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
        Messaging.handleNotificationResponse(response, applicationOpened: true, customActionId: mockCustomActinoId)
        wait(for: [expectation], timeout: 1)
    }
}
