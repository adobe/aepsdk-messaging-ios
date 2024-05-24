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

@available(*, deprecated, message: "Unused class 'Feed' will be removed in next major version update of AEPMessaging extension.")
@objc(AEPFeed)
@objcMembers
public class Feed: NSObject, Codable {
    /// Identification for this feed, represented by the AJO Surface URI used to retrieve it
    public let surface: Surface

    /// Friendly name for the feed, provided in the AJO UI
    public let name: String

    /// Array of `FeedItemSchemaData` that are members of this `Feed`
    public internal(set) var items: [FeedItemSchemaData]

    public init(name: String, surface: Surface, items: [FeedItemSchemaData]) {
        self.name = name
        self.surface = surface
        self.items = items
    }
}
