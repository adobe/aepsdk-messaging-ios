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
    /// String representing a unique ID for this feed item
    public let id: String

    /// Contains key-value pairs representing content for this feed item
    public let content: [String: Any]

    /// Contains mime type for this feed item
    public let contentType: String

    /// Represents when this feed item went live. Represented in seconds since January 1, 1970
    public let publishedDate: Int
    
    /// Represents when this feed item expires. Represented in seconds since January 1, 1970
    public let expiryDate: Int

    /// Contains additional key-value pairs associated with this feed item
    public let meta: [String: Any]?

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case contentType
        case publishedDate
        case expiryDate
        case meta
    }

    /// Decode FeedItem instance from the given decoder.
    /// - Parameter decoder: The decoder to read feed item data from.
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)

        contentType = try values.decode(String.self, forKey: .contentType)
        if contentType != "application/json" {
            throw DecodingError.typeMismatch(FeedItem.self,
                                             DecodingError.Context(codingPath: decoder.codingPath,
                                                                   debugDescription: "FeedItem content is not of an expected type."))
        }

        let codableContentDict = try values.decodeIfPresent([String: AnyCodable].self, forKey: .content)
        content = AnyCodable.toAnyDictionary(dictionary: codableContentDict) ?? [:]

        publishedDate = try values.decode(Int.self, forKey: .publishedDate)
        expiryDate = try values.decode(Int.self, forKey: .expiryDate)

        let codableMetaDict = try values.decodeIfPresent([String: AnyCodable].self, forKey: .meta)
        meta = AnyCodable.toAnyDictionary(dictionary: codableMetaDict)
    }

    /// Encode FeedItem instance into the given encoder.
    /// - Parameter encoder: The encoder to write feed item data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(AnyCodable.from(dictionary: content), forKey: .content)
        try container.encode(contentType, forKey: .contentType)
        try container.encode(publishedDate, forKey: .publishedDate)
        try container.encode(expiryDate, forKey: .expiryDate)
        try container.encode(AnyCodable.from(dictionary: meta), forKey: .meta)
    }
}

// MARK: - Encodable support

extension FeedItem: Renderable {
    /// Plain-text title for the feed item
    var title: String {
        content[MessagingConstants.Event.Data.Key.FEED.TITLE] as? String ?? ""
    }

    /// Plain-text body representing the content for the feed item
    var body: String {
        content[MessagingConstants.Event.Data.Key.FEED.BODY] as? String ?? ""
    }

    /// String representing a URI that contains an image to be used for this feed item
    var imageUrl: String? {
        content[MessagingConstants.Event.Data.Key.FEED.IMAGE_URL] as? String
    }

    /// Contains a URL to be opened if the user interacts with the feed item
    var actionUrl: String? {
        content[MessagingConstants.Event.Data.Key.FEED.ACTION_URL] as? String
    }

    /// Required if `actionUrl` is provided. Text to be used in title of button or link in feed item
    var actionTitle: String? {
        content[MessagingConstants.Event.Data.Key.FEED.ACTION_TITLE] as? String
    }

    var surface: String? {
        meta?[MessagingConstants.Event.Data.Key.FEED.SURFACE] as? String
    }

    var feedName: String? {
        meta?[MessagingConstants.Event.Data.Key.FEED.FEED_NAME] as? String
    }

    func shouldRender() -> Bool {
        !title.isEmpty && !body.isEmpty
    }

    static func from(data: [String: Any]?, id: String, scopeDetails: [String: AnyCodable]? = nil) -> FeedItem? {
        guard data != nil else {
            return nil
        }

        var feedItemData = data ?? [:]
        feedItemData["id"] = id

        if let scopeDetails = scopeDetails,
           !scopeDetails.isEmpty,
           let scopeDetailsAnyDict = AnyCodable.toAnyDictionary(dictionary: scopeDetails) {
            feedItemData["scopeDetails"] = scopeDetailsAnyDict
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: feedItemData as Any) else {
            return nil
        }
        return try? JSONDecoder().decode(FeedItem.self, from: jsonData)
    }
}
