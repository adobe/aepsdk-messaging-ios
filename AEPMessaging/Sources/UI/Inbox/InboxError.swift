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

/// An enum which describes different errors that InboxUI API's can return
@available(iOS 15.0, *)
public enum InboxError: Int, Error {
    public typealias RawValue = Int
    
    /// No propositions were returned for the specified surface
    case dataUnavailable = 1
    
    /// InboxSchemaData were not found in the propositions
    case inboxSchemaDataNotFound = 2
    
    /// Invalid inboxSchemaData schema or parsing failed
    case invalidInboxSchemaData = 3
    
    /// inbox creation failed due to internal error
    case inboxCreationFailed = 4
}

/// Extension to provide user-friendly error descriptions
@available(iOS 15.0, *)
extension InboxError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .dataUnavailable:
            return "No propositions available for the specified surface"
        case .inboxSchemaDataNotFound:
            return "InboxSchemaData not found in propositions"
        case .invalidInboxSchemaData:
            return "Invalid inboxSchemaData schema or parsing failed"
        case .inboxCreationFailed:
            return "Inbox creation failed due to internal error"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .dataUnavailable:
            return "The surface may not be configured or no campaigns are targeting it"
        case .inboxSchemaDataNotFound:
            return "The propositions do not contain valid InboxSchemaData"
        case .invalidInboxSchemaData:
            return "The inboxSchemaData is malformed or incompatible"
        case .inboxCreationFailed:
            return "An internal error occurred while creating the InboxUI"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .dataUnavailable:
            return "Verify the surface configuration and ensure campaigns are active"
        case .inboxSchemaDataNotFound:
            return "Check that the proposition contains inboxSchemaData in the expected format"
        case .invalidInboxSchemaData:
            return "Validate the InboxSchemaData JSON against the expected schema"
        case .inboxCreationFailed:
            return "Check logs for additional error details and retry the operation"
        }
    }
}
