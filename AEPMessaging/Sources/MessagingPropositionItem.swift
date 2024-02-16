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

/// A `MessagingPropositionItem` object represents a personalization JSON object returned by Konductor
/// In its JSON form, it has the following properties:
/// - `id`
/// - `schema`
/// - `data`
/// This contents of `data` will be determined by the provided `schema`.
/// This class provides helper access to get strongly typed content - e.g. `getTypedData`
@objc(AEPMessagingPropositionItem)
@objcMembers
public class MessagingPropositionItem: NSObject, Codable {
    /// Unique identifier for this `MessagingPropositionItem`
    /// contains value for `id` in JSON
    public let itemId: String

    /// `MessagingPropositionItem` schema string
    /// contains value for `schema` in JSON
    public let schema: SchemaType

    /// `MessagingPropositionItem` data as dictionary
    /// contains value for `data` in JSON
    public let itemData: [String: Any]

    /// Weak reference to Proposition instance
    weak var proposition: MessagingProposition?

    enum CodingKeys: String, CodingKey {
        case id
        case schema
        case data
    }

    init(itemId: String, schema: SchemaType, itemData: [String: Any]) {
        self.itemId = itemId
        self.schema = schema
        self.itemData = itemData
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        itemId = try container.decode(String.self, forKey: .id)
        schema = try SchemaType(from: container.decode(String.self, forKey: .schema))
        let codableItemData = try container.decode([String: AnyCodable].self, forKey: .data)
        itemData = AnyCodable.toAnyDictionary(dictionary: codableItemData) ?? [:]
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(itemId, forKey: .id)
        try container.encode(schema.toString(), forKey: .schema)
        try container.encode(AnyCodable.from(dictionary: itemData), forKey: .data)
    }
}

public extension MessagingPropositionItem {
    /// Tracks interaction with the given proposition item.
    ///
    /// - Parameter eventType: an enum specifying event type for the interaction.
    func track(eventType: MessagingEdgeEventType) {
        guard let propositionInteractionXdm = generateInteractionXdm(forEventType: eventType) else {
            Log.debug(label: MessagingConstants.LOG_TAG,
                      "Cannot track proposition interaction for item \(itemId), could not generate interactions XDM.")
            return
        }

        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.TRACK_PROPOSITIONS: true,
            MessagingConstants.Event.Data.Key.PROPOSITION_INTERACTION: propositionInteractionXdm
        ]

        let event = Event(name: MessagingConstants.Event.Name.TRACK_PROPOSITIONS,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)

        MobileCore.dispatch(event: event)
    }

    /// Creates a dictionary containing XDM data for interaction with the given proposition item, for the provided event type.
    ///
    /// If the proposition reference within the item is released and no longer valid, the method returns `nil`.
    ///
    /// - Parameter eventType: an enum specifying event type for the interaction.
    /// - Returns A dictionary containing XDM data for the propositon interaction.
    func generateInteractionXdm(forEventType eventType: MessagingEdgeEventType) -> [String: Any]? {
        guard let proposition = proposition else {
            Log.debug(label: MessagingConstants.LOG_TAG,
                      "Cannot generate interaction XDM for item \(itemId), proposition reference is not available.")
            return nil
        }

        return MessagingPropositionInteraction(eventType: eventType, interaction: nil, propositionInfo: PropositionInfo.fromProposition(proposition), itemId: itemId).xdm
    }

    static func fromRuleConsequence(_ consequence: RuleConsequence) -> MessagingPropositionItem? {
        guard let detailsData = try? JSONSerialization.data(withJSONObject: consequence.details, options: .prettyPrinted) else {
            return nil
        }
        return try? JSONDecoder().decode(MessagingPropositionItem.self, from: detailsData)
    }

    static func fromRuleConsequenceEvent(_ event: Event) -> MessagingPropositionItem? {
        guard let id = event.schemaId, let schema = event.schemaType, let schemaData = event.schemaData else {
            return nil
        }

        return MessagingPropositionItem(itemId: id, schema: schema, itemData: schemaData)
    }

    var jsonContentDictionary: [String: Any]? {
        guard schema == .jsonContent, let jsonItem = getTypedData(JsonContentSchemaData.self) else {
            return nil
        }

        return jsonItem.getDictionaryValue
    }

    var jsonContentArray: [Any]? {
        guard schema == .jsonContent, let jsonItem = getTypedData(JsonContentSchemaData.self) else {
            return nil
        }

        return jsonItem.getArrayValue
    }

    var htmlContent: String? {
        guard schema == .htmlContent, let htmlItem = getTypedData(HtmlContentSchemaData.self) else {
            return nil
        }

        return htmlItem.content
    }

    var inappSchemaData: InAppSchemaData? {
        guard schema == .inapp else {
            return nil
        }
        return getTypedData(InAppSchemaData.self)
    }

    var feedItemSchemaData: FeedItemSchemaData? {
        guard schema == .feed else {
            return nil
        }
        return getTypedData(FeedItemSchemaData.self)
    }

    private func getTypedData<T>(_ type: T.Type) -> T? where T: Decodable {
        guard let itemDataAsData = try? JSONSerialization.data(withJSONObject: itemData)
        else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Unable to get typed data for proposition item - could not convert 'data' field to type 'Data'.")
            return nil
        }
        do {
            return try JSONDecoder().decode(type, from: itemDataAsData)
        } catch {
            print("error \(error.localizedDescription)")
            return nil
        }
    }
}
