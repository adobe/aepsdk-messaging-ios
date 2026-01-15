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

import AEPMessagingLiveActivity

@available(iOS 16.1, *)
extension LiveActivityAttributes {
    /// A unique string identifier representing the `LiveActivityAttributes` type.
    ///
    /// This value is derived from the type's name and is used as a key when
    /// registering or dispatching events associated with a specific Live Activity type.
    /// It provides a consistent way to reference the type across token and task management, logging, and event data.
    static var attributeType: String {
        String(describing: self)
    }

    /// Returns a dictionary with the non-nil `liveActivityID` and/or `channelID`.
    /// If both are nil, returns an empty dictionary.
    var liveActivityIdentifierData: [String: String] {
        let data = [
            MessagingConstants.XDM.LiveActivity.ID: liveActivityData.liveActivityID,
            MessagingConstants.XDM.LiveActivity.CHANNEL_ID: liveActivityData.channelID
        ]
        return data.compactMapValues { $0 }
    }
}
