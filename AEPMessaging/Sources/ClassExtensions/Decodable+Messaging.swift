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

// TODO: remove this once the Core version is available
public extension Decodable {
    /// Attempts to decode `Self` from a `[String: Any]` dictionary.
    /// - Parameters:
    ///   - dictionary: the dictionary to decode from
    ///   - dateDecodingStrategy: how to decode `Date` values (default: `.deferredToDate`)
    /// - Returns: an instance of `Self` if decoding succeeds, or `nil`
    static func from(
        _ dictionary: [String: Any],
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate
    ) -> Self? {
        // Make sure it’s valid JSON and serialize it back to Data
        guard JSONSerialization.isValidJSONObject(dictionary),
              let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []) else {
            return nil
        }

        // Decode into type
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy
        return try? decoder.decode(Self.self, from: data)
    }
}
