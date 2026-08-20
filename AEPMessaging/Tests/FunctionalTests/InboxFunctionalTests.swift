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
import AEPTestUtils
@testable import AEPCore
@testable import AEPMessaging

class InboxFunctionalTests: XCTestCase {
    var messaging: Messaging!
    var mockRuntime: TestableExtensionRuntime!

    private let iamSurface = Surface(uri: "mobileapp://inapp")
    private let inboxSurface = Surface(uri: "mobileapp://test.app/inbox")
    private let cardSurface = Surface(uri: "mobileapp://apifeed")

    override func setUp() {
        super.setUp()
        mockRuntime = TestableExtensionRuntime()
        messaging = Messaging(runtime: mockRuntime)
        messaging.onRegistered()
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
    }

    override func tearDown() {
        messaging = nil
        mockRuntime = nil
        super.tearDown()
    }

    // MARK: - Full Edge personalization flow for inbox

    func testInboxPropositionStoredAfterEdgeResponse() {
        // Simulate a full Edge personalization response containing an inbox proposition
        let inboxProposition = makeInboxProposition(surface: inboxSurface, index: 0)
        let payloadDicts = [inboxProposition].compactMap { $0.asDictionary() }
        let requestId = "INBOX_REQUEST_1"

        messaging.setRequestedSurfacesforEventId(requestId, expectedSurfaces: [inboxSurface])

        let decisionsEvent = makeDecisionsEvent(payload: payloadDicts, requestId: requestId)
        mockRuntime.simulateComingEvents(decisionsEvent)
        messaging.handleProcessCompletedEvent(makeProcessCompleteEvent(requestId: requestId))
        Thread.sleep(forTimeInterval: 0.1)

        XCTAssertEqual(1, messaging.inboxPropositionsBySurface.count)
        XCTAssertEqual(1, messaging.inboxPropositionsBySurface[inboxSurface]?.count)
        XCTAssertEqual("inboxProp_0", messaging.inboxPropositionsBySurface[inboxSurface]?.first?.uniqueId)
    }

    func testInboxPropositionsStoredWithCorrectSurfaceKey() {
        let inboxProposition = makeInboxProposition(surface: inboxSurface, index: 0)
        let requestId = "INBOX_REQUEST_KEY"

        messaging.setRequestedSurfacesforEventId(requestId, expectedSurfaces: [inboxSurface])
        mockRuntime.simulateComingEvents(makeDecisionsEvent(payload: [inboxProposition].compactMap { $0.asDictionary() }, requestId: requestId))
        messaging.handleProcessCompletedEvent(makeProcessCompleteEvent(requestId: requestId))
        Thread.sleep(forTimeInterval: 0.1)

        XCTAssertNotNil(messaging.inboxPropositionsBySurface[inboxSurface],
                        "Inbox propositions should be keyed by their surface")
        XCTAssertNil(messaging.inboxPropositionsBySurface[cardSurface],
                     "Unrelated surface should have no inbox propositions")
    }

    func testMultipleInboxPropositionsForSameSurface() {
        // Two inbox propositions targeting the same surface should both be stored
        let inbox0 = makeInboxProposition(surface: inboxSurface, index: 0)
        let inbox1 = makeInboxProposition(surface: inboxSurface, index: 1)
        let payloadDicts = [inbox0, inbox1].compactMap { $0.asDictionary() }
        let requestId = "INBOX_MULTI"

        messaging.setRequestedSurfacesforEventId(requestId, expectedSurfaces: [inboxSurface])
        mockRuntime.simulateComingEvents(makeDecisionsEvent(payload: payloadDicts, requestId: requestId))
        messaging.handleProcessCompletedEvent(makeProcessCompleteEvent(requestId: requestId))
        Thread.sleep(forTimeInterval: 0.1)

        XCTAssertEqual(2, messaging.inboxPropositionsBySurface[inboxSurface]?.count,
                       "Both inbox propositions should be stored for the same surface")
    }

