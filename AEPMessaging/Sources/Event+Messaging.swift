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
import Foundation

extension Event {
    // MARK: - In-app Message Consequence Event Handling
    // MARK: Internal
    var isInAppMessage: Bool {
        return consequenceType == MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE
    }

    // MARK: Fullscreen Message Properties
    var messageId: String? {
        return data?[MessagingConstants.Event.Data.Key.IAM.ID] as? String
    }
    
    var template: String? {
        return details?[MessagingConstants.Event.Data.Key.IAM.TEMPLATE] as? String
    }

    var html: String? {
        return details?[MessagingConstants.Event.Data.Key.IAM.HTML] as? String
    }

    var remoteAssets: [String]? {
        return details?[MessagingConstants.Event.Data.Key.IAM.REMOTE_ASSETS] as? [String]
    }
    
    /// Returns the `_experience` dictionary from the `_xdm.mixins` object for Experience Event tracking
    var experienceInfo: [String: Any]? {
        guard let xdm = details?[MessagingConstants.XDM.AdobeKeys._XDM] as? [String: Any],
              let xdmMixins = xdm[MessagingConstants.XDM.AdobeKeys.MIXINS] as? [String: Any] else {
            return nil
        }
        
        return xdmMixins[MessagingConstants.XDM.AdobeKeys.EXPERIENCE] as? [String: Any]
    }

    // MARK: Message Object Validation
    var containsValidInAppMessage: Bool {
        // remoteAssets are optional
        return template != nil && html != nil
    }

    // MARK: Private
    // MARK: Consequence EventData Processing
    private var consequence: [String: Any]? {
        return data?[MessagingConstants.Event.Data.Key.TRIGGERED_CONSEQUENCE] as? [String: Any]
    }

    private var consequenceId: String? {
        return consequence?[MessagingConstants.Event.Data.Key.ID] as? String
    }

    private var consequenceType: String? {
        return consequence?[MessagingConstants.Event.Data.Key.TYPE] as? String
    }

    private var details: [String: Any]? {
        return consequence?[MessagingConstants.Event.Data.Key.DETAIL] as? [String: Any]
    }

    // MARK: - AEP Response Event Handling
    // MARK: Public
    var isPersonalizationDecisionResponse: Bool {
        return isEdgeType && isPersonalizationSource
    }

    var offerActivityId: String? {
        return activity?[MessagingConstants.Event.Data.Key.Offers.ID] as? String
    }

    var offerPlacementId: String? {
        return placement?[MessagingConstants.Event.Data.Key.Offers.ID] as? String
    }

    /// each entry in the array represents "content" from an offer, which contains a rule
    var rulesJson: [String]? {
        guard let items = items else {
            return nil
        }

        var rules: [String] = []
        for item in items {
            guard let data = item[MessagingConstants.Event.Data.Key.Offers.DATA] as? [String: Any] else {
                continue
            }
            if let content = data[MessagingConstants.Event.Data.Key.Offers.CONTENT] as? String {
                rules.append(content)
            }
        }

        return rules.isEmpty ? nil : rules
    }

    // MARK: Private
    private var isEdgeType: Bool {
        return type == EventType.edge
    }

    private var isPersonalizationSource: Bool {
        return source == MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS
    }

    /// payload is an array of dictionaries, but since we are only asking for a single DecisionScope
    /// in the messaging sdk, we can assume this array will only have 0-1 items
    private var payload: [[String: Any]]? {
        return data?[MessagingConstants.Event.Data.Key.Offers.PAYLOAD] as? [[String: Any]]
    }

    private var activity: [String: Any]? {
        guard let payload = payload, !payload.isEmpty else {
            return nil
        }

        return payload[0][MessagingConstants.Event.Data.Key.Offers.ACTIVITY] as? [String: Any]
    }

    private var placement: [String: Any]? {
        guard let payload = payload, !payload.isEmpty else {
            return nil
        }

        return payload[0][MessagingConstants.Event.Data.Key.Offers.PLACEMENT] as? [String: Any]
    }

    private var items: [[String: Any]]? {
        guard let payload = payload, !payload.isEmpty else {
            return nil
        }

        return payload[0][MessagingConstants.Event.Data.Key.Offers.ITEMS] as? [[String: Any]]
    }

    // MARK: Refresh Messages Public API Event
    var isRefreshMessageEvent: Bool {
        return isMessagingType && isRequestContentSource && refreshMessages
    }

    private var isMessagingType: Bool {
        return type == MessagingConstants.Event.EventType.messaging
    }

    private var isRequestContentSource: Bool {
        return source == EventSource.requestContent
    }

    private var refreshMessages: Bool {
        return data?[MessagingConstants.Event.Data.Key.REFRESH_MESSAGES] as? Bool ?? false
    }

    /// Returns true if this event is a generic identity request content event
    var isGenericIdentityRequestContentEvent: Bool {
        return type == EventType.genericIdentity && source == EventSource.requestContent
    }

    var token: String? {
        return data?[MessagingConstants.Event.Data.Key.PUSH_IDENTIFIER] as? String
    }

    var xdmEventType: String? {
        return data?[MessagingConstants.Event.Data.Key.EVENT_TYPE] as? String
    }

    var messagingId: String? {
        return data?[MessagingConstants.Event.Data.Key.MESSAGE_ID] as? String
    }

    var actionId: String? {
        return data?[MessagingConstants.Event.Data.Key.ACTION_ID] as? String
    }

    var applicationOpened: Bool {
        return data?[MessagingConstants.Event.Data.Key.APPLICATION_OPENED] as? Bool ?? false
    }

    var mixins: [String: Any]? {
        return adobeXdm?[MessagingConstants.XDM.AdobeKeys.MIXINS] as? [String: Any]
    }

    var cjm: [String: Any]? {
        return adobeXdm?[MessagingConstants.XDM.AdobeKeys.CJM] as? [String: Any]
    }

    var adobeXdm: [String: Any]? {
        return data?[MessagingConstants.XDM.Key.ADOBE_XDM] as? [String: Any]
    }

    var isMessagingRequestContentEvent: Bool {
        return type == MessagingConstants.Event.EventType.messaging && source == EventSource.requestContent
    }
}
