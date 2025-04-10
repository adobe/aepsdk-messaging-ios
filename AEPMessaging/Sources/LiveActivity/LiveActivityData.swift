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

/// Encapsulates data for Adobe Experience Platform integration with iOS Live Activities.
///
/// This struct provides the necessary identifiers and data for both managing and tracking Live
/// Activities through Adobe Experience Platform. Use this struct when implementing the
/// `LiveActivityAttributes` protocol.
@available(iOS 16.1, *)
public struct LiveActivityData: Codable {
    /// Unique identifier for managing and tracking an individual Live Activity in Adobe Experience Platform.
    var liveActivityID: String?

    /// Unique identifier for managing and tracking a broadcast Live Activity channel in Adobe Experience Platform.
    var channelID: String?

    /// Creates an `LiveActivityData` instance with the specified Live Activity ID.
    /// Use this method for Live Activities for an individual person.
    ///
    /// - Parameter liveActivityID: The unique identifier for the Live Activity.
    /// - Returns: A new `LiveActivityData` instance populated with the provided `liveActivityID`.
    public static func create(liveActivityID: String) -> LiveActivityData {
        LiveActivityData(liveActivityID: liveActivityID)
    }

    /// Creates an `LiveActivityData` instance with the specified Live Activity channel ID.
    /// Use this method for Live Activities broadcast to subscribers of a channel.
    ///
    /// - Parameter channelID: The unique identifier for the Live Activity channel, used for broadcast push notifications.
    /// - Returns: A new `LiveActivityData` instance populated with the provided `channelID`.
    public static func create(channelID: String) -> LiveActivityData {
        LiveActivityData(channelID: channelID)
    }
}
