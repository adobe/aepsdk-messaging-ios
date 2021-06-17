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

@testable import AEPCore
@testable import AEPMessaging
@testable import AEPServices
import XCTest

class MessagingFunctionalTests: XCTestCase {
    var messaging: Messaging!
    var mockRuntime: TestableExtensionRuntime!
    var mockConfigSharedState: [String: Any] = [:]

    override func setUp() {
        mockRuntime = TestableExtensionRuntime()
        messaging = Messaging(runtime: mockRuntime)
        messaging.onRegistered()
    }

    // MARK: - Handle Notification Response

    func testPushTokenSync() {
        let data = [MessagingConstants.EventDataKeys.PUSH_IDENTIFIER: "mockPushToken"] as [String: Any]
        let event = Event(name: "", type: EventType.genericIdentity, source: EventSource.requestContent, data: data)

        // mock configuration shared state
        mockRuntime.simulateSharedState(for: (extensionName: "com.adobe.module.configuration", event: event), data: (value: mockConfigSharedState, status: .set))

        // creates an edge identity's xdm shared state
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: "MOCK_ECID"]]]]
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))

        mockRuntime.simulateComingEvents(event)
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        let edgeEvent = mockRuntime.dispatchedEvents[1]

        XCTAssertEqual(edgeEvent.type, EventType.edge)
        let flattenEdgeEvent = edgeEvent.data?.flattening()
        let pushNotification = flattenEdgeEvent?["data.pushNotificationDetails"] as? [[String: Any]]
        XCTAssertEqual(1, pushNotification?.count)
        let flattenedPushNotification = pushNotification?.first?.flattening()
        XCTAssertEqual("MOCK_ECID", flattenedPushNotification?["identity.id"] as? String)
        XCTAssertEqual("mockPushToken", flattenedPushNotification?["token"] as? String)
        XCTAssertEqual("com.apple.dt.xctest.tool", flattenedPushNotification?["appID"] as? String)
        XCTAssertEqual(false, flattenedPushNotification?["denylisted"] as? Bool)
        XCTAssertEqual("ECID", flattenedPushNotification?["identity.namespace.code"] as? String)
        XCTAssertEqual("apns", flattenedPushNotification?["platform"] as? String)

        // verify that push token is shared in sharedState
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)
        XCTAssertEqual("mockPushToken", mockRuntime.firstSharedState![MessagingConstants.SharedState.Messaging.PUSH_IDENTIFIER] as! String)
    }

    func testPushTokenSync_emptyToken() {
        let data = [MessagingConstants.EventDataKeys.PUSH_IDENTIFIER: ""] as [String: Any]
        let event = Event(name: "", type: EventType.genericIdentity, source: EventSource.requestContent, data: data)

        // mock configuration shared state
        mockRuntime.simulateSharedState(for: (extensionName: "com.adobe.module.configuration", event: event), data: (value: mockConfigSharedState, status: .set))

        // creates an edge identity's xdm shared state
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: "MOCK_ECID"]]]]
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))

        mockRuntime.simulateComingEvents(event)
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count, "only an event to retrieve in-app messages should be dispatched")

        // verify that push token is not shared in sharedState
        XCTAssertEqual(0, mockRuntime.createdSharedStates.count)
    }

    func testPushTokenSync_noECID() {
        let data = [MessagingConstants.EventDataKeys.PUSH_IDENTIFIER: true] as [String: Any] // pushtoken is an boolean instead of string
        let event = Event(name: "", type: EventType.genericIdentity, source: EventSource.requestContent, data: data)

        // mock configuration shared state
        mockRuntime.simulateSharedState(for: (extensionName: "com.adobe.module.configuration", event: event), data: (value: mockConfigSharedState, status: .set))

        // creates an edge identity's xdm shared state
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: ""]]]]
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))

        mockRuntime.simulateComingEvents(event)
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count, "only an event to retrieve in-app messages should be dispatched")

        // verify that push token is not shared in sharedState
        XCTAssertEqual(0, mockRuntime.createdSharedStates.count)
    }

    func testPushTokenSync_invalidPushId() {
        let data = [MessagingConstants.EventDataKeys.PUSH_IDENTIFIER: "mockPushToken"] as [String: Any]
        let event = Event(name: "", type: EventType.genericIdentity, source: EventSource.requestContent, data: data)

        // mock configuration shared state
        mockRuntime.simulateSharedState(for: (extensionName: "com.adobe.module.configuration", event: event), data: (value: mockConfigSharedState, status: .set))

        // creates an edge identity's xdm shared state
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: ""]]]]
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))

        mockRuntime.simulateComingEvents(event)
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count, "only an event to retrieve in-app messages should be dispatched")

        // verify that push token is shared in sharedState
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)
        XCTAssertEqual("mockPushToken", try XCTUnwrap(mockRuntime.firstSharedState?[MessagingConstants.SharedState.Messaging.PUSH_IDENTIFIER] as? String))
    }

    func testPushTokenSync_withSandbox() {
        mockConfigSharedState["messaging.useSandbox"] = true
        let data = [MessagingConstants.EventDataKeys.PUSH_IDENTIFIER: "mockPushToken"] as [String: Any]
        let event = Event(name: "", type: EventType.genericIdentity, source: EventSource.requestContent, data: data)

        // mock configuration shared state
        mockRuntime.simulateSharedState(for: (extensionName: "com.adobe.module.configuration", event: event), data: (value: mockConfigSharedState, status: .set))

        // creates an edge identity's xdm shared state
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: "MOCK_ECID"]]]]
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))

        mockRuntime.simulateComingEvents(event)
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        let edgeEvent = mockRuntime.dispatchedEvents[1]

        XCTAssertEqual(edgeEvent.type, EventType.edge)
        let flattenEdgeEvent = edgeEvent.data?.flattening()
        let pushNotification = flattenEdgeEvent?["data.pushNotificationDetails"] as? [[String: Any]]
        XCTAssertEqual(1, pushNotification?.count)
        let flattenedPushNotification = pushNotification?.first?.flattening()
        XCTAssertEqual("MOCK_ECID", flattenedPushNotification?["identity.id"] as? String)
        XCTAssertEqual("mockPushToken", flattenedPushNotification?["token"] as? String)
        XCTAssertEqual("com.apple.dt.xctest.tool", flattenedPushNotification?["appID"] as? String)
        XCTAssertEqual(false, flattenedPushNotification?["denylisted"] as? Bool)
        XCTAssertEqual("ECID", flattenedPushNotification?["identity.namespace.code"] as? String)
        XCTAssertEqual("apnsSandbox", flattenedPushNotification?["platform"] as? String)

        // verify that push token is shared in sharedState
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)
        XCTAssertEqual("mockPushToken", mockRuntime.firstSharedState![MessagingConstants.SharedState.Messaging.PUSH_IDENTIFIER] as! String)
    }
}
