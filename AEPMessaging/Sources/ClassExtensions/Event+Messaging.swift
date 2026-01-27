/*
  Copyright 2021 Adobe. All rights reserved.
  This file is licensed to you under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License. You may obtain a copy
  of the License at http://www.apache.org/licenses/LICENSE-2.0
 ​
  Unless required by applicable law or agreed to in writing, software distributed under
  the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
  OF ANY KIND, either express or implied. See the License for the specific language
  governing permissions and limitations under the License.
  */

import AEPCore
import AEPMessagingLiveActivity
import AEPServices
import CoreGraphics
import Foundation

extension Event {
    // MARK: - In-app Message Consequence Event Handling

    var isSchemaConsequence: Bool {
        consequenceType == MessagingConstants.ConsequenceTypes.SCHEMA
    }

    // MARK: - Consequence EventData Processing

    private var consequence: [String: Any]? {
        data?[MessagingConstants.Event.Data.Key.TRIGGERED_CONSEQUENCE] as? [String: Any]
    }

    private var consequenceType: String? {
        consequence?[MessagingConstants.Event.Data.Key.TYPE] as? String
    }

    private var details: [String: Any]? {
        consequence?[MessagingConstants.Event.Data.Key.DETAIL] as? [String: Any]
    }

    // MARK: - AEP Response Event Handling

    var isPersonalizationDecisionResponse: Bool {
        isEdgeType && isPersonalizationSource
    }

    var requestEventId: String? {
        parentID?.uuidString as? String ?? data?[MessagingConstants.Event.Data.Key.REQUEST_EVENT_ID] as? String
    }

    /// payload is an array of `Proposition` objects, each containing inbound content and related tracking information
    var payload: [Proposition]? {
        guard let payloadMap = data?[MessagingConstants.Event.Data.Key.Personalization.PAYLOAD] as? [[String: Any]] else {
            return nil
        }

        var returnablePayloads: [Proposition] = []
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for thisPayloadAny in payloadMap {
            if
                let thisPayload = AnyCodable.from(dictionary: thisPayloadAny),
                let payloadData = try? encoder.encode(thisPayload) {
                do {
                    let payloadObject = try decoder.decode(Proposition.self, from: payloadData)
                    returnablePayloads.append(payloadObject)
                } catch {
                    Log.warning(label: MessagingConstants.LOG_TAG, "Failed to decode an invalid personalization response: \(error)")
                }
            }
        }
        return returnablePayloads
    }

    var scope: String? {
        payload?.first?.scope
    }

    // MARK: Private

    private var isEdgeType: Bool {
        type == EventType.edge
    }

    private var isPersonalizationSource: Bool {
        source == MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS
    }

    // MARK: - Refresh Messages Public API Event

    var isRefreshMessageEvent: Bool {
        isMessagingType && isRequestContentSource && refreshMessages
    }

    private var isMessagingType: Bool {
        type == EventType.messaging
    }

    private var isRequestContentSource: Bool {
        source == EventSource.requestContent
    }

    private var refreshMessages: Bool {
        data?[MessagingConstants.Event.Data.Key.REFRESH_MESSAGES] as? Bool ?? false
    }

    // MARK: - Update Propositions Public API Event

    var isUpdatePropositionsEvent: Bool {
        isMessagingType && isRequestContentSource && updatePropositions
    }

    var surfaces: [Surface]? {
        guard
            let surfacesData = data?[MessagingConstants.Event.Data.Key.SURFACES] as? [[String: Any]],
            let jsonData = try? JSONSerialization.data(withJSONObject: surfacesData)
        else {
            return nil
        }

        return try? JSONDecoder().decode([Surface].self, from: jsonData)
    }

    private var updatePropositions: Bool {
        data?[MessagingConstants.Event.Data.Key.UPDATE_PROPOSITIONS] as? Bool ?? false
    }

    // MARK: - Track Propositions Public API event

    var isTrackPropositionsEvent: Bool {
        isMessagingType && isRequestContentSource && trackPropositions
    }

    var propositionInteractionXdm: [String: Any]? {
        guard
            let propositionInteractionXdm = data?[MessagingConstants.Event.Data.Key.PROPOSITION_INTERACTION] as? [String: Any],
            !propositionInteractionXdm.isEmpty
        else {
            return nil
        }
        return propositionInteractionXdm
    }

    private var trackPropositions: Bool {
        data?[MessagingConstants.Event.Data.Key.TRACK_PROPOSITIONS] as? Bool ?? false
    }

    // MARK: - Get propositions public API event

    var isGetPropositionsEvent: Bool {
        isMessagingType && isRequestContentSource && getPropositions
    }

    private var getPropositions: Bool {
        data?[MessagingConstants.Event.Data.Key.GET_PROPOSITIONS] as? Bool ?? false
    }

    var propositions: [Proposition]? {
        guard
            let propositionsData = data?[MessagingConstants.Event.Data.Key.PROPOSITIONS] as? [[String: Any]],
            let jsonData = try? JSONSerialization.data(withJSONObject: propositionsData)
        else {
            return nil
        }

        return try? JSONDecoder().decode([Proposition].self, from: jsonData)
    }

    var responseError: AEPError? {
        guard let errorInt = data?[MessagingConstants.Event.Data.Key.RESPONSE_ERROR] as? Int else {
            return nil
        }
        return AEPError(rawValue: errorInt)
    }

    // MARK: - SetPushIdentifier Event

    var isPushTokenEvent: Bool {
        type == EventType.genericIdentity && source == EventSource.requestContent &&
            data?[MessagingConstants.Event.Data.Key.PUSH_IDENTIFIER] as? String != nil
    }

