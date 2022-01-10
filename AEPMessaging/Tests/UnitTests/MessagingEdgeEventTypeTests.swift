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

class MessagingEdgeEventTypeTests: XCTestCase {
    func testInAppDismiss() throws {
        // setup
        let value = MessagingEdgeEventType(rawValue: 0)
        
        // verify
        XCTAssertEqual(value, .inappDismiss)
        XCTAssertEqual(MessagingConstants.XDM.IAM.EventType.DISMISS, value?.toString())
    }
    
    func testInAppInteract() throws {
        // setup
        let value = MessagingEdgeEventType(rawValue: 1)
        
        // verify
        XCTAssertEqual(value, .inappInteract)
        XCTAssertEqual(MessagingConstants.XDM.IAM.EventType.INTERACT, value?.toString())
    }
    
    func testInAppTrigger() throws {
        // setup
        let value = MessagingEdgeEventType(rawValue: 2)
        
        // verify
        XCTAssertEqual(value, .inappTrigger)
        XCTAssertEqual(MessagingConstants.XDM.IAM.EventType.TRIGGER, value?.toString())
    }
    
    func testInAppDisplay() throws {
        // setup
        let value = MessagingEdgeEventType(rawValue: 3)
        
        // verify
        XCTAssertEqual(value, .inappDisplay)
        XCTAssertEqual(MessagingConstants.XDM.IAM.EventType.DISPLAY, value?.toString())
    }
    
    func testPushApplicationOpened() throws {
        // setup
        let value = MessagingEdgeEventType(rawValue: 4)
        
        // verify
        XCTAssertEqual(value, .pushApplicationOpened)
        XCTAssertEqual(MessagingConstants.XDM.Push.EventType.APPLICATION_OPENED, value?.toString())
    }
    
    func testPushCustomAction() throws {
        // setup
        let value = MessagingEdgeEventType(rawValue: 5)
        
        // verify
        XCTAssertEqual(value, .pushCustomAction)
        XCTAssertEqual(MessagingConstants.XDM.Push.EventType.CUSTOM_ACTION, value?.toString())
    }
}
