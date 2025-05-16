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

@testable import AEPMessaging

/// A simple mock token map type.
///
/// Stores a dictionary of string keys and values, and provides helpers
/// for conversion to and from dictionary representations, as expected by `TokenStoreBase`.
struct MockTokenMap: Codable, LiveActivity.DefaultInitializable, Equatable {
    private static let KEY = "values"

    /// The underlying dictionary storing token values.
    var values: [String: String]

    /// Creates a token map with the given key-value pairs.
    /// - Parameter values: The dictionary of tokens to initialize the map with.
    init(values: [String: String]) {
        self.values = values
    }

    // DefaultInitializable conformance
    /// Creates an empty token map.
    init() {
        values = [:]
    }

    /// Decodes a `MockTokenMap` from a dictionary representation.
    ///
    /// - Parameter dict: A dictionary expected to have a `"values"` key with a `[String: String]` value.
    /// - Returns: An initialized `MockTokenMap` if decoding succeeds, otherwise `nil`.
    static func from(_ dict: [String: Any]) -> MockTokenMap? {
        guard let raw = dict["values"] as? [String: String] else {
            return nil
        }
        return MockTokenMap(values: raw)
    }

    /// Encodes the token map as a dictionary suitable for persistence.
    ///
    /// - Returns: A dictionary with a `"values"` key containing the token pairs.
    func asDictionary() -> [String: Any]? {
        ["values": values]
    }
}
