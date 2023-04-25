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

class EdgeResponseManager {
    let propositions: [PropositionPayload]?
    let requestedSurfaces: [String]
    weak var parent: Messaging?
    let responseHandlersDict: [String: any EdgeResponseHandler.Type] = [
        MessagingConstants.ConsequenceTypes.FEED_ITEM: FeedHandler.self,
        MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE: InAppHandler.self
    ]

    init(_ propositions: [PropositionPayload]?, requestedSurfaces: [String], parent: Messaging) {
        self.propositions = propositions
        self.requestedSurfaces = requestedSurfaces
        self.parent = parent
    }

    func generateResponseHandlers(for consequenceType: String? = nil) -> [any EdgeResponseHandler] {
        guard let propositions = propositions, !propositions.isEmpty else {
            return []
        }

        var parsedRulesDict: [String: [LaunchRule]] = [:]
        var parsedPropositionsDict: [String: PropositionPayload] = [:]
        var messageIdsDict: [String: [String]] = [:]
        for proposition in propositions {
            guard requestedSurfaces.contains(proposition.propositionInfo.scope) else {
                Log.debug(label: MessagingConstants.LOG_TAG,
                          "Ignoring proposition where scope (\(proposition.propositionInfo.scope)) does not match one of the expected surfaces (\(requestedSurfaces)).")
                continue
            }

            guard let rulesString = proposition.items.first?.data.content, !rulesString.isEmpty else {
                Log.debug(label: MessagingConstants.LOG_TAG, "Skipping proposition with no message content.")
                continue
            }

            guard let rules = JSONRulesParser.parse(rulesString.data(using: .utf8) ?? Data(), runtime: parent?.runtime) else {
                Log.debug(label: MessagingConstants.LOG_TAG, "Skipping proposition with malformed message content.")
                continue
            }

            guard let messageId = rules.first?.consequences.first?.id else {
                continue
            }

            guard let inboundSubtype = rules.first?.consequences.first?.inboundSubtype, inboundSubtype != "unknown" else {
                Log.debug(label: MessagingConstants.LOG_TAG, "Skipping proposition with unknown message content type.")
                continue
            }

            parsedPropositionsDict[messageId] = proposition
            parsedRulesDict[messageId] = rules

            if messageIdsDict[inboundSubtype] == nil {
                messageIdsDict[inboundSubtype] = [messageId]
            } else {
                messageIdsDict[inboundSubtype]?.append(messageId)
            }
        }

        let requestedInboundSubtype = consequenceType ?? ""
        var responseHandlers: [any EdgeResponseHandler] = []
        for (inboundSubtype, messageIds) in messageIdsDict {
            if !requestedInboundSubtype.isEmpty,
               inboundSubtype != requestedInboundSubtype {
                continue
            }
            if !messageIds.isEmpty,
               let parent = parent,
               let handler = responseHandlersDict[inboundSubtype]?
                .init(propositionsDict: parsedPropositionsDict.filter { messageIds.contains($0.key) },
                      rulesDict: parsedRulesDict.filter { messageIds.contains($0.key) },
                      requestedSurfaces: requestedSurfaces,
                      parent: parent) {
                responseHandlers.append(handler)
            }
        }
        return responseHandlers
    }
}
