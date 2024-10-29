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
import XCTest

@testable import AEPMessaging
import AEPServices
import AEPTestUtils

class PropositionTests: XCTestCase, AnyCodableAsserts {
    
    let mockScope = "mockScope"
    let mockPropositionId = "mockPropositionId"
    let mockItemId = "mockItemId"
    let mockHtmlSchema: SchemaType = .htmlContent
    let mockJsonSchema: SchemaType = .jsonContent
    let mockScopeDetails: [String: Any] = ["key":"value"]
    
    func getDecodedObject(fromString: String) -> Proposition? {
        let decoder = JSONDecoder()
        let objectData = fromString.data(using: .utf8)!
        guard let proposition = try? decoder.decode(Proposition.self, from: objectData) else {
            return nil
        }
        return proposition
    }
    
    func testPropositionInit() {
        // setup
        let mockCodeBasedContent = JSONFileLoader.getRulesJsonFromFile("codeBasedPropositionJsonContent")
        
        // test
        let propositionItem = PropositionItem(itemId: mockItemId, schema: .jsonContent, itemData: mockCodeBasedContent)
        let proposition = Proposition(uniqueId: mockPropositionId, scope: mockScope, scopeDetails: mockScopeDetails, items: [propositionItem])
        
        // verify
        XCTAssertEqual(mockPropositionId, proposition.uniqueId)
        XCTAssertEqual(mockScope, proposition.scope)
        assertEqual(expected: AnyCodable(mockScopeDetails), actual: AnyCodable(proposition.scopeDetails))
        XCTAssertEqual(1, proposition.items.count)
        let propItem = proposition.items[0]
        XCTAssertEqual(mockItemId, propItem.itemId)
        XCTAssertEqual(mockJsonSchema, propItem.schema)
        assertExactMatch(expected: AnyCodable(mockCodeBasedContent["content"] as? [String: Any]), actual: AnyCodable(propItem.jsonContentDictionary))
    }
    
    func testPropositionIsDecodable() {
        // setup
        let mockCodeBasedContent = "<html><body>My custom content</body></html>"
        let mockHtmlFormat: ContentType = .textHtml
        let mockScopeDetailsString = "{\"key\":\"value\"}"
        let propositionJsonString = "{\"id\":\"\(mockPropositionId)\",\"scope\":\"\(mockScope)\",\"scopeDetails\":\(mockScopeDetailsString),\"items\":[{\"id\":\"\(mockItemId)\",\"schema\":\"\(mockHtmlSchema.toString())\",\"data\":{\"content\":\"\(mockCodeBasedContent)\",\"format\":\"\(mockHtmlFormat)\"}}]}"
        
        // test
        guard let proposition = getDecodedObject(fromString: propositionJsonString) else {
            XCTFail("Proposition object should be decodable.")
            return
        }
        
        // verify
        XCTAssertEqual(mockPropositionId, proposition.uniqueId)
        XCTAssertEqual(mockScope, proposition.scope)
        assertExactMatch(expected: mockScopeDetailsString.toAnyCodable()!, actual: proposition.scopeDetails.toAnyCodable(), pathOptions: [])
        XCTAssertEqual(1, proposition.items.count)
        let propItem = proposition.items[0]
        XCTAssertEqual(mockItemId, propItem.itemId)
        XCTAssertEqual(mockHtmlSchema, propItem.schema)
        XCTAssertEqual(mockCodeBasedContent, propItem.htmlContent)
    }
    
    func testPropositionIsEncodable() {
        // setup
        let propositionJsonString = JSONFileLoader.getRulesStringFromFile("codeBasedPropositionHtml")
        guard let proposition = getDecodedObject(fromString: propositionJsonString) else {
            XCTFail("Proposition object should be decodable.")
            return
        }
        
        let encoder = JSONEncoder()
        let expected = propositionJsonString.toAnyCodable() ?? "fail"

        // test
        guard let encodedObject = try? encoder.encode(proposition) else {
            XCTFail("Proposition object should be encodable.")
            return
        }

        // verify
        let actual = String(data: encodedObject, encoding: .utf8)?.toAnyCodable() ?? ""
        assertExactMatch(expected: expected, actual: actual, pathOptions: [])
    }
    
