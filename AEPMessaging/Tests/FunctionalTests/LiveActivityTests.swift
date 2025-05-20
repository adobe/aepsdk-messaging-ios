/*
 Copyright 2025 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */
import Foundation
@testable import AEPCore
@testable import AEPMessaging
@testable import AEPServices
import AEPTestUtils
import XCTest

class LiveActivityTests: XCTestCase, AnyCodableAsserts {
    
    var messaging: Messaging!
    var mockRuntime: TestableExtensionRuntime!
    let ATTRIBUTE_TYPE = "TestLiveActivityAttributes"
    let PUSH_TO_START_TOKEN = "testPushToStartToken"
    let LIVE_ACTIVITY_ID = "testLiveActivityID"
    let CHANNEL_ID = "testChannelID"
    let ECID = "MOCK_ECID"
    
    override func setUp() {
        super.setUp()
        FileManager.default.clearCache()
        FileManager.default.clearDirectory()
        mockRuntime = TestableExtensionRuntime()
        mockRuntime.ignoreEvent(type: EventType.rulesEngine, source: EventSource.requestReset)
        messaging = Messaging(runtime: mockRuntime)
        messaging.onRegistered()
        MobileCore.setLogLevel(.trace)
    }
    
    // MARK: - PushToStartTokens Tests
    
    func test_LiveActivity_PushToStart_Happy() {
        // create and dispatch event
        let event = createPushToStartEvent(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE)
        mockSharedStates(for: event)
        mockRuntime.simulateComingEvents(event)
        
        // verify edge event and shared state
        verifyPushToStartEdgeEvent(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE)
        verifyPushToStartSharedState(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE)
    }
    
    func test_LiveActivity_PushToStart_MultipleTokens() {
        let token1 = PUSH_TO_START_TOKEN
        let token2 = "testPushToStartToken2"
        let attributeType1 = ATTRIBUTE_TYPE
        let attributeType2 = "TestLiveActivityAttributes2"
        
        // Step 1: Dispatch event with token 1 and attributeType1
        let event1 = createPushToStartEvent(token: token1, attributeType: attributeType1)
        mockSharedStates(for: event1)
        mockRuntime.simulateComingEvents(event1)
        
        // Step 2: Dispatch event with token 2 and attributeType2
        let event2 = createPushToStartEvent(token: token2, attributeType: attributeType2)
        mockSharedStates(for: event2)
        mockRuntime.simulateComingEvents(event2)
        
        // There should be two edge events dispatched
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        let edgeEvent2 = mockRuntime.dispatchedEvents[1]
        XCTAssertEqual(EventType.edge, edgeEvent2.type)
        XCTAssertEqual(EventSource.requestContent, edgeEvent2.source)
        
        // verify edge event for token 2 contains both tokens in the array
        let data = edgeEvent2.data?["data"] as? [String: Any]
        let details = data?["liveActivityPushNotificationDetails"] as? [[String: Any]]
        let expected1: [String: Any] = [
            "appID": "com.adobe.ajo.e2eTestApp",
            "denylisted": false,
            "platform": "apns",
            "token": token1,
            "liveActivityAttributeType": attributeType1,
            "identity": [
                "namespace": ["code": "ECID"],
                "id": ECID
            ]
        ]
        let expected2: [String: Any] = [
            "appID": "com.adobe.ajo.e2eTestApp",
            "denylisted": false,
            "platform": "apns",
            "token": token2,
            "liveActivityAttributeType": attributeType2,
            "identity": [
                "namespace": ["code": "ECID"],
                "id": ECID
            ]
        ]
        
        assertLiveActivityPushNotificationDetailsContains(details ?? [], expected: [expected1, expected2])
        
        // Step 3: Verify the final shared state contains both tokens under their respective attribute types
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)
        let finalSharedState = mockRuntime.createdSharedStates[1]
        XCTAssertNotNil(finalSharedState?[MessagingConstants.SharedState.Messaging.LIVE_ACTIVITY_PUSH_TO_START_TOKENS])
        
