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

class ConfigurationLoader {
    /// Reads the configuration from the provided bundled file and returns a map
    static func getConfig(_ fileName: String) -> [String: Any] {
        let testBundle = Bundle(for: ConfigurationLoader.self)
        guard let url = testBundle.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return [:]
        }

        guard let configMap = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] else {
            return [:]
        }

        return configMap
    }
}
