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

class JsonContentSchemaDataTests: XCTestCase, AnyCodableAsserts {
    
    let mockJsonObjectContent = "{\"key\":\"value\"}"
    let mockJsonArrayContent = "[\"content\",\"moreContent\"]"
    let mockFormat = ContentType.applicationJson
        
    func getDecodedObject(fromString: String) -> JsonContentSchemaData? {
        let decoder = JSONDecoder()
        let objectData = fromString.data(using: .utf8)!
        guard let object = try? decoder.decode(JsonContentSchemaData.self, from: objectData) else {
            return nil
        }
        return object
    }
    
    func testIsDecodableJsonObject() throws {
        // setup
        let json = "{\"content\":\(mockJsonObjectContent),\"format\":\"\(mockFormat.toString())\"}"
        
        // test
        guard let decodedObject = getDecodedObject(fromString: json) else {
            XCTFail("unable to decode json")
            return
        }
        
        // verify
        XCTAssertNotNil(decodedObject)
        XCTAssertTrue(decodedObject.isDictionary)
        XCTAssertFalse(decodedObject.isArray)
        let dictionaryValue = decodedObject.getDictionaryValue
        XCTAssertEqual("value", dictionaryValue?["key"] as? String)
        XCTAssertEqual(mockFormat, decodedObject.format)
    }
    
    func testIsDecodableJsonArray() throws {
        // setup
        let json = "{\"content\":\(mockJsonArrayContent),\"format\":\"\(mockFormat.toString())\"}"
        
        // test
        guard let decodedObject = getDecodedObject(fromString: json) else {
            XCTFail("unable to decode json")
            return
        }
        
        // verify
        XCTAssertNotNil(decodedObject)
        XCTAssertFalse(decodedObject.isDictionary)
        XCTAssertTrue(decodedObject.isArray)
        let arrayValue = decodedObject.getArrayValue
        XCTAssertEqual(2, arrayValue?.count)
        XCTAssertEqual("content", arrayValue?[0] as? String)
        XCTAssertEqual("moreContent", arrayValue?[1] as? String)
        XCTAssertEqual(mockFormat, decodedObject.format)
    }
    
    func testIsEncodableJsonObject() throws {
        // setup
        let json = "{\"content\":\(mockJsonObjectContent),\"format\":\"\(mockFormat.toString())\"}"
        guard let object = getDecodedObject(fromString: json) else {
            XCTFail("unable to decode json")
            return
        }
        let encoder = JSONEncoder()
        let expected = getAnyCodable("{\"content\":\(mockJsonObjectContent),\"format\":\"\(mockFormat.toString())\"}") ?? "fail"

        // test
        guard let encodedObject = try? encoder.encode(object) else {
            XCTFail("unable to encode object")
            return
        }

        // verify
        let actual = getAnyCodable(String(data: encodedObject, encoding: .utf8) ?? "")
        assertExactMatch(expected: expected, actual: actual)
    }
    
    func testIsEncodableJsonArray() throws {
        // setup
        let json = "{\"content\":\(mockJsonArrayContent),\"format\":\"\(mockFormat.toString())\"}"
        guard let object = getDecodedObject(fromString: json) else {
            XCTFail("unable to decode json")
            return
        }
        let encoder = JSONEncoder()
        let expected = getAnyCodable("{\"content\":\(mockJsonArrayContent),\"format\":\"\(mockFormat.toString())\"}") ?? "fail"

        // test
        guard let encodedObject = try? encoder.encode(object) else {
            XCTFail("unable to encode object")
            return
        }

        // verify
        let actual = getAnyCodable(String(data: encodedObject, encoding: .utf8) ?? "")
        assertExactMatch(expected: expected, actual: actual)
    }
    
    func testContentIsRequired() throws {
        // setup
        let json = "{\"format\":\"\(mockFormat.toString())\"}"
        
        // test
        let object = getDecodedObject(fromString: json)

        // verify
        XCTAssertNil(object)
    }
    
    func testFormatIsOptional() throws {
        // setup
        let json = "{\"content\":\(mockJsonObjectContent)}"
                
        // test
        let decodedObject = getDecodedObject(fromString: json)

        // verify
        XCTAssertNotNil(decodedObject)
        XCTAssertEqual(true, decodedObject?.isDictionary)
        XCTAssertEqual(false, decodedObject?.isArray)
        let dictionaryValue = decodedObject?.getDictionaryValue
        XCTAssertEqual("value", dictionaryValue?["key"] as? String)
        XCTAssertEqual(mockFormat, decodedObject?.format)
    }
    
}
