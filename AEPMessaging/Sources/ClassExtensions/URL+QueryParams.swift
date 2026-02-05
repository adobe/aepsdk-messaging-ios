/*
 Copyright 2022 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

extension URL {
    /// Converts the query string of a URL into a dictionary.
    ///
    /// If they query string has a parameter without a value, its value will be represented as an empty string
    /// in the resulting dictionary.
    ///
    /// - Returns: a map containing key-value pairs represented by the query string.
    func queryParamMap() -> [String: String] {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let items = components.queryItems else {
            return [:]
        }
        
        return items.reduce(into: [:]) {
            $0[$1.name] = $1.value ?? ""
        }
    }
}
