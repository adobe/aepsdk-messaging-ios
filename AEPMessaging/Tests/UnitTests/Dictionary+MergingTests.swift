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

class DictionaryMergingTests: XCTestCase {
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

    func testMerge() throws {
        // test
        dictionary1.mergeXdm(rhs: dictionary2)

        // verify
        XCTAssertEqual("newValue", dictionary1["key"] as? String)
        XCTAssertEqual("value2", dictionary1["key2"] as? String)
        XCTAssertEqual("value3", dictionary1["key3"] as? String)
        XCTAssertEqual(552, dictionary1["number"] as? Int)
    }
}
