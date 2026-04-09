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

/// Integration-style tests for the content card cache path that runs after a personalization
/// response completes (`updateRulesEngines` → `removeOrReplaceContentCards`).
///
/// Android parity: `MessagingPublicAPITests` content-card cases that drive Edge + rules;
/// here we simulate the **authoritative refresh** slice using the DEBUG-only
/// `callUpdateRulesEngines(with:requestedSurfaces:)` hook (same code path as
/// `applyPropositionChangeFor` when the parsed response omits content-card rules for
/// requested surfaces — including when the `.contentCard` key is missing entirely.
/// Direct unit coverage uses the DEBUG-only `callRemoveOrReplaceContentCards` hook in `MessagingTests.swift`.
#if DEBUG
final class ContentCardCacheFunctionalTests: XCTestCase {
    var messaging: Messaging!
    var mockRuntime: TestableExtensionRuntime!

    private let surfaceA = Surface(uri: "mobileapp://com.adobe.messaging.functionaltests/feed/a")
    private let surfaceB = Surface(uri: "mobileapp://com.adobe.messaging.functionaltests/feed/b")
    private let surfaceC = Surface(uri: "mobileapp://com.adobe.messaging.functionaltests/feed/c")

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

    // MARK: - Authoritative refresh (empty content-card rules for request)

    func testQualifiedContentCardsEvictedForBothRequestedSurfaces_whenNoContentCardRulesReturned() {
        let propA = makeContentCardProposition(surface: surfaceA, uniqueId: "cardA")
        let propB = makeContentCardProposition(surface: surfaceB, uniqueId: "cardB")
        messaging.qualifiedContentCardsBySurface = [surfaceA: [propA], surfaceB: [propB]]
        Thread.sleep(forTimeInterval: 0.1)

        let emptyContentCardRules: [SchemaType: [Surface: [LaunchRule]]] = [.contentCard: [:]]
        messaging.callUpdateRulesEngines(with: emptyContentCardRules, requestedSurfaces: [surfaceA, surfaceB])
        Thread.sleep(forTimeInterval: 0.15)

        XCTAssertTrue(messaging.qualifiedContentCardsBySurface.isEmpty,
                      "Both requested surfaces should be evicted when the authoritative refresh qualifies no cards")
    }

    func testQualifiedContentCardsPreservedForUnrequestedSurface_whenOtherRequestedSurfacesCleared() {
        let propA = makeContentCardProposition(surface: surfaceA, uniqueId: "cardA")
        let propB = makeContentCardProposition(surface: surfaceB, uniqueId: "cardB")
        let propC = makeContentCardProposition(surface: surfaceC, uniqueId: "cardC")
        messaging.qualifiedContentCardsBySurface = [surfaceA: [propA], surfaceB: [propB], surfaceC: [propC]]
        Thread.sleep(forTimeInterval: 0.1)

        let emptyContentCardRules: [SchemaType: [Surface: [LaunchRule]]] = [.contentCard: [:]]
        messaging.callUpdateRulesEngines(with: emptyContentCardRules, requestedSurfaces: [surfaceA, surfaceB])
        Thread.sleep(forTimeInterval: 0.15)

        XCTAssertEqual(1, messaging.qualifiedContentCardsBySurface.count)
        XCTAssertNil(messaging.qualifiedContentCardsBySurface[surfaceA])
        XCTAssertNil(messaging.qualifiedContentCardsBySurface[surfaceB])
        XCTAssertNotNil(messaging.qualifiedContentCardsBySurface[surfaceC])
        XCTAssertEqual("cardC", messaging.qualifiedContentCardsBySurface[surfaceC]?.first?.uniqueId)
    }

    func testQualifiedContentCardsUnchanged_whenRequestedSurfacesEmpty() {
        let propA = makeContentCardProposition(surface: surfaceA, uniqueId: "cardA")
        messaging.qualifiedContentCardsBySurface = [surfaceA: [propA]]
        Thread.sleep(forTimeInterval: 0.1)

        let emptyContentCardRules: [SchemaType: [Surface: [LaunchRule]]] = [.contentCard: [:]]
        messaging.callUpdateRulesEngines(with: emptyContentCardRules, requestedSurfaces: [])
        Thread.sleep(forTimeInterval: 0.15)

        XCTAssertEqual(1, messaging.qualifiedContentCardsBySurface.count)
        XCTAssertEqual("cardA", messaging.qualifiedContentCardsBySurface[surfaceA]?.first?.uniqueId)
    }

    /// When the server omits the content-card schema entirely, `surfaceRulesBySchemaType[.contentCard]` is nil.
    /// Rules for requested surfaces are cleared in `processRulesForSchemaType`, but the qualified cache must
    /// still be refreshed (same outcome as an empty `.contentCard` map).
    func testQualifiedContentCardsEvicted_whenContentCardKeyAbsentFromResponse() {
        let propA = makeContentCardProposition(surface: surfaceA, uniqueId: "cardA")
        let propB = makeContentCardProposition(surface: surfaceB, uniqueId: "cardB")
        messaging.qualifiedContentCardsBySurface = [surfaceA: [propA], surfaceB: [propB]]
        Thread.sleep(forTimeInterval: 0.1)

        // No `.contentCard` entry — e.g. response only carries other schema types or an empty payload.
        let rulesWithNoContentCardKey: [SchemaType: [Surface: [LaunchRule]]] = [:]
        messaging.callUpdateRulesEngines(with: rulesWithNoContentCardKey, requestedSurfaces: [surfaceA, surfaceB])
        Thread.sleep(forTimeInterval: 0.15)

        XCTAssertTrue(messaging.qualifiedContentCardsBySurface.isEmpty,
                      "Stale qualified cards must be evicted when the response has no content-card key")
    }

    // MARK: - Helpers

    private func makeContentCardProposition(surface: Surface, uniqueId: String) -> Proposition {
        let item = PropositionItem(itemId: "\(uniqueId)_item", schema: .contentCard, itemData: [:])
        return Proposition(uniqueId: uniqueId,
                           scope: surface.uri,
                           scopeDetails: ["decisionProvider": "AJO"],
                           items: [item])
    }
}
#endif
