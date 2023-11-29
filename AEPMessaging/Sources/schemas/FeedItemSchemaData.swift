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

/// represents the schema data object for a feed item schema
@objc(AEPFeedItemSchemaData)
@objcMembers
public class FeedItemSchemaData: NSObject, Codable {
    public let content: Any
    public let contentType: ContentType
    public let publishedDate: Int?
    public let expiryDate: Int?
    public let meta: [String: Any]?

    enum CodingKeys: String, CodingKey {
        case content
        case contentType
        case publishedDate
        case expiryDate
        case meta
    }

    /// ONLY USED FOR TESTING
    override private init() {
        content = "plain-text content"
        contentType = .textPlain
        publishedDate = nil
        expiryDate = nil
        meta = nil
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        contentType = try ContentType(from: values.decode(String.self, forKey: .contentType))
        if contentType == .applicationJson {
            let codableContent = try values.decode([String: AnyCodable].self, forKey: .content)
            content = AnyCodable.toAnyDictionary(dictionary: codableContent) ?? [:]
        } else {
            content = try values.decode(String.self, forKey: .content)
        }
        publishedDate = try? values.decode(Int.self, forKey: .publishedDate)
        expiryDate = try? values.decode(Int.self, forKey: .expiryDate)
        let codableMeta = try? values.decode([String: AnyCodable].self, forKey: .meta)
        meta = AnyCodable.toAnyDictionary(dictionary: codableMeta)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(contentType.toString(), forKey: .contentType)
        if contentType == .applicationJson {
            try container.encode(AnyCodable.from(dictionary: content as? [String: Any]), forKey: .content)
        } else {
            try container.encode(content as? String, forKey: .content)
        }
        try container.encode(publishedDate, forKey: .publishedDate)
        try container.encode(expiryDate, forKey: .expiryDate)
        try container.encode(AnyCodable.from(dictionary: meta), forKey: .meta)
    }
}

extension FeedItemSchemaData {
    /// ONLY USED FOR TESTING
    static func getEmpty() -> FeedItemSchemaData {
        FeedItemSchemaData()
    }

    public func getFeedItem() -> FeedItem? {
        guard contentType == .applicationJson,
              let contentAsJsonData = try? JSONSerialization.data(withJSONObject: content, options: .prettyPrinted)
        else {
            return nil
        }

        return try? JSONDecoder().decode(FeedItem.self, from: contentAsJsonData)
    }
}
