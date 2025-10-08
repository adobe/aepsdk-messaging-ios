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
    typealias AttributeType = String
    typealias ID = String

    // MARK: - Protocols

    /// A type that can be initialized with no arguments.
    protocol DefaultInitializable {
        init()
    }

    /// A type that defines a reference date used to determine expiration based on a TTL.
    protocol Expirable {
        var referenceDate: Date { get }
    }

    /// A type that exposes a dictionary-backed storage keyed by `ID`, with `Element` values.
    /// Used for types that support Codable persistence and default initialisation.
    protocol DictionaryBacked: Codable, DefaultInitializable {
        associatedtype Element
        var storage: [ID: Element] { get set }
    }

    // MARK: - Element structs

    struct ChannelActivity: Codable, Equatable, Expirable {
        let attributeType: String
        let startedAt: Date

        // Expirable conformance
        var referenceDate: Date { startedAt }
    }

    struct PushToStartToken: Codable, Equatable {
        let firstIssued: Date
        let token: String
    }

    struct UpdateToken: Codable, Equatable, Expirable {
        let attributeType: String
        let firstIssued: Date
        let token: String

        // Expirable conformance
        var referenceDate: Date { firstIssued }
    }

    // MARK: - Map structs

    struct ChannelMap: Codable, DefaultInitializable, DictionaryBacked {
        var channels: [ID: ChannelActivity]

        // DictionaryBacked conformance
        var storage: [ID: ChannelActivity] {
            get { channels }
            set { channels = newValue }
        }

        // DefaultInitializable conformance
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

        // DictionaryBacked conformance
        var storage: [ID: UpdateToken] {
            get { tokens }
            set { tokens = newValue }
        }

        // DefaultInitializable conformance
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
    struct PushToStartTokenMap: Codable, DefaultInitializable, DictionaryBacked {
        var tokens: [AttributeType: PushToStartToken]

        // DictionaryBacked conformance
        var storage: [AttributeType: PushToStartToken] {
            get { tokens }
            set { tokens = newValue }
        }

        // DefaultInitializable conformance
        init() {
            tokens = [:]
        }
    }
}
