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

import Foundation
import AEPServices

/// Represents the schema data object for inbox based on the exact JSON schema
@objc(AEPInboxSchemaData)
@objcMembers
@available(iOS 15.0, *)
public class InboxSchemaData: NSObject, Codable {
    /// Inbox settings containing all configuration
    public let content: InboxSettings
    
    /// Reference to the parent proposition item for tracking purposes
    weak var parent: PropositionItem?
    
    enum CodingKeys: String, CodingKey {
        case content
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode(InboxSettings.self, forKey: .content)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
    }
    
    /// Tracks interaction with the given Inbox.
    ///
    /// - Parameters
    ///     - interaction: a custom string value describing the interaction.
    ///     - eventType: an enum specifying event type for the interaction.
    func track(_ interaction: String? = nil, withEdgeEventType eventType: MessagingEdgeEventType) {
        guard let parent = parent else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Unable to track InboxSchemaData, parent proposition item is unavailable.")
            return
        }
        parent.track(interaction, withEdgeEventType: eventType)
    }
}
