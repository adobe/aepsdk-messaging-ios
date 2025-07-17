/*
 Copyright 2025 Adobe. All rights reserved.
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

/// Represents the schema-data object for
/// `https://ns.adobe.com/personalization/eventHistoryOperation`
@objc(AEPEventHistoryOperationSchemaData)
@objcMembers
public class EventHistoryOperationSchemaData: NSObject, Codable {
    /// “operation” field – qualify / unqualify / disqualify …
    public let operation: String

    /// Whatever object is stored under “content”
    /// (usually a dictionary containing messageId, eventType …)
    public let content: [String: AnyCodable]

    enum CodingKeys: String, CodingKey {
        case content
        case operation
    }
}

extension EventHistoryOperationSchemaData {
    /// Convenience accessors -------------------------------------------------

    /// eventHistoryOperation.content.messageId
    var messageId: String? {
        content[MessagingConstants.Event.History.Mask.MESSAGE_ID]?.stringValue
    }

    /// eventHistoryOperation.content.eventType
    var eventType: String? {
        content[MessagingConstants.Event.History.Mask.EVENT_TYPE]?.stringValue
    }
}
