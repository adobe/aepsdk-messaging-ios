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

@available(*, deprecated, message: "'ContentCard' will be removed in the next major version of AEPMessaging. Use `ContentCardSchemaData` instead.")
@objc(AEPContentCard)
@objcMembers
public class ContentCard: NSObject, Codable {
    /// Plain-text title for the content card
    public let title: String

    /// Plain-text body representing the content for the content card
    public let body: String

    /// String representing a URI that contains an image to be used for this content card
    public let imageUrl: String?

    /// Contains a URL to be opened if the user interacts with the content card
    public let actionUrl: String?

    /// Required if `actionUrl` is provided. Text to be used in title of button or link in content card
    public let actionTitle: String?

    /// Reference to parent ContentCardSchemaData instance
    var parent: ContentCardSchemaData?

    enum CodingKeys: String, CodingKey {
        case title
        case body
        case imageUrl
        case actionUrl
        case actionTitle
    }

    public init(title: String, body: String, imageUrl: String? = "", actionUrl: String? = "", actionTitle: String? = "") {
        self.title = title
        self.body = body
        self.imageUrl = imageUrl
        self.actionUrl = actionUrl
        self.actionTitle = actionTitle
    }

    /// Decode ContentCard instance from the given decoder.
    /// - Parameter decoder: The decoder to read content card data from.
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        title = try values.decode(String.self, forKey: .title)
        body = try values.decode(String.self, forKey: .body)
        imageUrl = try? values.decode(String.self, forKey: .imageUrl)
        actionUrl = try? values.decode(String.self, forKey: .actionUrl)
        actionTitle = try? values.decode(String.self, forKey: .actionTitle)
    }

    /// Encode ContentCard instance into the given encoder.
    /// - Parameter encoder: The encoder to write content card data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(title, forKey: .title)
        try container.encode(body, forKey: .body)
        try? container.encode(imageUrl, forKey: .imageUrl)
        try? container.encode(actionUrl, forKey: .actionUrl)
        try? container.encode(actionTitle, forKey: .actionTitle)
    }
}

@available(*, deprecated, message: "'ContentCard' will be removed in the next major version of AEPMessaging. Use `ContentCardSchemaData` instead.")
public extension ContentCard {
    /// Tracks interaction with the given content card.
    ///
    /// - Parameters
    ///     - interaction: a custom string value describing the interaction.
    ///     - eventType: an enum specifying event type for the interaction.
    func track(_ interaction: String? = nil, withEdgeEventType eventType: MessagingEdgeEventType) {
        guard let parent = parent else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Unable to track ContentCard, parent schema object is unavailable.")
            return
        }
        parent.track(interaction, withEdgeEventType: eventType)
    }
}
