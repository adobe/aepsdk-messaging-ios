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

import AEPServices
import Foundation

/// A struct that helps to build data for batched proposition interaction event
struct BatchedPropositionInteraction {
    /// Edge event type represented by enum `MessagingEdgeEventType`
    let eventType: MessagingEdgeEventType

    /// Interaction string to identify interaction type with the proposition items
    let interaction: String?

    /// Collection of proposition items
    let propositionItems: [PropositionItem]

    /// Generates the XDM for the batched proposition interaction
    /// - Returns: XDM dictionary
    func generateXDM() -> [String: Any] {
        let propositionInteractionDict = createPropositionInteractions()

        // Return empty dictionary if no valid propositions
        guard !propositionInteractionDict.isEmpty else {
            return [:]
        }

        var decisioning: [String: Any] = [
            MessagingConstants.XDM.Inbound.Key.PROPOSITION_EVENT_TYPE: [
                eventType.propositionEventType: 1
            ],
            MessagingConstants.XDM.Inbound.Key.PROPOSITIONS: propositionInteractionDict
        ]

        if let interaction = interaction {
            switch eventType {
            case .interact:
                decisioning[MessagingConstants.XDM.Inbound.Key.PROPOSITION_ACTION] = [
                    MessagingConstants.XDM.Inbound.Key.ID: interaction,
                    MessagingConstants.XDM.Inbound.Key.LABEL: interaction
                ]
            case .suppressDisplay:
                decisioning[MessagingConstants.XDM.Inbound.Key.PROPOSITION_ACTION] = [
                    MessagingConstants.XDM.Inbound.Key.REASON: interaction
                ]
            default:
                break
            }
        }

        return [
            MessagingConstants.XDM.Key.EVENT_TYPE: eventType.toString(),
            MessagingConstants.XDM.AdobeKeys.EXPERIENCE: [
                MessagingConstants.XDM.Inbound.Key.DECISIONING: decisioning
            ]
        ]
    }

    /// Creates proposition interaction dictionaries from proposition items
    /// - Returns: Array of proposition interaction dictionaries
    private func createPropositionInteractions() -> [[String: Any]] {
        propositionItems.compactMap { item -> [String: Any]? in
            guard let proposition = item.proposition else { return nil }

            let propositionInfo = PropositionInfo(
                id: proposition.uniqueId,
                scope: proposition.scope,
                scopeDetails: AnyCodable.from(dictionary: proposition.scopeDetails) ?? [:]
            )

            return [
                MessagingConstants.XDM.Inbound.Key.ID: propositionInfo.id,
                MessagingConstants.XDM.Inbound.Key.SCOPE: propositionInfo.scope,
                MessagingConstants.XDM.Inbound.Key.SCOPE_DETAILS: propositionInfo.scopeDetails.asDictionary() ?? [:],
                MessagingConstants.XDM.Inbound.Key.ITEMS: [
                    [MessagingConstants.XDM.Inbound.Key.ID: item.itemId]
                ]
            ]
        }
    }
}
