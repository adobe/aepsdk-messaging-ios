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

import AEPRulesEngine
import AEPTestUtils

@testable import AEPCore
@testable import AEPMessaging

class MessagingProcessCompletedEventTests: XCTestCase {
    private var messaging: Messaging!
    private var mockRuntime: TestableExtensionRuntime!
    private var mockCache: MockCache!
    private var mockLaunchRulesEngine: MockLaunchRulesEngine!
    private var mockMessagingRulesEngine: MockMessagingRulesEngine!
    private var mockContentCardLaunchRulesEngine: MockLaunchRulesEngine!
    private var mockContentCardRulesEngine: MockContentCardRulesEngine!

    // Surfaces that will be used in the tests
    private let iamSurface = Surface(uri: "mobileapp://inapp")
    private let cardSurface = Surface(uri: "mobileapp://apifeed")

    override func setUp() {
        super.setUp()
        EventHub.shared = EventHub()

        mockRuntime = TestableExtensionRuntime()
        mockCache = MockCache(name: "mockCache")

        mockLaunchRulesEngine = MockLaunchRulesEngine(name: "mockIAMRulesEngine", extensionRuntime: mockRuntime)
        mockMessagingRulesEngine = MockMessagingRulesEngine(extensionRuntime: mockRuntime,
                                                            launchRulesEngine: mockLaunchRulesEngine,
                                                            cache: mockCache)

        mockContentCardLaunchRulesEngine = MockLaunchRulesEngine(name: "mockCardRulesEngine", extensionRuntime: mockRuntime)
        mockContentCardRulesEngine = MockContentCardRulesEngine(extensionRuntime: mockRuntime,
                                                                launchRulesEngine: mockContentCardLaunchRulesEngine)

        messaging = Messaging(runtime: mockRuntime,
                              rulesEngine: mockMessagingRulesEngine,
                              contentCardRulesEngine: mockContentCardRulesEngine,
                              expectedSurfaceUri: iamSurface.uri,
                              cache: mockCache,
                              stateManager: .init())
        messaging.onRegistered()
    }

    override func tearDown() {
        super.tearDown()
    }

