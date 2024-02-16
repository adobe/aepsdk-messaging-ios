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
    weak var runtime: ExtensionRuntime?

    // store tracking information for propositions loaded into rules engines
    var propositionInfoToCache: [String: PropositionInfo] = [:]

    // non-in-app propositions should be cached and not persisted
    var propositionsToCache: [Surface: [MessagingProposition]] = [:]

    // in-app propositions don't need to stay in cache, but must be persisted
    // also need to store tracking info for in-app propositions as `PropositionInfo`
    var propositionsToPersist: [Surface: [MessagingProposition]] = [:]

    // in-app and feed rules that need to be applied to their respective rules engines
    var surfaceRulesBySchemaType: [SchemaType: [Surface: [LaunchRule]]] = [:]

    init(with propositions: [Surface: [MessagingProposition]], requestedSurfaces: [Surface], runtime: ExtensionRuntime) {
        self.runtime = runtime
        for propositionsArray in propositions.values {
            for proposition in propositionsArray {
                guard let surface = requestedSurfaces.first(where: { $0.uri == proposition.scope }) else {
                    Log.debug(label: MessagingConstants.LOG_TAG,
                              "Ignoring proposition where scope (\(proposition.scope)) does not match one of the expected surfaces.")
                    continue
                }

                // handle schema consequences which are representable as MessagingPropositionItems
                guard let firstPropositionItem = proposition.items.first else {
                    continue
                }

                switch firstPropositionItem.schema {
                // - handle ruleset-item schemas
                case .ruleset:
                    guard let parsedRules = parseRule(firstPropositionItem.itemData) else {
                        continue
                    }
                    guard let consequence = parsedRules.first?.consequences.first,
                          let schemaConsequence = MessagingPropositionItem.fromRuleConsequence(consequence)
                    else {
                        continue
                    }

                    // handle these schemas when they're embedded in ruleset-item schemas:
                    // a. in-app schema consequences get persisted to disk, cached for reporting, and added to rules that need to be updated
                    //    i. default-content schema consequences are treated like in-app at a proposition level
                    // b. feed schema consequences get cached for reporting added to rules that need to be updated
                    //
                    // IMPORTANT! - for schema consequences that are embedded in ruleset-items, the following is true:
                    //
                    //    consequence.id == consequence.detail.id
                    //
                    // this is important because we need a reliable key to store and retrieve `PropositionInfo` for reporting
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
            }
        }
    }

    private func parseRule(_ rule: [String: Any]) -> [LaunchRule]? {
        let ruleData = try? JSONSerialization.data(withJSONObject: rule, options: .prettyPrinted)
        return JSONRulesParser.parse(ruleData ?? Data(), runtime: runtime)
    }

    private mutating func mergeRules(_ rules: [LaunchRule], for surface: Surface, with schemaType: SchemaType) {
        // get rules we may already have for this schemaType
        var tempRulesBySchemaType = surfaceRulesBySchemaType[schemaType] ?? [:]

        // combine rules with existing
        tempRulesBySchemaType.addArray(rules, forKey: surface)

        // apply up to surfaceRulesBySchemaType
        surfaceRulesBySchemaType[schemaType] = tempRulesBySchemaType
    }
}
