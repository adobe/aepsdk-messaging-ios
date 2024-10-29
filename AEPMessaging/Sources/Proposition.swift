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
    var scopeDetails: [String: Any]

    /// Priority of the `Proposition` entered in the AJO UI for the corresponding campaign
    public var priority: Int {
        if let scopeDetails = scopeDetails as? [String: AnyCodable] {
            guard let activity = scopeDetails[MessagingConstants.Event.Data.Key.Personalization.ACTIVITY]?.dictionaryValue else {
                return 0
            }
            return activity[MessagingConstants.Event.Data.Key.Personalization.PRIORITY] as? Int ?? 0
        } else if let activity = scopeDetails[MessagingConstants.Event.Data.Key.Personalization.ACTIVITY] as? [String: Any] {
            return activity[MessagingConstants.Event.Data.Key.Personalization.PRIORITY] as? Int ?? 0
        } else {
            return 0
        }
    }

    /// Array containing proposition decision items
    private let propositionItems: [PropositionItem]

    public lazy var items: [PropositionItem] = {
        for item in propositionItems {
            item.proposition = self
        }
        return propositionItems
    }()

    enum CodingKeys: String, CodingKey {
        case id
        case scope
        case scopeDetails
        case items
    }

    init(uniqueId: String, scope: String, scopeDetails: [String: Any], items: [PropositionItem]) {
        self.uniqueId = uniqueId
        self.scope = scope
        self.scopeDetails = scopeDetails
        propositionItems = items
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        uniqueId = try container.decode(String.self, forKey: .id)
        scope = try container.decode(String.self, forKey: .scope)
        let codableScopeDetails = try? container.decode([String: AnyCodable].self, forKey: .scopeDetails)
        scopeDetails = AnyCodable.toAnyDictionary(dictionary: codableScopeDetails) ?? [:]
        guard !scopeDetails.isEmpty else {
            throw DecodingError.dataCorruptedError(forKey: CodingKeys.scopeDetails, in: container, debugDescription: "Scope details is corrupted and cannot be decoded.")
        }
        let tempItems = (try? container.decode([PropositionItem].self, forKey: .items))
        propositionItems = tempItems ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(uniqueId, forKey: .id)
        try container.encode(scope, forKey: .scope)
        try container.encode(AnyCodable.from(dictionary: scopeDetails), forKey: .scopeDetails)
        try container.encode(items, forKey: .items)
    }

    override public func isEqual(_ object: Any?) -> Bool {
        activityId == (object as? Proposition)?.activityId
    }
}

extension Proposition {
    /// scopeDetails is sometimes a `[String, Any]` and other times a `[String, AnyCodable]` - need to account for both
    var activityId: String {
        if let scopeDetails = scopeDetails as? [String: AnyCodable] {
            guard let activity = scopeDetails[MessagingConstants.Event.Data.Key.Personalization.ACTIVITY]?.dictionaryValue else {
                return ""
            }
            return activity[MessagingConstants.Event.Data.Key.Personalization.ID] as? String ?? ""
        } else if let activity = scopeDetails[MessagingConstants.Event.Data.Key.Personalization.ACTIVITY] as? [String: Any] {
            return activity[MessagingConstants.Event.Data.Key.Personalization.ID] as? String ?? ""
        } else {
            return ""
        }
    }

    /// rank is an ordinal value computed by IDS, used for prioritization
    /// it is expected that IDS will always return a value for rank
    /// a default value of -1 is used in the absense of rank in the IDS response and should be considered an error state
    var rank: Int {
        if let scopeDetails = scopeDetails as? [String: AnyCodable] {
            return scopeDetails[MessagingConstants.Event.Data.Key.Personalization.RANK]?.intValue ?? -1
        } else {
            return scopeDetails[MessagingConstants.Event.Data.Key.Personalization.RANK] as? Int ?? -1
        }
    }
}