    func test_handleProcessCompletedEvent_InAppAndContentCardRulesCompleted() {
        // Setup
        // Create 3 IAM and 4 content-card propositions
        let iamPropositions = (0..<3).map { makeInAppProposition(index: $0) }
        let cardPropositions = (0..<4).map { makeCardProposition(surface: cardSurface, index: $0) }
        let payloadDicts = (iamPropositions + cardPropositions).compactMap { $0.asDictionary() }

        // Prime `requestedSurfacesForEventId` so that the decision event is accepted
        let requestId = "TESTING_ID"

        messaging.setRequestedSurfacesforEventId(requestId, expectedSurfaces: [iamSurface, cardSurface, Surface(uri: "mobileapp://mockSurface")])

        // Simulate the personalization:decisions event
        let decisionsEvent = Event(name: "decisions",
                                   type: EventType.edge,
                                   source: MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS,
                                   data: [
                                       MessagingConstants.Event.Data.Key.Personalization.PAYLOAD: payloadDicts,
                                       MessagingConstants.Event.Data.Key.REQUEST_EVENT_ID: requestId
                                   ])

        mockRuntime.simulateComingEvents(decisionsEvent)

        // Simulate Edge’s process-completed callback
        let processEvent = Event(name: "process complete",
                                 type: EventType.messaging,
                                 source: EventSource.contentComplete,
                                 data: [MessagingConstants.Event.Data.Key.ENDING_EVENT_ID: requestId])

        messaging.handleProcessCompletedEvent(processEvent)

        // Validate
        // IAM and content card rules should be replaced once each
        XCTAssertTrue(mockLaunchRulesEngine.replaceRulesCalled,
                      "In-app rules engine should have replaceRules called")
        XCTAssertTrue(mockContentCardLaunchRulesEngine.replaceRulesCalled,
                      "Content-card rules engine should have replaceRules called")

        // Expect 3 IAM rules and 12 content card associated event history operation rules
        // 3 IAM + (4 cards x 3 event history operation rules = 12) = 15 total
        let iamRuleCount = mockLaunchRulesEngine.paramReplaceRulesRules?.filter { rule in
            rule.consequences.contains { consequence in
                let ruleType = consequence.details[MessagingTestConstants.EventDataKeys.RulesEngine.MESSAGE_CONSEQUENCE_DETAIL_KEY_SCHEMA] as? String
                return ruleType == SchemaType.inapp.toString()
            }
        }.count ?? 0

        let eventHistoryRuleCount = mockLaunchRulesEngine.paramReplaceRulesRules?.filter { rule in
            rule.consequences.contains { consequence in
                let ruleType = consequence.details[MessagingTestConstants.EventDataKeys.RulesEngine.MESSAGE_CONSEQUENCE_DETAIL_KEY_SCHEMA] as? String
                return ruleType == SchemaType.eventHistoryOperation.toString()
            }
        }.count ?? 0

        XCTAssertEqual(3, iamRuleCount)
        XCTAssertEqual(12, eventHistoryRuleCount)

        // Verify IAM rules are returned in priority order using helper
        let iamRules: [LaunchRule] = (mockLaunchRulesEngine.paramReplaceRulesRules ?? []).filter { rule in
            rule.consequences.contains { consequence in
                let ruleType = consequence.details[MessagingTestConstants.EventDataKeys.RulesEngine.MESSAGE_CONSEQUENCE_DETAIL_KEY_SCHEMA] as? String
                return ruleType == SchemaType.inapp.toString()
            }
        }
        verifyInAppRulesOrdering(iamRules)

        // Content card rules engine should receive 4 rules (one per card)
        let cardRuleCount = mockContentCardLaunchRulesEngine.paramReplaceRulesRules?.count ?? 0
        XCTAssertEqual(4, cardRuleCount)

        // Verify propositions were cached once
        XCTAssertTrue(mockCache.setCalled, "Cache should have been updated with new propositions")
        if let entry = mockCache.setParamEntry {
            // Decode cached data into dictionary
            if let decoded = try? JSONDecoder().decode([String: [Proposition]].self, from: entry.data) {
                // Only IAM surface should be present (mockSurface removed)
                XCTAssertEqual(1, decoded.count)
                if let iamCached = decoded[iamSurface.uri] {
                    XCTAssertEqual(3, iamCached.count, "Three IAM propositions should be cached")
                } else {
                    XCTFail("IAM surface not found in cached propositions")
                }
            }
        }
        // Cache.remove should NOT be invoked because the propositions file remains with other surfaces
        XCTAssertFalse(mockCache.removeCalled)
        // Notification event should NOT be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func test_handleProcessCompletedEvent_IAMPropositionsNotReturnedInSubsequentResponse() {
        // ---------- First response contains IAM + content cards ----------
        let iamPropositions = (0..<3).map { makeInAppProposition(index: $0) }
        let cardPropositions = (0..<4).map { makeCardProposition(surface: cardSurface, index: $0) }
        let firstPayload = (iamPropositions + cardPropositions).compactMap { $0.asDictionary() }
        let firstRequestId = "TESTING_ID_1"

        // Register expected surfaces for first request
        messaging.setRequestedSurfacesforEventId(firstRequestId, expectedSurfaces: [iamSurface, cardSurface])

        // Fire personalization:decisions event for first response
        let decisionsEvent1 = Event(name: "decisions",
                                    type: EventType.edge,
                                    source: MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS,
                                    data: [
                                        MessagingConstants.Event.Data.Key.Personalization.PAYLOAD: firstPayload,
                                        MessagingConstants.Event.Data.Key.REQUEST_EVENT_ID: firstRequestId
                                    ])
        mockRuntime.simulateComingEvents(decisionsEvent1)

        // Process-completed for first response
        let processEvent1 = Event(name: "process complete",
                                  type: EventType.messaging,
                                  source: EventSource.contentComplete,
                                  data: [MessagingConstants.Event.Data.Key.ENDING_EVENT_ID: firstRequestId])
        messaging.handleProcessCompletedEvent(processEvent1)

        // Capture first call results BEFORE second request overwrites them
        let firstEngineRules = mockLaunchRulesEngine.paramReplaceRulesRules ?? []
        let firstCardEngineRules = mockContentCardLaunchRulesEngine.paramReplaceRulesRules ?? []

        XCTAssertEqual(15, firstEngineRules.count, "First replaceRules should load 15 total rules (3 IAM + 12 event-history)")
        XCTAssertEqual(4, firstCardEngineRules.count, "First content-card rules engine call should load 4 rules")

        // Cache should have been written with IAM propositions
        XCTAssertTrue(mockCache.setCalled)
        XCTAssertFalse(mockCache.removeCalled)

        // ---------- Second response contains ONLY content cards ----------
        mockLaunchRulesEngine.replaceRulesCalled = false
        mockContentCardLaunchRulesEngine.replaceRulesCalled = false
        mockCache.setCalled = false
        mockCache.removeCalled = false

        let secondPayload = cardPropositions.compactMap { $0.asDictionary() }
        let secondRequestId = "TESTING_ID_2"

        messaging.setRequestedSurfacesforEventId(secondRequestId, expectedSurfaces: [iamSurface, cardSurface])

        let decisionsEvent2 = Event(name: "decisions",
                                    type: EventType.edge,
                                    source: MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS,
                                    data: [
                                        MessagingConstants.Event.Data.Key.Personalization.PAYLOAD: secondPayload,
                                        MessagingConstants.Event.Data.Key.REQUEST_EVENT_ID: secondRequestId
                                    ])
        mockRuntime.simulateComingEvents(decisionsEvent2)

        let processEvent2 = Event(name: "process complete",
                                  type: EventType.messaging,
                                  source: EventSource.contentComplete,
                                  data: [MessagingConstants.Event.Data.Key.ENDING_EVENT_ID: secondRequestId])
        messaging.handleProcessCompletedEvent(processEvent2)

        let secondEngineRules = mockLaunchRulesEngine.paramReplaceRulesRules ?? []
        let secondCardEngineRules = mockContentCardLaunchRulesEngine.paramReplaceRulesRules ?? []

        XCTAssertEqual(12, secondEngineRules.count, "Second replaceRules should load only 12 event-history rules (no IAM)")
        XCTAssertEqual(4, secondCardEngineRules.count, "Second content-card rules engine call should still load 4 rules")

        // Validate no IAM rules in second engine rules
        let secondIamRules = secondEngineRules.filter { rule in
            rule.consequences.contains { consequence in
                let ruleType = consequence.details[MessagingTestConstants.EventDataKeys.RulesEngine.MESSAGE_CONSEQUENCE_DETAIL_KEY_SCHEMA] as? String
                return ruleType == SchemaType.inapp.toString()
            }
        }
        XCTAssertEqual(0, secondIamRules.count, "Second response should not contain any IAM rules")

        // Cache behavior: set should NOT be called, but propositions file should be removed (removeCalled)
        XCTAssertFalse(mockCache.setCalled)
        XCTAssertTrue(mockCache.removeCalled, "Cache file should be deleted when no IAM propositions remain")

        // No proposition-received event dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func test_handleProcessCompletedEvent_SomeContentCardPropositionsNotReturnedInSubsequentResponse() {
        let cardSurface1 = Surface(uri: "mobileapp://apifeed1")
        let cardSurface2 = Surface(uri: "mobileapp://apifeed2")
        let cardSurface3 = Surface(uri: "mobileapp://apifeed3")

        // ---------- First response (IAM + 3 card surfaces) ----------
        let iamPropositions = (0..<3).map { makeInAppProposition(index: $0) }

        let card1 = makeCardProposition(surface: cardSurface1, index: 0)
        let card2 = makeCardProposition(surface: cardSurface2, index: 1)
        let card3 = makeCardProposition(surface: cardSurface3, index: 2)

        let firstPayload = (iamPropositions + [card1, card2, card3]).compactMap { $0.asDictionary() }
        let firstRequestId = "TESTING_ID_1"

        messaging.setRequestedSurfacesforEventId(firstRequestId, expectedSurfaces: [iamSurface, cardSurface1, cardSurface2, cardSurface3])

        let decisionsEvent1 = Event(name: "decisions",
                                    type: EventType.edge,
                                    source: MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS,
                                    data: [
                                        MessagingConstants.Event.Data.Key.Personalization.PAYLOAD: firstPayload,
                                        MessagingConstants.Event.Data.Key.REQUEST_EVENT_ID: firstRequestId
                                    ])
        mockRuntime.simulateComingEvents(decisionsEvent1)

        let processEvent1 = Event(name: "process complete",
                                  type: EventType.messaging,
                                  source: EventSource.contentComplete,
                                  data: [MessagingConstants.Event.Data.Key.ENDING_EVENT_ID: firstRequestId])
        messaging.handleProcessCompletedEvent(processEvent1)

        let firstEngineRules = mockLaunchRulesEngine.paramReplaceRulesRules ?? []
        let firstCardRules = mockContentCardLaunchRulesEngine.paramReplaceRulesRules ?? []
        XCTAssertEqual(12, firstEngineRules.count) // 3 IAM + 9 event-history
        XCTAssertEqual(3, firstCardRules.count)

        // ---------- Second response (IAM + ONLY cardSurface1) ----------
        mockLaunchRulesEngine.replaceRulesCalled = false
        mockContentCardLaunchRulesEngine.replaceRulesCalled = false

        let secondPayload = (iamPropositions + [card1]).compactMap { $0.asDictionary() }
        let secondRequestId = "TESTING_ID_2"

        messaging.setRequestedSurfacesforEventId(secondRequestId, expectedSurfaces: [iamSurface, cardSurface1, cardSurface2, cardSurface3])

        let decisionsEvent2 = Event(name: "decisions",
                                    type: EventType.edge,
                                    source: MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS,
                                    data: [
                                        MessagingConstants.Event.Data.Key.Personalization.PAYLOAD: secondPayload,
                                        MessagingConstants.Event.Data.Key.REQUEST_EVENT_ID: secondRequestId
                                    ])
        mockRuntime.simulateComingEvents(decisionsEvent2)

        let processEvent2 = Event(name: "process complete",
                                  type: EventType.messaging,
                                  source: EventSource.contentComplete,
                                  data: [MessagingConstants.Event.Data.Key.ENDING_EVENT_ID: secondRequestId])
        messaging.handleProcessCompletedEvent(processEvent2)

        let secondEngineRules = mockLaunchRulesEngine.paramReplaceRulesRules ?? []
        let secondCardRules = mockContentCardLaunchRulesEngine.paramReplaceRulesRules ?? []

        // 3 IAM + 3 event-history for card1
        XCTAssertEqual(6, secondEngineRules.count)
        XCTAssertEqual(1, secondCardRules.count)

        // Validate event-history rules count is 3 in second engine rules
        let eventHistoryRules = secondEngineRules.filter { rule in
            rule.consequences.contains { consequence in
                let schema = consequence.details[MessagingTestConstants.EventDataKeys.RulesEngine.MESSAGE_CONSEQUENCE_DETAIL_KEY_SCHEMA] as? String
                return schema == SchemaType.eventHistoryOperation.toString()
            }
        }
        XCTAssertEqual(3, eventHistoryRules.count)

        // No proposition notification dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func test_handleProcessCompletedEvent_SeparateIAMAndContentCardRequests() {
        let contentCardSurface = Surface(uri: "mobileapp://apifeed")

        // ---------- First request: IAM only ----------
        let iamProps = (0..<3).map { makeInAppProposition(index: $0) }
        let iamPayload = iamProps.compactMap { $0.asDictionary() }
        let iamRequestId = "TESTING_ID_IAM"

        messaging.setRequestedSurfacesforEventId(iamRequestId, expectedSurfaces: [iamSurface])

        let decisionsIAM = Event(name: "decisions",
                                 type: EventType.edge,
                                 source: MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS,
                                 data: [
                                     MessagingConstants.Event.Data.Key.Personalization.PAYLOAD: iamPayload,
                                     MessagingConstants.Event.Data.Key.REQUEST_EVENT_ID: iamRequestId
                                 ])
        mockRuntime.simulateComingEvents(decisionsIAM)

        let processIAM = Event(name: "process complete",
                               type: EventType.messaging,
                               source: EventSource.contentComplete,
                               data: [MessagingConstants.Event.Data.Key.ENDING_EVENT_ID: iamRequestId])
        messaging.handleProcessCompletedEvent(processIAM)

        // Capture first engine rules & reset mocks for next request
        let firstEngineRules = mockLaunchRulesEngine.paramReplaceRulesRules ?? []
        XCTAssertEqual(3, firstEngineRules.count, "First call should load 3 IAM rules")
        mockLaunchRulesEngine.replaceRulesCalled = false
        mockContentCardLaunchRulesEngine.replaceRulesCalled = false

        // ---------- Second request: content cards only ----------
        let cardProps = (0..<4).map { makeCardProposition(surface: contentCardSurface, index: $0) }
        let cardPayload = cardProps.compactMap { $0.asDictionary() }
        let cardRequestId = "TESTING_ID_CONTENT_CARD"

        messaging.setRequestedSurfacesforEventId(cardRequestId, expectedSurfaces: [contentCardSurface])

        let decisionsCard = Event(name: "decisions",
                                  type: EventType.edge,
                                  source: MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS,
                                  data: [
                                      MessagingConstants.Event.Data.Key.Personalization.PAYLOAD: cardPayload,
                                      MessagingConstants.Event.Data.Key.REQUEST_EVENT_ID: cardRequestId
                                  ])
        mockRuntime.simulateComingEvents(decisionsCard)

        let processCard = Event(name: "process complete", type: EventType.messaging, source: EventSource.contentComplete, data: [MessagingConstants.Event.Data.Key.ENDING_EVENT_ID: cardRequestId])
        messaging.handleProcessCompletedEvent(processCard)

        // Validate second engine rules
        let secondEngineRules = mockLaunchRulesEngine.paramReplaceRulesRules ?? []
        XCTAssertEqual(15, secondEngineRules.count, "Second call should load 3 IAM + 12 event-history rules")

        // Split them
        let inAppRules = secondEngineRules.filter { $0.consequences.contains { ($0.details[MessagingTestConstants.EventDataKeys.RulesEngine.MESSAGE_CONSEQUENCE_DETAIL_KEY_SCHEMA] as? String) == SchemaType.inapp.toString() } }
        let eventHistoryRules = secondEngineRules.filter { $0.consequences.contains { ($0.details[MessagingTestConstants.EventDataKeys.RulesEngine.MESSAGE_CONSEQUENCE_DETAIL_KEY_SCHEMA] as? String) == SchemaType.eventHistoryOperation.toString() } }
        XCTAssertEqual(3, inAppRules.count)
        XCTAssertEqual(12, eventHistoryRules.count)

        // Card rules engine should have been called once (only second response)
        XCTAssertTrue(mockContentCardLaunchRulesEngine.replaceRulesCalled)
        let cardRules = mockContentCardLaunchRulesEngine.paramReplaceRulesRules ?? []
        XCTAssertEqual(4, cardRules.count)

        // No proposition notification dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func test_handleProcessCompletedEvent_CodeBasedPropositions() {
        // Surface for code-based HTML experience
        let codeBasedSurface = Surface(uri: "mobileapp://com.steveb.iamStagingTester/cbeoffers3")
        let codeBasedPropositionDict = JSONFileLoader.getRulesJsonFromFile("codeBasedPropositionHtml")

        let payload = [codeBasedPropositionDict]

        let requestId = "TESTING_ID"

        // Register expected surface
        messaging.setRequestedSurfacesforEventId(requestId, expectedSurfaces: [codeBasedSurface])

        // decisions event containing only code-based content
        let decisionsEvent = Event(name: "decisions",
                                   type: EventType.edge,
                                   source: MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS,
                                   data: [
                                       MessagingConstants.Event.Data.Key.Personalization.PAYLOAD: payload,
                                       MessagingConstants.Event.Data.Key.REQUEST_EVENT_ID: requestId
                                   ])
        mockRuntime.simulateComingEvents(decisionsEvent)

        // process-completed callback
        let processEvent = Event(name: "process complete",
                                 type: EventType.messaging,
                                 source: EventSource.contentComplete,
                                 data: [MessagingConstants.Event.Data.Key.ENDING_EVENT_ID: requestId])
        messaging.handleProcessCompletedEvent(processEvent)

        XCTAssertFalse(mockLaunchRulesEngine.replaceRulesCalled, "In-app rules engine should NOT be invoked for code-based propositions")
        XCTAssertFalse(mockContentCardLaunchRulesEngine.replaceRulesCalled, "Content-card rules engine should NOT be invoked for code-based propositions")

        // One notification event should be dispatched containing the propositions
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents.first!
        XCTAssertEqual(MessagingConstants.Event.Name.MESSAGE_PROPOSITIONS_NOTIFICATION, dispatchedEvent.name)
        XCTAssertEqual(EventType.messaging, dispatchedEvent.type)
        XCTAssertEqual(EventSource.notification, dispatchedEvent.source)

        if let dispatchedPayload = dispatchedEvent.data?[MessagingConstants.Event.Data.Key.PROPOSITIONS] as? [[String: Any]] {
            XCTAssertEqual(1, dispatchedPayload.count)
            // Loose equality: check the id field matches expected, indicating same proposition
            if let expectedId = codeBasedPropositionDict["id"] as? String,
               let actualId = dispatchedPayload.first?["id"] as? String {
                XCTAssertEqual(expectedId, actualId)
            }
        } else {
            XCTFail("Notification event missing propositions array")
        }
    }

