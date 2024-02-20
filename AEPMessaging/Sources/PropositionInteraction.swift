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

import AEPServices
import Foundation

struct PropositionInteraction: Codable {
    var eventType: MessagingEdgeEventType
    var interaction: String?
    var propositionInfo: PropositionInfo
    var itemId: String?

    var xdm: [String: Any] {
        var propositionDetailsData: [String: Any] = [:]

        propositionDetailsData = [
            MessagingConstants.XDM.Inbound.Key.ID: propositionInfo.id,
            MessagingConstants.XDM.Inbound.Key.SCOPE: propositionInfo.scope,
            MessagingConstants.XDM.Inbound.Key.SCOPE_DETAILS: propositionInfo.scopeDetails.asDictionary() ?? [:]
        ]

        if
            let itemId = itemId,
            !itemId.isEmpty
        {
            propositionDetailsData[MessagingConstants.XDM.Inbound.Key.ITEMS] = [
                [
                    MessagingConstants.XDM.Inbound.Key.ID: itemId
                ]
            ]
        }

        let propositionEventType: [String: Any] = [
            eventType.propositionEventType: 1
        ]

        var decisioning: [String: Any] = [
            MessagingConstants.XDM.Inbound.Key.PROPOSITION_EVENT_TYPE: propositionEventType,
            MessagingConstants.XDM.Inbound.Key.PROPOSITIONS: [propositionDetailsData]
        ]

        // only add `propositionAction` data if this is an interact event
        if
            eventType == .interact,
            let interaction = interaction
        {
            let propositionAction: [String: String] = [
                MessagingConstants.XDM.Inbound.Key.ID: interaction,
                MessagingConstants.XDM.Inbound.Key.LABEL: interaction
            ]
            decisioning[MessagingConstants.XDM.Inbound.Key.PROPOSITION_ACTION] = propositionAction
        }

        let experience: [String: Any] = [
            MessagingConstants.XDM.Inbound.Key.DECISIONING: decisioning
        ]

        let xdm: [String: Any] = [
            MessagingConstants.XDM.Key.EVENT_TYPE: eventType.toString(),
            MessagingConstants.XDM.AdobeKeys.EXPERIENCE: experience
        ]
        return xdm
    }

    enum CodingKeys: String, CodingKey {
        case eventType
        case interaction
        case propositionInfo
        case itemId
    }

    init(eventType: MessagingEdgeEventType, interaction: String?, propositionInfo: PropositionInfo, itemId: String?) {
        self.eventType = eventType
        self.interaction = interaction
        self.propositionInfo = propositionInfo
        self.itemId = itemId
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(eventType.toString(), forKey: .eventType)
        try container.encode(interaction, forKey: .interaction)
        try container.encode(propositionInfo, forKey: .propositionInfo)
        try container.encode(itemId, forKey: .itemId)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard
            let eventTypeString = try? container.decode(String.self, forKey: .eventType),
            let edgeEventType = MessagingEdgeEventType(fromType: eventTypeString)
        else {
            throw DecodingError.dataCorruptedError(forKey: CodingKeys.eventType, in: container, debugDescription: "Cannot create MessagingEdgeEventType from the provided event type string.")
        }
        eventType = edgeEventType
        interaction = try container.decodeIfPresent(String.self, forKey: .interaction)
        propositionInfo = try container.decode(PropositionInfo.self, forKey: .propositionInfo)
        itemId = try container.decodeIfPresent(String.self, forKey: .itemId)
    }
}
