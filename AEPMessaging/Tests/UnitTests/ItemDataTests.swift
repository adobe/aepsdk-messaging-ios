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
import XCTest

@testable import AEPMessaging

class ItemDataTests: XCTestCase {
    // MARK: - Happy path
    func testIsConstructable() throws {
        // setup
        let itemData = ItemData(id: "abcd", content: "efgh")
        
        // verify
        XCTAssertNotNil(itemData)
        XCTAssertEqual("abcd", itemData.id)
        XCTAssertEqual("efgh", itemData.content)
    }
    
    func testIsEncodable() throws {
        // setup
        let encoder = JSONEncoder()
        let itemData = ItemData(id: "abcd", content: "efgh")
        
        // test
        guard let encodedItemData = try? encoder.encode(itemData) else {
            XCTFail("unable to encode ItemData")
            return
        }
        
        // verify
        XCTAssertEqual("{\"id\":\"abcd\",\"content\":\"efgh\"}", String(data: encodedItemData, encoding: .utf8))
    }
    
    func testIsDecodable() throws {
        // setup
        let decoder = JSONDecoder()
        let itemData = "{\"id\":\"abcd\", \"content\": \"efgh\"}".data(using: .utf8)!
        
        // test
        guard let decodedItemData = try? decoder.decode(ItemData.self, from: itemData) else {
            XCTFail("unable to decode ItemData json")
            return
        }
        
        // verify
        XCTAssertEqual("abcd", decodedItemData.id)
        XCTAssertEqual("efgh", decodedItemData.content)
    }
    
    // MARK: - Exception path
    func testIdIsOptional() throws {
        // setup
        let decoder = JSONDecoder()
        let itemData = "{\"content\": \"efgh\"}".data(using: .utf8)!
        
        // test
        guard let decodedItemData = try? decoder.decode(ItemData.self, from: itemData) else {
            XCTFail("unable to decode ItemData json")
            return
        }
        
        // verify
        XCTAssertNil(decodedItemData.id)
        XCTAssertEqual("efgh", decodedItemData.content)
    }
    
    func testContentIsRequired() throws {
        // setup
        let decoder = JSONDecoder()
        let itemData = "{\"id\": \"abcd\"}".data(using: .utf8)!
        
        // test
        let decodedItemData = try? decoder.decode(ItemData.self, from: itemData)
        
        // verify
        XCTAssertNil(decodedItemData)
    }
}
