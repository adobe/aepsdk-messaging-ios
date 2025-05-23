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

import AEPServices

class MessagingStateManager {
    let channelActivityStore = ChannelActivityStore()
    let updateTokenStore = UpdateTokenStore()
    let pushToStartTokenStore = PushToStartTokenStore()

    // MARK: - Messaging shared state

    func buildMessagingSharedState() -> [String: Any] {
        var sharedStateData: [String: Any] = [:]
        var liveActivity: [String: Any] = [:]

        // Update tokens
        if let updateTokens = updateTokenStore
            .all()
            .asDictionary(dateEncodingStrategy: .millisecondsSince1970),
           !updateTokens.isEmpty {
            liveActivity[MessagingConstants.SharedState.Messaging.LiveActivity.UPDATE_TOKENS] = updateTokens
        }

        // Push-to-start tokens
        if let pushToStartTokens = pushToStartTokenStore
            .all()
            .asDictionary(dateEncodingStrategy: .millisecondsSince1970),
           !pushToStartTokens.isEmpty {
            liveActivity[MessagingConstants.SharedState.Messaging.LiveActivity.PUSH_TO_START_TOKENS] = pushToStartTokens
        }

        // Channel activities
        if let channelActivities = channelActivityStore
            .all()
            .asDictionary(dateEncodingStrategy: .millisecondsSince1970),
           !channelActivities.isEmpty {
            liveActivity[MessagingConstants.SharedState.Messaging.LiveActivity.CHANNEL_ACTIVITIES] = channelActivities
        }

        // Only add "liveActivity" if any subkeys exist
        if !liveActivity.isEmpty {
            sharedStateData[MessagingConstants.SharedState.Messaging.LIVE_ACTIVITY] = liveActivity
        }

        return sharedStateData
    }
}
