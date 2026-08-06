/*
 Copyright 2024 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Testing
import SwiftUI
@testable import AEPCore
@testable import AEPMessaging

@Suite("GetContentCardUI", .serialized)
class GetContentCardUITest : IntegrationTestBase {
    
    override init() {
        super.init()
    }
    
    @Test("when no cards available")
    func noCards() async throws {
        // setup
        setContentCardResponse(fromFile: "NoCard")
        
        // test and verify
        await #expect(throws: ContentCardUIError.dataUnavailable) {
            try await getContentCardUI(homeSurface)
        }
    }
        
    @Test("when multiple cards downloaded")
    func multipleCards() async throws {
        // setup
        setContentCardResponse(fromFile: "MultipleCards")
        
        // test
        let cards = try await getContentCardUI(homeSurface)
        
        // verify
        #expect(cards.count == 4)
    }
    
    @Test("for invalid surface")
    func invalidSurface() async throws {
        // setup
        setContentCardResponse(fromFile: "SmallImageCard")

        // test and verify
        await #expect(throws: ContentCardUIError.dataUnavailable) {
            try await getContentCardUI(invalidSurface)
        }
    }
}

/// Covers the app-boot hydration path: `hydrateAllPersistedContentCards()`, which is invoked once from
/// `readyForEvent` (after Configuration + Edge Identity are ready) mirroring the Edge/Edge Identity
/// `bootupIfReady` pattern. After a successful network update has persisted content cards to disk, a
/// fresh boot must repopulate the in-memory qualified-card cache FROM DISK — without any
/// `getContentCardsUI`/`getPropositionsForSurfaces` call — and tag those cards `.disk` so their display
/// analytics correctly report `servedFromPersistentCache`.
@Suite("BootHydratePersistedContentCards", .serialized)
class BootHydratePersistedContentCardsTest: IntegrationTestBase {

    override init() {
        super.init()
    }

    /// The live Messaging extension instance registered with the Event Hub.
    private var messagingExtension: Messaging? {
        EventHub.shared.getExtensionContainer(Messaging.self)?.exten as? Messaging
    }

    @Test("boot hydration repopulates qualified cards from disk and tags them .disk, with no get call")
    func bootHydrationServesQualifiedCardsFromDisk() async throws {
        // 1. Persist real content card rules to disk via a successful network update. Wait on the real
        //    completion handler — by the time it fires, applyPropositionChangeFor has written disk.
        setContentCardResponse(fromFile: "MultipleCards")
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Messaging.updatePropositionsForSurfacesWithCompletionHandler([homeSurface]) { _ in
                continuation.resume()
            }
        }

        let messaging = try #require(messagingExtension, "Messaging extension should be registered")

        // sanity: the network update qualified cards into memory
        #expect(messaging.qualifiedContentCardsBySurface[homeSurface]?.isEmpty == false,
                "Network update should have qualified content cards into memory")

        // 2. Simulate a fresh cold boot: clear the in-memory qualified cache + origin map (the disk
        //    cache is left intact). If hydration did NOT read disk, the array would stay empty below.
        messaging.qualifiedContentCardsBySurface = [:]
        messaging.contentCardOriginByProposition = [:]
        #expect(messaging.qualifiedContentCardsBySurface[homeSurface] == nil)

        // 3. Run the boot hydration (exactly what readyForEvent does at boot). No get API is called.
        messaging.hydrateAllPersistedContentCards()

        // 4. The qualified array must be repopulated FROM DISK (proves disk was read + rules re-ran).
        let hydratedCards = messaging.qualifiedContentCardsBySurface[homeSurface] ?? []
        #expect(!hydratedCards.isEmpty,
                "Boot hydration must repopulate qualified content cards from the persisted disk cache")

        // 5. Every hydrated card must be tagged `.disk`, so servedFromPersistentCache reports offline.
        #expect(!messaging.contentCardOriginByProposition.isEmpty,
                "Boot-hydrated cards must have their origin tracked")
        for card in hydratedCards {
            #expect(messaging.contentCardOriginByProposition[card.uniqueId] == .disk,
                    "Boot-hydrated card \(card.uniqueId) must be tagged .disk for accurate analytics")
        }
    }
}
