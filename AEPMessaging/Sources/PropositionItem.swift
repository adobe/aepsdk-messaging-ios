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

@objc(AEPPropositionItem)
@objcMembers
public class PropositionItem: NSObject, Codable {
    /// Unique PropositionItem identifier
    public let uniqueId: String

    /// PropositionItem schema string
    public let schema: String

    /// PropositionItem data content e.g. html or plain-text string or string containing image URL, JSON string
    public let content: String

    /// Weak reference to Proposition instance
    weak var proposition: Proposition?

    enum CodingKeys: String, CodingKey {
        case id
        case schema
        case data
    }

    enum DataKeys: String, CodingKey {
        case content
    }

    init(uniqueId: String, schema: String, content: String) {
        self.uniqueId = uniqueId
        self.schema = schema
        self.content = content
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uniqueId = try container.decode(String.self, forKey: .id)
        schema = try container.decode(String.self, forKey: .schema)

        let nestedContainer = try container.nestedContainer(keyedBy: DataKeys.self, forKey: .data)
        let codableContent = try nestedContainer.decode(AnyCodable.self, forKey: .content)
        if let contentString = codableContent.stringValue {
            content = contentString
        } else if let jsonData = codableContent.dictionaryValue {
            guard
                let encodedData = try? JSONSerialization.data(withJSONObject: jsonData),
                let contentString = String(data: encodedData, encoding: .utf8)
            else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath,
                                                                        debugDescription: "PropositionItem content dictionary is invalid."))
            }
            content = contentString
        } else {
            throw DecodingError.typeMismatch(PropositionItem.self,
                                             DecodingError.Context(codingPath: decoder.codingPath,
                                                                   debugDescription: "PropositionItem content is not of an expected type."))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(uniqueId, forKey: .id)
        try container.encode(schema, forKey: .schema)

        var nestedContainer = container.nestedContainer(keyedBy: DataKeys.self, forKey: .data)
        try nestedContainer.encode(content, forKey: .content)
    }
}

public extension PropositionItem {
    // Decode data content to generic inbound
    func decodeContent() -> Inbound? {
        guard let jsonData = content.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(Inbound.self, from: jsonData)
    }
}
