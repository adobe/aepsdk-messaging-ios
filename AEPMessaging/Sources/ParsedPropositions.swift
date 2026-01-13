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

struct ParsedPropositions {
    let LOG_TAG = "ParsedPropositions"

    weak var runtime: ExtensionRuntime?

    // store tracking information for propositions loaded into rules engines
    var propositionInfoToCache: [String: PropositionInfo] = [:]

    // non-in-app propositions should be cached and not persisted
    var propositionsToCache: [Surface: [Proposition]] = [:]

    // in-app propositions don't need to stay in cache, but must be persisted
    // also need to store tracking info for in-app propositions as `PropositionInfo`
    var propositionsToPersist: [Surface: [Proposition]] = [:]

    // in-app and feed rules that need to be applied to their respective rules engines
    var surfaceRulesBySchemaType: [SchemaType: [Surface: [LaunchRule]]] = [:]

    init(with propositions: [Surface: [Proposition]], requestedSurfaces: [Surface], runtime: ExtensionRuntime) {
        self.runtime = runtime

        // sort these propositions by ordinal rank before processing them
        let sortedPropositionsBySurface = sortByRank(propositions)

        for propositionsArray in sortedPropositionsBySurface.values {
            for proposition in propositionsArray {
                guard let surface = requestedSurfaces.first(where: { $0.uri == proposition.scope }) else {
                    Log.debug(label: MessagingConstants.LOG_TAG,
                              "Ignoring proposition where scope (\(proposition.scope)) does not match one of the expected surfaces.")
                    continue
                }

                // handle schema consequences which are representable as PropositionItems
                guard let firstPropositionItem = proposition.items.first else {
                    continue
                }

                switch firstPropositionItem.schema {
                // - handle ruleset-item schemas
                case .ruleset:
                    guard let parsedRules = parseRule(firstPropositionItem.itemData) else {
                        continue
                    }

                    // A ruleset-item can contain multiple rules with varying schema consequence types
                    for parsedRule in parsedRules {
                        guard let consequence = parsedRule.consequences.first,
                              let schemaConsequence = PropositionItem.fromRuleConsequence(consequence)
                        else {
                            continue
                        }

                        // handle these schemas when they're embedded in ruleset-item schemas:
                        // a. in-app schema consequences get persisted to disk, cached for reporting, and added to rules that need to be updated
                        //    i. default-content schema consequences are treated like in-app at a proposition level
                        // b. content card/feed schema consequences get cached for reporting added to rules that need to be updated
                        //
                        // IMPORTANT! - for schema consequences that are embedded in ruleset-items, the following is true:
                        //
                        //    consequence.id == consequence.detail.id
                        //
                        // this is important because we need a reliable key to store and retrieve `PropositionInfo` for reporting
                        switch schemaConsequence.schema {
                        case .inapp:
                            propositionInfoToCache[consequence.id] = PropositionInfo.fromProposition(proposition)
                            propositionsToPersist.add(proposition, forKey: surface)
                            mergeRules(parsedRule, for: surface, with: .inapp)
                        case .feed, .contentCard:
                            propositionInfoToCache[consequence.id] = PropositionInfo.fromProposition(proposition)
                            mergeRules(parsedRule, for: surface, with: .contentCard)
                        case .eventHistoryOperation:
                            // Event history operations don't have proposition info that needs to be cached unlike the cards they are tied to
                            // The rules just need to be loaded into the processing rules engine
                            mergeRules(parsedRule, for: surface, with: .eventHistoryOperation)
                        case .defaultContent:
                            // in a future release, determine whether this holdout is replacing IAM or CC, handle accordingly
                            // for now, do nothing
                            Log.debug(label: LOG_TAG, "Ignoring holdout treatment for activity '\(proposition.activityId)'")
                        default:
                            continue
                        }
                    }
                // - handle json-content, html-content, and default-content schemas for code based experiences
                //   a. code based schemas are cached for reporting
                case .jsonContent, .htmlContent, .defaultContent:
                    propositionsToCache.add(proposition, forKey: surface)
                case .unknown:
                    continue
                default:
                    continue
                }
            }
        }
    }

    private func parseRule(_ rule: [String: Any]) -> [LaunchRule]? {
        let ruleData = try? JSONSerialization.data(withJSONObject: rule, options: .prettyPrinted)
        return JSONRulesParser.parse(ruleData ?? Data(), runtime: runtime)
    }

    private mutating func mergeRules(_ rule: LaunchRule, for surface: Surface, with schemaType: SchemaType) {
        // Get any existing surface to [LaunchRule] map for this schema type
        var tempRulesBySurface = surfaceRulesBySchemaType[schemaType] ?? [:]

        // Append the single rule to the array stored for the surface key, or create a new array if none exists
        tempRulesBySurface.add(rule, forKey: surface)

        // Set the updated surface map back to the schema type
        surfaceRulesBySchemaType[schemaType] = tempRulesBySurface
    }

    private func sortByRank(_ propositionsBySurface: [Surface: [Proposition]]) -> [Surface: [Proposition]] {
        var propositionsSortedByRank: [Surface: [Proposition]] = [:]

        for (surface, propositions) in propositionsBySurface {
            propositionsSortedByRank[surface] = propositions.sorted { $0.rank < $1.rank }
        }

        return propositionsSortedByRank
    }
}
