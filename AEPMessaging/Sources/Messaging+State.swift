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

    func clear(surfaces: [Surface]) {
        for surface in surfaces {
            propositions.removeValue(forKey: surface)
            inboundMessages.removeValue(forKey: surface)
            for (key, value) in propositionInfo where value.scope == surface.uri {
                propositionInfo.removeValue(forKey: key)
            }
        }

        // remove in-app message from cache
        removeCachedPropositions(surfaces: surfaces)
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

    func updateInboundMessages(_ newInboundMessages: [Surface: [Inbound]], surfaces: [Surface]) {
        for surface in surfaces {
            if let inboundMessagesArray = newInboundMessages[surface] {
                inboundMessages[surface] = inboundMessagesArray
            } else {
                if inboundMessages.contains(where: { $0.key == surface }) {
                    inboundMessages.removeValue(forKey: surface)
                }
            }
        }
    }

    func retrieveFeedMessages() -> [Surface: Feed] {
        var feedMessages: [Surface: Feed] = [:]
        for (surface, inboundArr) in inboundMessages {
            for inbound in inboundArr {
                guard let feedItem: FeedItem = inbound.decodeContent(FeedItem.self) else {
                    continue
                }

                feedItem.inbound = inbound
                let feedName = inbound.meta?[MessagingConstants.Event.Data.Key.Feed.FEED_NAME] as? String ?? ""

                // Find the feed to insert the feed item else create a new feed for it
                if feedMessages[surface] != nil {
                    feedMessages[surface]?.items.append(feedItem)
                } else {
                    feedMessages[surface] = Feed(name: feedName, surface: surface, items: [feedItem])
                }
            }
        }
        return feedMessages
    }

    // MARK: - private methods

    private func hydratePropositionsRulesEngine() {
        let parsedPropositions = ParsedPropositions(with: propositions, requestedSurfaces: propositions.map { $0.key })
        if let inAppRules = parsedPropositions.surfaceRulesByInboundType[.inapp] {
            rulesEngine.launchRulesEngine.replaceRules(with: inAppRules.flatMap { $0.value })
        }
    }

    private func removeCachedPropositions(surfaces: [Surface]) {
        cache.updatePropositions(nil, removing: surfaces)
    }
}