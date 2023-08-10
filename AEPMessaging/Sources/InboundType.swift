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

/// Enum representing the supported Inbound content types.
@objc(AEPInboundType)
public enum InboundType: Int, Codable {
    /// Unknown inbound type
    case unknown = 0

    /// Feed Item
    case feed = 1

    /// InApp
    case inapp = 2

    /// Initializes InboundType with the provided content schema string.
    /// - Parameter format: Inbound content schema string
    init(from schema: String) {
        switch schema {
        case MessagingConstants.Event.Data.Values.Inbound.SCHEMA_FEED_ITEM:
            self = .feed

        case MessagingConstants.Event.Data.Values.Inbound.SCHEMA_IAM:
            self = .inapp

        default:
            self = .unknown
        }
    }

    /// Returns the content schema string of `InboundType`.
    /// - Returns: A string representing the Inbound content schema.
    public func toString() -> String {
        switch self {
        case .feed:
            return MessagingConstants.Event.Data.Values.Inbound.SCHEMA_FEED_ITEM
        case .inapp:
            return MessagingConstants.Event.Data.Values.Inbound.SCHEMA_IAM
        default:
            return ""
        }
    }
}
