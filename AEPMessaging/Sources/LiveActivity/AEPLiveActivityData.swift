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

/// A structure containing the data necessary to track a Live Activity in the Adobe Experience Platform.
@available(iOS 16.1, *)
public struct AEPLiveActivityData: Codable {
    /// Unique identifier for identifying an on going Live Activity in the Adobe Experience Platform.
    public var liveActivityID: String?

    /// A unique identifier for a broadcast channel.
    public var channelID: String?

    /// Creates an `AEPLiveActivityData` instance with the specified Live Activity ID.
    /// You will use this method for 1:1 Live Activity use cases.
    ///
    /// - Parameter liveActivityID: The unique identifier for the Live Activity.
    /// - Returns: A new `AEPLiveActivityData` instance populated with the provided `liveActivityID`.
    public static func create(liveActivityID: String) -> AEPLiveActivityData {
        AEPLiveActivityData(liveActivityID: liveActivityID)
    }

    /// Creates an `AEPLiveActivityData` instance with the specified channel ID.
    /// You will use this method for broadcast live activity use cases.
    ///
    /// - Parameter channelID: The unique identifier for the channel, used for broadcast push notifications.
    /// - Returns: A new `AEPLiveActivityData` instance populated with the provided `channelID`.
    public static func create(channelID: String) -> AEPLiveActivityData {
        AEPLiveActivityData(channelID: channelID)
    }
}
