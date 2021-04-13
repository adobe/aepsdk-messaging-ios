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
    // MARK: Public
    var isInAppMessage: Bool {
        return consequenceType == MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE
    }
    
    // MARK: Fullscreen Message Properties
    var template: String? {
        return details?[MessagingConstants.EventDataKeys.InAppMessages.TEMPLATE] as? String
    }
    
    var html: String? {
        return details?[MessagingConstants.EventDataKeys.InAppMessages.HTML] as? String
    }
    
    var remoteAssets: [String]? {
        return details?[MessagingConstants.EventDataKeys.InAppMessages.REMOTE_ASSETS] as? [String]
    }
    
    // MARK: Message Object Validation
    var containsValidInAppMessage: Bool {
        // remoteAssets are optional
        return template != nil && html != nil
    }
    
    // MARK: Private
    // MARK: Consequence EventData Processing
    private var consequence: [String: Any]? {
        return data?[MessagingConstants.EventDataKeys.TRIGGERED_CONSEQUENCE] as? [String: Any]
    }
    
    private var consequenceId: String? {
        return consequence?[MessagingConstants.EventDataKeys.ID] as? String
    }
    
    private var consequenceType: String? {
        return consequence?[MessagingConstants.EventDataKeys.TYPE] as? String
    }
    
    private var details: [String: Any]? {
        return consequence?[MessagingConstants.EventDataKeys.DETAIL] as? [String: Any]
    }
    
    // MARK: - AEP Response Event Handling
    // MARK: Public
    var isPersonalizationDecisionResponse: Bool {
        return isEdgeType && isPersonalizationSource
    }
    
    var offerActivityId: String? {
        return activity?[MessagingConstants.EventDataKeys.Offers.ID] as? String
    }
    
    var offerPlacementId: String? {
        return placement?[MessagingConstants.EventDataKeys.Offers.ID] as? String
    }
    
    /// each entry in the array represents "content" from an offer, which contains a rule
    var rulesJson: [String]? {
        guard let items = items else {
            return nil
        }
        
        var rules: [String] = []
        for item in items {
            guard let data = item[MessagingConstants.EventDataKeys.Offers.DATA] as? [String: Any] else {
                continue
            }
            if let content = data[MessagingConstants.EventDataKeys.Offers.CONTENT] as? String {
                rules.append(content)
            }
        }
        
        return rules.count > 0 ? rules : nil
    }
    
    // MARK: Private
    private var isEdgeType: Bool {
        return type == EventType.edge
    }
    
    private var isPersonalizationSource: Bool {
        return source == MessagingConstants.EventSource.PERSONALIZATION_DECISIONS
    }
    
    /// payload is an array of dictionaries, but since we are only asking for a single DecisionScope
    /// in the messaging sdk, we can assume this array will only have 0-1 items
    private var payload: [[String: Any]]? {
        return data?[MessagingConstants.EventDataKeys.Offers.PAYLOAD] as? [[String: Any]]
    }
    
    private var activity: [String: Any]? {
        return payload?[0][MessagingConstants.EventDataKeys.Offers.ACTIVITY] as? [String: Any]
    }
    
    private var placement: [String: Any]? {
        return payload?[0][MessagingConstants.EventDataKeys.Offers.PLACEMENT] as? [String: Any]
    }
    
    private var items: [[String: Any]]? {
        return payload?[0][MessagingConstants.EventDataKeys.Offers.ITEMS] as? [[String: Any]]
    }
}
