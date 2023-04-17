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

import AEPServices
import Foundation

@objc(AEPFeed)
@objcMembers
public class Feed: NSObject, Codable {
    /// Identification for this feed, represented by the AJO Surface URI used to retrieve it
    public let surfaceUri: String

    /// Friendly name for the feed, provided in the AJO UI
    public let name: String

    /// Array of `FeedItem` that are members of this `Feed`
    public internal(set) var items: [FeedItem]

    public init(surfaceUri: String, items: [FeedItem]) {
        self.surfaceUri = surfaceUri
        self.items = items
        name = self.items.first?.meta?[MessagingConstants.Event.Data.Key.FEED.FEED_NAME] as? String ?? ""
    }
}
