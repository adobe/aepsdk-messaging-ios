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

/// Encapsulates data for Adobe Experience Platform integration with iOS Live Activities.
///
/// This struct provides the necessary identifiers and data for both managing and tracking Live
/// Activities through Adobe Experience Platform. Use this struct when implementing the
/// `LiveActivityAttributes` protocol.
@available(iOS 16.1, *)
public struct LiveActivityData: Codable {
    /// Unique identifier for managing and tracking a broadcast Live Activity channel in Adobe Experience Platform.
    public let channelID: String?

    /// Unique identifier for managing and tracking an individual Live Activity in Adobe Experience Platform.
    public let liveActivityID: String?

    /// Defines whether the Live Activity was started locally by the app or remotely via a push-to-start notification.
    public let origin: LiveActivityOrigin?

    /// Initializes a `LiveActivityData` instance with the specified broadcast channel ID.
    /// Use this initializer for Live Activities broadcast to subscribers of a channel.
    ///
    /// - Parameter channelID: The unique identifier for the Live Activity broadcast channel.
    public init(channelID: String) {
        self.channelID = channelID
        self.liveActivityID = nil
        self.origin = .local
    }

    /// Initializes a `LiveActivityData` instance with the specified Live Activity ID.
    /// Use this initializer for Live Activities targeted at an individual user.
    ///
    /// - Parameter liveActivityID: The unique identifier for the Live Activity.
    public init(liveActivityID: String) {
        self.channelID = nil
        self.liveActivityID = liveActivityID
        self.origin = .local
    }
}
