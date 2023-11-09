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

import Foundation

/// Enum representing  schema types.
@objc(AEPSchemaType)
public enum SchemaType: Int, Codable {
    case unknown = 0
    case htmlContent = 1
    case jsonContent = 2
    case ruleset = 3
    case inapp = 4
    case feed = 5
    case nativeAlert = 6
    case defaultContent = 7

    /// Initializes SchemaType with the provided content schema string
    /// - Parameter schema: SchemaType content schema string
    init(from schema: String) {
        switch schema {
        case MessagingConstants.PersonalizationSchemas.HTML_CONTENT:
            self = .htmlContent

        case MessagingConstants.PersonalizationSchemas.JSON_CONTENT:
            self = .jsonContent

        case MessagingConstants.PersonalizationSchemas.RULESET_ITEM:
            self = .ruleset

        case MessagingConstants.PersonalizationSchemas.IN_APP:
            self = .inapp

        case MessagingConstants.PersonalizationSchemas.FEED_ITEM:
            self = .feed

        case MessagingConstants.PersonalizationSchemas.NATIVE_ALERT:
            self = .nativeAlert

        case MessagingConstants.PersonalizationSchemas.DEFAULT_CONTENT:
            self = .defaultContent

        default:
            self = .unknown
        }
    }

    /// Returns the schema type string.
    /// - Returns: A string representing the schema type.
    public func toString() -> String {
        switch self {
        case .htmlContent:
            return MessagingConstants.PersonalizationSchemas.HTML_CONTENT
        case .jsonContent:
            return MessagingConstants.PersonalizationSchemas.JSON_CONTENT
        case .ruleset:
            return MessagingConstants.PersonalizationSchemas.RULESET_ITEM
        case .inapp:
            return MessagingConstants.PersonalizationSchemas.IN_APP
        case .feed:
            return MessagingConstants.PersonalizationSchemas.FEED_ITEM
        case .nativeAlert:
            return MessagingConstants.PersonalizationSchemas.NATIVE_ALERT
        case .defaultContent:
            return MessagingConstants.PersonalizationSchemas.DEFAULT_CONTENT
        default:
            return ""
        }
    }
}
