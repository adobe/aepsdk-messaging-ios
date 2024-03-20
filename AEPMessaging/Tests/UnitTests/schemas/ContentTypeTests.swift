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

class ContentTypeTests: XCTestCase {
    func testApplicationJson() throws {
        // setup
        let value = ContentType(rawValue: 0)

        // verify
        XCTAssertEqual(value, .applicationJson)
        XCTAssertEqual("application/json", value?.toString())
    }
    
    func testTextHtml() throws {
        // setup
        let value = ContentType(rawValue: 1)

        // verify
        XCTAssertEqual(value, .textHtml)
        XCTAssertEqual("text/html", value?.toString())
    }
    
    func testTextXml() throws {
        // setup
        let value = ContentType(rawValue: 2)

        // verify
        XCTAssertEqual(value, .textXml)
        XCTAssertEqual("text/xml", value?.toString())
    }
    
    func testTextPlain() throws {
        // setup
        let value = ContentType(rawValue: 3)

        // verify
        XCTAssertEqual(value, .textPlain)
        XCTAssertEqual("text/plain", value?.toString())
    }
    
    func testUnknown() throws {
        // setup
        let value = ContentType(rawValue: 4)

        // verify
        XCTAssertEqual(value, .unknown)
        XCTAssertEqual("", value?.toString())
    }

    func testInitFromStringApplicationJson() throws {
        // setup
        let value = ContentType(from: "application/json")
        
        // verify
        XCTAssertEqual(.applicationJson, value)
    }
    
    func testInitFromStringTextHtml() throws {
        // setup
        let value = ContentType(from: "text/html")
        
        // verify
        XCTAssertEqual(.textHtml, value)
    }
    
    func testInitFromStringTextXml() throws {
        // setup
        let value = ContentType(from: "text/xml")
        
        // verify
        XCTAssertEqual(.textXml, value)
    }
    
    func testInitFromStringTextPlain() throws {
        // setup
        let value = ContentType(from: "text/plain")
        
        // verify
        XCTAssertEqual(.textPlain, value)
    }
    
    func testInitFromStringUnknown() throws {
        // setup
        let value = ContentType(from: "i don't match anything")
        
        // verify
        XCTAssertEqual(.unknown, value)
    }
}
