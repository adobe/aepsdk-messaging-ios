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

import AEPCore
import AEPServices
import Foundation

extension Collection where Element == PropositionItem {
    /// Tracks interaction with multiple proposition items in a single batch.
    ///
    /// - Parameters
    ///     - interaction: a custom string value describing the interaction
    ///     - eventType: an enum specifying event type for the interaction
    func track(_ interaction: String? = nil, withEdgeEventType eventType: MessagingEdgeEventType) {
        guard !isEmpty else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Cannot track proposition interactions, proposition items are empty.")
            return
        }

        let batchedInteraction = BatchedPropositionInteraction(
            eventType: eventType,
            interaction: interaction,
            propositionItems: Array(self)
        )

        let xdmData = batchedInteraction.generateXDM()

        // Check if XDM data is empty
        guard !xdmData.isEmpty else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Cannot track proposition interactions, no valid propositions found.")
            return
        }

        // Record the proposition history for each proposition item in the collection.
        recordPropositionHistory(interaction: interaction, eventType: eventType)

        dispatchEvent(with: xdmData)
    }

    /// Records the proposition history for each proposition item in the collection.
    ///
    /// - Parameters:
    ///     - interaction: a custom string value describing the interaction
    ///     - eventType: an enum specifying event type for the interaction
    private func recordPropositionHistory(interaction: String?, eventType: MessagingEdgeEventType) {
        forEach { item in
            if let activityId = item.proposition?.activityId, !activityId.isEmpty {
                PropositionHistory.record(activityId: activityId, eventType: eventType, interaction: interaction)
            }
        }
    }

    /// Dispatch the batched proposition interaction event.
    ///
    /// - Parameters:
    ///     - xdmData: the XDM data for the batched proposition interaction
    private func dispatchEvent(with xdmData: [String: Any]) {
        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.TRACK_PROPOSITIONS: true,
            MessagingConstants.Event.Data.Key.PROPOSITION_INTERACTION: xdmData
        ]

        let event = Event(
            name: MessagingConstants.Event.Name.TRACK_PROPOSITIONS,
            type: EventType.messaging,
            source: EventSource.requestContent,
            data: eventData
        )

        MobileCore.dispatch(event: event)
    }
}
