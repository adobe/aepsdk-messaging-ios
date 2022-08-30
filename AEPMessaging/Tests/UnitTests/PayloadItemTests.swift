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

class PayloadItemTests: XCTestCase {
    let mockDataId = "mockDataId"
    let mockDataContent = "mockDataContent"
    var mockItemData: ItemData!
    
    override func setUp() {
        mockItemData = ItemData(id: mockDataId, content: mockDataContent)
    }
    
    // MARK: - Happy path
    func testIsConstructable() throws {
        // setup
        let payloadItem = PayloadItem(id: "id", schema: "schema", data: mockItemData)
        
        // verify
        XCTAssertNotNil(payloadItem)
        XCTAssertEqual("id", payloadItem.id)
        XCTAssertEqual("schema", payloadItem.schema)
        XCTAssertEqual(mockDataId, payloadItem.data.id)
        XCTAssertEqual(mockDataContent, payloadItem.data.content)
    }
    
    func testIsEncodable() throws {
        // setup
        let encoder = JSONEncoder()
        let payloadItem = PayloadItem(id: "id", schema: "schema", data: mockItemData)
        
        // test
        guard let encodedPayloadItem = try? encoder.encode(payloadItem) else {
            XCTFail("unable to encode PayloadItem")
            return
        }
        
        // verify
        XCTAssertEqual("{\"id\":\"id\",\"schema\":\"schema\",\"data\":{\"id\":\"\(mockDataId)\",\"content\":\"\(mockDataContent)\"}}", String(data: encodedPayloadItem, encoding: .utf8))
    }
    
    func testIsDecodable() throws {
        // setup
        let decoder = JSONDecoder()
        let payloadItem = "{\"id\":\"id\",\"schema\":\"schema\",\"data\":{\"id\":\"\(mockDataId)\",\"content\":\"\(mockDataContent)\"}}".data(using: .utf8)!
        
        // test
        guard let decodedPayloadItem = try? decoder.decode(PayloadItem.self, from: payloadItem) else {
            XCTFail("unable to decode PayloadItem json")
            return
        }
        
        // verify
        XCTAssertEqual("id", decodedPayloadItem.id)
        XCTAssertEqual("schema", decodedPayloadItem.schema)
        XCTAssertEqual(mockDataId, decodedPayloadItem.data.id)
        XCTAssertEqual(mockDataContent, decodedPayloadItem.data.content)
    }
    
    // MARK: - Exception path
    func testIdIsOptional() throws {
        // setup
        let decoder = JSONDecoder()
        let payloadItem = "{\"schema\":\"schema\",\"data\":{\"id\":\"\(mockDataId)\",\"content\":\"\(mockDataContent)\"}}".data(using: .utf8)!
        
        // test
        guard let decodedPayloadItem = try? decoder.decode(PayloadItem.self, from: payloadItem) else {
            XCTFail("unable to decode PayloadItem json")
            return
        }
        
        // verify
        XCTAssertNil(decodedPayloadItem.id)
        XCTAssertEqual("schema", decodedPayloadItem.schema)
        XCTAssertEqual(mockDataId, decodedPayloadItem.data.id)
        XCTAssertEqual(mockDataContent, decodedPayloadItem.data.content)
    }
    
    func testSchemaIsOptional() throws {
        // setup
        let decoder = JSONDecoder()
        let payloadItem = "{\"id\":\"id\",\"data\":{\"id\":\"\(mockDataId)\",\"content\":\"\(mockDataContent)\"}}".data(using: .utf8)!
        
        // test
        guard let decodedPayloadItem = try? decoder.decode(PayloadItem.self, from: payloadItem) else {
            XCTFail("unable to decode PayloadItem json")
            return
        }
        
        // verify
        XCTAssertEqual("id", decodedPayloadItem.id)
        XCTAssertNil(decodedPayloadItem.schema)
        XCTAssertEqual(mockDataId, decodedPayloadItem.data.id)
        XCTAssertEqual(mockDataContent, decodedPayloadItem.data.content)
    }
    
    func testDataIsRequired() throws {
        // setup
        let decoder = JSONDecoder()
        let payloadItem = "{\"id\":\"id\",\"schema\":\"schema\"}".data(using: .utf8)!
        
        // test
        let decodedPayloadItem = try? decoder.decode(PayloadItem.self, from: payloadItem)
        
        // verify
        XCTAssertNil(decodedPayloadItem)        
    }
}