    var token: String? {
        data?[MessagingConstants.Event.Data.Key.PUSH_IDENTIFIER] as? String
    }

    // MARK: - Push tracking

    var isPushInteractionEvent: Bool {
        data?[MessagingConstants.Event.Data.Key.PUSH_INTERACTION] as? Bool ?? false
    }

    var pushTrackingStatus: PushTrackingStatus? {
        guard let statusInt = data?[MessagingConstants.Event.Data.Key.PUSH_NOTIFICATION_TRACKING_STATUS] as? Int else {
            return nil
        }
        return PushTrackingStatus(fromRawValue: statusInt)
    }

    var pushClickThroughUrl: URL? {
        guard let link = data?[MessagingConstants.Event.Data.Key.PUSH_CLICK_THROUGH_URL] as? String else {
            return nil
        }
        return URL(string: link)
    }

    var isMessagingRequestContentEvent: Bool {
        type == EventType.messaging && source == EventSource.requestContent
    }

    var xdmEventType: String? {
        data?[MessagingConstants.Event.Data.Key.EVENT_TYPE] as? String
    }

    var messagingId: String? {
        data?[MessagingConstants.Event.Data.Key.ID] as? String
    }

    var actionId: String? {
        data?[MessagingConstants.Event.Data.Key.ACTION_ID] as? String
    }

    var applicationOpened: Bool {
        data?[MessagingConstants.Event.Data.Key.APPLICATION_OPENED] as? Bool ?? false
    }

    var mixins: [String: Any]? {
        adobeXdm?[MessagingConstants.XDM.AdobeKeys.MIXINS] as? [String: Any]
    }

    var cjm: [String: Any]? {
        adobeXdm?[MessagingConstants.XDM.AdobeKeys.CJM] as? [String: Any]
    }

    var adobeXdm: [String: Any]? {
        data?[MessagingConstants.XDM.Key.ADOBE_XDM] as? [String: Any]
    }

    // MARK: - Error response Event

    /// Creates a response event with specified AEPError type added in the Event data.
    /// - Parameter error: type of AEPError
    /// - Returns: error response Event
    func createErrorResponseEvent(_ error: AEPError) -> Event {
        createResponseEvent(name: MessagingConstants.Event.Name.MESSAGE_PROPOSITIONS_RESPONSE,
                            type: EventType.messaging,
                            source: EventSource.responseContent,
                            data: [
                                MessagingConstants.Event.Data.Key.RESPONSE_ERROR: error.rawValue
                            ])
    }

    // MARK: - Schema consequence event

    var schemaId: String? {
        details?[MessagingConstants.Event.Data.Key.ID] as? String
    }

    var schemaType: SchemaType? {
        guard let schemaString = details?[MessagingConstants.Event.Data.Key.SCHEMA] as? String else {
            return nil
        }

        return SchemaType(from: schemaString)
    }

    var schemaData: [String: Any]? {
        details?[MessagingConstants.Event.Data.Key.DATA] as? [String: Any]
    }

    // MARK: - Live Activity events

    var isLiveActivityUpdateTokenEvent: Bool {
        isMessagingType && isRequestContentSource && liveActivityUpdateTokenFlag
    }

    var isLiveActivityPushToStartTokenEvent: Bool {
        isMessagingType && isRequestContentSource && liveActivityPushToStartTokenFlag
    }

    var isLiveActivityStartEvent: Bool {
        isMessagingType && isRequestContentSource && liveActivityTrackStartFlag
    }

    var isLiveActivityStateEvent: Bool {
        isMessagingType && isRequestContentSource && liveActivityTrackStateFlag
    }

    private var liveActivityUpdateTokenFlag: Bool {
        data?[MessagingConstants.Event.Data.Key.LiveActivity.UPDATE_TOKEN] as? Bool ?? false
    }

    private var liveActivityPushToStartTokenFlag: Bool {
        data?[MessagingConstants.Event.Data.Key.LiveActivity.PUSH_TO_START_TOKEN] as? Bool ?? false
    }

    private var liveActivityTrackStartFlag: Bool {
        data?[MessagingConstants.Event.Data.Key.LiveActivity.TRACK_START] as? Bool ?? false
    }

    private var liveActivityTrackStateFlag: Bool {
        data?[MessagingConstants.Event.Data.Key.LiveActivity.TRACK_STATE] as? Bool ?? false
    }

    var liveActivityPushToStartToken: String? {
        data?[MessagingConstants.XDM.Push.TOKEN] as? String
    }

    /// Returns the batched push-to-start tokens array from the event data.
    /// Each element is a dictionary with "attributeType" and "token" keys.
    var liveActivityBatchedPushToStartTokens: [[String: String]]? {
        data?[MessagingConstants.Event.Data.Key.LiveActivity.BATCHED_PUSH_TO_START_TOKENS] as? [[String: String]]
    }

    var liveActivityUpdateToken: String? {
        data?[MessagingConstants.XDM.Push.TOKEN] as? String
    }

    var liveActivityAttributeType: String? {
        data?[MessagingConstants.Event.Data.Key.LiveActivity.ATTRIBUTE_TYPE] as? String
    }

    var liveActivityID: String? {
        data?[MessagingConstants.XDM.LiveActivity.ID] as? String
    }

    var liveActivityChannelID: String? {
        data?[MessagingConstants.XDM.LiveActivity.CHANNEL_ID] as? String
    }

    var liveActivityOrigin: String? {
        data?[MessagingConstants.XDM.LiveActivity.ORIGIN] as? String
    }

    var liveActivityState: String? {
        data?[MessagingConstants.Event.Data.Key.LiveActivity.STATE] as? String
    }
}
