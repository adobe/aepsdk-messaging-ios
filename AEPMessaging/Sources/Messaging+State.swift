/*
 Copyright 2023 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import AEPCore
import AEPServices
import Foundation

extension Messaging {
    /// Loads propositions from persistence into memory then hydrates the messaging rules engine
    func loadCachedPropositions() {
        guard let cachedPropositions = cache.propositions else {
            return
        }
        inMemoryPropositions = cachedPropositions
        hydratePropositionsRulesEngine()
    }

    func updatePropositionInfo(_ newPropositionInfo: [String: PropositionInfo], removing surfaces: [Surface]? = nil) {
        propositionInfo.merge(newPropositionInfo) { _, new in new }

        // currently, we can't remove entries that pre-exist by message id since they are not linked to surfaces
        // need to get surface uri from propositionInfo.scope and remove entry based on incoming `surfaces`
        if let surfaces = surfaces {
            propositionInfo = propositionInfo.filter { propInfo in
                !surfaces.contains { $0.uri == propInfo.value.scope }
            }
        }
    }

    func updatePropositions(_ newPropositions: [Surface: [Proposition]], removing surfaces: [Surface]? = nil) {
        // add new surfaces or replace existing surfaces
        for (surface, propositionsArray) in newPropositions {
            inMemoryPropositions[surface] = propositionsArray
        }

        // remove any surfaces if necessary
        if let surfaces = surfaces {
            for surface in surfaces {
                inMemoryPropositions.removeValue(forKey: surface)
            }
        }
    }

    func updateInboxPropositions(_ newPropositions: [Surface: [Proposition]], removing surfaces: [Surface]? = nil) {
        // add new surfaces or replace existing surfaces
        for (surface, propositionsArray) in newPropositions {
            inboxPropositionsBySurface[surface] = propositionsArray
        }

        // remove any surfaces if necessary
        if let surfaces = surfaces {
            for surface in surfaces {
                inboxPropositionsBySurface.removeValue(forKey: surface)
            }
        }
    }

    /// Stores raw content card propositions from a live network response into `inMemoryContentCardPropositions`
    /// and tags every incoming proposition `.network` in the origin map. Mirrors `updatePropositions` (IAM/CBE).
    /// Called from `applyPropositionChangeFor` after the disk write, before `updateRulesEngines`.
    func updateContentCardPropositions(_ newPropositions: [Surface: [Proposition]], removing surfaces: [Surface]? = nil) {
        for (surface, propositionsArray) in newPropositions {
            inMemoryContentCardPropositions[surface] = propositionsArray
        }
        if let surfaces = surfaces {
            for surface in surfaces {
                inMemoryContentCardPropositions.removeValue(forKey: surface)
            }
        }
        // Network propositions always win — overwrite any prior `.disk` tag so analytics correctly
        // reports `servedFromPersistentCache: false` for cards that came from a live fetch.
        var origins = contentCardOriginByProposition
        for (_, propositions) in newPropositions {
            for proposition in propositions {
                origins[proposition.uniqueId] = .network
            }
        }
        contentCardOriginByProposition = origins
    }

    /// Reads raw content card propositions from disk for the requested surfaces.
    /// Used exclusively by `hydrateContentCardRulesEngineFromDisk` to seed the rules engine at boot.
    /// Do NOT use for `retrieveMessages` — raw disk propositions are ruleset-item wrappers and
    /// cannot be converted to `ContentCardUI` directly; use `getPropositionsFromContentCardRulesEngine`.
    func readContentCardPropositionsFromDisk(for surfaces: [Surface]) -> [Surface: [Proposition]] {
        guard let cached = cache.contentCardPropositions, !cached.isEmpty else { return [:] }
        return cached.filter { surfaces.contains($0.key) }
    }

    // MARK: - private methods

    private func hydratePropositionsRulesEngine() {
        let parsedPropositions = ParsedPropositions(with: inMemoryPropositions, requestedSurfaces: inMemoryPropositions.map { $0.key }, runtime: runtime,
                                                    contentCardOfflineAvailable: false)
        if let inAppRules = parsedPropositions.surfaceRulesBySchemaType[.inapp] {
            // Record the loaded IAM rules in `inAppRulesBySurface` so the dictionary stays an accurate
            // source of truth for what's in the shared `rulesEngine`. Without this, a later rebuild of the
            // shared engine (e.g. content-card disk hydration adding event-history rules) would collect an
            // empty in-app set and silently erase these IAM rules on `replaceRules`. Mirrors the network
            // path (`updateRulesEngines` → `processRulesForSchemaType(.inapp, ...)`).
            for (surface, rules) in inAppRules {
                inAppRulesBySurface[surface] = rules
            }
            rulesEngine.launchRulesEngine.replaceRules(with: inAppRules.flatMap { $0.value })
        }
        updatePropositionInfo(parsedPropositions.propositionInfoToCache)
    }

    private func removeCachedPropositions(surfaces: [Surface]) {
        cache.updatePropositions(nil, removing: surfaces)
    }
}