    func testInboxPropositionsForDifferentSurfaces() {
        let anotherInboxSurface = Surface(uri: "mobileapp://test.app/inbox2")
        let inbox0 = makeInboxProposition(surface: inboxSurface, index: 0)
        let inbox1 = makeInboxProposition(surface: anotherInboxSurface, index: 1)
        let payloadDicts = [inbox0, inbox1].compactMap { $0.asDictionary() }
        let requestId = "INBOX_TWO_SURFACES"

        messaging.setRequestedSurfacesforEventId(requestId, expectedSurfaces: [inboxSurface, anotherInboxSurface])
        mockRuntime.simulateComingEvents(makeDecisionsEvent(payload: payloadDicts, requestId: requestId))
        messaging.handleProcessCompletedEvent(makeProcessCompleteEvent(requestId: requestId))
        Thread.sleep(forTimeInterval: 0.1)

        XCTAssertEqual(2, messaging.inboxPropositionsBySurface.count,
                       "Each inbox surface should be stored separately")
        XCTAssertNotNil(messaging.inboxPropositionsBySurface[inboxSurface])
        XCTAssertNotNil(messaging.inboxPropositionsBySurface[anotherInboxSurface])
    }

    func testInboxPropositionsRemovedWhenSurfaceAbsentFromSubsequentResponse() {
        // First response: populate inbox for inboxSurface
        let firstRequestId = "INBOX_FIRST"
        messaging.setRequestedSurfacesforEventId(firstRequestId, expectedSurfaces: [inboxSurface])
        mockRuntime.simulateComingEvents(makeDecisionsEvent(
            payload: [makeInboxProposition(surface: inboxSurface, index: 0)].compactMap { $0.asDictionary() },
            requestId: firstRequestId))
        messaging.handleProcessCompletedEvent(makeProcessCompleteEvent(requestId: firstRequestId))
        Thread.sleep(forTimeInterval: 0.1)

        XCTAssertEqual(1, messaging.inboxPropositionsBySurface.count, "Inbox should be populated after first response")

        // Second response: same surface registered but no inbox in payload
        let secondRequestId = "INBOX_SECOND"
        messaging.setRequestedSurfacesforEventId(secondRequestId, expectedSurfaces: [inboxSurface])
        mockRuntime.simulateComingEvents(makeDecisionsEvent(payload: [], requestId: secondRequestId))
        messaging.handleProcessCompletedEvent(makeProcessCompleteEvent(requestId: secondRequestId))
        Thread.sleep(forTimeInterval: 0.1)

        XCTAssertNil(messaging.inboxPropositionsBySurface[inboxSurface],
                     "Inbox propositions for the surface should be cleared when absent from the response")
    }

    func testInboxNotStoredWhenRequestIdIsUnregistered() {
        // No call to setRequestedSurfacesforEventId — decisions event should be ignored
        let inboxProposition = makeInboxProposition(surface: inboxSurface, index: 0)
        let payloadDicts = [inboxProposition].compactMap { $0.asDictionary() }

        mockRuntime.simulateComingEvents(makeDecisionsEvent(payload: payloadDicts, requestId: "UNREGISTERED_ID"))
        messaging.handleProcessCompletedEvent(makeProcessCompleteEvent(requestId: "UNREGISTERED_ID"))
        Thread.sleep(forTimeInterval: 0.1)

        XCTAssertTrue(messaging.inboxPropositionsBySurface.isEmpty,
                      "Inbox propositions from an unregistered request should be ignored")
    }

    // MARK: - Mixed storage: inbox + content cards for the same surface