        if let pushToStartTokens = finalSharedState?[MessagingConstants.SharedState.Messaging.LIVE_ACTIVITY_PUSH_TO_START_TOKENS] as? [String: Any],
           let tokens = pushToStartTokens["tokens"] as? [String: [String: Any]] {
            XCTAssertEqual(token1, tokens[attributeType1]?["token"] as? String)
            XCTAssertEqual(token2, tokens[attributeType2]?["token"] as? String)
        } else {
            XCTFail("Push to start tokens not found in shared state")
        }
    }
    
    func test_LiveActivity_PushToStart_NewToken_OverwritesOldToken() {
        let NEW_TOKEN = "newToken"
        
        // create and dispatch event with token 1
        let event1 = createPushToStartEvent(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE)
        mockSharedStates(for: event1)
        mockRuntime.simulateComingEvents(event1)
        
        // create and dispatch event with token 2
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
        let event2 = createPushToStartEvent(token: NEW_TOKEN, attributeType: ATTRIBUTE_TYPE)
        mockSharedStates(for: event2)
        mockRuntime.simulateComingEvents(event2)
        
        // verify edge event and shared state contains latest token
        verifyPushToStartEdgeEvent(token: NEW_TOKEN, attributeType: ATTRIBUTE_TYPE)
        verifyPushToStartSharedState(token: NEW_TOKEN, attributeType: ATTRIBUTE_TYPE)
    }
    
    func test_LiveActivity_PushToStart_EmptyToken() {
        // create and dispatch event with empty token
        let event = createPushToStartEvent(token: "", attributeType: ATTRIBUTE_TYPE)
        mockSharedStates(for: event)
        mockRuntime.simulateComingEvents(event)
        
        // verify no edge event is dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        
        // verify no shared state is created
        XCTAssertEqual(0, mockRuntime.createdSharedStates.count)
    }
    
    func test_LiveActivity_PushToStart_MissingECID() {
        // create and dispatch event
        let event = createPushToStartEvent(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE)
        mockSharedStates(for: event, ecid: "")
        mockRuntime.simulateComingEvents(event)
        
        // verify no edge event is dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        
        // verify shared state is still created
        verifyPushToStartSharedState(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE)
    }
    
    func test_LiveActivity_PushToStart_MissingAttributeType() {
        // create event without attribute type
        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.LIVE_ACTIVITY_PUSH_TO_START_TOKEN: true,
            MessagingConstants.XDM.Push.TOKEN: PUSH_TO_START_TOKEN
        ]
        let event = Event(name: MessagingConstants.Event.Name.LIVE_ACTIVITY_PUSH_TO_START,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)
        
        mockSharedStates(for: event)
        mockRuntime.simulateComingEvents(event)
        
        // verify no edge event is dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        
        // verify no shared state is created
        XCTAssertEqual(0, mockRuntime.createdSharedStates.count)
    }
    
    func test_LiveActivity_PushToStart_InvalidTokenFormat() {
        // create event with invalid token format (non-string)
        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.LIVE_ACTIVITY_PUSH_TO_START_TOKEN: true,
            MessagingConstants.XDM.Push.TOKEN: 123, // Invalid token format
            MessagingConstants.Event.Data.Key.ATTRIBUTE_TYPE: ATTRIBUTE_TYPE
        ]
        let event = Event(name: MessagingConstants.Event.Name.LIVE_ACTIVITY_PUSH_TO_START,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)
        
        mockSharedStates(for: event)
        mockRuntime.simulateComingEvents(event)
        
        // verify no edge event is dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        
        // verify no shared state is created
        XCTAssertEqual(0, mockRuntime.createdSharedStates.count)
    }
    
    func test_LiveActivity_PushToStart_PausedForPendingEdgeIdentity() {
        let event = createPushToStartEvent(token: "token1", attributeType: ATTRIBUTE_TYPE)
        
        // Simulate NO Edge Identity shared state
        mockRuntime.simulateSharedState(
            for: (extensionName: "com.adobe.module.configuration", event: event),
            data: (value: [:], status: .set))
        
        mockRuntime.simulateComingEvents(event)
        
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(0, mockRuntime.createdSharedStates.count)
    }
    
    // MARK: - UpdateTokens Tests
    
    func test_LiveActivity_UpdateToken_Happy() {
        // create and dispatch event
        let event = createUpdateTokenEvent(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE, liveActivityID: LIVE_ACTIVITY_ID)
        mockSharedStates(for: event)
        mockRuntime.simulateComingEvents(event)
        
        // verify edge event and shared state
        verifyUpdateTokenEdgeEvent(token: PUSH_TO_START_TOKEN, liveActivityID: LIVE_ACTIVITY_ID)
        verifyUpdateTokenSharedState(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE, liveActivityID: LIVE_ACTIVITY_ID)
    }
    
    func test_LiveActivity_UpdateToken_EmptyToken() {
        // create and dispatch event with empty token
        let event = createUpdateTokenEvent(token: "", attributeType: ATTRIBUTE_TYPE, liveActivityID: LIVE_ACTIVITY_ID)
        mockSharedStates(for: event)
        mockRuntime.simulateComingEvents(event)
        
        // verify no edge event is dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        
        // verify no shared state is created
        XCTAssertEqual(0, mockRuntime.createdSharedStates.count)
    }
    
    func test_LiveActivity_UpdateToken_MissingLiveActivityID() {
        // create event without Live Activity ID
        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.LIVE_ACTIVITY_UPDATE_TOKEN: true,
            MessagingConstants.XDM.Push.TOKEN: PUSH_TO_START_TOKEN,
            MessagingConstants.Event.Data.Key.ATTRIBUTE_TYPE: ATTRIBUTE_TYPE
        ]
        let event = Event(name: MessagingConstants.Event.Name.LIVE_ACTIVITY_UPDATE_TOKEN,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)
        
        mockSharedStates(for: event)
        mockRuntime.simulateComingEvents(event)
        
        // verify no edge event is dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        
        // verify no shared state is created
        XCTAssertEqual(0, mockRuntime.createdSharedStates.count)
    }
    
    func test_UpdateToken_MissingAttributeType() {
        let event = Event(
            name: MessagingConstants.Event.Name.LIVE_ACTIVITY_UPDATE_TOKEN,
            type: EventType.messaging,
            source: EventSource.requestContent,
            data: [
                MessagingConstants.Event.Data.Key.LIVE_ACTIVITY_UPDATE_TOKEN: true,
                MessagingConstants.XDM.Push.TOKEN: "tok",
                // Attribute type intentionally omitted
                MessagingConstants.XDM.LiveActivity.ID: "LID"
            ])
        mockSharedStates(for: event)
        mockRuntime.simulateComingEvents(event)
        
        // Edge call still sent but no shared state dispatched
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(0, mockRuntime.createdSharedStates.count)
    }
    
    func test_LiveActivity_UpdateToken_InvalidTokenFormat() {
        // create event with invalid token format (non-string)
        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.LIVE_ACTIVITY_UPDATE_TOKEN: true,
            MessagingConstants.XDM.Push.TOKEN: 123, // Invalid token format
            MessagingConstants.Event.Data.Key.ATTRIBUTE_TYPE: ATTRIBUTE_TYPE,
            MessagingConstants.XDM.LiveActivity.ID: LIVE_ACTIVITY_ID
        ]
        let event = Event(name: MessagingConstants.Event.Name.LIVE_ACTIVITY_UPDATE_TOKEN,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)
        
        mockSharedStates(for: event)
        mockRuntime.simulateComingEvents(event)
        
        // verify no edge event is dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        
        // verify no shared state is created
        XCTAssertEqual(0, mockRuntime.createdSharedStates.count)
    }
    
    // MARK: - LiveActivity Start Event Tests
    
    func test_LiveActivity_Start_Happy() {
        // create and dispatch event
        let event = createStartEvent(liveActivityID: LIVE_ACTIVITY_ID, channelID: nil, origin: "local")
        mockSharedStates(for: event)
        mockRuntime.simulateComingEvents(event)
        
        // verify edge event
        verifyStartEdgeEvent(liveActivityID: LIVE_ACTIVITY_ID, channelID: nil, origin: "local")
    }
    
    func test_LiveActivity_Start_WithChannelID() {
        // create and dispatch event with channel ID instead of Live Activity ID
        let event = createStartEvent(liveActivityID: nil, channelID: CHANNEL_ID, origin: "local")
        mockSharedStates(for: event)
        mockRuntime.simulateComingEvents(event)
        
        // verify edge event
        verifyStartEdgeEvent(liveActivityID: nil, channelID: CHANNEL_ID, origin: "local")
    }
    
    func test_LiveActivity_Start_MissingIdentifiers() {
        // create event without Live Activity ID or Channel ID
        let event = createStartEvent(liveActivityID: nil, channelID: nil, origin: "local")
        mockSharedStates(for: event)
        mockRuntime.simulateComingEvents(event)
        
        // verify no edge event is dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }
    
    func test_LiveActivity_Start_MissingOrigin() {
        // create event without origin
        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.LIVE_ACTIVITY_TRACK_START: true,
            MessagingConstants.Event.Data.Key.ATTRIBUTE_TYPE: ATTRIBUTE_TYPE,
            MessagingConstants.Event.Data.Key.APPLE_LIVE_ACTIVITY_ID: "testAppleActivityID",
            MessagingConstants.XDM.LiveActivity.ID: LIVE_ACTIVITY_ID
        ]
        let event = Event(name: MessagingConstants.Event.Name.LIVE_ACTIVITY_START,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)
        
        mockSharedStates(for: event)
        mockRuntime.simulateComingEvents(event)
        
        // verify no edge event is dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }
    
    // MARK: - LiveActivity State Event Tests
    
    func test_LiveActivity_Dismiss() {
        // Setup initial token state
        setupInitialTokenState()
        
        // Create and dispatch dismiss event
        let dismissEvent = createStateEvent(state: MessagingConstants.LiveActivity.States.DISMISSED, liveActivityID: LIVE_ACTIVITY_ID)
        mockSharedStates(for: dismissEvent)
        mockRuntime.simulateComingEvents(dismissEvent)
        
        // Verify token was removed
        verifyTokenRemovedFromSharedState()
    }
    
    func test_LiveActivity_Ended() {
        // Setup initial token state
        setupInitialTokenState()
        
        // Create and dispatch ended event
        let endedEvent = createStateEvent(state: MessagingConstants.LiveActivity.States.ENDED, liveActivityID: LIVE_ACTIVITY_ID)
        mockSharedStates(for: endedEvent)
        mockRuntime.simulateComingEvents(endedEvent)
        
        // Verify token was removed
        verifyTokenRemovedFromSharedState()
    }
    
    func test_LiveActivity_ActiveState() {
        // Setup initial token state
        setupInitialTokenState()
        
        // Create and dispatch ended event
        let endedEvent = createStateEvent(state: "Active", liveActivityID: LIVE_ACTIVITY_ID)
        mockSharedStates(for: endedEvent)
        mockRuntime.simulateComingEvents(endedEvent)

        // verify token is still in shared state
        verifyUpdateTokenSharedState(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE, liveActivityID: LIVE_ACTIVITY_ID)
    }
    
    func test_LiveActivity_StateEvent_MissingState() {
        // Setup initial token state
        setupInitialTokenState()
        
        // Create event without state
        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.LIVE_ACTIVITY_TRACK_STATE: true,
            MessagingConstants.Event.Data.Key.ATTRIBUTE_TYPE: ATTRIBUTE_TYPE,
            MessagingConstants.Event.Data.Key.APPLE_LIVE_ACTIVITY_ID: "testAppleActivityID",
            MessagingConstants.XDM.LiveActivity.ID: LIVE_ACTIVITY_ID
        ]
        let event = Event(name: MessagingConstants.Event.Name.LIVE_ACTIVITY_STATE,
                         type: EventType.messaging,
                         source: EventSource.requestContent,
                         data: eventData)
        
        mockSharedStates(for: event)
        mockRuntime.simulateComingEvents(event)
        
        // verify no edge event is dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        
        // verify token is still in shared state
        verifyUpdateTokenSharedState(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE, liveActivityID: LIVE_ACTIVITY_ID)
    }
    
    func test_LiveActivity_StateEvent_MissingAttributeType() {
        // Setup initial token state
        setupInitialTokenState()
        
        // Create event without attribute type
        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.LIVE_ACTIVITY_TRACK_STATE: true,
            MessagingConstants.Event.Data.Key.APPLE_LIVE_ACTIVITY_ID: "testAppleActivityID",
            MessagingConstants.XDM.LiveActivity.ID: LIVE_ACTIVITY_ID,
            MessagingConstants.Event.Data.Key.STATE: MessagingConstants.LiveActivity.States.DISMISSED
        ]
        let event = Event(name: MessagingConstants.Event.Name.LIVE_ACTIVITY_STATE,
                         type: EventType.messaging,
                         source: EventSource.requestContent,
                         data: eventData)
        
        mockSharedStates(for: event)
        mockRuntime.simulateComingEvents(event)
        
        // verify no edge event is dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        
        // verify token is still in shared state
        verifyUpdateTokenSharedState(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE, liveActivityID: LIVE_ACTIVITY_ID)
    }
    
    func test_LiveActivity_StateEvent_MissingLiveActivityID() {
        // Setup initial token state
        setupInitialTokenState()
        
        // Create event without live activity ID
        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.LIVE_ACTIVITY_TRACK_STATE: true,
            MessagingConstants.Event.Data.Key.ATTRIBUTE_TYPE: ATTRIBUTE_TYPE,
            MessagingConstants.Event.Data.Key.APPLE_LIVE_ACTIVITY_ID: "testAppleActivityID",
            MessagingConstants.Event.Data.Key.STATE: MessagingConstants.LiveActivity.States.DISMISSED
        ]
        let event = Event(name: MessagingConstants.Event.Name.LIVE_ACTIVITY_STATE,
                         type: EventType.messaging,
                         source: EventSource.requestContent,
                         data: eventData)
        
        mockSharedStates(for: event)
        mockRuntime.simulateComingEvents(event)
        
        // verify no edge event is dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        
        // verify token is still in shared state
        verifyUpdateTokenSharedState(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE, liveActivityID: LIVE_ACTIVITY_ID)
    }
    
    
    // MARK: - Helper Methods
    
    private func createPushToStartEvent(token: String, attributeType: String) -> Event {
        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.LIVE_ACTIVITY_PUSH_TO_START_TOKEN: true,
            MessagingConstants.XDM.Push.TOKEN: token,
            MessagingConstants.Event.Data.Key.ATTRIBUTE_TYPE: attributeType
        ]
        return Event(name: MessagingConstants.Event.Name.LIVE_ACTIVITY_PUSH_TO_START,
                     type: EventType.messaging,
                     source: EventSource.requestContent,
                     data: eventData)
    }
    
    private func createUpdateTokenEvent(token: String, attributeType: String, liveActivityID: String) -> Event {
        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.LIVE_ACTIVITY_UPDATE_TOKEN: true,
            MessagingConstants.XDM.Push.TOKEN: token,
            MessagingConstants.Event.Data.Key.ATTRIBUTE_TYPE: attributeType,
            MessagingConstants.XDM.LiveActivity.ID: liveActivityID
        ]
        return Event(name: MessagingConstants.Event.Name.LIVE_ACTIVITY_UPDATE_TOKEN,
                     type: EventType.messaging,
                     source: EventSource.requestContent,
                     data: eventData)
    }
    
    private func createStartEvent(liveActivityID: String?, channelID: String?, origin: String) -> Event {
        var eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.LIVE_ACTIVITY_TRACK_START: true,
            MessagingConstants.Event.Data.Key.ATTRIBUTE_TYPE: ATTRIBUTE_TYPE,
            MessagingConstants.Event.Data.Key.APPLE_LIVE_ACTIVITY_ID: "testAppleActivityID",
            MessagingConstants.XDM.LiveActivity.ORIGIN: origin
        ]
        
        if let liveActivityID = liveActivityID {
            eventData[MessagingConstants.XDM.LiveActivity.ID] = liveActivityID
        }
        
        if let channelID = channelID {
            eventData[MessagingConstants.XDM.LiveActivity.CHANNEL_ID] = channelID
        }
        
        return Event(name: MessagingConstants.Event.Name.LIVE_ACTIVITY_START,
                     type: EventType.messaging,
                     source: EventSource.requestContent,
                     data: eventData)
    }
    
    private func mockSharedStates(for event: Event, ecid: String? = nil) {
        // mock configuration shared state
        mockRuntime.simulateSharedState(for: (extensionName: "com.adobe.module.configuration", event: event), data: (value: [:], status: .set))
        
        // mock edge identity shared state with ECID
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: ecid ?? ECID]]]]
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))
    }
    
    private func verifyPushToStartEdgeEvent(token: String, attributeType: String) {
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let edgeEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.edge, edgeEvent.type)
        XCTAssertEqual(EventSource.requestContent, edgeEvent.source)
        
        let expectedJSON = """
        {
          "xdm": {
            "eventType": "liveActivity.pushToStart"
          },
          "data": {
            "liveActivityPushNotificationDetails": [
              {
                "appID": "com.adobe.ajo.e2eTestApp",
                "denylisted": false,
                "platform": "apns",
                "token": "\(token)",
                "liveActivityAttributeType": "\(attributeType)",
                "identity": {
                  "namespace": {
                    "code": "ECID"
                  },
                  "id": "\(ECID)"
                }
              }
            ]
          }
        }
        """
        assertExactMatch(expected: expectedJSON, actual: edgeEvent)
    }
    
    private func verifyUpdateTokenEdgeEvent(token: String, liveActivityID: String) {
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let edgeEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.edge, edgeEvent.type)
        XCTAssertEqual(EventSource.requestContent, edgeEvent.source)
        
        let expectedJSON = """
        {
          "xdm": {
            "eventType": "liveActivity.updateToken"
          },
          "data": {
            "liveActivityID": "\(liveActivityID)",
            "token": "\(token)"
          }
        }
        """
        assertExactMatch(expected: expectedJSON, actual: edgeEvent)
    }
    
    private func verifyPushToStartSharedState(token: String, attributeType: String) {
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)
        let sharedState = mockRuntime.firstSharedState!
        XCTAssertNotNil(sharedState[MessagingConstants.SharedState.Messaging.LIVE_ACTIVITY_PUSH_TO_START_TOKENS])
        
        if let pushToStartTokens = sharedState[MessagingConstants.SharedState.Messaging.LIVE_ACTIVITY_PUSH_TO_START_TOKENS] as? [String: Any],
           let tokens = pushToStartTokens["tokens"] as? [String: [String: Any]],
           let testActivityTokens = tokens[attributeType],
           let storedToken = testActivityTokens["token"] as? String {
            XCTAssertEqual(token, storedToken)
        } else {
            XCTFail("Push to start token not found in shared state")
        }
    }
    
    private func verifyUpdateTokenSharedState(token: String, attributeType: String, liveActivityID: String) {
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)
        let sharedState = mockRuntime.firstSharedState!
        XCTAssertNotNil(sharedState[MessagingConstants.SharedState.Messaging.LIVE_ACTIVITY_UPDATE_TOKENS])
        
        if let updateTokens = sharedState[MessagingConstants.SharedState.Messaging.LIVE_ACTIVITY_UPDATE_TOKENS] as? [String: Any],
           let tokens = updateTokens["tokens"] as? [String: [String: [String: Any]]],
           let attributeTokens = tokens[attributeType],
           let activityToken = attributeTokens[liveActivityID],
           let storedToken = activityToken["token"] as? String {
            XCTAssertEqual(token, storedToken)
        } else {
            XCTFail("Update token not found in shared state")
        }
    }
    
    private func verifyStartEdgeEvent(liveActivityID: String?, channelID: String?, origin: String) {
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let edgeEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.edge, edgeEvent.type)
        XCTAssertEqual(EventSource.requestContent, edgeEvent.source)
        
        var liveActivityData: [String: Any] = [
            "appID": "com.adobe.ajo.e2eTestApp",
            "origin": origin
        ]
        
        if let liveActivityID = liveActivityID {
            liveActivityData["liveActivityID"] = liveActivityID
        }
        
        if let channelID = channelID {
            liveActivityData["channelID"] = channelID
        }
        
        let expectedData: [String: Any] = [
            "xdm": [
                "eventType": "liveActivity.start",
                "liveActivity": liveActivityData
            ]
        ]
        
        assertExactMatch(expected: expectedData, actual: edgeEvent)
    }
    
    private func createStateEvent(state: String, liveActivityID: String) -> Event {
        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.LIVE_ACTIVITY_TRACK_STATE: true,
            MessagingConstants.Event.Data.Key.ATTRIBUTE_TYPE: ATTRIBUTE_TYPE,
            MessagingConstants.Event.Data.Key.APPLE_LIVE_ACTIVITY_ID: "testAppleActivityID",
            MessagingConstants.XDM.LiveActivity.ID: liveActivityID,
            MessagingConstants.Event.Data.Key.STATE: state
        ]
        return Event(name: MessagingConstants.Event.Name.LIVE_ACTIVITY_STATE,
                     type: EventType.messaging,
                     source: EventSource.requestContent,
                     data: eventData)
    }
    
    private func setupInitialTokenState() {
        let event = createUpdateTokenEvent(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE, liveActivityID: LIVE_ACTIVITY_ID)
        mockSharedStates(for: event)
        mockRuntime.simulateComingEvents(event)
        
        // Verify token was added to shared state
        verifyUpdateTokenSharedState(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE, liveActivityID: LIVE_ACTIVITY_ID)
        mockRuntime.dispatchedEvents.removeAll()
    }
    
    private func verifyTokenRemovedFromSharedState() {
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)
        let finalSharedState = mockRuntime.createdSharedStates[1]
        XCTAssertNotNil(finalSharedState?[MessagingConstants.SharedState.Messaging.LIVE_ACTIVITY_UPDATE_TOKENS])
        
        if let updateTokens = finalSharedState?[MessagingConstants.SharedState.Messaging.LIVE_ACTIVITY_UPDATE_TOKENS] as? [String: Any],
           let tokens = updateTokens["tokens"] as? [String: [String: [String: Any]]] {
            XCTAssertEqual(0, tokens.count, "Token should be removed from shared state")
        } else {
            XCTFail("Update tokens should not be found in shared state")
        }
    }
    
    func assertLiveActivityPushNotificationDetailsContains(_ actual: [[String: Any]], expected: [[String: Any]]) {
        XCTAssertEqual(actual.count, expected.count, "Array count mismatch")
        for expectedDict in expected {
            XCTAssertTrue(actual.contains(where: { NSDictionary(dictionary: $0).isEqual(to: expectedDict) }),
                          "Expected dictionary not found: \(expectedDict)")
        }
    }
}
