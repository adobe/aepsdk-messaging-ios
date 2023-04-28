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

import AEPCore
import AEPServices
import XCTest

@testable import AEPMessaging

class MessagingTests: XCTestCase {
    var messaging: Messaging!
    var mockRuntime: TestableExtensionRuntime!
    var mockNetworkService: MockNetworkService?
    var mockMessagingRulesEngine: MockMessagingRulesEngine!
    var mockLaunchRulesEngine: MockLaunchRulesEngine!
    var mockCache: MockCache!
    let mockIamSurface = "mobileapp://com.apple.dt.xctest.tool"

    // Mock constants
    let MOCK_ECID = "mock_ecid"
    let MOCK_EVENT_DATASET = "mock_event_dataset"
    let MOCK_EXP_ORG_ID = "mock_exp_org_id"
    let MOCK_PUSH_TOKEN = "mock_pushToken"

    // before each
    override func setUp() {
        mockRuntime = TestableExtensionRuntime()
        mockCache = MockCache(name: "mockCache")
        mockLaunchRulesEngine = MockLaunchRulesEngine(name: "mockLaunchRulesEngine", extensionRuntime: mockRuntime)
        mockMessagingRulesEngine = MockMessagingRulesEngine(extensionRuntime: mockRuntime, rulesEngine: mockLaunchRulesEngine, cache: mockCache)
        messaging = Messaging(runtime: mockRuntime, rulesEngine: mockMessagingRulesEngine, expectedScope: mockIamSurface)
        messaging.onRegistered()

        mockNetworkService = MockNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService!
    }

    /// validate the extension is registered without any error
    func testRegisterExtension_registersWithoutAnyErrorOrCrash() {
        XCTAssertNoThrow(MobileCore.registerExtensions([Messaging.self]))
    }

    /// validate that 5 listeners are registered onRegister
    func testOnRegistered_fiveListenersAreRegistered() {
        XCTAssertEqual(mockRuntime.listeners.count, 5)
    }

    func testOnUnregisteredCallable() throws {
        messaging.onUnregistered()
    }

