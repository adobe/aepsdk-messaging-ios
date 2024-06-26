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
    @available(*, deprecated, renamed: "isContentCard")
    var isFeedItem: Bool {
        detailSchema == MessagingConstants.PersonalizationSchemas.FEED_ITEM
    }

    var isContentCard: Bool {
        detailSchema == MessagingConstants.PersonalizationSchemas.CONTENT_CARD
    }

    var isInApp: Bool {
        detailSchema == MessagingConstants.PersonalizationSchemas.IN_APP
    }

    private var detailSchema: String {
        details[MessagingConstants.Event.Data.Key.SCHEMA] as? String ?? ""
    }
}
