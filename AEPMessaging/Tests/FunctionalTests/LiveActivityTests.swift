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

import XCTest

import AEPMessagingLiveActivity
import AEPTestUtils

@testable import AEPCore
@testable import AEPMessaging
@testable import AEPServices

@available(iOS 16.1, *)
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
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
        MobileCore.setLogLevel(.trace)
    }

    // MARK: - PushToStartTokens Tests

    func test_LiveActivity_PushToStart_Happy() {
        // create and dispatch batched event
        let event = createPushToStartEvent(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE)
        simulateEventWithSharedStates(event)

        // verify edge event and shared state (batching happens at API layer, so no delay needed here)
        verifyPushToStartEdgeEvent(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE)
        verifyPushToStartSharedState(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE)
    }

    func test_LiveActivity_PushToStart_MultipleTokens() {
        let token1 = PUSH_TO_START_TOKEN
        let token2 = "testPushToStartToken2"
        let attributeType1 = ATTRIBUTE_TYPE
        let attributeType2 = "TestLiveActivityAttributes2"

        // Dispatch a single batched event with multiple tokens
        // (batching now happens at the API layer before dispatch)
        let event = createBatchedPushToStartEvent(tokens: [
            (token: token1, attributeType: attributeType1),
            (token: token2, attributeType: attributeType2)
        ])
        simulateEventWithSharedStates(event)

        // Both tokens are sent in a single edge event
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let edgeEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.edge, edgeEvent.type)
        XCTAssertEqual(EventSource.requestContent, edgeEvent.source)

        // verify edge event contains both tokens in the array
        let expected = """
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
                "token": "\(token1)",
                "attributeType": "\(attributeType1)",
                "identity": {
                  "namespace": {
                    "code": "ECID"
                  },
                  "id": "\(ECID)"
                }
              },
              {
                "appID": "com.adobe.ajo.e2eTestApp",
                "denylisted": false,
                "platform": "apns",
                "token": "\(token2)",
                "attributeType": "\(attributeType2)",
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

        assertExactMatch(expected: expected, actual: edgeEvent, pathOptions: AnyOrderMatch(scope: .subtree))

        // verify the shared state contains both tokens under their respective attribute types
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)
        let sharedState = mockRuntime.createdSharedStates[0]
        XCTAssertNotNil(sharedState?[MessagingConstants.SharedState.Messaging.LIVE_ACTIVITY])

        if let pushToStartTokens = sharedState?[MessagingConstants.SharedState.Messaging.LIVE_ACTIVITY] as? [String: Any],
           let tokens = pushToStartTokens[MessagingConstants.SharedState.Messaging.LiveActivity.PUSH_TO_START_TOKENS] as? [String: [String: Any]] {
            XCTAssertEqual(token1, tokens[attributeType1]?["token"] as? String)
            XCTAssertEqual(token2, tokens[attributeType2]?["token"] as? String)
        } else {
            XCTFail("Push to start tokens not found in shared state")
        }
    }

    func test_LiveActivity_PushToStart_NewToken_OverwritesOldToken() {
        let NEW_TOKEN = "newToken"

        // create and dispatch batched event with first token
        let event1 = createPushToStartEvent(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE)
        simulateEventWithSharedStates(event1)

        mockRuntime.resetDispatchedEventAndCreatedSharedStates()

        // create and dispatch batched event with new token (same attribute type)
        let event2 = createPushToStartEvent(token: NEW_TOKEN, attributeType: ATTRIBUTE_TYPE)
        simulateEventWithSharedStates(event2)

        // verify edge event and shared state contains latest token
        verifyPushToStartEdgeEvent(token: NEW_TOKEN, attributeType: ATTRIBUTE_TYPE)
        verifyPushToStartSharedState(token: NEW_TOKEN, attributeType: ATTRIBUTE_TYPE)
    }

    func test_LiveActivity_PushToStart_EmptyToken() {
        // create and dispatch batched event with empty token
        let event = createPushToStartEvent(token: "", attributeType: ATTRIBUTE_TYPE)
        simulateEventWithSharedStates(event)

        // verify no edge event is dispatched (empty token is skipped)
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // verify no shared state is created
        XCTAssertEqual(0, mockRuntime.createdSharedStates.count)
    }

    func test_LiveActivity_PushToStart_EmptyBatchedTokensArray() {
        // create batched event with empty tokens array
        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.LiveActivity.PUSH_TO_START_TOKEN: true,
            MessagingConstants.Event.Data.Key.LiveActivity.BATCHED_PUSH_TO_START_TOKENS: [] as [[String: String]]
        ]
        let event = Event(name: MessagingConstants.Event.Name.LiveActivity.PUSH_TO_START,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)

        simulateEventWithSharedStates(event)

        // verify no edge event is dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // verify no shared state is created
        XCTAssertEqual(0, mockRuntime.createdSharedStates.count)
    }

    func test_LiveActivity_PushToStart_MissingBatchedTokensArray() {
        // create push-to-start event without the batched tokens array
        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.LiveActivity.PUSH_TO_START_TOKEN: true
            // Missing BATCHED_PUSH_TO_START_TOKENS
        ]
        let event = Event(name: MessagingConstants.Event.Name.LiveActivity.PUSH_TO_START,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)

        simulateEventWithSharedStates(event)

        // verify no edge event is dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // verify no shared state is created
        XCTAssertEqual(0, mockRuntime.createdSharedStates.count)
    }

    func test_LiveActivity_PushToStart_MissingECID() {
        // create and dispatch event
        let event = createPushToStartEvent(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE)
        mockConfigurationAndEdgeIdentitySharedStates(at: event, ecid: "")
        mockRuntime.simulateComingEvents(event)

        // verify no edge event is dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // verify shared state is still created
        verifyPushToStartSharedState(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE)
    }

    func test_LiveActivity_PushToStart_MissingAttributeType() {
        // create batched event with token missing attribute type
        let tokensArray: [[String: String]] = [
            [MessagingConstants.XDM.Push.TOKEN: PUSH_TO_START_TOKEN]
            // Missing ATTRIBUTE_TYPE
        ]
        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.LiveActivity.PUSH_TO_START_TOKEN: true,
            MessagingConstants.Event.Data.Key.LiveActivity.BATCHED_PUSH_TO_START_TOKENS: tokensArray
        ]
        let event = Event(name: MessagingConstants.Event.Name.LiveActivity.PUSH_TO_START,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)

        simulateEventWithSharedStates(event)

        // verify no edge event is dispatched (token skipped due to missing attribute type)
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // verify no shared state is created
        XCTAssertEqual(0, mockRuntime.createdSharedStates.count)
    }

    func test_LiveActivity_PushToStart_InvalidTokenFormat() {
        // create batched event with invalid token format in the array
        let tokensArray: [[String: Any]] = [
            [
                MessagingConstants.XDM.Push.TOKEN: 123, // Invalid token format (non-string)
                MessagingConstants.Event.Data.Key.LiveActivity.ATTRIBUTE_TYPE: ATTRIBUTE_TYPE
            ]
        ]
        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.LiveActivity.PUSH_TO_START_TOKEN: true,
            MessagingConstants.Event.Data.Key.LiveActivity.BATCHED_PUSH_TO_START_TOKENS: tokensArray
        ]
        let event = Event(name: MessagingConstants.Event.Name.LiveActivity.PUSH_TO_START,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)

        simulateEventWithSharedStates(event)

        // verify no edge event is dispatched (token skipped due to invalid format)
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // verify no shared state is created
        XCTAssertEqual(0, mockRuntime.createdSharedStates.count)
    }

    func test_LiveActivity_PushToStart_PausedForPendingEdgeIdentity() {
        let event = createPushToStartEvent(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE)

        // Simulate NO Edge Identity shared state
        mockRuntime.simulateSharedState(
            for: (extensionName: "com.adobe.module.configuration", event: event),
            data: (value: [:], status: .set)
        )

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(0, mockRuntime.createdSharedStates.count)
    }

    // MARK: - UpdateTokens Tests

    func test_LiveActivity_UpdateToken_Happy() {
        // create and dispatch event
        let event = createUpdateTokenEvent(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE, liveActivityID: LIVE_ACTIVITY_ID)
        simulateEventWithSharedStates(event)

        // verify edge event and shared state
        verifyUpdateTokenEdgeEvent(token: PUSH_TO_START_TOKEN, liveActivityID: LIVE_ACTIVITY_ID)
        verifyUpdateTokenSharedState(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE, liveActivityID: LIVE_ACTIVITY_ID)
    }

    func test_LiveActivity_UpdateToken_EmptyToken() {
        // create and dispatch event with empty token
        let event = createUpdateTokenEvent(token: "", attributeType: ATTRIBUTE_TYPE, liveActivityID: LIVE_ACTIVITY_ID)
        simulateEventWithSharedStates(event)

        // verify no edge event is dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // verify no shared state is created
        XCTAssertEqual(0, mockRuntime.createdSharedStates.count)
    }

    func test_LiveActivity_UpdateToken_MissingLiveActivityID() {
        // create event without Live Activity ID
        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.LiveActivity.UPDATE_TOKEN: true,
            MessagingConstants.XDM.Push.TOKEN: PUSH_TO_START_TOKEN,
            MessagingConstants.Event.Data.Key.LiveActivity.ATTRIBUTE_TYPE: ATTRIBUTE_TYPE
        ]
        let event = Event(name: MessagingConstants.Event.Name.LiveActivity.UPDATE_TOKEN,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)

        simulateEventWithSharedStates(event)

        // verify no edge event is dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // verify no shared state is created
        XCTAssertEqual(0, mockRuntime.createdSharedStates.count)
    }

    func test_UpdateToken_MissingAttributeType() {
        let event = Event(
            name: MessagingConstants.Event.Name.LiveActivity.UPDATE_TOKEN,
            type: EventType.messaging,
            source: EventSource.requestContent,
            data: [
                MessagingConstants.Event.Data.Key.LiveActivity.UPDATE_TOKEN: true,
                MessagingConstants.XDM.Push.TOKEN: PUSH_TO_START_TOKEN,
                // Attribute type intentionally omitted
                MessagingConstants.XDM.LiveActivity.ID: "LID"
            ]
        )
        simulateEventWithSharedStates(event)

        // Edge call still sent but no shared state dispatched
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(0, mockRuntime.createdSharedStates.count)
    }

    func test_LiveActivity_UpdateToken_InvalidTokenFormat() {
        // create event with invalid token format (non-string)
        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.LiveActivity.UPDATE_TOKEN: true,
            MessagingConstants.XDM.Push.TOKEN: 123, // Invalid token format
            MessagingConstants.Event.Data.Key.LiveActivity.ATTRIBUTE_TYPE: ATTRIBUTE_TYPE,
            MessagingConstants.XDM.LiveActivity.ID: LIVE_ACTIVITY_ID
        ]
        let event = Event(name: MessagingConstants.Event.Name.LiveActivity.UPDATE_TOKEN,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)

        simulateEventWithSharedStates(event)

        // verify no edge event is dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // verify no shared state is created
        XCTAssertEqual(0, mockRuntime.createdSharedStates.count)
    }

    // MARK: - LiveActivity Start Event Tests

    func test_LiveActivity_Start_Happy() {
        // create and dispatch event
        let event = createStartEvent(liveActivityID: LIVE_ACTIVITY_ID, channelID: nil, origin: .local)
        simulateEventWithSharedStates(event)

        // verify edge event
        verifyStartEdgeEvent(liveActivityID: LIVE_ACTIVITY_ID, channelID: nil, origin: "local")
    }

    func test_LiveActivity_Start_WithChannelID() {
        let event = createStartEvent(liveActivityID: nil, channelID: CHANNEL_ID, origin: .local)
        simulateEventWithSharedStates(event)

        // edge event still verified
        verifyStartEdgeEvent(liveActivityID: nil,
                             channelID: CHANNEL_ID,
                             origin: "local")

        // NEW: shared state should exist after a channel start
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)
    }

    func test_LiveActivity_Start_MissingIdentifiers() {
        // create event without Live Activity ID or Channel ID
        let event = createStartEvent(liveActivityID: nil, channelID: nil, origin: .local)
        simulateEventWithSharedStates(event)

        // verify no edge event is dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func test_LiveActivity_Start_MissingOrigin() {
        // create event without origin
        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.LiveActivity.TRACK_START: true,
            MessagingConstants.Event.Data.Key.LiveActivity.ATTRIBUTE_TYPE: ATTRIBUTE_TYPE,
            MessagingConstants.Event.Data.Key.LiveActivity.APPLE_ID: "testAppleActivityID",
            MessagingConstants.XDM.LiveActivity.ID: LIVE_ACTIVITY_ID
        ]
        let event = Event(name: MessagingConstants.Event.Name.LiveActivity.START,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)

        simulateEventWithSharedStates(event)

        // verify no edge event is dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    // MARK: - LiveActivity State Event Tests

    func test_LiveActivity_Dismiss() {
        // Setup initial token state
        setupInitialTokenState()

        // Create and dispatch dismiss event
        let dismissEvent = createStateEvent(state: MessagingConstants.LiveActivity.States.DISMISSED, liveActivityID: LIVE_ACTIVITY_ID, channelID: nil)
        simulateEventWithSharedStates(dismissEvent)

        // Verify token was removed
        verifyTokenRemovedFromSharedState()
    }

    func test_LiveActivity_Ended() {
        // Setup initial token state
        setupInitialTokenState()

        // Create and dispatch ended event
        let endedEvent = createStateEvent(state: MessagingConstants.LiveActivity.States.ENDED, liveActivityID: LIVE_ACTIVITY_ID, channelID: nil)
        simulateEventWithSharedStates(endedEvent)

        // Verify token was removed
        verifyTokenRemovedFromSharedState()
    }

    func test_LiveActivity_ActiveStateEvent() {
        // Setup initial token state
        setupInitialTokenState()

        // Create and dispatch active state event
        let activeEvent = createStateEvent(state: "Active", liveActivityID: LIVE_ACTIVITY_ID, channelID: nil)
        simulateEventWithSharedStates(activeEvent)

        // verify token is still in shared state
        verifyUpdateTokenSharedState(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE, liveActivityID: LIVE_ACTIVITY_ID)
    }

    func test_LiveActivity_StateEvent_MissingState() {
        // Setup initial token state
        setupInitialTokenState()

        // Create event without state
        let eventName = "\(MessagingConstants.Event.Name.LIVE_ACTIVITY) "
        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.LiveActivity.TRACK_STATE: true,
            MessagingConstants.Event.Data.Key.LiveActivity.ATTRIBUTE_TYPE: ATTRIBUTE_TYPE,
            MessagingConstants.Event.Data.Key.LiveActivity.APPLE_ID: "testAppleActivityID",
            MessagingConstants.XDM.LiveActivity.ID: LIVE_ACTIVITY_ID
        ]
        let event = Event(name: eventName,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)

        simulateEventWithSharedStates(event)

        // verify no edge event is dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // verify token is still in shared state
        verifyUpdateTokenSharedState(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE, liveActivityID: LIVE_ACTIVITY_ID)
    }

    func test_LiveActivity_StateEvent_MissingAttributeType() {
        // Setup initial token state
        setupInitialTokenState()

        // Create event without attribute type
        let eventName = "\(MessagingConstants.Event.Name.LIVE_ACTIVITY) \(MessagingConstants.LiveActivity.States.DISMISSED)"
        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.LiveActivity.TRACK_STATE: true,
            MessagingConstants.Event.Data.Key.LiveActivity.APPLE_ID: "testAppleActivityID",
            MessagingConstants.XDM.LiveActivity.ID: LIVE_ACTIVITY_ID,
            MessagingConstants.Event.Data.Key.LiveActivity.STATE: MessagingConstants.LiveActivity.States.DISMISSED
        ]
        let event = Event(name: eventName,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)

        simulateEventWithSharedStates(event)

        // verify no edge event is dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // verify token is still in shared state
        verifyUpdateTokenSharedState(token: PUSH_TO_START_TOKEN, attributeType: ATTRIBUTE_TYPE, liveActivityID: LIVE_ACTIVITY_ID)
    }

    func test_LiveActivity_StateEvent_MissingLiveActivityID() {
        // Setup initial token state
        setupInitialTokenState()

        // Create event without live activity ID
        let eventName = "\(MessagingConstants.Event.Name.LIVE_ACTIVITY) \(MessagingConstants.LiveActivity.States.DISMISSED)"
        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.LiveActivity.TRACK_STATE: true,
            MessagingConstants.Event.Data.Key.LiveActivity.ATTRIBUTE_TYPE: ATTRIBUTE_TYPE,
            MessagingConstants.Event.Data.Key.LiveActivity.APPLE_ID: "testAppleActivityID",
            MessagingConstants.Event.Data.Key.LiveActivity.STATE: MessagingConstants.LiveActivity.States.DISMISSED
        ]
        let event = Event(name: eventName,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)

        simulateEventWithSharedStates(event)

        // verify no edge event is dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // verify token is still in shared state
        verifyUpdateTokenSharedState(
            token: PUSH_TO_START_TOKEN,
            attributeType: ATTRIBUTE_TYPE,
            liveActivityID: LIVE_ACTIVITY_ID
        )
    }

    // MARK: - Channel Tests

    func test_LiveActivity_Channel_Dismiss() {
        setupInitialChannelState()
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()

        let dismissEvent = createStateEvent(state: MessagingConstants.LiveActivity.States.DISMISSED,
                                            liveActivityID: nil,
                                            channelID: CHANNEL_ID)
        simulateEventWithSharedStates(dismissEvent)

        verifyChannelStoreRemovedFromSharedState()
    }

    func test_LiveActivity_Channel_Ended() {
        setupInitialChannelState()
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()

        let endedEvent = createStateEvent(state: MessagingConstants.LiveActivity.States.ENDED,
                                          liveActivityID: nil,
                                          channelID: CHANNEL_ID)
        simulateEventWithSharedStates(endedEvent)

        verifyChannelStoreRemovedFromSharedState()
    }

    func test_LiveActivity_Channel_ActiveStateEvent() {
        setupInitialChannelState()
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()

        let activeEvent = createStateEvent(state: "Active",
                                           liveActivityID: nil,
                                           channelID: CHANNEL_ID)
        simulateEventWithSharedStates(activeEvent)

        // A non-terminal state should not publish a new shared state
        XCTAssertEqual(0, mockRuntime.createdSharedStates.count)
    }

    func test_LiveActivity_Channel_MultipleActivities_OneEnds() {
        let CHANNEL_ID_2 = "channel_2"

        // Start two channel based activities
        let startFirstChannel = createStartEvent(liveActivityID: nil, channelID: CHANNEL_ID, origin: .remote)
        simulateEventWithSharedStates(startFirstChannel)

        let startSecondChannel = createStartEvent(liveActivityID: nil, channelID: CHANNEL_ID_2, origin: .remote)
        simulateEventWithSharedStates(startSecondChannel)

        // Two shared-state snapshots should exist - one per start
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()

        // End only first channel activity
        let endFirstChannel = createStateEvent(state: MessagingConstants.LiveActivity.States.DISMISSED,
                                               liveActivityID: nil,
                                               channelID: CHANNEL_ID)
        simulateEventWithSharedStates(endFirstChannel)

        // A new shared state after dismiss should be published
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)

        // Verify first channel activity is gone and other channel remains
        guard let sharedState = mockRuntime.createdSharedStates.first ?? nil,
              let liveActivity = sharedState[MessagingConstants.SharedState.Messaging.LIVE_ACTIVITY] as? [String: Any],
              let channelActivities = liveActivity[MessagingConstants.SharedState.Messaging.LiveActivity.CHANNEL_ACTIVITIES] as? [String: Any]
        else {
            XCTFail("Live Activity shared state missing")
            return
        }

        XCTAssertNil(channelActivities[CHANNEL_ID], "Dismissed channel should be removed")
        XCTAssertNotNil(channelActivities[CHANNEL_ID_2], "Ongoing channel should remain")
    }

    // MARK: - Helper Methods

    /// Creates a batched push-to-start event with a single token
    private func createPushToStartEvent(token: String, attributeType: String) -> Event {
        createBatchedPushToStartEvent(tokens: [(token: token, attributeType: attributeType)])
    }

    /// Creates a batched push-to-start event with multiple tokens
    private func createBatchedPushToStartEvent(tokens: [(token: String, attributeType: String)]) -> Event {
        let tokensArray = tokens.map { tokenData in
            [
                MessagingConstants.Event.Data.Key.LiveActivity.ATTRIBUTE_TYPE: tokenData.attributeType,
                MessagingConstants.XDM.Push.TOKEN: tokenData.token
            ]
        }
        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.LiveActivity.PUSH_TO_START_TOKEN: true,
            MessagingConstants.Event.Data.Key.LiveActivity.BATCHED_PUSH_TO_START_TOKENS: tokensArray
        ]
        return Event(name: "\(MessagingConstants.Event.Name.LiveActivity.PUSH_TO_START) (Batched)",
                     type: EventType.messaging,
                     source: EventSource.requestContent,
                     data: eventData)
    }

    private func createUpdateTokenEvent(token: String, attributeType: String, liveActivityID: String) -> Event {
        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.LiveActivity.UPDATE_TOKEN: true,
            MessagingConstants.XDM.Push.TOKEN: token,
            MessagingConstants.Event.Data.Key.LiveActivity.ATTRIBUTE_TYPE: attributeType,
            MessagingConstants.XDM.LiveActivity.ID: liveActivityID
        ]
        return Event(name: MessagingConstants.Event.Name.LiveActivity.UPDATE_TOKEN,
                     type: EventType.messaging,
                     source: EventSource.requestContent,
                     data: eventData)
    }

    private func createStartEvent(liveActivityID: String?, channelID: String?, origin: LiveActivityOrigin) -> Event {
        var eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.LiveActivity.TRACK_START: true,
            MessagingConstants.Event.Data.Key.LiveActivity.ATTRIBUTE_TYPE: ATTRIBUTE_TYPE,
            MessagingConstants.Event.Data.Key.LiveActivity.APPLE_ID: "testAppleActivityID",
            MessagingConstants.XDM.LiveActivity.ORIGIN: origin.rawValue
        ]

        if let liveActivityID = liveActivityID {
            eventData[MessagingConstants.XDM.LiveActivity.ID] = liveActivityID
        }

        if let channelID = channelID {
            eventData[MessagingConstants.XDM.LiveActivity.CHANNEL_ID] = channelID
        }

        return Event(name: MessagingConstants.Event.Name.LiveActivity.START,
                     type: EventType.messaging,
                     source: EventSource.requestContent,
                     data: eventData)
    }

    private func mockConfigurationAndEdgeIdentitySharedStates(at event: Event, ecid: String? = nil) {
        // mock configuration shared state with dataset id for Edge collect
        mockRuntime.simulateSharedState(
            for: (extensionName: "com.adobe.module.configuration", event: event),
            data: (value: [MessagingConstants.SharedState.Configuration.EXPERIENCE_EVENT_DATASET: "mockDataset"], status: .set)
        )

        // mock edge identity shared state with ECID
        let mockEdgeIdentity: [String: Any] = [
            MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [
                MessagingConstants.SharedState.EdgeIdentity.ECID: [
                    [MessagingConstants.SharedState.EdgeIdentity.ID: ecid ?? ECID]
                ]
            ]
        ]
        mockRuntime.simulateXDMSharedState(
            for: MessagingConstants.SharedState.EdgeIdentity.NAME,
            data: (value: mockEdgeIdentity, status: SharedStateStatus.set)
        )
    }

    private func verifyPushToStartEdgeEvent(token: String, attributeType: String) {
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let edgeEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.edge, edgeEvent.type)
        XCTAssertEqual(EventSource.requestContent, edgeEvent.source)
        // Validate event type
        if let xdm = edgeEvent.data?["xdm"] as? [String: Any] {
            XCTAssertEqual("liveActivity.pushToStart", xdm["eventType"] as? String)
        } else {
            XCTFail("Missing xdm in edge event")
        }

        // Validate details contains an entry for the expected attributeType with the expected token
        guard let data = edgeEvent.data?["data"] as? [String: Any],
              let details = data["liveActivityPushNotificationDetails"] as? [[String: Any]]
        else {
            XCTFail("Missing push-to-start details in edge event data")
            return
        }

        let matchingEntry = details.first { entry in
            (entry["attributeType"] as? String) == attributeType &&
            (entry["token"] as? String) == token
        }

        XCTAssertNotNil(matchingEntry, "Expected push-to-start details to include attributeType=\(attributeType) with token=\(token). Actual: \(details)")
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
        guard let finalSharedStateOptional = mockRuntime.createdSharedStates.last,
              let finalSharedState = finalSharedStateOptional else {
            XCTFail("Final shared state is missing or nil")
            return
        }

        if let liveActivity = finalSharedState[MessagingConstants.SharedState.Messaging.LIVE_ACTIVITY] as? [String: Any],
           let pushToStartTokens = liveActivity[MessagingConstants.SharedState.Messaging.LiveActivity.PUSH_TO_START_TOKENS] as? [String: Any],
           let testActivityTokens = pushToStartTokens[attributeType] as? [String: Any],
           let storedToken = testActivityTokens["token"] as? String {
            XCTAssertEqual(token, storedToken)
        } else {
            XCTFail("Push to start token not found in shared state")
        }
    }

    private func verifyUpdateTokenSharedState(token: String, attributeType _: String, liveActivityID: String) {
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)
        let sharedState = mockRuntime.firstSharedState!

        if let liveActivity = sharedState[MessagingConstants.SharedState.Messaging.LIVE_ACTIVITY] as? [String: Any],
           let updateTokens = liveActivity[MessagingConstants.SharedState.Messaging.LiveActivity.UPDATE_TOKENS] as? [String: Any],
           let activity = updateTokens[liveActivityID] as? [String: Any],
           let storedToken = activity["token"] as? String {
            XCTAssertEqual(token, storedToken)
        } else {
            XCTFail("Update token not found in shared state")
        }
    }

    private func verifyStartEdgeEvent(liveActivityID: String?, channelID: String?, origin _: String) {
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let edgeEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.edge, edgeEvent.type)
        XCTAssertEqual(EventSource.requestContent, edgeEvent.source)

        var liveActivityNode: [String: Any] = [
            "event": MessagingConstants.XDM.LiveActivity.START
        ]
        if let liveActivityID = liveActivityID {
            liveActivityNode["liveActivityID"] = liveActivityID
        }
        if let channelID = channelID {
            liveActivityNode["channelID"] = channelID
        }

        let expectedData: [String: Any] = [
            "xdm": [
                "eventType": "liveActivity.start",
                "_experience": [
                    "customerJourneyManagement": [
                        "messageProfile": [
                            "channel": [
                                "_id": MessagingConstants.XDM.AdobeKeys.LIVE_ACTIVITY_CHANNEL_ID
                            ]
                        ],
                        "pushChannelContext": [
                            "liveActivity": liveActivityNode,
                            "platform": MessagingConstants.XDM.Push.Value.APNS
                        ]
                    ]
                ]
            ],
            "meta": [
                "collect": [
                    "datasetId": "mockDataset"
                ]
            ]
        ]

        assertExactMatch(expected: expectedData, actual: edgeEvent, pathOptions: AnyOrderMatch(scope: .subtree))
    }

    private func createStateEvent(state: String,
                                  liveActivityID: String?,
                                  channelID: String?) -> Event {
        let eventName = "\(MessagingConstants.Event.Name.LIVE_ACTIVITY) \(state)"
        var data: [String: Any] = [
            MessagingConstants.Event.Data.Key.LiveActivity.TRACK_STATE: true,
            MessagingConstants.Event.Data.Key.LiveActivity.ATTRIBUTE_TYPE: ATTRIBUTE_TYPE,
            MessagingConstants.Event.Data.Key.LiveActivity.APPLE_ID: "testAppleActivityID",
            MessagingConstants.Event.Data.Key.LiveActivity.STATE: state
        ]
        if let liveActivityID = liveActivityID {
            data[MessagingConstants.XDM.LiveActivity.ID] = liveActivityID
        }
        if let channelID = channelID {
            data[MessagingConstants.XDM.LiveActivity.CHANNEL_ID] = channelID
        }
        return Event(name: eventName,
                     type: EventType.messaging,
                     source: EventSource.requestContent,
                     data: data)
    }

    private func simulateEventWithSharedStates(_ event: Event) {
        mockConfigurationAndEdgeIdentitySharedStates(at: event)
        mockRuntime.simulateComingEvents(event)
    }

    private func setupInitialTokenState() {
        let event = createUpdateTokenEvent(
            token: PUSH_TO_START_TOKEN,
            attributeType: ATTRIBUTE_TYPE,
            liveActivityID: LIVE_ACTIVITY_ID
        )

        simulateEventWithSharedStates(event)

        // Verify token was added to shared state
        verifyUpdateTokenSharedState(
            token: PUSH_TO_START_TOKEN,
            attributeType: ATTRIBUTE_TYPE,
            liveActivityID: LIVE_ACTIVITY_ID
        )
        mockRuntime.dispatchedEvents.removeAll()
    }

    private func verifyTokenRemovedFromSharedState() {
        XCTAssertEqual(mockRuntime.createdSharedStates.count, 2, "Expected exactly two shared states")
        guard let finalSharedStateOptional = mockRuntime.createdSharedStates.last,
              let finalSharedState = finalSharedStateOptional else {
            XCTFail("Final shared state is missing or nil")
            return
        }
        XCTAssertTrue(finalSharedState.isEmpty, "Expected the final shared state to be empty")
        print("finalsharedstate: \(finalSharedState)")
    }

    private func setupInitialChannelState() {
        let startEvent = createStartEvent(liveActivityID: nil,
                                          channelID: CHANNEL_ID,
                                          origin: .remote)
        simulateEventWithSharedStates(startEvent)

        XCTAssertEqual(1, mockRuntime.createdSharedStates.count, "Channel start should publish a shared state")

        if let sharedState = mockRuntime.firstSharedState,
           let liveActivity = sharedState[MessagingConstants.SharedState.Messaging.LIVE_ACTIVITY] as? [String: Any],
           let channelActivities = liveActivity[MessagingConstants.SharedState.Messaging.LiveActivity.CHANNEL_ACTIVITIES] as? [String: Any],
           let activity = channelActivities[CHANNEL_ID] as? [String: Any],
           let attributeType = activity["attributeType"] as? String {
            XCTAssertEqual(ATTRIBUTE_TYPE, attributeType)
        } else {
            XCTFail("Channel activity entry missing from shared state")
        }
    }

    private func verifyChannelStoreRemovedFromSharedState() {
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count,
                       "Exactly one shared state (the post-dismiss one) expected.")
        guard let sharedState = mockRuntime.createdSharedStates.first ?? nil else {
            XCTFail("shared state missing")
            return
        }
        XCTAssertTrue(sharedState.isEmpty, "Channel activity shared state should be empty after dismissal.")
    }
}
