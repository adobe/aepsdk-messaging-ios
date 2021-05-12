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

class MessagingPublicAPITests: XCTestCase {
    var messaging: Messaging!
    var mockRuntime: TestableExtensionRuntime!
    var mockConfigSharedState: [String: Any] = [:]

    override func setUp() {
        mockConfigSharedState = ["messaging.eventDataset": "mockEventDataset"]
        mockRuntime = TestableExtensionRuntime()
        messaging = Messaging(runtime: mockRuntime)
        messaging.onRegistered()
    }

    // MARK: - Handle Notification Response

    func testHandleNotificationResponse() {
        let event = Event(name: "", type: MessagingConstants.EventType.messaging, source: EventSource.requestContent, data: getEventData())

        // mock configuration shared state
        mockRuntime.simulateSharedState(for: (extensionName: "com.adobe.module.configuration", event: event), data: (value: mockConfigSharedState, status: .set))

        // creates an edge identity's xdm shared state
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: "MOCK_ECID"]]]]
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))

        mockRuntime.simulateComingEvents(event)
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        guard let edgeEvent = mockRuntime.dispatchedEvents.first else {
            XCTFail()
            return
        }
        XCTAssertEqual(edgeEvent.type, EventType.edge)
        let flattenEdgeEvent = edgeEvent.data?.flattening()
        XCTAssertEqual("apns", flattenEdgeEvent?["xdm.pushNotificationTracking.pushProvider"] as? String)
        XCTAssertEqual("mockMessageId", flattenEdgeEvent?["xdm.pushNotificationTracking.pushProviderMessageID"] as? String)
        XCTAssertEqual(1, flattenEdgeEvent?["xdm.application.launches.value"] as? Int)
        XCTAssertEqual("pushTracking.customAction", flattenEdgeEvent?["xdm.eventType"] as? String)
        XCTAssertEqual("mockEventDataset", flattenEdgeEvent?["meta.collect.datasetId"] as? String)
        XCTAssertEqual("mockCustomActionId", flattenEdgeEvent?["xdm.pushNotificationTracking.customAction.actionID"] as? String)
        // cjm/mixins data
        XCTAssertEqual("some-journeyVersionId", flattenEdgeEvent?["xdm._experience.customerJourneyManagement.messageExecution.journeyVersionID"] as? String)
        XCTAssertEqual("someJourneyVersionInstanceId", flattenEdgeEvent?["xdm._experience.customerJourneyManagement.messageExecution.journeyVersionInstanceId"] as? String)
        XCTAssertEqual("567", flattenEdgeEvent?["xdm._experience.customerJourneyManagement.messageExecution.messageID"] as? String)
        XCTAssertEqual("apns", flattenEdgeEvent?["xdm._experience.customerJourneyManagement.pushChannelContext.platform"] as? String)
        XCTAssertEqual("https://ns.adobe.com/xdm/channels/push", flattenEdgeEvent?["xdm._experience.customerJourneyManagement.messageProfile.channel._id"] as? String)
        XCTAssertEqual("16-Sept-postman", flattenEdgeEvent?["xdm._experience.customerJourneyManagement.messageExecution.messageExecutionID"] as? String)
    }

    func testHandleNotificationResponse_noEventDatasetId() {
        let event = Event(name: "", type: MessagingConstants.EventType.messaging, source: EventSource.requestContent, data: getEventData())

        // empty datasetId
        mockConfigSharedState = [:]

        // mock configuration shared state
        mockRuntime.simulateSharedState(for: (extensionName: "com.adobe.module.configuration", event: event), data: (value: mockConfigSharedState, status: .set))

        // creates an edge identity's xdm shared state
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: "MOCK_ECID"]]]]
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))

        mockRuntime.simulateComingEvents(event)
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
    }

    func testHandleNotificationResponse_datasetIdIsEmpty() {
        let event = Event(name: "", type: MessagingConstants.EventType.messaging, source: EventSource.requestContent, data: getEventData())

        // empty datasetId
        mockConfigSharedState = ["messaging.eventDataset": ""]

        // mock configuration shared state
        mockRuntime.simulateSharedState(for: (extensionName: "com.adobe.module.configuration", event: event), data: (value: mockConfigSharedState, status: .set))

        // creates an edge identity's xdm shared state
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: "MOCK_ECID"]]]]
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))

        mockRuntime.simulateComingEvents(event)
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
    }

    func testHandleNotificationResponse_missingXDMData() {
        var data = getEventData()
        data[MessagingConstants.EventDataKeys.ADOBE_XDM] = nil
        let event = Event(name: "", type: MessagingConstants.EventType.messaging, source: EventSource.requestContent, data: data)

        // mock configuration shared state
        mockRuntime.simulateSharedState(for: (extensionName: "com.adobe.module.configuration", event: event), data: (value: mockConfigSharedState, status: .set))

        // creates an edge identity's xdm shared state
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: "MOCK_ECID"]]]]
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))

        mockRuntime.simulateComingEvents(event)
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        guard let edgeEvent = mockRuntime.dispatchedEvents.first else {
            XCTFail()
            return
        }
        XCTAssertEqual(edgeEvent.type, EventType.edge)
        let flattenEdgeEvent = edgeEvent.data?.flattening()
        XCTAssertEqual("apns", flattenEdgeEvent?["xdm.pushNotificationTracking.pushProvider"] as? String)
        XCTAssertEqual("mockMessageId", flattenEdgeEvent?["xdm.pushNotificationTracking.pushProviderMessageID"] as? String)
        XCTAssertEqual(1, flattenEdgeEvent?["xdm.application.launches.value"] as? Int)
        XCTAssertEqual("pushTracking.customAction", flattenEdgeEvent?["xdm.eventType"] as? String)
        XCTAssertEqual("mockEventDataset", flattenEdgeEvent?["meta.collect.datasetId"] as? String)
        XCTAssertEqual("mockCustomActionId", flattenEdgeEvent?["xdm.pushNotificationTracking.customAction.actionID"] as? String)
        XCTAssertNil(flattenEdgeEvent?["xdm._experience.customerJourneyManagement.messageExecution.messageExecutionID"])
    }

    // MARK: - Helpers

    private func getEventData() -> [String: Any] {
        let cjmData = ["cjm": ["_experience": ["customerJourneyManagement": ["messageExecution": [
            "messageExecutionID": "16-Sept-postman",
            "journeyVersionID": "some-journeyVersionId",
            "journeyVersionInstanceId": "someJourneyVersionInstanceId",
            "messageID": "567"
        ]]]]]
        let data = [MessagingConstants.EventDataKeys.MESSAGE_ID: "mockMessageId",
                    MessagingConstants.EventDataKeys.APPLICATION_OPENED: true,
                    MessagingConstants.EventDataKeys.EVENT_TYPE: MessagingConstants.EventDataKeys.EVENT_TYPE_PUSH_TRACKING_CUSTOM_ACTION,
                    MessagingConstants.EventDataKeys.ACTION_ID: "mockCustomActionId",
                    MessagingConstants.EventDataKeys.ADOBE_XDM: cjmData] as [String: Any]
        return data
    }
}
