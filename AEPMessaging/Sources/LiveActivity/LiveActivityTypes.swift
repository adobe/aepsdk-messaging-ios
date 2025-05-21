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

    /// Anything that has a date TTL is compared against.
    protocol Expirable {
        var referenceDate: Date { get }
    }

    /// Anything that can expose its internal dictionary with `ID` keys, whose values are ``Expirable``.
    protocol DictionaryBacked: Codable, LiveActivity.DefaultInitializable {
        associatedtype Element: Expirable
        var storage: [LiveActivity.ID: Element] { get set }
    }

    typealias AttributeType = String
    typealias ID = String

    struct ChannelActivity: Codable, Equatable, Expirable {
        let attributeType: String
        let startedAt: Date

        // Expirable conformance
        var referenceDate: Date { startedAt }
    }

    struct PushToStartToken: Codable, Equatable {
        let firstIssued: Date
        let value: String
    }

    struct UpdateToken: Codable, Equatable, Expirable {
        let attributeType: String
        let firstIssued: Date
        let value: String

        // Expirable conformance
        var referenceDate: Date { firstIssued }
    }

    struct ChannelMap: Codable, DefaultInitializable, DictionaryBacked {
        var channels: [ID: ChannelActivity]

        // DictionaryBacked conformance
        var storage: [LiveActivity.ID: LiveActivity.ChannelActivity] {
            get { channels }
            set { channels = newValue }
        }

        init() {
            channels = [:]
        }
    }

    /// A data structure representing a mapping of Live Activity update tokens,
    /// organized by attribute type and live activity ID.
    ///
    /// The structure of this dictionary is:
    /// ```json
    /// {
    ///   "<LiveActivityID>": {
    ///     "attributeType": "<String>",
    ///     "firstIssued": "<Date>",
    ///     "token": "<String>"
    ///   }
    /// }
    /// ```
    ///
    /// Example:
    /// ```json
    /// {
    ///   "order123": {
    ///     "attributeType": "DrinkOrderTrackerActivity",
    ///     "firstIssued": "2025-04-30T10:00:00Z",
    ///     "token": "abc123"
    ///   },
    ///   "order456": {
    ///     "attributeType": "DrinkOrderTrackerActivity",
    ///     "firstIssued": "2025-04-30T11:00:00Z",
    ///     "token": "def456"
    ///   }
    /// }
    /// ```
    struct UpdateTokenMap: Codable, DefaultInitializable, DictionaryBacked {
        var tokens: [ID: UpdateToken]

        var storage: [LiveActivity.ID: LiveActivity.UpdateToken] {
            get { tokens }
            set { tokens = newValue }
        }

        init() {
            tokens = [:]
        }
    }

    /// Represents a mapping from Live Activity attribute types to their corresponding push-to-start tokens.
    ///
    /// The structure of this dictionary is:
    /// ```json
    /// {
    ///   "<LiveActivityAttributeType>": {
    ///     "firstIssued": "<Date>",
    ///     "token": "<String>"
    ///   }
    /// }
    /// ```
    ///
    /// Example:
    /// ```json
    /// {
    ///   "DrinkOrderTrackerActivity": {
    ///     "firstIssued": "2025-04-30T10:00:00Z",
    ///     "token": "abc123"
    ///   },
    ///   "FoodOrderTrackerActivity": {
    ///     "firstIssued": "2025-04-30T10:00:00Z",
    ///     "token": "def456"
    ///   }
    /// }
    /// ```
    struct PushToStartTokenMap: Codable, DefaultInitializable {
        var tokens: [AttributeType: PushToStartToken]

        init() {
            tokens = [:]
        }
    }
}