    func test_handleProcessCompletedEvent_EmptyPayload() {
        // Empty payload array
        let emptyPayload: [[String: Any]] = []
        let requestId = "TESTING_ID"

        // Register at least one surface so handler accepts the event
        messaging.setRequestedSurfacesforEventId(requestId, expectedSurfaces: [iamSurface])

        // decisions event with empty payload
        let decisionsEvent = Event(name: "decisions",
                                   type: EventType.edge,
                                   source: MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS,
                                   data: [
                                       MessagingConstants.Event.Data.Key.Personalization.PAYLOAD: emptyPayload,
                                       MessagingConstants.Event.Data.Key.REQUEST_EVENT_ID: requestId
                                   ])
        mockRuntime.simulateComingEvents(decisionsEvent)

        // process-completed event
        let processEvent = Event(name: "process complete",
                                 type: EventType.messaging,
                                 source: EventSource.contentComplete,
                                 data: [MessagingConstants.Event.Data.Key.ENDING_EVENT_ID: requestId])
        messaging.handleProcessCompletedEvent(processEvent)

        // Validate: no rules engines invoked, no notification dispatched
        XCTAssertFalse(mockLaunchRulesEngine.replaceRulesCalled)
        XCTAssertFalse(mockContentCardLaunchRulesEngine.replaceRulesCalled)
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func test_handleProcessCompletedEvent_ProcessCompletedEventMissingRequestId() {
        // Build a process-completed event whose data is missing ENDING_EVENT_ID
        let badProcessEvent = Event(name: "process complete",
                                    type: EventType.messaging,
                                    source: EventSource.contentComplete,
                                    data: [:])

        messaging.handleProcessCompletedEvent(badProcessEvent)

        // Verify no interactions with rules engines or event dispatches
        XCTAssertFalse(mockLaunchRulesEngine.replaceRulesCalled)
        XCTAssertFalse(mockContentCardLaunchRulesEngine.replaceRulesCalled)
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func test_handleProcessCompletedEvent_NoValidRulesInPayload() {
        // Build invalid IAM proposition (missing "rules" key)
        var invalidIamRules = JSONFileLoader.getRulesJsonFromFile("inappPropositionV2Content")
        invalidIamRules.removeValue(forKey: "rules")
        let invalidIamItem = PropositionItem(itemId: "invalid_iam", schema: .ruleset, itemData: invalidIamRules)
        let invalidIamProp = Proposition(uniqueId: "invalidIAM", scope: iamSurface.uri, scopeDetails: ["decisionProvider": "AJO"], items: [invalidIamItem])

        // Build invalid card proposition (missing rules)
        var invalidCardRules = JSONFileLoader.getRulesJsonFromFile("contentCardPropositionContent")
        invalidCardRules.removeValue(forKey: "rules")
        let invalidCardItem = PropositionItem(itemId: "invalid_card", schema: .ruleset, itemData: invalidCardRules)
        let invalidCardProp = Proposition(uniqueId: "invalidCard", scope: cardSurface.uri, scopeDetails: ["decisionProvider": "AJO"], items: [invalidCardItem])

        let payload = [invalidIamProp, invalidCardProp].compactMap { $0.asDictionary() }
        let requestId = "TESTING_ID"

        messaging.setRequestedSurfacesforEventId(requestId, expectedSurfaces: [iamSurface, cardSurface])

        let decisionsEvent = Event(name: "decisions",
                                   type: EventType.edge,
                                   source: MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS,
                                   data: [
                                       MessagingConstants.Event.Data.Key.Personalization.PAYLOAD: payload,
                                       MessagingConstants.Event.Data.Key.REQUEST_EVENT_ID: requestId
                                   ])
        mockRuntime.simulateComingEvents(decisionsEvent)

        let processEvent = Event(name: "process complete",
                                 type: EventType.messaging,
                                 source: EventSource.contentComplete,
                                 data: [MessagingConstants.Event.Data.Key.ENDING_EVENT_ID: requestId])
        messaging.handleProcessCompletedEvent(processEvent)

        // Validate: rules engines not invoked, no notification dispatched
        XCTAssertFalse(mockLaunchRulesEngine.replaceRulesCalled)
        XCTAssertFalse(mockContentCardLaunchRulesEngine.replaceRulesCalled)
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    // MARK: - Private helpers
    /// Verifies that the supplied in-app rules are ordered by highest priority (ascending two-digit id suffix).
    /// The last two characters of each first consequence id are expected to be "00", "01", … in the same
    /// order as the array provided. Fails the test if any rule is out of order or missing an id.
    /// - Parameter inAppRules: The list of `LaunchRule`s to validate.
    private func verifyInAppRulesOrdering(_ inAppRules: [LaunchRule]) {
        for (index, rule) in inAppRules.enumerated() {
            guard let consequenceId = rule.consequences.first?.id else {
                XCTFail("Rule at index \(index) has no consequence id – cannot verify ordering.")
                return
            }
            let actualSuffix = String(consequenceId.suffix(2))
            let expectedSuffix = String(format: "%02d", index)
            XCTAssertEqual(expectedSuffix, actualSuffix, "In-app rule at index \(index) expected id suffix \(expectedSuffix) but found \(actualSuffix)")
        }
    }

    /// Mutates the supplied rules JSON so the first consequence id ends with a two-digit
    /// suffix derived from `index` (that is, 00-99). This is used to set the priority normally
    /// set by the server.
    /// - Parameters:
    ///   - rulesJson: The original rules JSON dictionary.
    ///   - index: The index whose value will be substituted into the id suffix.
    /// - Returns: A new dictionary with the modified consequence id.
    private func setRulesJsonConsequenceIdPriority(_ rulesJson: [String: Any], index: Int) -> [String: Any] {
        var result = rulesJson
        if var rules = result["rules"] as? [[String: Any]],
           var firstRule = rules.first,
           var consequences = firstRule["consequences"] as? [[String: Any]],
           var firstConsequence = consequences.first,
           var idString = firstConsequence["id"] as? String {
            let suffix = String(format: "%02d", index)
            idString = String(idString.dropLast(2)) + suffix
            firstConsequence["id"] = idString
            consequences[0] = firstConsequence
            firstRule["consequences"] = consequences
            rules[0] = firstRule
            result["rules"] = rules
        }
        return result
    }

    /// Builds a single in-app proposition (based on `inappPropositionV2Content.json`) whose item id is unique.
    private func makeInAppProposition(index: Int) -> Proposition {
        let rulesJson = setRulesJsonConsequenceIdPriority(
            JSONFileLoader.getRulesJsonFromFile("inappPropositionV2Content"),
            index: index)
        let item = PropositionItem(itemId: "iam_\(index)", schema: .ruleset, itemData: rulesJson)
        return Proposition(uniqueId: "iamProp_\(index)",
                           scope: iamSurface.uri,
                           scopeDetails: [
                               "decisionProvider": "AJO",
                               "activity": [MessagingConstants.Event.Data.Key.Personalization.RANK: index]
                           ],
                           items: [item])
    }

    /// Builds a single content card proposition (based on `contentCardPropositionContent.json`) for the given surface.
    private func makeCardProposition(surface: Surface, index: Int) -> Proposition {
        let rulesJson = setRulesJsonConsequenceIdPriority(
            JSONFileLoader.getRulesJsonFromFile("contentCardPropositionContent"),
            index: index)
        let item = PropositionItem(itemId: "card_\(index)", schema: .ruleset, itemData: rulesJson)
        return Proposition(uniqueId: "cardProp_\(index)",
                           scope: surface.uri,
                           scopeDetails: [
                               "decisionProvider": "AJO",
                               "activity": [MessagingConstants.Event.Data.Key.Personalization.RANK: index]
                           ],
                           items: [item])
    }
}
