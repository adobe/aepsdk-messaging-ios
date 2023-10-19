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

struct ParsedPropositions {
    // store tracking information for propositions loaded into rules engines
    var propositionInfoToCache: [String: PropositionInfo] = [:]

    // non-in-app propositions should be cached and not persisted
    var propositionsToCache: [Surface: [Proposition]] = [:]

    // in-app propositions don't need to stay in cache, but must be persisted
    // also need to store tracking info for in-app propositions as `PropositionInfo`
    var propositionsToPersist: [Surface: [Proposition]] = [:]

    // in-app and feed rules that need to be applied to their respective rules engines
    var surfaceRulesByInboundType: [InboundType: [Surface: [LaunchRule]]] = [:]

    init(with propositions: [Surface: [Proposition]], requestedSurfaces: [Surface]) {
        for propositionsArray in propositions.values {
            for proposition in propositionsArray {
                guard let surface = requestedSurfaces.first(where: { $0.uri == proposition.scope }) else {
                    Log.debug(label: MessagingConstants.LOG_TAG,
                              "Ignoring proposition where scope (\(proposition.scope)) does not match one of the expected surfaces.")
                    continue
                }
                
                // handle format for old versions of IAM
                if let oldRules = parseRule(proposition.items.first?.content.stringValue ?? "") {
                    guard let consequence = oldRules.first?.consequences.first else {
                        Log.debug(label: MessagingConstants.LOG_TAG, "Proposition rule did not contain a consequence, no action to take for this Proposition.")
                        continue
                    }
                    if consequence.isOldInApp {
                        propositionInfoToCache[consequence.id] = PropositionInfo.fromProposition(proposition)
                        propositionsToPersist.add(proposition, forKey: surface)
                        mergeRules(oldRules, for: surface, with: .inapp)
                    }
                    continue
                }
                
                
                // if not an old format of IAM, handle schema consequences which are representable as PropositionItems
                guard let firstPropositionItem = proposition.items.first else {
                    continue
                }
                
                switch firstPropositionItem.schema {
                // - handle ruleset-item schemas
                case .ruleset:
                    guard let dataValue = firstPropositionItem.content.dataValue,
                        let parsedRules = JSONRulesParser.parse(dataValue) else {
                        continue
                    }
                    guard let consequence = parsedRules.first?.consequences.first,
                          let schemaConsequence = PropositionItem.fromRuleConsequence(consequence) else {
                        continue
                    }
                    
                    // handle these schemas when they're embedded in ruleset-item schemas
                    // a. in-app schema consequences get persisted to disk, cached for reporting, and added to rules that need to be updated
                    //    i. default-content schema consequences are treated like in-app at a proposition level
                    // b. feed schema consequences get cached for reporting added to rules that need to be updated
                    switch schemaConsequence.schema {
                    case .inapp, .defaultContent:
                        propositionInfoToCache[consequence.id] = PropositionInfo.fromProposition(proposition)
                        propositionsToPersist.add(proposition, forKey: surface)
                        mergeRules(parsedRules, for: surface, with: .inapp)
                    case .feed:
                        propositionInfoToCache[consequence.id] = PropositionInfo.fromProposition(proposition)
                        mergeRules(parsedRules, for: surface, with: .feed)
                    default:
                        continue
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
                
//                guard let contentString = proposition.items.first?.content, !contentString.isEmpty else {
//                    Log.debug(label: MessagingConstants.LOG_TAG, "Ignoring Proposition with empty content.")
//                    continue
//                }
//
//                // iam and feed items will be wrapped in a valid rules engine rule - code-based experiences are not
//                guard let parsedRules = parseRule(contentString) else {
//                    Log.debug(label: MessagingConstants.LOG_TAG, "Proposition did not contain a rule, adding as a code-based experience.")
//                    propositionsToCache.add(proposition, forKey: surface)
//                    continue
//                }
//
//                guard let consequence = parsedRules.first?.consequences.first else {
//                    Log.debug(label: MessagingConstants.LOG_TAG, "Proposition rule did not contain a consequence, no action to take for this Proposition.")
//                    continue
//                }
//
//                // store reporting data for this payload
//                propositionInfoToCache[consequence.id] = PropositionInfo.fromProposition(proposition)
//
//                var inboundType = InboundType.unknown
//                if consequence.isInApp {
//                    inboundType = .inapp
//                    propositionsToPersist.add(proposition, forKey: surface)
//                } else {
//                    inboundType = InboundType(from: consequence.detailSchema)
//                    if !consequence.isFeedItem {
//                        propositionsToCache.add(proposition, forKey: surface)
//                    }
//                }
//
//                mergeRules(parsedRules, for: surface, with: inboundType)
            }
        }
    }
    
    private func parseRule(_ rule: String) -> [LaunchRule]? {
        JSONRulesParser.parse(rule.data(using: .utf8) ?? Data())
    }

    private mutating func mergeRules(_ rules: [LaunchRule], for surface: Surface, with inboundType: InboundType) {
        // get rules we may already have for this inboundType
        var tempRulesByInboundType = surfaceRulesByInboundType[inboundType] ?? [:]

        // combine rules with existing
        tempRulesByInboundType.addArray(rules, forKey: surface)

        // apply up to surfaceRulesByInboundType
        surfaceRulesByInboundType[inboundType] = tempRulesByInboundType
    }
}