    func testReadyForEventHappy() throws {
        // setup
        let event = Event(name: "Test Event Name", type: "type", source: "source", data: nil)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: [:], status: SharedStateStatus.set))
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: SampleEdgeIdentityState, status: SharedStateStatus.set))

        // test
        let result = messaging.readyForEvent(event)

        // verify
        XCTAssertTrue(result)
    }

    func testReadyForEventNoConfigurationSharedState() throws {
        // setup
        let event = Event(name: "Test Event Name", type: "type", source: "source", data: nil)
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: SampleEdgeIdentityState, status: SharedStateStatus.set))

        // test
        let result = messaging.readyForEvent(event)

        // verify
        XCTAssertFalse(result)
    }

    func testReadyForEventNoIdentitySharedState() throws {
        // setup
        let event = Event(name: "Test Event Name", type: "type", source: "source", data: nil)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: [:], status: SharedStateStatus.set))

        // test
        let result = messaging.readyForEvent(event)

        // verify
        XCTAssertFalse(result)
    }

    func testHandleWildcardEvent() throws {
        // setup
        let event = Event(name: "Test Event Name", type: "type", source: "source", data: nil)

        // test
        mockRuntime.simulateComingEvents(event)

        // verify
        XCTAssertTrue(mockMessagingRulesEngine.processCalled)
        XCTAssertEqual(event, mockMessagingRulesEngine.paramProcessEvent)
    }

    func testFetchMessages() throws {
        // setup
        let event = Event(name: "Test Event Name", type: "type", source: "source", data: nil)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: [MessagingConstants.SharedState.Configuration.EXPERIENCE_CLOUD_ORG: "aTestOrgId"], status: SharedStateStatus.set))
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: SampleEdgeIdentityState, status: SharedStateStatus.set))

        // test
        _ = messaging.readyForEvent(event)

        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let fetchEvent = mockRuntime.firstEvent
        XCTAssertNotNil(fetchEvent)
        XCTAssertEqual(EventType.edge, fetchEvent?.type)
        XCTAssertEqual(EventSource.requestContent, fetchEvent?.source)
        let fetchEventData = fetchEvent?.data
        XCTAssertNotNil(fetchEventData)
        let fetchEventQuery = fetchEventData?[MessagingConstants.XDM.IAM.Key.QUERY] as? [String: Any]
        XCTAssertNotNil(fetchEventQuery)
        let fetchEventPersonalization = fetchEventQuery?[MessagingConstants.XDM.IAM.Key.PERSONALIZATION] as? [String: Any]
        XCTAssertNotNil(fetchEventPersonalization)
        let fetchEventSurfaces = fetchEventPersonalization?[MessagingConstants.XDM.IAM.Key.SURFACES] as? [String]
        XCTAssertNotNil(fetchEventSurfaces)
        XCTAssertEqual(1, fetchEventSurfaces?.count)
        XCTAssertEqual("mobileapp://com.apple.dt.xctest.tool", fetchEventSurfaces?.first)
    }

    func testHandleEdgePersonalizationNotificationHappy() throws {
        // setup
        let event = Event(name: "Test Offer Notification Event", type: EventType.edge,
                          source: MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS, data: getOfferEventData())

        // test
        mockRuntime.simulateComingEvents(event)

        // verify
        XCTAssertTrue(mockMessagingRulesEngine.loadPropositionsCalled)
        let loadedRules = mockMessagingRulesEngine.paramLoadPropositionsPropositions
        XCTAssertNotNil(loadedRules)
        XCTAssertNotNil(loadedRules?.first)
        XCTAssertEqual(false, mockMessagingRulesEngine.paramLoadPropositionsClearExisting)
        XCTAssertEqual(true, mockMessagingRulesEngine.paramLoadPropositionsPersistChanges)
    }

    func testHandleEdgePersonalizationNotificationEmptyPayload() throws {
        // setup
        let eventData = getOfferEventData(items: [:])
        let event = Event(name: "Test Offer Notification Event", type: EventType.edge,
                          source: MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS, data: eventData)

        // test
        mockRuntime.simulateComingEvents(event)

        // verify
        XCTAssertTrue(mockMessagingRulesEngine.loadPropositionsCalled)
        XCTAssertEqual(0, mockMessagingRulesEngine.paramLoadPropositionsPropositions?.count)
        XCTAssertEqual(false, mockMessagingRulesEngine.paramLoadPropositionsClearExisting)
        XCTAssertEqual(true, mockMessagingRulesEngine.paramLoadPropositionsPersistChanges)
    }
    
    func testHandleEdgePersonalizationNotificationNewRequestEvent() throws {
        // setup
        messaging.setLastProcessedRequestEventId("oldEventId")
        let event = Event(name: "Test Offer Notification Event", type: EventType.edge,
                          source: MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS, data: getOfferEventData())

        // test
        mockRuntime.simulateComingEvents(event)

        // verify
        XCTAssertTrue(mockMessagingRulesEngine.loadPropositionsCalled)        
        XCTAssertEqual(true, mockMessagingRulesEngine.paramLoadPropositionsClearExisting)
        XCTAssertEqual(true, mockMessagingRulesEngine.paramLoadPropositionsPersistChanges)
    }
    
    func testHandleEdgePersonalizationNotificationRequestEventDoesNotMatch() throws {
        // setup
        messaging.setMessagesRequestEventId("requestEventId")
        let event = Event(name: "Test Offer Notification Event", type: EventType.edge,
                          source: MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS, data: getOfferEventData())

        // test
        mockRuntime.simulateComingEvents(event)

        // verify
        XCTAssertFalse(mockMessagingRulesEngine.loadPropositionsCalled)        
    }

    func testHandleRulesResponseHappy() throws {
        // setup
        mockMessagingRulesEngine.propositionInfoForMessageIdReturnValue = PropositionInfo(id: "id", scope: "scope", scopeDetails: [:])
        let event = Event(name: "Test Rules Engine Response Event",
                          type: EventType.rulesEngine,
                          source: EventSource.responseContent,
                          data: getRulesResponseEventData())

        // test
        mockRuntime.simulateComingEvents(event)

        // verify
        XCTAssertNotNil(messaging.currentMessage)
    }
    
    func testHandleRulesResponseNoHtml() throws {
        // setup
        mockMessagingRulesEngine.propositionInfoForMessageIdReturnValue = PropositionInfo(id: "id", scope: "scope", scopeDetails: [:])
        let event = Event(name: "Test Rules Engine Response Event",
                          type: EventType.rulesEngine,
                          source: EventSource.responseContent,
                          data: getRulesResponseEventData(html: nil))

        // test
        mockRuntime.simulateComingEvents(event)

        // verify
        XCTAssertNil(messaging.currentMessage)
    }
    
    func testHandleRulesResponseNoPropositionInfoForMessage() throws {
        // setup
        let event = Event(name: "Test Rules Engine Response Event",
                          type: EventType.rulesEngine,
                          source: EventSource.responseContent,
                          data: getRulesResponseEventData())

        // test
        mockRuntime.simulateComingEvents(event)

        // verify
        XCTAssertNotNil(messaging.currentMessage)
    }

    func testHandleRulesResponseNilData() throws {
        // setup
        let event = Event(name: "Test Rules Engine Response Event",
                          type: EventType.rulesEngine,
                          source: EventSource.responseContent,
                          data: nil)

        // test
        mockRuntime.simulateComingEvents(event)

        // verify
        XCTAssertNil(messaging.currentMessage)
    }

    func testHandleRulesResponseNoHtmlInData() throws {
        // setup
        let event = Event(name: "Test Rules Engine Response Event",
                          type: EventType.rulesEngine,
                          source: EventSource.responseContent,
                          data: [:])

        // test
        mockRuntime.simulateComingEvents(event)

        // verify
        XCTAssertNil(messaging.currentMessage)
    }

    /// validating handleProcessEvent
    func testHandleProcessEvent_SetPushIdentifierEvent_Happy() {
        let eventData: [String: Any] = [MessagingConstants.Event.Data.Key.PUSH_IDENTIFIER: MOCK_PUSH_TOKEN]
        let event = Event(name: "handleProcessEvent", type: EventType.genericIdentity, source: EventSource.requestContent, data: eventData)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: [:], status: SharedStateStatus.set))
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: SampleEdgeIdentityState, status: SharedStateStatus.set))

        // test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))

        // verify that shared state is created
        XCTAssertEqual(MOCK_PUSH_TOKEN, mockRuntime.firstSharedState?[MessagingConstants.SharedState.Messaging.PUSH_IDENTIFIER] as! String)

        // verify the dispatched edge event
        guard let edgeEvent = mockRuntime.firstEvent else {
            XCTFail()
            return
        }
        XCTAssertEqual("Push notification profile edge event", edgeEvent.name)
        XCTAssertEqual(EventType.edge, edgeEvent.type)
        XCTAssertEqual(EventSource.requestContent, edgeEvent.source)

        // verify event data
        let flattenEdgeEvent = edgeEvent.data?.flattening()
        let pushNotification = flattenEdgeEvent?["data.pushNotificationDetails"] as? [[String: Any]]
        XCTAssertEqual(1, pushNotification?.count)
        let flattenedPushNotification = pushNotification?.first?.flattening()
        XCTAssertEqual("mock_ecid", flattenedPushNotification?["identity.id"] as? String)
        XCTAssertEqual(MOCK_PUSH_TOKEN, flattenedPushNotification?["token"] as? String)
        XCTAssertEqual(false, flattenedPushNotification?["denylisted"] as? Bool)
        XCTAssertNotNil(flattenedPushNotification?["appID"] as? String)
        XCTAssertEqual("ECID", flattenedPushNotification?["identity.namespace.code"] as? String)
        XCTAssertEqual("apns", flattenedPushNotification?["platform"] as? String)
    }

    /// validating handleProcessEvent withNilData
    func testHandleProcessEvent_withNilEventData() {
        let event = Event(name: "handleProcessEvent", type: EventType.genericIdentity, source: EventSource.requestContent, data: nil)
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
    }

    /// validating handleProcessEvent with no shared state
    func testHandleProcessEvent_NoSharedState() {
        let eventData: [String: Any] = [:]
        let event = Event(name: "handleProcessEvent", type: EventType.genericIdentity, source: EventSource.requestContent, data: eventData)

        // test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
    }

    /// validating handleProcessEvent with empty shared state
    func testHandleProcessEvent_withEmptySharedState() {
        let eventData: [String: Any] = [:]
        let event = Event(name: "handleProcessEvent", type: EventType.genericIdentity, source: EventSource.requestContent, data: eventData)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: nil, status: SharedStateStatus.set))
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: nil, status: SharedStateStatus.set))
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: nil, status: SharedStateStatus.set))

        // test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
    }

    /// validating handleProcessEvent with invalid config
    func testhandleProcessEvent_withInvalidConfig() {
        let event = Event(name: "handleProcessEvent", type: EventType.genericIdentity, source: EventSource.requestContent, data: [:])
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: [:], status: SharedStateStatus.set))
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: SampleEdgeIdentityState, status: SharedStateStatus.set))

        // test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
    }

    /// validating handleProcessEvent with empty token
    func testhandleProcessEvent_withEmptyToken() {
        let mockConfig = [MessagingConstants.Event.Data.Key.PUSH_IDENTIFIER: ""]

        let event = Event(name: "handleProcessEvent", type: EventType.genericIdentity, source: EventSource.requestContent, data: [:])
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: mockConfig, status: SharedStateStatus.set))
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: SampleEdgeIdentityState, status: SharedStateStatus.set))

        // test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count, "push token event should not be dispatched")
    }

    /// validating handleProcessEvent with working shared state and data
    func testHandleProcessEvent_withNoIdentityData() {
        let mockConfig = [MessagingConstants.SharedState.Configuration.EXPERIENCE_CLOUD_ORG: MOCK_EXP_ORG_ID]

        let eventData: [String: Any] = [MessagingConstants.Event.Data.Key.PUSH_IDENTIFIER: MOCK_PUSH_TOKEN]

        let event = Event(name: "handleProcessEvent", type: EventType.genericIdentity, source: EventSource.requestContent, data: eventData)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: mockConfig, status: SharedStateStatus.set))
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: nil, status: SharedStateStatus.none))

        // test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count, "push token event should not be dispatched")
    }

    /// validating handleProcessEvent with working shared state and data

    func testhandleProcessEvent_withConfigAndIdentityData() {
        let mockConfig = [MessagingConstants.SharedState.Configuration.EXPERIENCE_CLOUD_ORG: MOCK_EXP_ORG_ID]

        let eventData: [String: Any] = [MessagingConstants.Event.Data.Key.PUSH_IDENTIFIER: MOCK_PUSH_TOKEN]

        let event = Event(name: "handleProcessEvent", type: EventType.genericIdentity, source: EventSource.requestContent, data: eventData)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: mockConfig, status: SharedStateStatus.set))
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: SampleEdgeIdentityState, status: SharedStateStatus.set))

        // test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
        XCTAssertNotNil(mockRuntime.dispatchedEvents)
        let pushTokenEvent = mockRuntime.firstEvent
        XCTAssertEqual(EventType.edge, pushTokenEvent?.type)
        XCTAssertEqual(EventSource.requestContent, pushTokenEvent?.source)
    }

    /// validating handleProcessEvent with working apns sandbox
    func testHandleProcessEvent_withApnsSandbox() {
        let mockConfig = [MessagingConstants.SharedState.Configuration.EXPERIENCE_CLOUD_ORG: MOCK_EXP_ORG_ID,
                          MessagingConstants.SharedState.Configuration.USE_SANDBOX: true] as [String: Any]

        let eventData: [String: Any] = [MessagingConstants.Event.Data.Key.PUSH_IDENTIFIER: MOCK_PUSH_TOKEN]

        let event = Event(name: "handleProcessEvent", type: EventType.genericIdentity, source: EventSource.requestContent, data: eventData)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: mockConfig, status: SharedStateStatus.set))
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: SampleEdgeIdentityState, status: SharedStateStatus.set))

        // test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
    }

    /// validating handleProcessEvent with working apns sandbox
    func testHandleProcessEvent_withApns() {
        let mockConfig = [MessagingConstants.SharedState.Configuration.EXPERIENCE_CLOUD_ORG: MOCK_EXP_ORG_ID,
                          MessagingConstants.SharedState.Configuration.USE_SANDBOX: false] as [String: Any]

        let eventData: [String: Any] = [MessagingConstants.Event.Data.Key.PUSH_IDENTIFIER: MOCK_PUSH_TOKEN]

        let event = Event(name: "handleProcessEvent", type: EventType.genericIdentity, source: EventSource.requestContent, data: eventData)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: mockConfig, status: SharedStateStatus.set))
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: SampleEdgeIdentityState, status: SharedStateStatus.set))

        // test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
    }

    /// validating handleProcessEvent with Tracking info event when event data is empty
    func testHandleProcessEvent_withTrackingInfoEvent() {
        let mockConfig = [MessagingConstants.SharedState.Configuration.EXPERIENCE_EVENT_DATASET: MOCK_EVENT_DATASET] as [String: Any]
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: MOCK_ECID]]]]

        let eventData: [String: Any]? = [
            MessagingConstants.Event.Data.Key.EVENT_TYPE: "testEventType",
            MessagingConstants.Event.Data.Key.MESSAGE_ID: "testMessageId"
        ]

        let event = Event(name: "trackingInfo", type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent, data: eventData)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: mockConfig, status: SharedStateStatus.set))
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))

        // test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedInfoEvent = mockRuntime.firstEvent
        XCTAssertEqual(EventType.edge, dispatchedInfoEvent?.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedInfoEvent?.source)
    }

    func testHandleProcessEventRefreshMessageEvent() throws {
        // setup
        let event = Event(name: "handleProcessEvent", type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent, data: [
            MessagingConstants.Event.Data.Key.REFRESH_MESSAGES: true
        ])
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: [:], status: SharedStateStatus.set))
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: SampleEdgeIdentityState, status: SharedStateStatus.set))

        // test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
    }

    func testHandleProcessEventNoIdentityMap() throws {
        // setup
        let mockConfig = [MessagingConstants.SharedState.Configuration.EXPERIENCE_CLOUD_ORG: MOCK_EXP_ORG_ID]
        let eventData: [String: Any] = [MessagingConstants.Event.Data.Key.PUSH_IDENTIFIER: MOCK_PUSH_TOKEN]
        let event = Event(name: "handleProcessEvent", type: EventType.genericIdentity, source: EventSource.requestContent, data: eventData)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: mockConfig, status: SharedStateStatus.set))
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: [:], status: SharedStateStatus.set))

        // test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count, "push token event should not be dispatched")
    }

    func testhandleProcessEventNoEcidArrayInIdentityMap() {
        let mockConfig = [MessagingConstants.SharedState.Configuration.EXPERIENCE_CLOUD_ORG: MOCK_EXP_ORG_ID]
        let eventData: [String: Any] = [MessagingConstants.Event.Data.Key.PUSH_IDENTIFIER: MOCK_PUSH_TOKEN]
        let event = Event(name: "handleProcessEvent", type: EventType.genericIdentity, source: EventSource.requestContent, data: eventData)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: mockConfig, status: SharedStateStatus.set))
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: [
            MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [:]
        ], status: SharedStateStatus.set))

        // test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count, "push token event should not be dispatched")
    }

    // MARK: - Helpers

    func readJSONFromFile(fileName: String) -> [String: Any]? {
        var json: Any?

        guard let pathString = Bundle(for: type(of: self)).path(forResource: fileName, ofType: "json") else {
            print("\(fileName).json not found")
            return [:]
        }
        let fileUrl = URL(fileURLWithPath: pathString)
        // Getting data from JSON file using the file URL
        do {
            let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
            json = try? JSONSerialization.jsonObject(with: data)
        } catch {
            print("Error while getting data from json")
        }
        return json as? [String: Any]
    }

    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }

    let mockContent1 = "content1"
    let mockContent2 = "content2"
    let mockPayloadId1 = "id1"
    let mockPayloadId2 = "id2"
    let mockAppSurface = "mobileapp://com.apple.dt.xctest.tool"
    func getOfferEventData(items: [String: Any]? = nil, scope: String? = nil) -> [String: Any] {
        let data1 = ["content": mockContent1]
        let item1 = ["data": data1]
        let payload1: [String: Any] = [
            "id": mockPayloadId1,
            "scope": scope ?? mockAppSurface,
            "scopeDetails": [
                "someInnerKey": "someInnerValue"
            ],
            "items": items ?? [item1]
        ]
        
        let data2 = ["content": mockContent2]
        let item2 = ["data": data2]
        let payload2: [String: Any] = [
            "id": mockPayloadId2,
            "scope": scope ?? mockAppSurface,
            "scopeDetails": [
                "someInnerKey": "someInnerValue2"
            ],
            "items": items ?? [item2]
        ]
        
        let eventData: [String: Any] = ["payload": [payload1, payload2]]
        return eventData
    }

    func getRulesResponseEventData(html: String? = "this is the html") -> [String: Any] {
        var detailDictionary: [String: Any] = [:]
        if html != nil {
            detailDictionary["html"] = html
        }
        return [
            MessagingConstants.Event.Data.Key.TRIGGERED_CONSEQUENCE: [
                MessagingConstants.Event.Data.Key.TYPE: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE,
                MessagingConstants.Event.Data.Key.DETAIL: detailDictionary
            ]
        ]
    }

    // MARK: Private methods

    private var SampleEdgeIdentityState: [String: Any] {
        [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: MOCK_ECID]]]]
    }
}
