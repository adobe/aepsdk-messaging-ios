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

import AEPCore
import AEPServices
import Foundation

enum PropositionHistory {
    /// Dispatches an event to be recorded in Event History.
    ///
    /// If `activityId` is an empty string, calling this function results in a no-op
    ///
    /// - Parameters:
    ///  - activityId: activity id for this interaction
    ///  - eventType: `MessagingEdgeEventType` to be recorded
    ///  - interaction: if provided, adds a custom interaction to the hash
    static func record(activityId: String, eventType: MessagingEdgeEventType, interaction: String? = nil) {
        guard !activityId.isEmpty else {
            Log.trace(label: MessagingConstants.LOG_TAG, "Ignoring request to record PropositionHistory - activityId is empty.")
            return
        }

        // iam dictionary used for event history
        let iamHistory: [String: String] = [
            MessagingConstants.Event.History.Keys.EVENT_TYPE: eventType.propositionEventType,
            MessagingConstants.Event.History.Keys.MESSAGE_ID: activityId,
            MessagingConstants.Event.History.Keys.TRACKING_ACTION: interaction ?? ""
        ]

        // wrap history in an "iam" object
        let eventHistoryData: [String: Any] = [
            MessagingConstants.Event.Data.Key.IAM_HISTORY: iamHistory
        ]

        let mask = [
            MessagingConstants.Event.History.Mask.EVENT_TYPE,
            MessagingConstants.Event.History.Mask.MESSAGE_ID,
            MessagingConstants.Event.History.Mask.TRACKING_ACTION
        ]

        var interactionLog = ""
        if let interaction = interaction {
            interactionLog = " with value '\(interaction)'"
        }
        Log.trace(label: MessagingConstants.LOG_TAG, "Writing '\(eventType.propositionEventType)' event\(interactionLog) to EventHistory for Proposition with activityId '\(activityId)'")

        // By setting a mask, event hub will record this event using the keys in the mask
        // (the keys must be flattened keys) and record into event history
        let event = Event(name: MessagingConstants.Event.Name.EVENT_HISTORY_WRITE,
                          type: EventType.messaging,
                          source: MessagingConstants.Event.Source.EVENT_HISTORY_WRITE,
                          data: eventHistoryData,
                          mask: mask)
        MobileCore.dispatch(event: event)
    }
}
