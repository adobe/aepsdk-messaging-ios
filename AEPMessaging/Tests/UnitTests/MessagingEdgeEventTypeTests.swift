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

@testable import AEPMessaging
import Foundation
import XCTest

class MessagingEdgeEventTypeTests: XCTestCase {
    func testDismiss() throws {
        // setup
        let value = MessagingEdgeEventType(rawValue: 6)

        // verify
        XCTAssertEqual(value, .dismiss)
        XCTAssertEqual("decisioning.propositionDismiss", value?.toString())
    }

    func testInteract() throws {
        // setup
        let value = MessagingEdgeEventType(rawValue: 7)

        // verify
        XCTAssertEqual(value, .interact)
        XCTAssertEqual("decisioning.propositionInteract", value?.toString())
    }

    func testTrigger() throws {
        // setup
        let value = MessagingEdgeEventType(rawValue: 8)

        // verify
        XCTAssertEqual(value, .trigger)
        XCTAssertEqual("decisioning.propositionTrigger", value?.toString())
    }

    func testDisplay() throws {
        // setup
        let value = MessagingEdgeEventType(rawValue: 9)

        // verify
        XCTAssertEqual(value, .display)
        XCTAssertEqual("decisioning.propositionDisplay", value?.toString())
    }
    
    func testInAppDismiss_Deprecated() throws {
        // setup
        let value = MessagingEdgeEventType(rawValue: 0)

        // verify
        XCTAssertEqual(value, .inappDismiss)
        XCTAssertEqual("decisioning.propositionDismiss", value?.toString())
    }

    func testInAppInteract_Deprecated() throws {
        // setup
        let value = MessagingEdgeEventType(rawValue: 1)

        // verify
        XCTAssertEqual(value, .inappInteract)
        XCTAssertEqual("decisioning.propositionInteract", value?.toString())
    }

    func testInAppTrigger_Deprecated() throws {
        // setup
        let value = MessagingEdgeEventType(rawValue: 2)

        // verify
        XCTAssertEqual(value, .inappTrigger)
        XCTAssertEqual("decisioning.propositionTrigger", value?.toString())
    }

    func testInAppDisplay_Deprecated() throws {
        // setup
        let value = MessagingEdgeEventType(rawValue: 3)

        // verify
        XCTAssertEqual(value, .inappDisplay)
        XCTAssertEqual("decisioning.propositionDisplay", value?.toString())
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
    
    func testPropEventTypeDismiss() throws {
        XCTAssertEqual("dismiss", MessagingEdgeEventType.dismiss.propositionEventType)
    }
    
    func testPropEventTypeDisplay() throws {
        XCTAssertEqual("display", MessagingEdgeEventType.display.propositionEventType)
    }
    
    func testPropEventTypeInteract() throws {
        XCTAssertEqual("interact", MessagingEdgeEventType.interact.propositionEventType)
    }
    
    func testPropEventTypeTrigger() throws {
        XCTAssertEqual("trigger", MessagingEdgeEventType.trigger.propositionEventType)
    }
    
    func testPropEventTypeDismiss_Deprecated() throws {
        XCTAssertEqual("dismiss", MessagingEdgeEventType.inappDismiss.propositionEventType)
    }
    
    func testPropEventTypeDisplay_Deprecated() throws {
        XCTAssertEqual("display", MessagingEdgeEventType.inappDisplay.propositionEventType)
    }
    
    func testPropEventTypeInteract_Deprecated() throws {
        XCTAssertEqual("interact", MessagingEdgeEventType.inappInteract.propositionEventType)
    }
    
    func testPropEventTypeTrigger_Deprecated() throws {
        XCTAssertEqual("trigger", MessagingEdgeEventType.inappTrigger.propositionEventType)
    }
}
