///*
// Copyright 2023 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
// */
//
//import AEPServices
//import Foundation
//
//@objc(AEPInbound)
//@objcMembers
//public class Inbound: NSObject, Codable {
//    /// String representing a unique ID for this inbound item
//    public let propositionId: String
//
//    /// Enum representing the inbound item type
//    public let inboundType: InboundType
//
//    /// Content for this inbound item e.g. inapp html string, or feed item JSON
//    public let content: String
//
//    /// Contains mime type for this inbound item
//    public let contentType: String
//
//    /// Represents when this inbound item went live. Represented in seconds since January 1, 1970
//    public let publishedDate: Int
//
//    /// Represents when this inbound item expires. Represented in seconds since January 1, 1970
//    public let expiryDate: Int
//
//    /// Contains additional key-value pairs associated with this inbound item
//    public let meta: [String: Any]?
//
//    enum CodingKeys: String, CodingKey {
//        case id
//        case schema
//        case data
//    }
//
//    enum DataKeys: String, CodingKey {
//        case content
//        case contentType
//        case publishedDate
//        case expiryDate
//        case meta
//    }
//
//    /// Decode Inbound instance from the given decoder.
//    /// - Parameter decoder: The decoder to read feed item data from.
//    public required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//
//        uniqueId = try container.decode(String.self, forKey: .id)
//        inboundType = try InboundType(from: container.decode(String.self, forKey: .schema))
//
//        let nestedContainer = try container.nestedContainer(keyedBy: DataKeys.self, forKey: .data)
//        contentType = try nestedContainer.decode(String.self, forKey: .contentType)
//        publishedDate = try nestedContainer.decode(Int.self, forKey: .publishedDate)
//        expiryDate = try nestedContainer.decode(Int.self, forKey: .expiryDate)
//        let codableMeta = try? nestedContainer.decode([String: AnyCodable].self, forKey: .meta)
//        meta = codableMeta?.mapValues {
//            guard let value = $0.value else {
//                return ""
//            }
//            return value
//        }
//
//        let codableContent = try nestedContainer.decode(AnyCodable.self, forKey: .content)
//        if let inboundContent = codableContent.stringValue {
//            content = inboundContent
//        } else if let jsonData = codableContent.dictionaryValue {
//            guard
//                let encodedData = try? JSONSerialization.data(withJSONObject: jsonData),
//                let inboundContent = String(data: encodedData, encoding: .utf8)
//            else {
//                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath,
//                                                                        debugDescription: "Inbound content dictionary is invalid."))
//            }
//            content = inboundContent
//        } else {
//            throw DecodingError.typeMismatch(Inbound.self,
//                                             DecodingError.Context(codingPath: decoder.codingPath,
//                                                                   debugDescription: "Inbound content is not of an expected type."))
//        }
//    }
//
//    /// Encode Inbound instance into the given encoder.
//    /// - Parameter encoder: The encoder to write feed item data to.
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(uniqueId, forKey: .id)
//        try container.encode(inboundType.toString(), forKey: .schema)
//
//        var nestedContainer = container.nestedContainer(keyedBy: DataKeys.self, forKey: .data)
//        try nestedContainer.encode(content, forKey: .content)
//        try nestedContainer.encode(contentType, forKey: .contentType)
//        try nestedContainer.encode(publishedDate, forKey: .publishedDate)
//        try nestedContainer.encode(expiryDate, forKey: .expiryDate)
//        try? nestedContainer.encode(AnyCodable.from(dictionary: meta), forKey: .meta)
//    }
//}
//
//public extension Inbound {
//    static func from(consequenceDetail: [String: Any]?, id: String) -> Inbound? {
//        guard var consequenceDetail = consequenceDetail else {
//            return nil
//        }
//
//        consequenceDetail["id"] = id
//        guard let jsonData = try? JSONSerialization.data(withJSONObject: consequenceDetail as Any) else {
//            return nil
//        }
//        return try? JSONDecoder().decode(Inbound.self, from: jsonData)
//    }
//
//    // Decode content to a specific inbound type
//    func decodeContent<T>(_ type: T.Type) -> T? where T: Decodable {
//        guard let jsonData = content.data(using: .utf8) else {
//            return nil
//        }
//        return try? JSONDecoder().decode(type, from: jsonData)
//    }
//}
