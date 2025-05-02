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

class MessagingProperties {
    let updateTokenStore = LiveActivityUpdateTokenStore()
    let pushToStartTokenStore = LiveActivityPushToStartTokenStore()

    // MARK: - Messaging shared state

    func buildMessagingSharedState() -> [String: Any] {
        var sharedStateData: [String: Any] = [:]

        // Update tokens
        let updateTokensDict = updateTokenStore.all().asDictionary()
        if let updateTokens = updateTokensDict, !updateTokens.isEmpty {
            sharedStateData[MessagingConstants.SharedState.Messaging.LIVE_ACTIVITY_UPDATE_TOKENS] = updateTokens
        }

        // Push-to-start tokens
        let pushToStartTokensDict = pushToStartTokenStore.all().asDictionary()
        if let pushToStartTokens = pushToStartTokensDict, !pushToStartTokens.isEmpty {
            sharedStateData[MessagingConstants.SharedState.Messaging.LIVE_ACTIVITY_PUSH_TO_START_TOKENS] = pushToStartTokens
        }

        return sharedStateData
    }
}
