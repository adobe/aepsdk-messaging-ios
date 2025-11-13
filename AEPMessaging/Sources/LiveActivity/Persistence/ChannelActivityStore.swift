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

import Foundation

final class ChannelActivityStore: PersistenceStoreBase<LiveActivity.ChannelMap> {
    convenience init() {
        self.init(
            storeKey: MessagingConstants.NamedCollectionKeys.LiveActivity.CHANNEL_DETAILS,
            ttl: MessagingConstants.LiveActivity.CHANNEL_ACTIVITY_MAX_TTL
            // No custom equivalence logic; any non-expired `ChannelActivity` replaces the old one
        )
    }
}
