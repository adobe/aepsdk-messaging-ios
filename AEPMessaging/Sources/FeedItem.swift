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

@objc(AEPFeedItem)
@objcMembers
public class FeedItem: NSObject, Codable {
    /// Plain-text title for the feed item
    public var title: String
    
    /// Plain-text body representing the content for the feed item
    public var body: String
    
    /// String representing a URI that contains an image to be used for this feed item
    public var imageUrl: String?
    
    /// Contains a URL to be opened if the user interacts with the feed item
    public var actionUrl: String?
    
    /// Required if `actionUrl` is provided. Text to be used in title of button or link in feed item
    public var actionTitle: String?
    
    /// Represents when this feed item went live. Represented in seconds since January 1, 1970
    public var publishedDate: Int
    
    /// Represents when this feed item exires. Represented in seconds since January 1, 1970
    public var expiryDate: Int
    
    /// Contains additional key-value pairs associated with this feed item
    public var meta: [String: AnyCodable]?
    
    public init(title: String, body: String, imageUrl: String? = nil, actionUrl: String? = nil, actionTitle: String? = nil, publishedDate: Int, expiryDate: Int, meta: [String : AnyCodable]? = nil) {
        self.title = title
        self.body = body
        self.imageUrl = imageUrl
        self.actionUrl = actionUrl
        self.actionTitle = actionTitle
        self.publishedDate = publishedDate
        self.expiryDate = expiryDate
        self.meta = meta
    }
}
