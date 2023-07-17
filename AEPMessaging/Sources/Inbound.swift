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

@objc(AEPInbound)
@objcMembers
public class Inbound: NSObject, Codable {
     /// String representing a unique ID for this inbound item
    public let uniqueId: String
 
    /// Enum representing the inbound item type
    public let inboundType: InboundType
 
    /// Content for this inbound item e.g. inapp html string, or feed item JSON
    public let content: String
 
    /// Contains mime type for this inbound item
    public let contentType: String
 
    /// Represents when this inbound item went live. Represented in seconds since January 1, 1970
    public let publishedDate: Int
     
    /// Represents when this inbound item expires. Represented in seconds since January 1, 1970
    public let expiryDate: Int
 
    /// Contains additional key-value pairs associated with this inbound item
    public let meta: [String: Any]?
 
    enum CodingKeys: String, CodingKey {
        case id
        case inboundType
        case content
        case contentType
        case publishedDate
        case expiryDate
        case meta
    }
    
    /// Decode Inbound instance from the given decoder.
    /// - Parameter decoder: The decoder to read feed item data from.
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        uniqueId = try values.decode(String.self, forKey: .id)
        if let format = try? values.decode(String.self, forKey: .inboundType) {
            inboundType = InboundType(from: format)
        } else {
            // TODO - use regex to deduce inbound content format from the content string
            inboundType = .unknown
        }
        contentType = try values.decode(String.self, forKey: .contentType)
        publishedDate = try values.decode(Int.self, forKey: .publishedDate)
        expiryDate = try values.decode(Int.self, forKey: .expiryDate)
        let codableMeta = try? values.decode([String: AnyCodable].self, forKey: .meta)
        meta = codableMeta?.mapValues {
            guard let value = $0.value else {
                return ""
            }
            return value
        }
        
        let codableContent = try values.decode(AnyCodable.self, forKey: .content)
        if contentType == "application/json" {
            if
                let jsonData = codableContent.dictionaryValue,
                let encodedData = try? JSONSerialization.data(withJSONObject: jsonData),
                let inboundContent = String(data: encodedData, encoding: .utf8) {
                    content = inboundContent
                    return
                }
        } else {
            if let inboundContent = codableContent.stringValue {
                content = inboundContent
                return
            }
        }
        throw DecodingError.typeMismatch(Inbound.self,
                                         DecodingError.Context(codingPath: decoder.codingPath,
                                                               debugDescription: "Inbound content is not of an expected type."))
    }
    
    /// Encode Inbound instance into the given encoder.
    /// - Parameter encoder: The encoder to write feed item data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(uniqueId, forKey: .id)
        try container.encode(inboundType.toString(), forKey: .inboundType)
        try container.encode(content, forKey: .content)
        try container.encode(contentType, forKey: .contentType)
        try container.encode(publishedDate, forKey: .publishedDate)
        try container.encode(expiryDate, forKey: .expiryDate)
        try? container.encode(AnyCodable.from(dictionary: meta), forKey: .meta)
    }
}
 
public extension Inbound {
    // Decode content to a specific inbound type
    func decodeContent<T: Decodable>() -> T? {
        guard
            let jsonObject = content.data(using: .utf8),
            let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject)
        else {
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: jsonData)
    }
}
