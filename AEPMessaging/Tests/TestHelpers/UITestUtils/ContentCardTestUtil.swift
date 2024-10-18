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
@testable import AEPMessaging

class ContentCardTestUtil {
    
    static func createContentCardSchemaData(fromFile file : String ) -> ContentCardSchemaData {
        let jsonString = FileReader.readFromFile(file)
        let data = jsonString.data(using: .utf8)
        let decoder = JSONDecoder()
        let contentCardSchemaData = try! decoder.decode(ContentCardSchemaData.self, from: data!)
        return contentCardSchemaData
    }
    
    static func createProposition(fromFile file : String ) -> Proposition {
        let jsonString = FileReader.readFromFile(file)
        let data = jsonString.data(using: .utf8)
        let itemData = try! JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
        let propositionItem = PropositionItem(itemId: "mockItemId", schema: .contentCard, itemData: itemData!)
        let proposition = Proposition(uniqueId: "mockID", scope: "mockScope", scopeDetails: [:], items: [propositionItem])
        return proposition
    }
}
