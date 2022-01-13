/*
 Copyright 2021 Adobe. All rights reserved.
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

// MARK: Offer extension

@objc
public extension Offer {
    /// Creates a dictionary containing XDM formatted data for `Experience Event - Proposition Interactions` field group from the given proposition option.
    ///
    /// The Edge `sendEvent(experienceEvent:_:)` API can be used to dispatch this data in an Experience Event along with any additional XDM, free-form data, or override dataset identifier.
    /// If the proposition reference within the option is released and no longer valid, the method returns `nil`.
    ///
    /// - Note: The returned XDM data also contains the `eventType` for the Experience Event with value `decisioning.propositionDisplay`.
    /// - Returns A dictionary containing XDM data for the propositon interactions.
    /// - SeeAlso: `interactionXdm(for:)`
    func generateDisplayInteractionXdm() -> [String: Any]? {
        generateInteractionXdm(for: OptimizeConstants.JsonValues.EE_EVENT_TYPE_PROPOSITION_DISPLAY)
    }

    /// Creates a dictionary containing XDM formatted data for `Experience Event - Proposition Interactions` field group from the given proposition option.
    ///
    /// The Edge `sendEvent(experienceEvent:_:)` API can be used to dispatch this data in an Experience Event along with any additional XDM, free-form data, or override dataset identifier.
    /// If the proposition reference within the option is released and no longer valid, the method returns `nil`.
    ///
    /// - Note: The returned XDM data also contains the `eventType` for the Experience Event with value `decisioning.propositionInteract`.
    /// - Returns A dictionary containing XDM data for the propositon interactions.
    /// - SeeAlso: `interactionXdm(for:)`
    func generateTapInteractionXdm() -> [String: Any]? {
        generateInteractionXdm(for: OptimizeConstants.JsonValues.EE_EVENT_TYPE_PROPOSITION_INTERACT)
    }

    /// Dispatches an event for the Edge extension to send an Experience Event to the Edge network with the display interaction data for the given proposition item.
    ///
    /// - SeeAlso: `trackWithData(_:)`
    func displayed() {
        trackWithData(generateDisplayInteractionXdm())
    }

    /// Dispatches an event for the Edge extension to send an Experience Event to the Edge network with the tap interaction data for the given proposition item.
    ///
    /// - SeeAlso: `trackWithData(_:)`
    func tapped() {
        trackWithData(generateTapInteractionXdm())
    }

    /// Creates a dictionary containing XDM formatted data for `Experience Event - Proposition Interactions` field group from the given proposition option and for the provided event type.
    ///
    /// If the proposition reference within the option is released and no longer valid, the method returns `nil`.
    ///
    /// - Parameter eventType: The Experience Event event type for the proposition interaction.
    /// - Returns A dictionary containing XDM data for the propositon interactions.
    private func generateInteractionXdm(for eventType: String) -> [String: Any]? {
        var propositionDetailsData: [String: Any] = [:]
        guard let proposition = proposition else {
            Log.debug(label: OptimizeConstants.LOG_TAG,
                      "Cannot send proposition interaction event (\(eventType)) for option \(id), proposition reference is not available.")
            return nil
        }

        propositionDetailsData = [
            OptimizeConstants.JsonKeys.DECISIONING_PROPOSITIONS_ID: proposition.id,
            OptimizeConstants.JsonKeys.DECISIONING_PROPOSITIONS_SCOPE: proposition.scope,
            OptimizeConstants.JsonKeys.DECISIONING_PROPOSITIONS_SCOPEDETAILS: proposition.scopeDetails,
            OptimizeConstants.JsonKeys.DECISIONING_PROPOSITIONS_ITEMS: [
                [
                    OptimizeConstants.JsonKeys.DECISIONING_PROPOSITIONS_ITEMS_ID: id
                ]
            ]
        ]

        let xdmData: [String: Any] = [
            OptimizeConstants.JsonKeys.EXPERIENCE_EVENT_TYPE: eventType,
            OptimizeConstants.JsonKeys.EXPERIENCE: [
                OptimizeConstants.JsonKeys.EXPERIENCE_DECISIONING: [
                    OptimizeConstants.JsonKeys.DECISIONING_PROPOSITIONS: [propositionDetailsData]
                ]
            ]
        ]
        return xdmData
    }

    /// Dispatches the track propositions request event with type `EventType.optimize` and source `EventSource.requestContent` and given proposition interactions data.
    ///
    /// No event is dispatched if the input xdm data is `nil`.
    ///
    /// - Parameter xdmData: A dictionary containing XDM data for the propositon interactions.
    private func trackWithData(_ xdmData: [String: Any]?) {
        guard let xdmData = xdmData else {
            Log.debug(label: OptimizeConstants.LOG_TAG,
                      "Cannot send track propositions request event, the provided xdmData is nil.")
            return
        }

        let eventData: [String: Any] = [
            OptimizeConstants.EventDataKeys.REQUEST_TYPE: OptimizeConstants.EventDataValues.REQUEST_TYPE_TRACK,
            OptimizeConstants.EventDataKeys.PROPOSITION_INTERACTIONS: xdmData
        ]

        let event = Event(name: OptimizeConstants.EventNames.TRACK_PROPOSITIONS_REQUEST,
                          type: EventType.optimize,
                          source: EventSource.requestContent,
                          data: eventData)

        MobileCore.dispatch(event: event)
    }
}
