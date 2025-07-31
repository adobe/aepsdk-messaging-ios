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

import AEPServices
import Foundation

/// Represents the schema data object for
/// `https://ns.adobe.com/personalization/eventHistoryOperation`
@objc(AEPEventHistoryOperationSchemaData)
@objcMembers
public class EventHistoryOperationSchemaData: NSObject, Codable {
    /// `operation` field (ex: qualify, unqualify, or disqualify)
    public let operation: String

    /// Whatever object is stored under `content` (usually a dictionary containing messageId, eventType, etc)
    public let content: [String: AnyCodable]
}

extension EventHistoryOperationSchemaData {
    /// Convenience accessor for the message ID in `content`
    var messageId: String? {
        content[MessagingConstants.Event.History.OperationKeys.MESSAGE_ID]?.stringValue
    }

    /// Convenience accessor for the event type in `content`
    var eventType: String? {
        content[MessagingConstants.Event.History.OperationKeys.EVENT_TYPE]?.stringValue
    }
}
