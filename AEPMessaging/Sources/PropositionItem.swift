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

import AEPCore
import AEPServices
import Foundation

@objc(AEPPropositionItem)
@objcMembers
public class PropositionItem: NSObject, Codable {
    /// Unique PropositionItem identifier
    public let uniqueId: String

    /// PropositionItem schema string
    public let schema: SchemaType

    /// PropositionItem data content in its raw format - either String or [String: Any]
    public let content: [String: Any]?

    /// Weak reference to Proposition instance
    weak var proposition: Proposition?

    enum CodingKeys: String, CodingKey {
        case id
        case schema
        case data
    }

    init(uniqueId: String, schema: String, content: [String: Any]?) {
        self.uniqueId = uniqueId
        self.schema = SchemaType(from: schema)
        self.content = content
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uniqueId = try container.decode(String.self, forKey: .id)
        schema = SchemaType(from: try container.decode(String.self, forKey: .schema))
        let codableContent = try? container.decode([String: AnyCodable].self, forKey: .data)
        content = codableContent?.asDictionary()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(uniqueId, forKey: .id)
        try container.encode(schema, forKey: .schema)
        try container.encode(AnyCodable.from(dictionary: content), forKey: .data)
    }
}

public extension PropositionItem {
    static func fromRuleConsequence(_ consequence: RuleConsequence) -> PropositionItem? {
        guard let detailsData = try? JSONSerialization.data(withJSONObject: consequence.details, options: .prettyPrinted) else {
            return nil
        }
        return try? JSONDecoder().decode(PropositionItem.self, from: detailsData)
    }
        
    func getTypedData<T>(_ type: T.Type) -> T? where T : Decodable {
        guard let content = content,
              let contentAsData = try? JSONSerialization.data(withJSONObject: content) else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Unable to get typed data for proposition item - could not convert 'data' field to type 'Data'.")
            return nil
        }
        do {
            return try JSONDecoder().decode(type, from: contentAsData)
        } catch {
            print("error \(error.localizedDescription)")
            return nil
        }
    }
    
    var jsonContent: [String: Any]? {
        guard let jsonItem = getTypedData(JsonContentSchemaData.self) else {
            return nil
        }
        
        return jsonItem.content.asDictionary()
    }
    
    var htmlContent: String? {
        guard let htmlItem = getTypedData(HtmlContentSchemaData.self) else {
            return nil
        }
        
        return htmlItem.content
    }
    
    internal var inappSchemaData: InAppSchemaData? {
        guard schema == .inapp else {
            return nil
        }
        return getTypedData(InAppSchemaData.self)
    }
    
    internal var feedItemSchemaData: FeedItemSchemaData? {
        guard schema == .feed else {
            return nil
        }
        return getTypedData(FeedItemSchemaData.self)
    }
    
}
