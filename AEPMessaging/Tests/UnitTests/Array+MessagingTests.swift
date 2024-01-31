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

class ArrayMessagingTests: XCTestCase {

    class Shape: Equatable {
        let name: String
        let vertices: Int
        
        init(_ name: String, withVertices vertices: Int) {
            self.name = name
            self.vertices = vertices
        }
        
        static func == (lhs: Shape, rhs: Shape) -> Bool {
            return lhs.name == rhs.name && lhs.vertices == rhs.vertices
        }
    }
    
    var shapes: [Shape] = []
    var array1: [String] = [ "value1", "value2", "value3" ]

    override func setUp() {
        shapes = [
            Shape("triangle", withVertices: 3),
            Shape("square", withVertices: 4),
            Shape("pentagon", withVertices: 5)
        ]
    }
    
    func testArrayMinus() {
        let arrayToMinus = ["value2", "value4"]
        
        // test
        let result = array1.minus(arrayToMinus).sorted()
        
        // verify
        XCTAssertEqual(2, result.count)
        XCTAssertEqual("value1", result[0])
        XCTAssertEqual("value3", result[1])
    }
    
    func testArrayMinusAll() {
        let arrayToMinus = ["value2", "value3", "value1"]
        
        // test
        let result = array1.minus(arrayToMinus)
        
        // verify
        XCTAssertTrue(result.isEmpty)
    }
    
    func testToDictionary() {
        // test
        let dict: [String: [Shape]] = shapes.toDictionary { String($0.vertices) }

        // verify
        XCTAssertEqual(3, dict.count)
        XCTAssertEqual([shapes[0]], dict["3"])
        XCTAssertEqual([shapes[1]], dict["4"])
        XCTAssertEqual([shapes[2]], dict["5"])
    }
    
    func testToDictionaryExistingKey() {
        shapes.append(Shape("rectangle", withVertices: 4))
        
        // test
        let dict: [String: [Shape]] = shapes.toDictionary { String($0.vertices) }

        // verify
        XCTAssertEqual(3, dict.count)
        XCTAssertEqual([shapes[0]], dict["3"])
        XCTAssertEqual(2, dict["4"]?.count)
        XCTAssertEqual(shapes[1], dict["4"]?[0])
        XCTAssertEqual(shapes[3], dict["4"]?[1])
        XCTAssertEqual([shapes[2]], dict["5"])
    }
}
