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

import AEPCore
@testable import AEPMessaging
import AEPServices

class UrlQueryParamsTests: XCTestCase {
    func testQueryParamMapHappy() throws {
        // setup
        let url = URL(string: "https://adobe.com/path?param=value&another=one")!
        
        // test
        let result = url.queryParamMap()
        
        // verify
        XCTAssertEqual(2, result.count)
        XCTAssertEqual("value", result["param"])
        XCTAssertEqual("one", result["another"])
    }
    
    func testQueryParamMapEmptyValue() throws {
        // setup
        let url = URL(string: "https://adobe.com/path?param=")!
        
        // test
        let result = url.queryParamMap()
        
        // verify
        XCTAssertEqual(1, result.count)
        XCTAssertEqual("", result["param"])
    }
    
    func testQueryParamMapValueContainsEquals() throws {
        // setup
        let url = URL(string: "adbinapp://dismiss?interaction=clicked&link=bos://pal?sport=3")!
        
        // test
        let result = url.queryParamMap()
        
        // verify
        XCTAssertEqual(2, result.count)
        XCTAssertEqual("clicked", result["interaction"])
        XCTAssertEqual("bos://pal?sport=3", result["link"])
    }
    
    func testQueryParamMapValueContainsMultipleEquals() throws {
        // setup
        let url = URL(string: "adbinapp://dismiss?interaction=clicked&link=bos://pal?sport=3&team=celtics")!
        
        // test
        let result = url.queryParamMap()
        
        // verify
        XCTAssertEqual(3, result.count)
        XCTAssertEqual("clicked", result["interaction"])
        XCTAssertEqual("bos://pal?sport=3", result["link"])
        XCTAssertEqual("celtics", result["team"])
    }
    
    func testQueryParamMapValueContainsEncodedAmpersand() throws {
        // setup - %26 is URL-encoded &
        let url = URL(string: "adbinapp://dismiss?interaction=clicked&link=bos://pal?sport=3%26team=celtics")!
        
        // test
        let result = url.queryParamMap()
        
        // verify - the encoded & becomes part of the link value
        XCTAssertEqual(2, result.count)
        XCTAssertEqual("clicked", result["interaction"])
        XCTAssertEqual("bos://pal?sport=3&team=celtics", result["link"])
    }
    
    func testQueryParamMapNoParams() throws {
        // setup
        let url = URL(string: "https://adobe.com/path")!
        
        // test
        let result = url.queryParamMap()
        
        // verify
        XCTAssertEqual(0, result.count)
    }
}
