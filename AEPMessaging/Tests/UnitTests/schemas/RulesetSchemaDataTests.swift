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

class RulesetSchemaDataTests: XCTestCase, AnyCodableAsserts {
                
    let mockVersion = 1
    let mockRuleKey = "ruleKey"
    let mockRuleValue = "ruleValue"
            
    func getDecodedObject(fromString: String) -> RulesetSchemaData? {
        let decoder = JSONDecoder()
        let objectData = fromString.data(using: .utf8)!
        guard let object = try? decoder.decode(RulesetSchemaData.self, from: objectData) else {
            return nil
        }
        return object
    }
    
    func testIsDecodable() throws {
        // setup
        let json = "{\"version\":\(mockVersion),\"rules\":[{\"\(mockRuleKey)\":\"\(mockRuleValue)\"}]}"
        
        // test
        guard let decodedObject = getDecodedObject(fromString: json) else {
            XCTFail("unable to decode json")
            return
        }
        
        // verify
        XCTAssertNotNil(decodedObject)
        XCTAssertEqual(mockVersion, decodedObject.version)
        let dictionaryValue = decodedObject.rules.first
        XCTAssertEqual(mockRuleValue, dictionaryValue?[mockRuleKey] as? String)
    }
    
    func testIsEncodable() throws {
        // setup
        let json = "{\"version\":\(mockVersion),\"rules\":[{\"\(mockRuleKey)\":\"\(mockRuleValue)\"}]}"
        guard let object = getDecodedObject(fromString: json) else {
            XCTFail("unable to decode json")
            return
        }
        let encoder = JSONEncoder()
        let expected = "{\"version\":\(mockVersion),\"rules\":[{\"\(mockRuleKey)\":\"\(mockRuleValue)\"}]}".toAnyCodable() ?? "fail"

        // test
        guard let encodedObject = try? encoder.encode(object) else {
            XCTFail("unable to encode object")
            return
        }

        // verify
        let actual = String(data: encodedObject, encoding: .utf8)?.toAnyCodable() ?? ""
        assertExactMatch(expected: expected, actual: actual, pathOptions: [])
    }
    
    func testVersionIsRequired() throws {
        // setup
        let json = "{\"rules\":[{\"\(mockRuleKey)\":\"\(mockRuleValue)\"}]}"
        
        // test
        let object = getDecodedObject(fromString: json)

        // verify
        XCTAssertNil(object)
    }
    
    func testRulesIsRequired() throws {
        // setup
        let json = "{\"version\":\(mockVersion)}"
        
        // test
        let object = getDecodedObject(fromString: json)

        // verify
        XCTAssertNil(object)
    }
}