    func testInboxPropositionStoredSeparatelyFromContentCardForSameSurface() {
        // One inbox proposition + one content card ruleset proposition for the same surface URI.
        // Inbox should land in inboxPropositionsBySurface; the content card goes through the
        // rules engine and never touches inboxPropositionsBySurface.
        let inboxProposition = makeInboxProposition(surface: inboxSurface, index: 0)
        let cardProposition = makeRulesetProposition(surface: inboxSurface, index: 0)
        let payloadDicts = [inboxProposition, cardProposition].compactMap { $0.asDictionary() }
        let requestId = "MIXED_SAME_SURFACE"

        messaging.setRequestedSurfacesforEventId(requestId, expectedSurfaces: [inboxSurface])
        mockRuntime.simulateComingEvents(makeDecisionsEvent(payload: payloadDicts, requestId: requestId))
        messaging.handleProcessCompletedEvent(makeProcessCompleteEvent(requestId: requestId))
        Thread.sleep(forTimeInterval: 0.1)

        // Inbox is correctly isolated in its own store
        XCTAssertEqual(1, messaging.inboxPropositionsBySurface[inboxSurface]?.count,
                       "Inbox store should contain exactly one proposition for the surface")
        XCTAssertEqual("inboxProp_0", messaging.inboxPropositionsBySurface[inboxSurface]?.first?.uniqueId)
    }

    func testInboxPropositionNotStoredInMemoryPropositions() {
        // Inbox propositions must NOT appear in inMemoryPropositions (the CBE/IAM cache).
        let inboxProposition = makeInboxProposition(surface: inboxSurface, index: 0)
        let requestId = "INBOX_NOT_IN_MEMORY"

        messaging.setRequestedSurfacesforEventId(requestId, expectedSurfaces: [inboxSurface])
        mockRuntime.simulateComingEvents(makeDecisionsEvent(payload: [inboxProposition].compactMap { $0.asDictionary() }, requestId: requestId))
        messaging.handleProcessCompletedEvent(makeProcessCompleteEvent(requestId: requestId))
        Thread.sleep(forTimeInterval: 0.1)

        XCTAssertTrue(messaging.inMemoryPropositions.isEmpty,
                      "Inbox propositions should not appear in the CBE/IAM in-memory cache")
    }

    func testMultipleContentCardsDoNotAffectInboxCount() {
        // Three content card ruleset propositions alongside one inbox proposition for the same surface.
        // The inbox store must have exactly one entry regardless of how many content cards arrive.
        let inboxProposition = makeInboxProposition(surface: inboxSurface, index: 0)
        let cardPropositions = (0..<3).map { makeRulesetProposition(surface: inboxSurface, index: $0) }
        let payloadDicts = ([inboxProposition] + cardPropositions).compactMap { $0.asDictionary() }
        let requestId = "MIXED_THREE_CARDS"

        messaging.setRequestedSurfacesforEventId(requestId, expectedSurfaces: [inboxSurface])
        mockRuntime.simulateComingEvents(makeDecisionsEvent(payload: payloadDicts, requestId: requestId))
        messaging.handleProcessCompletedEvent(makeProcessCompleteEvent(requestId: requestId))
        Thread.sleep(forTimeInterval: 0.1)

        XCTAssertEqual(1, messaging.inboxPropositionsBySurface[inboxSurface]?.count,
                       "Content card propositions must not inflate the inbox proposition count")
    }

    // MARK: - getPropositions public API

    func testGetPropositionsResponseIncludesInboxProposition() {
        // Pre-populate the inbox store directly, then verify the GET_PROPOSITIONS response
        // event contains that proposition.
        let inboxProposition = makeInboxProposition(surface: inboxSurface, index: 0)
        messaging.inboxPropositionsBySurface = [inboxSurface: [inboxProposition]]
        Thread.sleep(forTimeInterval: 0.1) // let the async write settle

        let getEvent = makeGetPropositionsEvent(surfaces: [inboxSurface])
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME,
                                        data: (["messaging.eventDataset": "mockDataset"], .set))
        mockRuntime.simulateComingEvents(getEvent)
        Thread.sleep(forTimeInterval: 0.2) // let eventsQueue process

