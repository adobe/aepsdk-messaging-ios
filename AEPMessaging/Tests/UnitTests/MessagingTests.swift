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
    var mockFeedRulesEngine: MockFeedRulesEngine!
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
        mockFeedRulesEngine = MockFeedRulesEngine(extensionRuntime: mockRuntime, launchRulesEngine: mockLaunchRulesEngine)
        mockMessagingRulesEngine = MockMessagingRulesEngine(extensionRuntime: mockRuntime, launchRulesEngine: mockLaunchRulesEngine, cache: mockCache)
        
        messaging = Messaging(runtime: mockRuntime, rulesEngine: mockMessagingRulesEngine, feedRulesEngine: mockFeedRulesEngine, expectedSurface: mockIamSurface, cache: mockCache)
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
    
    func testFetchMessages_whenUpdateFeedsRequest() throws {
        // setup
        let event = Event(name: "Update message feeds event",
                          type: "com.adobe.eventType.messaging",
                          source: "com.adobe.eventSource.requestContent",
                          data: [
                            "updatefeeds": true,
                            "surfaces": [
                                "promos/feed1"
                            ]
                          ])
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: [MessagingConstants.SharedState.Configuration.EXPERIENCE_CLOUD_ORG: "aTestOrgId"], status: SharedStateStatus.set))
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: SampleEdgeIdentityState, status: SharedStateStatus.set))

        // test
        mockRuntime.simulateComingEvents(event)

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
        XCTAssertEqual("mobileapp://com.apple.dt.xctest.tool/promos/feed1", fetchEventSurfaces?.first)
    }
    
    func testFetchMessages_whenUpdateFeedsRequest_emptySurfacesInArray() throws {
        // setup
        let event = Event(name: "Update message feeds event",
                          type: "com.adobe.eventType.messaging",
                          source: "com.adobe.eventSource.requestContent",
                          data: [
                            "updatefeeds": true,
                            "surfaces": [
                                "",
                                ""
                            ]
                          ])
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: [MessagingConstants.SharedState.Configuration.EXPERIENCE_CLOUD_ORG: "aTestOrgId"], status: SharedStateStatus.set))
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: SampleEdgeIdentityState, status: SharedStateStatus.set))

        // test
        mockRuntime.simulateComingEvents(event)

        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }
    
    func testFetchMessages_whenUpdateFeedsRequest_emptySurfacesArray() throws {
        // setup
        let event = Event(name: "Update message feeds event",
                          type: "com.adobe.eventType.messaging",
                          source: "com.adobe.eventSource.requestContent",
                          data: [
                            "updatefeeds": true,
                            "surfaces": []
                          ])
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: [MessagingConstants.SharedState.Configuration.EXPERIENCE_CLOUD_ORG: "aTestOrgId"], status: SharedStateStatus.set))
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: SampleEdgeIdentityState, status: SharedStateStatus.set))

        // test
        mockRuntime.simulateComingEvents(event)

        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testHandleEdgePersonalizationNotificationHappy() throws {
        // setup
        messaging.setMessagesRequestEventId("mockRequestEventId")
        messaging.setLastProcessedRequestEventId("mockRequestEventId")
        messaging.setRequestedSurfacesforEventId("mockRequestEventId", expectedSurfaces: ["mobileapp://com.apple.dt.xctest.tool"])
        let event = Event(name: "Test Offer Notification Event", type: EventType.edge,
                          source: MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS, data: getOfferEventData())

        // test
        mockRuntime.simulateComingEvents(event)

        // verify
        XCTAssertEqual(2, messaging.inMemoryPropositionsCount())
        XCTAssertEqual(2, messaging.propositionInfoCount())
        XCTAssertTrue(mockLaunchRulesEngine.addRulesCalled)
        XCTAssertEqual(2, mockLaunchRulesEngine.paramAddRulesRules?.count)
        XCTAssertTrue(mockCache.setCalled)
    }

        func testHandleEdgePersonalizationNotificationEmptyPayload() throws {
            // setup
            messaging.setMessagesRequestEventId("mockRequestEventId")
            messaging.setLastProcessedRequestEventId("mockRequestEventId")
            messaging.setRequestedSurfacesforEventId("mockRequestEventId", expectedSurfaces: ["mobileapp://com.apple.dt.xctest.tool"])
            let eventData = getOfferEventData(items: [[:]])
            let event = Event(name: "Test Offer Notification Event", type: EventType.edge,
                              source: MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS, data: eventData)
    
            // test
            mockRuntime.simulateComingEvents(event)
    
            // verify
            XCTAssertEqual(0, messaging.inMemoryPropositionsCount())
            XCTAssertEqual(0, messaging.propositionInfoCount())
            XCTAssertFalse(mockLaunchRulesEngine.addRulesCalled)
            XCTAssertFalse(mockLaunchRulesEngine.replaceRulesCalled)
            XCTAssertFalse(mockCache.setCalled)
        }
    
    func testHandleEdgePersonalizationNotificationNewRequestEvent() throws {
        // setup
        messaging.setLastProcessedRequestEventId("oldEventId")
        messaging.setMessagesRequestEventId("mockRequestEventId")
        messaging.setRequestedSurfacesforEventId("mockRequestEventId", expectedSurfaces: ["mobileapp://com.apple.dt.xctest.tool"])
        let event = Event(name: "Test Offer Notification Event", type: EventType.edge,
                          source: MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS, data: getOfferEventData())

        // test
        mockRuntime.simulateComingEvents(event)

        // verify
        XCTAssertEqual(2, messaging.inMemoryPropositionsCount())
        XCTAssertEqual(2, messaging.propositionInfoCount())
        XCTAssertTrue(mockLaunchRulesEngine.replaceRulesCalled)
        XCTAssertEqual(2, mockLaunchRulesEngine.paramReplaceRulesRules?.count)
        XCTAssertTrue(mockCache.setCalled)
    }
    
    func testHandleEdgePersonalizationNotificationRequestEventDoesNotMatch() throws {
        // setup
        messaging.setMessagesRequestEventId("someRequestEventId")
        let event = Event(name: "Test Offer Notification Event", type: EventType.edge,
                          source: MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS, data: getOfferEventData())

        // test
        mockRuntime.simulateComingEvents(event)

        // verify
        XCTAssertEqual(0, messaging.inMemoryPropositionsCount())
        XCTAssertEqual(0, messaging.propositionInfoCount())
        XCTAssertFalse(mockLaunchRulesEngine.replaceRulesCalled)
        XCTAssertFalse(mockLaunchRulesEngine.addRulesCalled)
        XCTAssertFalse(mockCache.setCalled)
    }
    
    func testHandleEdgePersonalizationNotificationRequestEventScopeDoesNotMatch() throws {
        // setup
        messaging.setMessagesRequestEventId("mockRequestEventId")
        messaging.setRequestedSurfacesforEventId("someRequestEventId", expectedSurfaces: ["mobileapp://com.apple.dt.xctest.tool"])
        let event = Event(name: "Test Offer Notification Event", type: EventType.edge,
                          source: MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS, data: getOfferEventData(surface: "someScope"))

        // test
        mockRuntime.simulateComingEvents(event)

        // verify
        XCTAssertEqual(0, messaging.inMemoryPropositionsCount())
        XCTAssertEqual(0, messaging.propositionInfoCount())
        XCTAssertTrue(mockLaunchRulesEngine.replaceRulesCalled)
        XCTAssertFalse(mockLaunchRulesEngine.addRulesCalled)
        XCTAssertTrue(mockCache.setCalled)
    }
    
    func testHandleEdgePersonalizationFeedsNotificationHappy() throws {
        // setup
        messaging.setMessagesRequestEventId("mockRequestEventId")
        messaging.setLastProcessedRequestEventId("mockRequestEventId")
        messaging.setRequestedSurfacesforEventId("mockRequestEventId", expectedSurfaces: ["mobileapp://com.apple.dt.xctest.tool/promos/feed1"])
        mockLaunchRulesEngine.ruleConsequences.removeAll()
        mockLaunchRulesEngine.ruleConsequences = [RuleConsequence(id: "someId", type: "cjmiam", details: [
            "mobileParameters": [
                "id": "5c2ec561-49dd-4c8d-80bb-1fd67f6fca5d",
                "title": "Flash sale!",
                "body": "All winter gear is now up to 30% off at checkout.",
                "imageUrl": "https://luma.com/wintersale.png",
                "actionUrl": "https://luma.com/sale",
                "actionTitle": "Shop the sale!",
                "publishedDate": 1680568056,
                "expiryDate": 1712190456,
                "meta": [
                    "feedName":"WinterPromo",
                    "surface":"mobileapp://com.apple.dt.xctest.tool/promos/feed1"
                ],
                "type": "messagefeed"
            ]
        ])]
        
        let event = Event(name: "Test Offer Notification Event", type: EventType.edge,
                          source: MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS, data: getOfferEventData(items:[["data": ["content": mockFeedContent]]], surface:"mobileapp://com.apple.dt.xctest.tool/promos/feed1"))

        // test
        mockRuntime.simulateComingEvents(event)

        // verify
        XCTAssertEqual(1, messaging.inMemoryFeedsCount())
        XCTAssertEqual(0, messaging.propositionInfoCount())
        XCTAssertTrue(mockLaunchRulesEngine.addRulesCalled)
        XCTAssertFalse(mockLaunchRulesEngine.replaceRulesCalled)
        XCTAssertFalse(mockCache.setCalled)
        
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents.first
        
        XCTAssertEqual("com.adobe.eventType.messaging", dispatchedEvent?.type)
        XCTAssertEqual("com.adobe.eventSource.notification", dispatchedEvent?.source)
        
        let feedsDict = dispatchedEvent?.feeds
        XCTAssertNotNil(feedsDict)
        XCTAssertEqual(1, feedsDict?.count)
        let feed = feedsDict?["mobileapp://com.apple.dt.xctest.tool/promos/feed1"]
        XCTAssertEqual("Winter Promo", feed?.name)
        XCTAssertEqual("mobileapp://com.apple.dt.xctest.tool/promos/feed1", feed?.surfaceUri)
        XCTAssertEqual(1, feed?.items.count)
        XCTAssertEqual("Flash sale!", feed?.items.first?.title)
        XCTAssertEqual("All winter gear is now up to 30% off at checkout.", feed?.items.first?.body)
        XCTAssertEqual("https://luma.com/wintersale.png", feed?.items.first?.imageUrl)
        XCTAssertEqual("https://luma.com/sale", feed?.items.first?.actionUrl)
        XCTAssertEqual("Shop the sale!", feed?.items.first?.actionTitle)
        XCTAssertEqual(1677190552, feed?.items.first?.publishedDate)
        XCTAssertEqual(1677243235, feed?.items.first?.expiryDate)
        XCTAssertNotNil(feed?.items.first?.meta)
        XCTAssertEqual(1, feed?.items.first?.meta?.count)
        XCTAssertEqual("Winter Promo", feed?.items.first?.meta?["feedName"] as? String)
        XCTAssertNotNil(feed?.items.first?.details)
        XCTAssertEqual(1, feed?.items.first?.details.count)
        XCTAssertEqual("someInnerValue", feed?.items.first?.details["someInnerKey"] as? String)
    }

    func testHandleRulesResponseHappy() throws {
        // setup
        messaging.propositionInfo["mockMessageId"] = PropositionInfo(id: "id", scope: "scope", scopeDetails: [:])
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
        messaging.propositionInfo["mockMessageId"] = PropositionInfo(id: "id", scope: "scope", scopeDetails: [:])
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

    func testHandleProcessEventUpdateFeedsEvent() throws {
        // setup
        let event = Event(name: "Update message feeds event",
                          type: MessagingConstants.Event.EventType.messaging,
                          source: EventSource.requestContent,
                          data: [
                            MessagingConstants.Event.Data.Key.UPDATE_FEEDS: true,
                            MessagingConstants.Event.Data.Key.SURFACES: ["promos/feed1"]
                          ])
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: [:], status: SharedStateStatus.set))
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: SampleEdgeIdentityState, status: SharedStateStatus.set))

        // test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.firstEvent
        XCTAssertEqual(EventType.edge, dispatchedEvent?.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent?.source)
        
        let eventData = try XCTUnwrap(dispatchedEvent?.data as? [String: Any])
        let xdm = try XCTUnwrap(eventData["xdm"] as? [String: Any])
        XCTAssertEqual("personalization.request", xdm["eventType"] as? String)
        let query =  try XCTUnwrap(eventData["query"] as? [String: Any])
        let personalization =  try XCTUnwrap(query["personalization"] as? [String: Any])
        let surfaces = try XCTUnwrap(personalization["surfaces"] as? [String])
        XCTAssertEqual(1, surfaces.count)
        XCTAssertEqual("mobileapp://com.apple.dt.xctest.tool/promos/feed1", surfaces[0])
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

    func testParsePropositionsHappy() throws {
        // setup
        let decoder = JSONDecoder()
        let propString: String = JSONFileLoader.getRulesStringFromFile("showOnceRule")
        let propositions = try decoder.decode([PropositionPayload].self, from: propString.data(using: .utf8)!)

        // test
        let rules = messaging.parsePropositions(propositions, expectedSurfaces: [mockIamSurface], clearExisting: false, persistChanges: true)

        // verify
        XCTAssertEqual(1, rules.count)
        XCTAssertEqual(1, messaging.inMemoryPropositionsCount())
        XCTAssertTrue(mockCache.setCalled)
    }

    func testParsePropositionsDefaultSavesToPersitence() throws {
        // setup
        let decoder = JSONDecoder()
        let propString: String = JSONFileLoader.getRulesStringFromFile("showOnceRule")
        let propositions = try decoder.decode([PropositionPayload].self, from: propString.data(using: .utf8)!)

        // test
        let rules = messaging.parsePropositions(propositions, expectedSurfaces: [mockIamSurface], clearExisting: false)

        // verify
        XCTAssertEqual(1, rules.count)
        XCTAssertEqual(1, messaging.inMemoryPropositionsCount())
        XCTAssertTrue(mockCache.setCalled)
    }

    func testParsePropositionsClearExisting() throws {
        // setup
        let decoder = JSONDecoder()
        let propString: String = JSONFileLoader.getRulesStringFromFile("showOnceRule")
        let propositions = try decoder.decode([PropositionPayload].self, from: propString.data(using: .utf8)!)

        // test
        let rules = messaging.parsePropositions(propositions, expectedSurfaces: [mockIamSurface], clearExisting: true)

        // verify
        XCTAssertEqual(1, rules.count)
        XCTAssertEqual(1, messaging.inMemoryPropositionsCount())
        XCTAssertTrue(mockCache.setCalled)
    }
        
    func testParsePropositionsMismatchedScope() throws {
        // setup
        let decoder = JSONDecoder()
        let propString: String = JSONFileLoader.getRulesStringFromFile("wrongScopeRule")
        let propositions = try decoder.decode([PropositionPayload].self, from: propString.data(using: .utf8)!)

        // test
        let rules = messaging.parsePropositions(propositions, expectedSurfaces: [mockIamSurface], clearExisting: false, persistChanges: true)

        // verify
        XCTAssertEqual(0, rules.count)
        XCTAssertEqual(0, messaging.inMemoryPropositionsCount())
        XCTAssertTrue(mockCache.setCalled)
    }

    func testParsePropositionsEmptyStringContent() throws {
        // setup
        let decoder = JSONDecoder()
        let propString: String = JSONFileLoader.getRulesStringFromFile("emptyContentStringRule")
        let propositions = try decoder.decode([PropositionPayload].self, from: propString.data(using: .utf8)!)

        // test
        let rules = messaging.parsePropositions(propositions, expectedSurfaces: [mockIamSurface], clearExisting: false, persistChanges: true)

        // verify
        XCTAssertEqual(0, rules.count)
        XCTAssertEqual(0, messaging.inMemoryPropositionsCount())
        XCTAssertTrue(mockCache.setCalled)
    }

    func testParsePropositionsMalformedContent() throws {
        // setup
        let decoder = JSONDecoder()
        let propString: String = JSONFileLoader.getRulesStringFromFile("malformedContentRule")
        let propositions = try decoder.decode([PropositionPayload].self, from: propString.data(using: .utf8)!)

        // test
        let rules = messaging.parsePropositions(propositions, expectedSurfaces: [mockIamSurface], clearExisting: false, persistChanges: true)

        // verify
        XCTAssertEqual(0, rules.count)
        XCTAssertEqual(0, messaging.inMemoryPropositionsCount())
        XCTAssertTrue(mockCache.setCalled)
    }

    func testParsePropositionsNoItemsInPayload() throws {
        // setup
        let propInfo = PropositionInfo(id: "a", scope: "a", scopeDetails: [:])
        let propPayload = PropositionPayload(propositionInfo: propInfo, items: [])

        // test
        let rules = messaging.parsePropositions([propPayload], expectedSurfaces: [mockIamSurface], clearExisting: false)

        // verify
        XCTAssertEqual(0, rules.count)
        XCTAssertEqual(0, messaging.inMemoryPropositionsCount())
        XCTAssertTrue(mockCache.setCalled)
    }

    func testParsePropositionsEmptyContentInPayload() throws {
        // setup
        let itemData = ItemData(content: "")
        let payloadItem = PayloadItem(data: itemData)
        let propInfo = PropositionInfo(id: "a", scope: "a", scopeDetails: [:])
        let propPayload = PropositionPayload(propositionInfo: propInfo, items: [payloadItem])

        // test
        let rules = messaging.parsePropositions([propPayload], expectedSurfaces: [mockIamSurface], clearExisting: false)

        // verify
        XCTAssertEqual(0, rules.count)
        XCTAssertEqual(0, messaging.inMemoryPropositionsCount())
        XCTAssertTrue(mockCache.setCalled)
    }
        
    func testParsePropositionsEventSequence() throws {
        // setup
        let decoder = JSONDecoder()
        let propString: String = JSONFileLoader.getRulesStringFromFile("eventSequenceRule")
        let propositions = try decoder.decode([PropositionPayload].self, from: propString.data(using: .utf8)!)

        // test
        let rules = messaging.parsePropositions(propositions, expectedSurfaces: [mockIamSurface], clearExisting: false)

        // verify
        XCTAssertEqual(1, rules.count)
        XCTAssertEqual(1, messaging.inMemoryPropositionsCount())
        XCTAssertTrue(mockCache.setCalled)
    }

    func testParsePropositionsEmptyPropositions() throws {
        // setup
        let propositions: [PropositionPayload] = []

        // test
        let rules = messaging.parsePropositions(propositions, expectedSurfaces: [mockIamSurface], clearExisting: false)

        // verify
        XCTAssertEqual(0, rules.count)
        XCTAssertEqual(0, messaging.inMemoryPropositionsCount())
        XCTAssertFalse(mockCache.setCalled)
    }

    func testParsePropositionsExistingReplacedWithEmpty() throws {
        // setup
        let decoder = JSONDecoder()
        let propString: String = JSONFileLoader.getRulesStringFromFile("showOnceRule")
        let propositions = try decoder.decode([PropositionPayload].self, from: propString.data(using: .utf8)!)

        // test
        var rules = messaging.parsePropositions(propositions, expectedSurfaces: [mockIamSurface], clearExisting: false)

        // verify
        XCTAssertEqual(1, rules.count)
        XCTAssertEqual(1, messaging.inMemoryPropositionsCount())
        XCTAssertEqual(1, messaging.propositionInfoCount())
        XCTAssertTrue(mockCache.setCalled)

        // test
        rules = messaging.parsePropositions(nil, expectedSurfaces: [mockIamSurface], clearExisting: true, persistChanges: true)

        // verify
        XCTAssertEqual(0, rules.count)
        XCTAssertEqual(0, messaging.inMemoryPropositionsCount())
        XCTAssertEqual(0, messaging.propositionInfoCount())
        XCTAssertTrue(mockCache.setCalled)
    }
    
    func testParsePropositionsExistingNoReplacedWithEmpty() throws {
        // setup
        let decoder = JSONDecoder()
        let propString: String = JSONFileLoader.getRulesStringFromFile("showOnceRule")
        let propositions = try decoder.decode([PropositionPayload].self, from: propString.data(using: .utf8)!)

        // test
        var rules = messaging.parsePropositions(propositions, expectedSurfaces: [mockIamSurface], clearExisting: false)

        // verify
        XCTAssertEqual(1, rules.count)
        XCTAssertEqual(1, messaging.inMemoryPropositionsCount())
        XCTAssertEqual(1, messaging.propositionInfoCount())
        XCTAssertTrue(mockCache.setCalled)

        // test
        rules = messaging.parsePropositions(nil, expectedSurfaces: [mockIamSurface], clearExisting: false, persistChanges: true)

        // verify
        XCTAssertEqual(0, rules.count)
        XCTAssertEqual(1, messaging.inMemoryPropositionsCount())
        XCTAssertEqual(1, messaging.propositionInfoCount())
        XCTAssertTrue(mockCache.setCalled)
    }

    func testParsePropositionsDoNotPersistChanges() throws {
        // setup
        let decoder = JSONDecoder()
        let propString: String = JSONFileLoader.getRulesStringFromFile("showOnceRule")
        let propositions = try decoder.decode([PropositionPayload].self, from: propString.data(using: .utf8)!)

        // test
        let rules = messaging.parsePropositions(propositions, expectedSurfaces: [mockIamSurface], clearExisting: false, persistChanges: false)

        // verify
        XCTAssertEqual(1, rules.count)
        XCTAssertEqual(1, messaging.inMemoryPropositionsCount())
        XCTAssertFalse(mockCache.setCalled)
    }

    func testPropositionInfoForMessageIdHappy() throws {
        // setup
        messaging.propositionInfo["id"] = PropositionInfo(id: "pid", scope: "scope", scopeDetails: [:])

        // test
        let propInfo = messaging.propositionInfoForMessageId("id")

        // verify
        XCTAssertNotNil(propInfo)
        XCTAssertEqual("pid", propInfo?.id)
        XCTAssertEqual("scope", propInfo?.scope)
        XCTAssertEqual(0, propInfo?.scopeDetails.count)
    }

    func testPropositionInfoForMessageIdNoMatch() throws {
        // test
        let propInfo = messaging.propositionInfoForMessageId("good luck finding a message with this id. ha!")

        // verify
        XCTAssertNil(propInfo)
    }

    func testLoadCachedPropositionsHappy() throws {
        // setup
        let aJsonString = JSONFileLoader.getRulesStringFromFile("showOnceRule")
        let cacheEntry = CacheEntry(data: aJsonString.data(using: .utf8)!, expiry: .never, metadata: nil)
        mockCache.getReturnValue = cacheEntry

        // test
        messaging.loadCachedPropositions(for: mockIamSurface)

        // verify
        XCTAssertTrue(mockCache.getCalled)
        XCTAssertEqual("propositions", mockCache.getParamKey)
        XCTAssertTrue(mockLaunchRulesEngine.addRulesCalled)
        XCTAssertEqual(1, mockLaunchRulesEngine.paramAddRulesRules?.count)
    }

    func testLoadCachedPropositionsWrongScope() throws {
        // setup
        let aJsonString = JSONFileLoader.getRulesStringFromFile("wrongScopeRule")
        let cacheEntry = CacheEntry(data: aJsonString.data(using: .utf8)!, expiry: .never, metadata: nil)
        mockCache.getReturnValue = cacheEntry

        // test
        messaging.loadCachedPropositions(for: mockIamSurface)

        // verify
        XCTAssertTrue(mockCache.getCalled)
        XCTAssertEqual("propositions", mockCache.getParamKey)
        XCTAssertFalse(mockLaunchRulesEngine.addRulesCalled)
    }

    func testLoadCachedPropositionsNoCacheFound() throws {
        // setup
        mockCache.getReturnValue = nil

        // test
        messaging.loadCachedPropositions(for: mockIamSurface)

        // verify
        XCTAssertTrue(mockCache.getCalled)
        XCTAssertEqual("propositions", mockCache.getParamKey)
        XCTAssertFalse(mockLaunchRulesEngine.addRulesCalled)
        XCTAssertFalse(mockLaunchRulesEngine.replaceRulesCalled)
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
    
    let mockFeedContent = "{\"version\":1,\"rules\":[{\"condition\":{\"definition\":{\"conditions\":[{\"definition\":{\"key\":\"~timestampu\",\"matcher\":\"ge\",\"values\":[1680568056]},\"type\":\"matcher\"},{\"definition\":{\"key\":\"~timestampu\",\"matcher\":\"le\",\"values\":[1712190456]},\"type\":\"matcher\"}],\"logic\":\"and\"},\"type\":\"group\"},\"consequences\":[{\"id\":\"6513c398-303a-4a04-adbf-116b194bcaea\",\"type\":\"cjmiam\",\"detail\":{\"mobileParameters\":{\"expiryDate\":1712190456,\"actionTitle\":\"Shop the sale!\",\"meta\":{\"feedName\":\"Winter Promo\"},\"imageUrl\":\"https://luma.com/wintersale.png\",\"actionUrl\":\"https://luma.com/sale\",\"publishedDate\":1680568056,\"body\":\"All winter gear is now up to 30% off at checkout.\",\"title\":\"Flash sale!\",\"type\":\"messagefeed\"},\"html\":\"<html><head></head><body></body></html>\",\"remoteAssets\":[]}}]}]}"

    let mockContent1 = "{\"version\":1,\"rules\":[{\"condition\":{\"type\":\"group\",\"definition\":{\"logic\":\"and\",\"conditions\":[{\"type\":\"group\",\"definition\":{\"logic\":\"and\",\"conditions\":[{\"type\":\"matcher\",\"definition\":{\"key\":\"~source\",\"matcher\":\"eq\",\"values\":[\"com.adobe.eventSource.applicationLaunch\"]}},{\"type\":\"matcher\",\"definition\":{\"key\":\"~type\",\"matcher\":\"eq\",\"values\":[\"com.adobe.eventType.lifecycle\"]}},{\"type\":\"matcher\",\"definition\":{\"key\":\"~state.com.adobe.module.lifecycle/lifecyclecontextdata.launchevent\",\"matcher\":\"ex\",\"values\":[]}}]}}]}},\"consequences\":[{\"id\":\"89ac1647-d48b-4206-a302-c74353e63fc7\",\"type\":\"cjmiam\",\"detail\":{\"mobileParameters\":{\"verticalAlign\":\"center\",\"horizontalInset\":0,\"dismissAnimation\":\"bottom\",\"uiTakeover\":true,\"horizontalAlign\":\"center\",\"verticalInset\":0,\"displayAnimation\":\"bottom\",\"width\":100,\"height\":100,\"gestures\":{}},\"html\":\"<html><head></head><body>Hello from InApp campaign: [CIT]::inapp::LqhnZy7y1Vo4EEWciU5qK</body></html>\",\"remoteAssets\":[]}}]}]}"
    let mockContent2 = "{\"version\":1,\"rules\":[{\"condition\":{\"type\":\"group\",\"definition\":{\"logic\":\"and\",\"conditions\":[{\"type\":\"group\",\"definition\":{\"logic\":\"and\",\"conditions\":[{\"type\":\"matcher\",\"definition\":{\"key\":\"~source\",\"matcher\":\"eq\",\"values\":[\"com.adobe.eventSource.applicationLaunch\"]}},{\"type\":\"matcher\",\"definition\":{\"key\":\"~type\",\"matcher\":\"eq\",\"values\":[\"com.adobe.eventType.lifecycle\"]}},{\"type\":\"matcher\",\"definition\":{\"key\":\"~state.com.adobe.module.lifecycle/lifecyclecontextdata.launchevent\",\"matcher\":\"ex\",\"values\":[]}}]}}]}},\"consequences\":[{\"id\":\"dcfc8404-eea2-49df-a39a-85fc262d897e\",\"type\":\"cjmiam\",\"detail\":{\"mobileParameters\":{\"verticalAlign\":\"center\",\"horizontalInset\":0,\"dismissAnimation\":\"bottom\",\"uiTakeover\":true,\"horizontalAlign\":\"center\",\"verticalInset\":0,\"displayAnimation\":\"bottom\",\"width\":100,\"height\":100,\"gestures\":{}},\"html\":\"<html><head></head><body>Hello from another InApp campaign: [CIT]::inapp::LqhnZy7y1Vo4EEWciU5qK</body></html>\",\"remoteAssets\":[]}}]}]}"
    let mockPayloadId1 = "id1"
    let mockPayloadId2 = "id2"
    let mockAppSurface = "mobileapp://com.apple.dt.xctest.tool"
    func getOfferEventData(items: [[String: Any]]? = nil, surface: String? = nil, requestEventId: String = "mockRequestEventId") -> [String: Any] {
        
        var eventData: [String: Any] = [:]
        if let items = items, !items.isEmpty {
            let payload: [String: Any] = [
                "id": mockPayloadId1,
                "scope": surface ?? mockAppSurface,
                "scopeDetails": [
                    "someInnerKey": "someInnerValue"
                ],
                "items": items
            ]
            
            eventData = ["payload": [payload], "requestEventId": requestEventId]
        } else {
            let data1 = ["content": mockContent1]
            let item1 = ["data": data1]
            let payload1: [String: Any] = [
                "id": mockPayloadId1,
                "scope": surface ?? mockAppSurface,
                "scopeDetails": [
                    "someInnerKey": "someInnerValue"
                ],
                "items": [item1]
            ]
            
            let data2 = ["content": mockContent2]
            let item2 = ["data": data2]
            let payload2: [String: Any] = [
                "id": mockPayloadId2,
                "scope": surface ?? mockAppSurface,
                "scopeDetails": [
                    "someInnerKey": "someInnerValue2"
                ],
                "items": [item2]
            ]
            
            eventData = ["payload": [payload1, payload2], "requestEventId": requestEventId]
        }
        return eventData
    }

    func getRulesResponseEventData(html: String? = "this is the html", id: String = "mockMessageId") -> [String: Any] {
        var detailDictionary: [String: Any] = [:]
        if html != nil {
            detailDictionary["html"] = html
        }
        return [
            MessagingConstants.Event.Data.Key.TRIGGERED_CONSEQUENCE: [
                MessagingConstants.Event.Data.Key.ID: id,
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
