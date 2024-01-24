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
        propositions = cachedPropositions
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

    func updatePropositions(_ newPropositions: [Surface: [MessagingProposition]], removing surfaces: [Surface]? = nil) {
        // add new surfaces or update replace existing surfaces
        for (surface, propositionsArray) in newPropositions {
            propositions.addArray(propositionsArray, forKey: surface)
        }

        // remove any surfaces if necessary
        if let surfaces = surfaces {
            for surface in surfaces {
                propositions.removeValue(forKey: surface)
            }
        }
    }

    // MARK: - private methods

    private func hydratePropositionsRulesEngine() {
        let parsedPropositions = ParsedPropositions(with: propositions, requestedSurfaces: propositions.map { $0.key }, runtime: self.runtime)
        if let inAppRules = parsedPropositions.surfaceRulesBySchemaType[.inapp] {
            rulesEngine.launchRulesEngine.replaceRules(with: inAppRules.flatMap { $0.value })
        }
    }

    private func removeCachedPropositions(surfaces: [Surface]) {
        cache.updatePropositions(nil, removing: surfaces)
    }
}
