/*
 Copyright 2024 Adobe. All rights reserved.
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

/// represents the schema data object for a content-card schema
@objc(AEPContentCardSchemaData)
@objcMembers
public class ContentCardSchemaData: NSObject, Codable {
    public let content: Any
    public let contentType: ContentType
    public let publishedDate: Int?
    public let expiryDate: Int?
    public let meta: [String: Any]?

    var parent: PropositionItem?
    
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

extension ContentCardSchemaData {
    /// ONLY USED FOR TESTING
    static func getEmpty() -> ContentCardSchemaData {
        ContentCardSchemaData()
    }
}

public extension ContentCardSchemaData {
    func getContentCard() -> ContentCard? {
        guard contentType == .applicationJson,
              let contentAsJsonData = try? JSONSerialization.data(withJSONObject: content, options: .prettyPrinted)
        else {
            return nil
        }
        
        guard let contentCard = try? JSONDecoder().decode(ContentCard.self, from: contentAsJsonData) else {
            return nil
        }

        contentCard.parent = self
        return contentCard
    }
    
    func track(_ interaction: String? = nil, withEdgeEventType eventType: MessagingEdgeEventType) {
        guard let parent = parent else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Unable to track FeedItemSchemaData, parent proposition item is unavailable.")
            return
        }
        parent.track(interaction, withEdgeEventType: eventType)
    }
}
