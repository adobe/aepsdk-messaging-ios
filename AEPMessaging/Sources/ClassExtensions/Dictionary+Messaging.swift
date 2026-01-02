/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import AEPCore
import Foundation

extension Dictionary where Key == String, Value == Any {
    /// Merges the values of `rhs` into `self`, preferring values in `rhs` when there is conflict.
    /// - Parameter rhs: a `[String: Any]` that will have its values merged into `self`.
    mutating func mergeXdm(rhs: [String: Any]) {
        merge(rhs) { _, new in new }
    }
    
    /// Returns a pretty-printed JSON string representation of the dictionary.
    /// - Returns: A formatted JSON string, or nil if the dictionary cannot be serialized to JSON.
    var prettyPrintedJson: String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted, .sortedKeys]),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        return jsonString
    }
}

extension Dictionary {
    mutating func addArray<S: Sequence>(_ sequence: S, forKey key: Key) where Value == [S.Element] {
        guard let value = sequence as? [S.Element], !value.isEmpty else {
            return
        }
        self[key] == nil ? self[key] = value : self[key]?.append(contentsOf: sequence)
    }

    mutating func add<T>(_ element: T, forKey key: Key) where Value == [T] {
        self[key] == nil ? self[key] = [element] : self[key]?.append(element)
    }
}
