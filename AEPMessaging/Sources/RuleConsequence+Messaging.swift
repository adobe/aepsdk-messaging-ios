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
import Foundation

extension RuleConsequence {
    var isFeedItem: Bool {
        guard let mobileParams = details[MessagingConstants.Event.Data.Key.FEED.MOBILE_PARAMETERS] as? [String: Any] else {
            return false
        }

        let type = mobileParams[MessagingConstants.Event.Data.Key.FEED.TYPE] as? String
        return type == MessagingConstants.Event.Data.Values.FEED.MESSAGE_FEED
    }
}
