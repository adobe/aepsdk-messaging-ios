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

@objc(AEPProposition)
@objcMembers
public class Proposition: NSObject, Codable {
    /// Unique proposition identifier
    public let uniqueId: String
 
     /// Scope string
    public let scope: String
 
    /// Scope details dictionary
    private var scopeDetails: [String: Any]
 
    /// Array containing proposition decision items
    private let propositionItems: [PropositionItem]
  
    public lazy var items: [PropositionItem] = {
        propositionItems.forEach {
            $0.proposition = self
        }
        return propositionItems
    }()
 
    enum CodingKeys: String, CodingKey {
        case id
        case scope
        case scopeDetails
        case items
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        uniqueId = try container.decode(String.self, forKey: .id)
        scope = try container.decode(String.self, forKey: .scope)
        let anyCodableDict = try? container.decode([String: AnyCodable].self, forKey: .scopeDetails)
        scopeDetails = AnyCodable.toAnyDictionary(dictionary: anyCodableDict) ?? [:]
        propositionItems = (try? container.decode([PropositionItem].self, forKey: .items)) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(uniqueId, forKey: .id)
        try container.encode(scope, forKey: .scope)
        try container.encode(AnyCodable.from(dictionary: scopeDetails), forKey: .scopeDetails)
        try container.encode(items, forKey: .items)
    }
}
