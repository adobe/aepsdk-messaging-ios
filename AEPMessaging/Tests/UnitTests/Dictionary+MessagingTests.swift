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
import XCTest

@testable import AEPMessaging

class DictionaryMessagingTests: XCTestCase {
    var dictionary1: [String: Any] = [
        "key": "value",
        "key2": "value2",
        "number": 1
    ]

    var dictionary2: [String: Any] = [
        "key": "newValue",
        "key3": "value3",
        "number": 552
    ]
    
    var dictionary3: [String: [Any]] = [
        "key4": ["value4a", "value4b"],
        "key5": ["value5"]
    ]

    func testMerge() throws {
        // test
        dictionary1.mergeXdm(rhs: dictionary2)

        // verify
        XCTAssertEqual(4, dictionary1.count)
        XCTAssertEqual("newValue", dictionary1["key"] as? String)
        XCTAssertEqual("value2", dictionary1["key2"] as? String)
        XCTAssertEqual("value3", dictionary1["key3"] as? String)
        XCTAssertEqual(552, dictionary1["number"] as? Int)
    }
    
    func testAddArray() {
        let arrayToAdd = ["value4c"]

        // test
        dictionary3.addArray(arrayToAdd, forKey: "key4")
        
        // verify
        XCTAssertEqual(3, dictionary3["key4"]?.count)
        XCTAssertEqual("value4a", dictionary3["key4"]?[0] as? String)
        XCTAssertEqual("value4b", dictionary3["key4"]?[1] as? String)
        XCTAssertEqual("value4c", dictionary3["key4"]?[2] as? String)
    }
    
    func testAddArrayKeyNotPresent() {
        let arrayToAdd = [42]

        // test
        dictionary3.addArray(arrayToAdd, forKey: "key6")
        
        // verify
        XCTAssertEqual(1, dictionary3["key6"]?.count)
        XCTAssertEqual(42, dictionary3["key6"]?[0] as? Int)
    }
    
    func testAddArrayEmpty() {
        let arrayToAdd: [String] = []

        // test
        dictionary3.addArray(arrayToAdd, forKey: "key4")
        
        // verify
        XCTAssertEqual(2, dictionary3["key4"]?.count)
        XCTAssertEqual("value4a", dictionary3["key4"]?[0] as? String)
        XCTAssertEqual("value4b", dictionary3["key4"]?[1] as? String)
    }
    
    func testAdd() {
        let elementToAdd = "value4c"

        // test
        dictionary3.add(elementToAdd, forKey: "key4")
        
        // verify
        XCTAssertEqual(3, dictionary3["key4"]?.count)
        XCTAssertEqual("value4a", dictionary3["key4"]?[0] as? String)
        XCTAssertEqual("value4b", dictionary3["key4"]?[1] as? String)
        XCTAssertEqual("value4c", dictionary3["key4"]?[2] as? String)
    }
    
    func testAddKeyNotPresent() {
        let elementToAdd = 42

        // test
        dictionary3.add(elementToAdd, forKey: "key6")
        
        // verify
        XCTAssertEqual(1, dictionary3["key6"]?.count)
        XCTAssertEqual(42, dictionary3["key6"]?[0] as? Int)
    }
}
