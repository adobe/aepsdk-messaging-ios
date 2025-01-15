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

class CompletionHandlerTests: XCTestCase {
    func testConstructorHappy() throws {
        // setup
        var handlerParam: Bool = false
        let handler: ((Bool) -> Void) = { bool in
            handlerParam = bool
        }
        let event = Event(name: "name", type: "type", source: "source", data: nil)
        
        // test
        let completionHandler = CompletionHandler(originatingEvent: event, handler: handler)
        
        // verify
        XCTAssertNotNil(completionHandler.originatingEventId)
        XCTAssertEqual(event.id, completionHandler.originatingEventId)
        XCTAssertNotNil(completionHandler.handle)
        completionHandler.handle?(true)
        XCTAssertTrue(handlerParam)
        XCTAssertNil(completionHandler.edgeRequestEventId)
    }
        
    func testOriginalEventIdOptional() throws {
        // setup
        let handler: ((Bool) -> Void) = { bool in }
        let event = Event(name: "name", type: "type", source: "source", data: nil)
        var completionHandler = CompletionHandler(originatingEvent: event, handler: handler)
        
        // test
        completionHandler.originatingEventId = nil
        
        // verify
        XCTAssertNil(completionHandler.originatingEventId)
    }
       
    func testEdgeRequestEventIdOptional() throws {
        // setup
        let handler: ((Bool) -> Void) = { bool in }
        let event = Event(name: "name", type: "type", source: "source", data: nil)
        var completionHandler = CompletionHandler(originatingEvent: event, handler: handler)
        
        // test
        completionHandler.edgeRequestEventId = nil
        
        // verify
        XCTAssertNil(completionHandler.edgeRequestEventId)
    }
        
    func testHandleOptional() throws {
        // setup
        let handler: ((Bool) -> Void) = { bool in }
        let event = Event(name: "name", type: "type", source: "source", data: nil)
        var completionHandler = CompletionHandler(originatingEvent: event, handler: handler)
        
        // test
        completionHandler.handle = nil
        
        // verify
        XCTAssertNil(completionHandler.handle)
    }
}
