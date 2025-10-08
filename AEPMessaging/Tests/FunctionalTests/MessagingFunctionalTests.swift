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
import AEPTestUtils
import XCTest

class MessagingFunctionalTests: XCTestCase, AnyCodableAsserts {
    var messaging: Messaging!
    var mockRuntime: TestableExtensionRuntime!
    var mockConfigSharedState: [String: Any] = [:]
    var stateManager: MessagingStateManager!

    override func setUp() {
        // clear the push identifier from persistence prior to each test
        stateManager = MessagingStateManager()
        stateManager.pushIdentifier = nil
        mockRuntime = TestableExtensionRuntime()
        mockRuntime.ignoreEvent(type: EventType.rulesEngine, source: EventSource.requestReset)
        messaging = Messaging(runtime: mockRuntime)
        messaging.onRegistered()
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
    }

    // MARK: - Handle Notification Response

    func testPushTokenSync() {
        let data = [MessagingConstants.Event.Data.Key.PUSH_IDENTIFIER: "mockPushToken"] as [String: Any]
        let event = Event(name: "", type: EventType.genericIdentity, source: EventSource.requestContent, data: data)

        // mock configuration shared state
        mockRuntime.simulateSharedState(for: (extensionName: "com.adobe.module.configuration", event: event), data: (value: mockConfigSharedState, status: .set))

        // creates an edge identity's xdm shared state
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: "MOCK_ECID"]]]]
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))

        mockRuntime.simulateComingEvents(event)
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        guard let edgeEvent = mockRuntime.firstEvent else {
            XCTFail("Unable to find Edge event")
            return
        }

        XCTAssertEqual(edgeEvent.type, EventType.edge)
        
        let expectedJSON = """
        {
          "data": {
            "pushNotificationDetails": [
              {
                "identity": {
                  "id": "MOCK_ECID",
                  "namespace": {
                    "code": "ECID"
                  }
                },
                "token": "mockPushToken",
                "appID": "com.adobe.ajo.e2eTestApp",
                "denylisted": false,
                "platform": "apns"
              }
            ]
          }
        }
        """
        
        assertExactMatch(expected: expectedJSON, actual: edgeEvent)
        if let dataDict = edgeEvent.data?["data"] as? [String: Any],
           let pushNotificationDetails = dataDict["pushNotificationDetails"] as? [[String: Any]] {
            XCTAssertEqual(1, pushNotificationDetails.count)
        }

        // verify that push token is shared in sharedState
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)
        XCTAssertEqual("mockPushToken", mockRuntime.firstSharedState![MessagingConstants.SharedState.Messaging.PUSH_IDENTIFIER] as! String)
    }

    func testPushTokenSync_emptyToken() {
        let data = [MessagingConstants.Event.Data.Key.PUSH_IDENTIFIER: ""] as [String: Any]
        let event = Event(name: "", type: EventType.genericIdentity, source: EventSource.requestContent, data: data)

        // mock configuration shared state
        mockRuntime.simulateSharedState(for: (extensionName: "com.adobe.module.configuration", event: event), data: (value: mockConfigSharedState, status: .set))

        // creates an edge identity's xdm shared state
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: "MOCK_ECID"]]]]
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))

        mockRuntime.simulateComingEvents(event)
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // verify that push token is not shared in sharedState
        XCTAssertEqual(0, mockRuntime.createdSharedStates.count)
    }

    func testPushTokenSync_noECID() {
        let data = [MessagingConstants.Event.Data.Key.PUSH_IDENTIFIER: true] as [String: Any] // pushtoken is an boolean instead of string
        let event = Event(name: "", type: EventType.genericIdentity, source: EventSource.requestContent, data: data)

        // mock configuration shared state
        mockRuntime.simulateSharedState(for: (extensionName: "com.adobe.module.configuration", event: event), data: (value: mockConfigSharedState, status: .set))

        // creates an edge identity's xdm shared state
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: ""]]]]
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))

        mockRuntime.simulateComingEvents(event)
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // verify that push token is not shared in sharedState
        XCTAssertEqual(0, mockRuntime.createdSharedStates.count)
    }

    func testPushTokenSync_invalidPushId() {
        let data = [MessagingConstants.Event.Data.Key.PUSH_IDENTIFIER: "mockPushToken"] as [String: Any]
        let event = Event(name: "", type: EventType.genericIdentity, source: EventSource.requestContent, data: data)

        // mock configuration shared state
        mockRuntime.simulateSharedState(for: (extensionName: "com.adobe.module.configuration", event: event), data: (value: mockConfigSharedState, status: .set))

        // creates an edge identity's xdm shared state
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: ""]]]]
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))

        mockRuntime.simulateComingEvents(event)
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // verify that push token is shared in sharedState
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)
        XCTAssertEqual("mockPushToken", try XCTUnwrap(mockRuntime.firstSharedState?[MessagingConstants.SharedState.Messaging.PUSH_IDENTIFIER] as? String))
    }

    func testPushTokenSync_withSandbox() {
        mockConfigSharedState["messaging.useSandbox"] = true
        let data = [MessagingConstants.Event.Data.Key.PUSH_IDENTIFIER: "mockPushToken"] as [String: Any]
        let event = Event(name: "", type: EventType.genericIdentity, source: EventSource.requestContent, data: data)

        // mock configuration shared state
        mockRuntime.simulateSharedState(for: (extensionName: "com.adobe.module.configuration", event: event), data: (value: mockConfigSharedState, status: .set))

        // creates an edge identity's xdm shared state
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: "MOCK_ECID"]]]]
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))

        mockRuntime.simulateComingEvents(event)
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let edgeEvent = mockRuntime.dispatchedEvents[0]
        
        XCTAssertEqual(edgeEvent.type, EventType.edge)

        let expectedJSON = """
        {
          "data": {
            "pushNotificationDetails": [
              {
                "identity": {
                  "id": "MOCK_ECID",
                  "namespace": {
                    "code": "ECID"
                  }
                },
                "token": "mockPushToken",
                "appID": "com.adobe.ajo.e2eTestApp",
                "denylisted": false,
                "platform": "apnsSandbox"
              }
            ]
          }
        }
        """
        
        assertExactMatch(expected: expectedJSON, actual: edgeEvent)
        if let dataDict = edgeEvent.data?["data"] as? [String: Any],
           let pushNotificationDetails = dataDict["pushNotificationDetails"] as? [[String: Any]] {
            XCTAssertEqual(1, pushNotificationDetails.count)
        }

        // verify that push token is shared in sharedState
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)
        XCTAssertEqual("mockPushToken", mockRuntime.firstSharedState![MessagingConstants.SharedState.Messaging.PUSH_IDENTIFIER] as! String)
    }
}
