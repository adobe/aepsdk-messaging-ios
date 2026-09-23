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

    // MARK: - Success + error on the same request id (end-to-end, real rules engines)

    /// End-to-end companion to
    /// `MessagingProcessCompletedEventTests.test_handleProcessCompletedEvent_successAndErrorForSameRequestId_stillReplacesRulesWithSuccessfulData`.
    ///
    /// That unit test verifies the collaboration against MOCK rules engines (asserts `replaceRules` was
    /// called). This one drives the SAME scenario through the REAL `MessagingRulesEngine` created by
    /// `Messaging(runtime:)`, so it proves the good data actually lands in the rules engine and reporting
    /// caches — not just that a method was invoked.
    ///
    /// Scenario: Edge returns a valid `personalization:decisions` response AND a non-recoverable
    /// `errorResponseContent` event for the SAME requesting event id. The successful in-app rules must
    /// still be loaded into `inAppRulesBySurface`, the proposition info must be cached for reporting,
    /// nothing may be evicted, and the completion handler must report success (`true`).
    func testSuccessAndErrorForSameRequestId_stillLoadsSuccessfulRulesIntoRealEngine() {
        let iamSurface = Surface(uri: "mobileapp://com.adobe.ajo.e2eTestApp/inapp")
        let consequenceId = "iam-consequence-0"
        let iamProposition = makeInAppRulesetProposition(surface: iamSurface, consequenceId: consequenceId)

        // Use a real UUID so the completion-handler lookup (UUID(uuidString:)) resolves.
        let requestId = UUID().uuidString
        messaging.setRequestedSurfacesforEventId(requestId, expectedSurfaces: [iamSurface])

        // Register a completion handler keyed to this Edge request event id.
        Messaging.completionHandlers.removeAll()
        let originatingEvent = Event(name: MessagingConstants.Event.Name.UPDATE_PROPOSITIONS,
                                     type: EventType.messaging,
                                     source: EventSource.requestContent,
                                     data: nil)
        var completionResult: Bool?
        var handler = CompletionHandler(originatingEvent: originatingEvent) { success in
            completionResult = success
        }
        handler.edgeRequestEventId = UUID(uuidString: requestId)
        Messaging.completionHandlers.append(handler)

        // 1) Successful personalization:decisions response for the request id.
        let decisionsEvent = makeDecisionsEvent(payload: [iamProposition].compactMap { $0.asDictionary() },
                                                requestId: requestId)
        mockRuntime.simulateComingEvents(decisionsEvent)

        // 2) A NON-recoverable Edge error (status 400) ALSO arrives for the SAME request id.
        mockRuntime.simulateComingEvents(makeEdgeErrorEvent(requestId: requestId, status: 400))

        // 3) End of streaming for the request.
        messaging.handleProcessCompletedEvent(makeProcessCompleteEvent(requestId: requestId))
        Thread.sleep(forTimeInterval: 0.1)

        // The successfully-returned in-app rule must be loaded for its surface even though an error
        // rode along on the same request. (With only an error and no decisions, this would be empty.)
        XCTAssertEqual(1, messaging.inAppRulesBySurface[iamSurface]?.count,
                       "The in-app rule from the successful response must be loaded into the real rules engine")

        // The proposition info must be cached for reporting, keyed by the consequence id.
        XCTAssertNotNil(messaging.propositionInfo[consequenceId],
                        "Proposition info for the successful in-app proposition must be cached for reporting")

        // The completion handler must report success even though an error was received.
        XCTAssertEqual(true, completionResult,
                       "Completion handler must return true when successful data accompanies an error")

        // Per-request error tracking must be cleaned up once the request ends.
        XCTAssertFalse(messaging.getNonRecoverableErrorEventIds().contains(requestId),
                       "Non-recoverable error tracking must be cleared after the request completes")
    }

    // MARK: - Private helpers

    /// Builds a `.ruleset` in-app proposition inline (the FunctionalTests target does not bundle the
    /// JSON rule fixtures). The single rule carries one in-app schema consequence, which
    /// `ParsedPropositions` loads into `inAppRulesBySurface` and records in `propositionInfo`.
    private func makeInAppRulesetProposition(surface: Surface, consequenceId: String) -> Proposition {
        let rulesJson: [String: Any] = [
            "version": 1,
            "rules": [[
                "condition": [
                    "type": "group",
                    "definition": [
                        "logic": "and",
                        "conditions": [[
                            "type": "matcher",
                            "definition": [
                                "key": "~type",
                                "matcher": "eq",
                                "values": ["com.adobe.eventType.generic.track"]
                            ]
                        ]]
                    ]
                ],
                "consequences": [[
                    "id": consequenceId,
                    "type": "schema",
                    "detail": [
                        "id": consequenceId,
                        "schema": MessagingConstants.PersonalizationSchemas.IN_APP,
                        "data": [
                            "content": "{\"body\":\"hello\"}",
                            "contentType": "application/json"
                        ]
                    ]
                ]]
            ]]
        ]
        let item = PropositionItem(itemId: "iam_0", schema: .ruleset, itemData: rulesJson)
        return Proposition(uniqueId: "iamProp_0",
                           scope: surface.uri,
                           scopeDetails: ["decisionProvider": "AJO"],
                           items: [item])
    }

    private func makeDecisionsEvent(payload: [[String: Any]], requestId: String) -> Event {
        Event(name: "decisions",
              type: EventType.edge,
              source: MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS,
              data: [
                  MessagingConstants.Event.Data.Key.Personalization.PAYLOAD: payload,
                  MessagingConstants.Event.Data.Key.REQUEST_EVENT_ID: requestId
              ])
    }

    private func makeEdgeErrorEvent(requestId: String, status: Int) -> Event {
        Event(name: "Edge Error",
              type: EventType.edge,
              source: MessagingConstants.Event.Source.EDGE_ERROR_RESPONSE,
              data: [
                  MessagingConstants.Event.Data.Key.REQUEST_EVENT_ID: requestId,
                  MessagingConstants.Event.Data.Key.EdgeError.STATUS: status
              ])
    }

    private func makeProcessCompleteEvent(requestId: String) -> Event {
        Event(name: "process complete",
              type: EventType.messaging,
              source: EventSource.contentComplete,
              data: [MessagingConstants.Event.Data.Key.ENDING_EVENT_ID: requestId])
    }
}
