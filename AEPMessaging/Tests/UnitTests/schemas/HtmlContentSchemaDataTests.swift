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

class HtmlContentSchemaDataTests: XCTestCase, AnyCodableAsserts {
     
    let mockContent = "<html>this is some html</html>"
    let mockFormat = ContentType.textHtml
        
    func getDecodedObject(fromString: String) -> HtmlContentSchemaData? {
        let decoder = JSONDecoder()
        let objectData = fromString.data(using: .utf8)!
        guard let object = try? decoder.decode(HtmlContentSchemaData.self, from: objectData) else {
            return nil
        }
        return object
    }
    
    func testIsDecodable() throws {
        // setup
        let json = "{\"content\":\"\(mockContent)\",\"format\":\"\(mockFormat.toString())\"}"
        
        // test
        guard let decodedObject = getDecodedObject(fromString: json) else {
            XCTFail("unable to decode json")
            return
        }
        
        // verify
        XCTAssertNotNil(decodedObject)
        XCTAssertEqual(mockContent, decodedObject.content)
        XCTAssertEqual(mockFormat, decodedObject.format)
    }
    
    func testIsEncodable() throws {
        // setup
        let json = "{\"content\":\"\(mockContent)\",\"format\":\"\(mockFormat.toString())\"}"
        guard let object = getDecodedObject(fromString: json) else {
            XCTFail("unable to decode json")
            return
        }
        let encoder = JSONEncoder()
        let expected = "{\"content\":\"\(mockContent)\",\"format\":\"\(mockFormat.toString())\"}".toAnyCodable() ?? "fail"

        // test
        guard let encodedObject = try? encoder.encode(object) else {
            XCTFail("unable to encode object")
            return
        }

        // verify
        let actual = String(data: encodedObject, encoding: .utf8)?.toAnyCodable() ?? ""
        assertExactMatch(expected: expected, actual: actual, pathOptions: [])
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
        let json = "{\"content\":\"\(mockContent)\"}"
                
        // test
        let object = getDecodedObject(fromString: json)

        // verify
        XCTAssertNotNil(object)
        XCTAssertEqual(mockContent, object?.content)
        XCTAssertEqual(.textHtml, object?.format)
    }
}
