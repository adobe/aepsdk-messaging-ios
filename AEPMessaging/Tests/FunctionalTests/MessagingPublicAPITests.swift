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

class MessagingPublicAPITests: XCTestCase, AnyCodableAsserts {
    var messaging: Messaging!
    var mockRuntime: TestableExtensionRuntime!
    var mockConfigSharedState: [String: Any] = [:]

    override func setUp() {
        mockConfigSharedState = ["messaging.eventDataset": "mockEventDataset"]
        mockRuntime = TestableExtensionRuntime()
        mockRuntime.ignoreEvent(type: EventType.rulesEngine, source: EventSource.requestReset)
        messaging = Messaging(runtime: mockRuntime)
        messaging.onRegistered()
    }

    // MARK: - Handle Notification Response

    func testHandleNotificationResponse() {
        let event = Event(name: "", type: EventType.messaging, source: EventSource.requestContent, data: getPushInteractionEventData())

        // mock configuration shared state
        mockRuntime.simulateSharedState(for: (extensionName: "com.adobe.module.configuration", event: event), data: (value: mockConfigSharedState, status: .set))

        // creates an edge identity's xdm shared state
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: "MOCK_ECID"]]]]
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))

        mockRuntime.simulateComingEvents(event)
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        let edgeEvent = mockRuntime.dispatchedEvents[1]

        XCTAssertEqual(edgeEvent.type, EventType.edge)
        
        let expectedJSON = """
        {
          "xdm": {
            "pushNotificationTracking": {
              "pushProvider": "apns",
              "pushProviderMessageID": "mockMessageId",
              "customAction": {
                "actionID": "mockCustomActionId"
              }
            },
            "application": {
              "launches": {
                "value": 1
              }
            },
            "eventType": "pushTracking.customAction",
            "_experience": {
              "customerJourneyManagement": {
                "messageExecution": {
                  "journeyVersionID": "some-journeyVersionId",
                  "journeyVersionInstanceId": "someJourneyVersionInstanceId",
                  "messageID": "567",
                  "messageExecutionID": "16-Sept-postman"
                },
                "pushChannelContext": {
                  "platform": "apns"
                },
                "messageProfile": {
                  "channel": {
                    "_id": "https://ns.adobe.com/xdm/channels/push"
                  }
                }
              }
            }
          },
          "meta": {
            "collect": {
              "datasetId": "mockEventDataset"
            }
          }
        }
        """
        
        assertExactMatch(expected: expectedJSON, actual: edgeEvent)
    }

    func testHandleNotificationResponse_noEventDatasetId() {
        let event = Event(name: "", type: EventType.messaging, source: EventSource.requestContent, data: getPushInteractionEventData())

        // empty datasetId
        mockConfigSharedState = [:]

        // mock configuration shared state
        mockRuntime.simulateSharedState(for: (extensionName: "com.adobe.module.configuration", event: event), data: (value: mockConfigSharedState, status: .set))

        // creates an edge identity's xdm shared state
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: "MOCK_ECID"]]]]
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))

        mockRuntime.simulateComingEvents(event)
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
    }

    func testHandleNotificationResponse_datasetIdIsEmpty() {
        let event = Event(name: "", type: EventType.messaging, source: EventSource.requestContent, data: getPushInteractionEventData())

        // empty datasetId
        mockConfigSharedState = ["messaging.eventDataset": ""]

        // mock configuration shared state
        mockRuntime.simulateSharedState(for: (extensionName: "com.adobe.module.configuration", event: event), data: (value: mockConfigSharedState, status: .set))

        // creates an edge identity's xdm shared state
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: "MOCK_ECID"]]]]
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))

        mockRuntime.simulateComingEvents(event)
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
    }

    func testHandleNotificationResponse_missingXDMData() {
        var data = getPushInteractionEventData()
        data[MessagingConstants.Event.Data.Key.ADOBE_XDM] = nil
        let event = Event(name: "", type: EventType.messaging, source: EventSource.requestContent, data: data)

        // mock configuration shared state
        mockRuntime.simulateSharedState(for: (extensionName: "com.adobe.module.configuration", event: event), data: (value: mockConfigSharedState, status: .set))

        // creates an edge identity's xdm shared state
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: "MOCK_ECID"]]]]
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))

        mockRuntime.simulateComingEvents(event)
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        let edgeEvent = mockRuntime.dispatchedEvents[1]

        XCTAssertEqual(edgeEvent.type, EventType.edge)
        
        let expectedJSON = """
        {
          "xdm": {
            "pushNotificationTracking": {
              "pushProvider": "apns",
              "pushProviderMessageID": "mockMessageId",
              "customAction": {
                "actionID": "mockCustomActionId"
              }
            },
            "application": {
              "launches": {
                "value": 1
              }
            },
            "eventType": "pushTracking.customAction"
          },
          "meta": {
            "collect": {
              "datasetId": "mockEventDataset"
            }
          }
        }
        """
        
        assertExactMatch(expected: expectedJSON, actual: edgeEvent)
    }

    // MARK: - Helpers

    private func getPushInteractionEventData() -> [String: Any] {
        let cjmData = ["cjm": ["_experience": ["customerJourneyManagement": ["messageExecution": [
            "messageExecutionID": "16-Sept-postman",
            "journeyVersionID": "some-journeyVersionId",
            "journeyVersionInstanceId": "someJourneyVersionInstanceId",
            "messageID": "567"
        ]]]]]
        let data = [MessagingConstants.Event.Data.Key.ID: "mockMessageId",
                    MessagingConstants.Event.Data.Key.PUSH_INTERACTION: true,
                    MessagingConstants.Event.Data.Key.APPLICATION_OPENED: true,
                    MessagingConstants.Event.Data.Key.EVENT_TYPE: MessagingConstants.XDM.Push.EventType.CUSTOM_ACTION,
                    MessagingConstants.Event.Data.Key.ACTION_ID: "mockCustomActionId",
                    MessagingConstants.Event.Data.Key.ADOBE_XDM: cjmData] as [String: Any]
        return data
    }
}
