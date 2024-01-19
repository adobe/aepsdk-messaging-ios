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

@objc
public extension MessagingPropositionItem {
    /// Tracks interaction with the given proposition item.
    ///
    /// - Parameter interaction: an enum specifying the type of interactioon.
    func track(interaction: MessagingEdgeEventType) {
        guard let interactionXdm = generateInteractionXdm(for: interaction) else {
            return
        }
        sendTrackEvent(interactionXdm)
    }

    /// Creates a dictionary containing XDM data for proposition interaction with the given proposition item, for the provided event type.
    ///
    /// If the proposition reference within the item is released and no longer valid, the method returns `nil`.
    ///
    /// - Parameter eventType: an enum specifying type of interaction.
    /// - Returns A dictionary containing XDM data for the propositon interactions.
    private func generateInteractionXdm(for eventType: MessagingEdgeEventType) -> [String: Any]? {
        var propositionDetailsData: [String: Any] = [:]
        guard let proposition = proposition else {
            Log.debug(label: MessagingConstants.LOG_TAG,
                      "Cannot send proposition interaction event (\(eventType.toString())) for item \(itemId), proposition reference is not available.")
            return nil
        }

        propositionDetailsData = [
            MessagingConstants.XDM.Inbound.Key.ID: proposition.uniqueId,
            MessagingConstants.XDM.Inbound.Key.SCOPE: proposition.scope,
            MessagingConstants.XDM.Inbound.Key.SCOPE_DETAILS: proposition.scopeDetails,
            MessagingConstants.XDM.Inbound.Key.ITEMS: [
                [
                    MessagingConstants.XDM.Inbound.Key.ID: itemId
                ]
            ]
        ]

        var propositionEventType: [String: Any] = [:]
        propositionEventType[eventType.propositionEventType] = 1

        let xdmData: [String: Any] = [
            MessagingConstants.XDM.Key.EVENT_TYPE: eventType.toString(),
            MessagingConstants.XDM.AdobeKeys.EXPERIENCE: [
                MessagingConstants.XDM.Inbound.Key.DECISIONING: [
                    MessagingConstants.XDM.Inbound.Key.PROPOSITION_EVENT_TYPE: propositionEventType,
                    MessagingConstants.XDM.Inbound.Key.PROPOSITIONS: [propositionDetailsData]
                ]
            ]
        ]
        return xdmData
    }

    /// Dispatches the track propositions request event containing proposition interactions data.
    ///
    /// No event is dispatched if the input XDM data is `nil`.
    ///
    /// - Parameter xdmData: A dictionary containing XDM data for the propositon interactions.
    private func sendTrackEvent(_ xdmData: [String: Any]?) {
        guard let xdmData = xdmData else {
            Log.debug(label: MessagingConstants.LOG_TAG,
                      "Cannot send track propositions request event, the provided xdmData is nil.")
            return
        }

        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.TRACK_PROPOSITIONS: true,
            MessagingConstants.Event.Data.Key.PROPOSITION_INTERACTIONS: xdmData
        ]

        let event = Event(name: MessagingConstants.Event.Name.TRACK_PROPOSITIONS,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)

        MobileCore.dispatch(event: event)
    }
}
