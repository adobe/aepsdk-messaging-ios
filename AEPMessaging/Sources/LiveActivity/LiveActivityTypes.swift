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

enum LiveActivity {
    /// A type that can be initialized with no arguments.
    protocol DefaultInitializable {
        init()
    }

    typealias AttributeTypeName = String
    typealias ID = String

    struct Token: Codable, Equatable {
        var tokenFirstIssued: Date?
        var token: String
    }

    /// A data structure representing a mapping of Live Activity update tokens,
    /// organized by attribute type and live activity ID.
    ///
    /// The structure of this dictionary is:
    /// ```json
    /// {
    ///     "<LiveActivityAttributeType>": {
    ///         "<LiveActivityID>": {
    ///             "tokenFirstIssued": "<Date or null>",
    ///             "token": "<String>"
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// Example:
    /// ```json
    /// {
    ///     "DrinkOrderTrackerActivity": {
    ///         "order123": {
    ///             "tokenFirstIssued": "2025-04-30T10:00:00Z",
    ///             "token": "abc123"
    ///         }
    ///     }
    /// }
    /// ```
    struct UpdateTokenMap: Codable, DefaultInitializable {
        var tokens: [AttributeTypeName: [ID: Token]]

        init() {
            self.tokens = [:]
        }
    }

    /// Represents a mapping from Live Activity attribute types to their corresponding push-to-start tokens.
    ///
    /// The structure of this dictionary is:
    /// ```json
    /// {
    ///     "<LiveActivityAttributeType>": "<token>"
    /// }
    /// ```
    ///
    /// Example:
    /// ```json
    /// {
    ///     "DrinkOrderTrackerActivity": "abc123",
    ///     "FoodOrderTrackerActivity": "def456"
    /// }
    /// ```
    struct PushToStartTokenMap: Codable, DefaultInitializable {
        var tokens: [AttributeTypeName: Token]

        init() {
            self.tokens = [:]
        }
    }
}
