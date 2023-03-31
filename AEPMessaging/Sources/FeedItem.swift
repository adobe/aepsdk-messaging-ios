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
    private var scopeDetails: [String: Any] = [:]
    
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
    
    /// Represents when this feed item expires. Represented in seconds since January 1, 1970
    public var expiryDate: Int
    
    /// Contains additional key-value pairs associated with this feed item
    public var meta: [String: Any]?
    
    /// Contains scope details for reporting
    public internal(set) var details: [String: Any] {
        set(newScopeDetails) {
            scopeDetails = newScopeDetails
        }
        get {
            return scopeDetails
        }
    }
    
    public init(title: String, body: String, imageUrl: String? = nil, actionUrl: String? = nil, actionTitle: String? = nil, publishedDate: Int, expiryDate: Int, meta: [String : Any]? = nil) {
        self.title = title
        self.body = body
        self.imageUrl = imageUrl
        self.actionUrl = actionUrl
        self.actionTitle = actionTitle
        self.publishedDate = publishedDate
        self.expiryDate = expiryDate
        self.meta = meta
    }
    
    enum CodingKeys: String, CodingKey {
        case title
        case body
        case imageUrl
        case actionUrl
        case actionTitle
        case publishedDate
        case expiryDate
        case meta
        case scopeDetails
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        title = try values.decode(String.self, forKey: .title)
        body = try values.decode(String.self, forKey: .body)
        imageUrl = try? values.decode(String.self, forKey: .imageUrl)
        actionUrl = try? values.decode(String.self, forKey: .actionUrl)
        actionTitle = try? values.decode(String.self, forKey: .actionTitle)
        publishedDate = try values.decode(Int.self, forKey: .publishedDate)
        expiryDate = try values.decode(Int.self, forKey: .expiryDate)
        let codableMeta = try? values.decode([String: AnyCodable].self, forKey: .meta)
        meta = codableMeta?.mapValues {
            guard let value = $0.value else {
                return ""
            }
            return value
        }
        let anyCodableDetailsDict = try? values.decode([String: AnyCodable].self, forKey: .scopeDetails)
        scopeDetails = AnyCodable.toAnyDictionary(dictionary: anyCodableDetailsDict) ?? [:]
    }
}

// MARK: - Encodable support
extension FeedItem {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(body, forKey: .body)
        try? container.encode(imageUrl, forKey: .imageUrl)
        try? container.encode(actionUrl, forKey: .actionUrl)
        try? container.encode(actionTitle, forKey: .actionTitle)
        try container.encode(publishedDate, forKey: .publishedDate)
        try container.encode(expiryDate, forKey: .expiryDate)        
        try? container.encode(AnyCodable.from(dictionary: meta) , forKey: .meta)
        try? container.encode(AnyCodable.from(dictionary: scopeDetails), forKey: .scopeDetails)
    }
    
    static func from(data: [String: Any]?, scopeDetails: [String: AnyCodable]? = nil) -> FeedItem? {
        guard data != nil else {
            return nil
        }
        
        var feedData = data ?? [:]
        if let scopeDetails = scopeDetails,
           !scopeDetails.isEmpty,
           let scopeDetailsAnyDict = AnyCodable.toAnyDictionary(dictionary: scopeDetails) {
            feedData["scopeDetails"] = scopeDetailsAnyDict
        }
            
        guard let jsonData = try? JSONSerialization.data(withJSONObject: feedData as Any) else {
            return nil
        }
        return try? JSONDecoder().decode(FeedItem.self, from: jsonData)
    }
}