    func testScopeDetailsIsRequired() throws {
        // setup
        let mockCodeBasedContent = "<html><body>My custom content</body></html>"
        let mockHtmlFormat: ContentType = .textHtml
        let propositionJsonString = "{\"id\":\"\(mockPropositionId)\",\"scope\":\"\(mockScope)\",\"items\":[{\"id\":\"\(mockItemId)\",\"schema\":\"\(mockHtmlSchema.toString())\",\"data\":{\"content\":\"\(mockCodeBasedContent)\",\"format\":\"\(mockHtmlFormat)\"}}]}"

        // test
       let proposition = getDecodedObject(fromString: propositionJsonString)

        // verify
        XCTAssertNil(proposition)
    }
    
    func testPriorityIsAccessible() throws {
        let mockCodeBasedContent = "<html><body>My custom content</body></html>"
        let mockHtmlFormat: ContentType = .textHtml
        let mockScopeDetailsString = "{\"activity\":{\"priority\":50}}"
        let propositionJsonString = "{\"id\":\"\(mockPropositionId)\",\"scope\":\"\(mockScope)\",\"scopeDetails\":\(mockScopeDetailsString),\"items\":[{\"id\":\"\(mockItemId)\",\"schema\":\"\(mockHtmlSchema.toString())\",\"data\":{\"content\":\"\(mockCodeBasedContent)\",\"format\":\"\(mockHtmlFormat)\"}}]}"

        // test
       let proposition = getDecodedObject(fromString: propositionJsonString)
        
        // verify
        XCTAssertNotNil(proposition)
        XCTAssertEqual(50, proposition?.priority)
    }
    
    func testPriorityDefaultValueZero() throws {
        let mockCodeBasedContent = "<html><body>My custom content</body></html>"
        let mockHtmlFormat: ContentType = .textHtml
        let mockScopeDetailsString = "{\"key\":\"value\"}"
        let propositionJsonString = "{\"id\":\"\(mockPropositionId)\",\"scope\":\"\(mockScope)\",\"scopeDetails\":\(mockScopeDetailsString),\"items\":[{\"id\":\"\(mockItemId)\",\"schema\":\"\(mockHtmlSchema.toString())\",\"data\":{\"content\":\"\(mockCodeBasedContent)\",\"format\":\"\(mockHtmlFormat)\"}}]}"

        // test
       let proposition = getDecodedObject(fromString: propositionJsonString)
        
        // verify
        XCTAssertNotNil(proposition)
        XCTAssertEqual(0, proposition?.priority)
    }
    
    func testRankIsAccessible() throws {
        let mockCodeBasedContent = "<html><body>My custom content</body></html>"
        let mockHtmlFormat: ContentType = .textHtml
        let mockScopeDetailsString = "{\"rank\":1}"
        let propositionJsonString = "{\"id\":\"\(mockPropositionId)\",\"scope\":\"\(mockScope)\",\"scopeDetails\":\(mockScopeDetailsString),\"items\":[{\"id\":\"\(mockItemId)\",\"schema\":\"\(mockHtmlSchema.toString())\",\"data\":{\"content\":\"\(mockCodeBasedContent)\",\"format\":\"\(mockHtmlFormat)\"}}]}"

        // test
       let proposition = getDecodedObject(fromString: propositionJsonString)
        
        // verify
        XCTAssertNotNil(proposition)
        XCTAssertEqual(1, proposition?.rank)
    }
    
    func testRankDefaultValueNegativeOne() throws {
        let mockCodeBasedContent = "<html><body>My custom content</body></html>"
        let mockHtmlFormat: ContentType = .textHtml
        let mockScopeDetailsString = "{\"norank\":\"foundhere\"}"
        let propositionJsonString = "{\"id\":\"\(mockPropositionId)\",\"scope\":\"\(mockScope)\",\"scopeDetails\":\(mockScopeDetailsString),\"items\":[{\"id\":\"\(mockItemId)\",\"schema\":\"\(mockHtmlSchema.toString())\",\"data\":{\"content\":\"\(mockCodeBasedContent)\",\"format\":\"\(mockHtmlFormat)\"}}]}"

        // test
       let proposition = getDecodedObject(fromString: propositionJsonString)
        
        // verify
        XCTAssertNotNil(proposition)
        XCTAssertEqual(-1, proposition?.rank)
    }
}
