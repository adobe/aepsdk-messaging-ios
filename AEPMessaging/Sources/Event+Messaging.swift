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
    // MARK: - Consequence Types
    var isInAppMessage: Bool {
        return consequenceType == MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE
    }
    
    // MARK: - Fullscreen Message Properties
    var template: String? {
        return details?[MessagingConstants.EventDataKeys.InAppMessages.TEMPLATE] as? String
    }
    
    var html: String? {
        return details?[MessagingConstants.EventDataKeys.InAppMessages.HTML] as? String
    }
    
    var remoteAssets: [String]? {
        return details?[MessagingConstants.EventDataKeys.InAppMessages.REMOTE_ASSETS] as? [String]
    }
    
    // MARK: - Message Object Validation
    var containsValidInAppMessage: Bool {
        // remoteAssets are optional
        return template != nil && html != nil
    }
    
    // MARK: - Consequence EventData Processing
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
}
