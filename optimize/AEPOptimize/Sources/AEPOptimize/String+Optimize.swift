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

import Foundation

// MARK: String extension

extension String {
    /// Encode a string to base-64 representation
    /// - Returns: base-64 encoded string
    func base64Encode() -> String? {
        if isEmpty {
            return self
        }

        guard let data = data(using: .utf8) else {
            return nil
        }
        return data.base64EncodedString()
    }

    /// Decode a string from the base-64 encoded representation
    /// - Returns: string decoded from base-64 format
    func base64Decode() -> String? {
        if isEmpty {
            return self
        }

        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