        let responseEvent = mockRuntime.dispatchedEvents.first {
            $0.type == EventType.messaging && $0.source == EventSource.responseContent
        }
        XCTAssertNotNil(responseEvent, "A propositions response event should be dispatched")
        XCTAssertEqual(1, responseEvent?.propositions?.count)
        XCTAssertEqual("inboxProp_0", responseEvent?.propositions?.first?.uniqueId)
    }

    func testGetPropositionsResponseEmptyWhenNoInboxStored() {
        // Nothing stored → GET_PROPOSITIONS should return an empty propositions list
        // (not nil — retrieveMessages dispatches a response even when the merge is empty).
        let getEvent = makeGetPropositionsEvent(surfaces: [inboxSurface])
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME,
                                        data: (["messaging.eventDataset": "mockDataset"], .set))
        mockRuntime.simulateComingEvents(getEvent)
        Thread.sleep(forTimeInterval: 0.2)

        let responseEvent = mockRuntime.dispatchedEvents.first {
            $0.type == EventType.messaging && $0.source == EventSource.responseContent
        }
        XCTAssertNotNil(responseEvent, "A response event should still be dispatched even when empty")
        let propositions = responseEvent?.propositions
        XCTAssertTrue(propositions == nil || propositions!.isEmpty,
                      "Response should contain no propositions when inbox store is empty")
    }

    func testGetPropositionsReturnsInboxAndContentCardTogether() {
        // Pre-populate both the inbox store and the qualified content card store for the same surface.
        // retrieveMessages merges both containers, so the response should contain propositions from each.
        let inboxProposition = makeInboxProposition(surface: inboxSurface, index: 0)
        messaging.inboxPropositionsBySurface = [inboxSurface: [inboxProposition]]

        let cardItem = PropositionItem(itemId: "card_0", schema: .contentCard, itemData: [:])
        let cardProposition = Proposition(uniqueId: "cardProp_0",
                                          scope: inboxSurface.uri,
                                          scopeDetails: ["decisionProvider": "AJO"],
                                          items: [cardItem])
        messaging.qualifiedContentCardsBySurface = [inboxSurface: [cardProposition]]
        // Mark the surface as network-refreshed this session so the qualified card is served.
        // With `messaging.contentCardOfflineAvailable` at its default (false), retrieveMessages only
        // returns content cards for surfaces present in `networkRefreshedSurfaces`; a card placed
        // directly into `qualifiedContentCardsBySurface` represents a live network-qualified card.
        messaging.setNetworkRefreshedSurfaces([inboxSurface])
        Thread.sleep(forTimeInterval: 0.1)

        let getEvent = makeGetPropositionsEvent(surfaces: [inboxSurface])
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME,
                                        data: (["messaging.eventDataset": "mockDataset"], .set))
        mockRuntime.simulateComingEvents(getEvent)
        Thread.sleep(forTimeInterval: 0.2)

        let responseEvent = mockRuntime.dispatchedEvents.first {
            $0.type == EventType.messaging && $0.source == EventSource.responseContent
        }
        XCTAssertNotNil(responseEvent)
        let uniqueIds = responseEvent?.propositions?.map { $0.uniqueId } ?? []
        XCTAssertTrue(uniqueIds.contains("inboxProp_0"), "Response must include the inbox proposition")
        XCTAssertTrue(uniqueIds.contains("cardProp_0"), "Response must include the qualified content card")
        XCTAssertEqual(2, uniqueIds.count)
    }

    // MARK: - getPropositions surface-independence from in-flight updates

    func testGetPropositions_differentSurfaceServedWhileUpdateInProgress() {
        // An update propositions request for `cardSurface` is in flight (blocking the events queue).
        // A get propositions request for a DIFFERENT surface (`inboxSurface`) must be served
        // immediately from cache, independent of the unrelated in-flight update.
        let inboxProposition = makeInboxProposition(surface: inboxSurface, index: 0)
        messaging.inboxPropositionsBySurface = [inboxSurface: [inboxProposition]]

        // Simulate an in-flight update for cardSurface (adds a blocking edge event to the queue).
        let updateEdgeEvent = makeUpdateEdgeEvent()
        messaging.callBeginRequestFor(updateEdgeEvent, with: [cardSurface])
        Thread.sleep(forTimeInterval: 0.1)

        let getEvent = makeGetPropositionsEvent(surfaces: [inboxSurface])
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME,
                                        data: (["messaging.eventDataset": "mockDataset"], .set))
        mockRuntime.simulateComingEvents(getEvent)
        Thread.sleep(forTimeInterval: 0.2)

        let responseEvent = mockRuntime.dispatchedEvents.first {
            $0.type == EventType.messaging && $0.source == EventSource.responseContent
        }
        XCTAssertNotNil(responseEvent, "Get for a different surface should be served while an unrelated update is in flight")
        XCTAssertEqual(1, responseEvent?.propositions?.count)
        XCTAssertEqual("inboxProp_0", responseEvent?.propositions?.first?.uniqueId)
    }

    func testGetPropositions_sameSurfaceQueuedUntilUpdateCompletes() {
        // An update propositions request for `inboxSurface` is in flight (blocking the events queue).
        // A get propositions request for the SAME surface must be queued and NOT served until the
        // in-flight update completes.
        let updateEdgeEvent = makeUpdateEdgeEvent()
        let requestId = updateEdgeEvent.id.uuidString
        messaging.callBeginRequestFor(updateEdgeEvent, with: [inboxSurface])
        Thread.sleep(forTimeInterval: 0.1)

        let getEvent = makeGetPropositionsEvent(surfaces: [inboxSurface])
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME,
                                        data: (["messaging.eventDataset": "mockDataset"], .set))
        mockRuntime.simulateComingEvents(getEvent)
        Thread.sleep(forTimeInterval: 0.2)

        // The get must be blocked behind the in-flight update for the same surface.
        var responseEvent = mockRuntime.dispatchedEvents.first {
            $0.type == EventType.messaging && $0.source == EventSource.responseContent
        }
        XCTAssertNil(responseEvent, "Get for the same surface must be queued while an update for that surface is in flight")

        // The in-flight update streams in a proposition for the surface, then completes.
        let inboxProposition = makeInboxProposition(surface: inboxSurface, index: 0)
        mockRuntime.simulateComingEvents(makeDecisionsEvent(payload: [inboxProposition].compactMap { $0.asDictionary() }, requestId: requestId))
        messaging.handleProcessCompletedEvent(makeProcessCompleteEvent(requestId: requestId))
        Thread.sleep(forTimeInterval: 0.2)

        // With the update complete, the queued get should now be processed and return the surface's content.
        responseEvent = mockRuntime.dispatchedEvents.first {
            $0.type == EventType.messaging && $0.source == EventSource.responseContent
        }
        XCTAssertNotNil(responseEvent, "Queued get should be served after the in-flight update completes")
        XCTAssertEqual(1, responseEvent?.propositions?.count)
        XCTAssertEqual("inboxProp_0", responseEvent?.propositions?.first?.uniqueId)
    }

    func testGetPropositions_contentCardSurfaceNotBlockedByColdBootInAppFetch() {
        // At cold boot / readyForEvent the SDK auto-fetches in-app messages for the BASE surface
        // (mobileapp://{bundleId}) via fetchPropositions(event) with no surfaces. A getPropositions
        // for a content-card sub-surface (mobileapp://{bundleId}/path) must NOT be blocked by that
        // in-flight base-surface fetch, since the URIs differ and matching is exact.
        let baseSurface = Surface(uri: "mobileapp://test.app")
        let cardSubSurface = Surface(uri: "mobileapp://test.app/homepage")

        // Seed a qualified, network-refreshed content card for the sub-surface.
        let cardItem = PropositionItem(itemId: "card_0", schema: .contentCard, itemData: [:])
        let cardProposition = Proposition(uniqueId: "cardProp_0",
                                          scope: cardSubSurface.uri,
                                          scopeDetails: ["decisionProvider": "AJO"],
                                          items: [cardItem])
        messaging.qualifiedContentCardsBySurface = [cardSubSurface: [cardProposition]]
        messaging.setNetworkRefreshedSurfaces([cardSubSurface])

        // Simulate the cold-boot in-app fetch in flight for the BASE surface.
        let inAppFetchEvent = makeUpdateEdgeEvent()
        messaging.callBeginRequestFor(inAppFetchEvent, with: [baseSurface])
        Thread.sleep(forTimeInterval: 0.1)

        let getEvent = makeGetPropositionsEvent(surfaces: [cardSubSurface])
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME,
                                        data: (["messaging.eventDataset": "mockDataset"], .set))
        mockRuntime.simulateComingEvents(getEvent)
        Thread.sleep(forTimeInterval: 0.2)

        let responseEvent = mockRuntime.dispatchedEvents.first {
            $0.type == EventType.messaging && $0.source == EventSource.responseContent
        }
        XCTAssertNotNil(responseEvent, "Content-card get must be served while the base-surface in-app fetch is in flight")
        XCTAssertEqual(1, responseEvent?.propositions?.count)
        XCTAssertEqual("cardProp_0", responseEvent?.propositions?.first?.uniqueId)
    }

    // MARK: - Private helpers

    private func makeUpdateEdgeEvent() -> Event {
        Event(name: MessagingConstants.Event.Name.RETRIEVE_MESSAGE_DEFINITIONS,
              type: EventType.edge,
              source: EventSource.requestContent,
              data: [:])
    }

    private func makeInboxProposition(surface: Surface, index: Int) -> Proposition {
        let inboxContent: [String: Any] = [
            "content": [
                "heading": ["content": "Trending Now Container"],
                "layout": ["orientation": "horizontal"],
                "capacity": 10,
                "emptyStateSettings": ["message": ["content": "Check back soon!"]],
                "isUnreadEnabled": true
            ]
        ]
        let item = PropositionItem(itemId: "inbox_\(index)", schema: .inbox, itemData: inboxContent)
        return Proposition(uniqueId: "inboxProp_\(index)",
                           scope: surface.uri,
                           scopeDetails: ["decisionProvider": "AJO"],
                           items: [item])
    }

    private func makeRulesetProposition(surface: Surface, index: Int) -> Proposition {
        // Minimal ruleset payload — rules engine will skip it gracefully if it can't parse,
        // but the inbox path is unaffected since .ruleset is handled separately.
        let item = PropositionItem(itemId: "card_\(index)", schema: .ruleset, itemData: ["rules": []])
        return Proposition(uniqueId: "cardProp_\(index)",
                           scope: surface.uri,
                           scopeDetails: ["decisionProvider": "AJO"],
                           items: [item])
    }

    private func makeGetPropositionsEvent(surfaces: [Surface]) -> Event {
        Event(name: MessagingConstants.Event.Name.GET_PROPOSITIONS,
              type: EventType.messaging,
              source: EventSource.requestContent,
              data: [
                  MessagingConstants.Event.Data.Key.GET_PROPOSITIONS: true,
                  MessagingConstants.Event.Data.Key.SURFACES: surfaces.compactMap { $0.asDictionary() }
              ])
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

    private func makeProcessCompleteEvent(requestId: String) -> Event {
        Event(name: "process complete",
              type: EventType.messaging,
              source: EventSource.contentComplete,
              data: [MessagingConstants.Event.Data.Key.ENDING_EVENT_ID: requestId])
    }
}
