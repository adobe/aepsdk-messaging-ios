/*
 Copyright 2024 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

class FileReader {
    
    /// Reads the text from the provided bundled file and returns the string value
    static func readFromFile(_ fileName: String) -> String {
        let testBundle = Bundle(for: FileReader.self)
        guard let url = testBundle.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let jsonString = String(data: data, encoding: .utf8)
        else {
            return ""
        }
        return jsonString
    }
}
