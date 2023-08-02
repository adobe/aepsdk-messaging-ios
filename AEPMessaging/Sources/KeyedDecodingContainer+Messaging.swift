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

// MARK: KeyedDecodingContainer extension

extension KeyedDecodingContainer {
    private struct AnyDecodable: Decodable {}

    /// Decodes a value of the given type.
    ///
    /// - Parameter type: The type of value to decode.
    /// - Returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - Throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    func decode<T: Decodable>(_: [T].Type, forKey key: Key, ignoreInvalid: Bool = false) throws -> [T] {
        var container = try nestedUnkeyedContainer(forKey: key)
        var elements = [T]()

        if let count = container.count {
            elements.reserveCapacity(count)
        }

        while !container.isAtEnd {
            guard let element = try? container.decode(T.self) else {
                if ignoreInvalid == false {
                    throw DecodingError.typeMismatch(T.self, DecodingError.Context(codingPath: container.codingPath,
                                                                                   debugDescription: "Array element is not of an expected type."))
                }
                // advance index
                _ = try? container.decode(AnyDecodable.self)
                continue
            }
            elements.append(element)
        }
        return elements
    }
}
