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

/// represents the schema data object for a ruleset schema
@objc(AEPRulesetSchemaData)
@objcMembers
public class RulesetSchemaData: NSObject, Codable {
    public let version: Int
    public let rules: [[String: Any]]
    
    enum CodingKeys: String, CodingKey {
        case version
        case rules
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        version = try values.decode(Int.self, forKey: .version)
        let codableRulesArray = try values.decode([[String: AnyCodable]].self, forKey: .rules)
        rules = codableRulesArray.compactMap { AnyCodable.toAnyDictionary(dictionary: $0) }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(version, forKey: .version)
        try container.encode(rules.compactMap { AnyCodable.from(dictionary: $0) }, forKey: .rules)
    }
}
