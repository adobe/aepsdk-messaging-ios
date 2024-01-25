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

import AEPCore
@testable import AEPMessaging
import AEPServices
import AEPTestUtils

class MessageFullscreenMessageDelegateTests: XCTestCase {
    var message: Message!
    var mockMessaging: MockMessaging!
    var mockRuntime = TestableExtensionRuntime()
    var mockEvent: Event!
    var mockFullscreenMessage: MockFullscreenMessage!
    var mockMessage: MockMessage!
    let invalidUrlString = "-.98.3/~@!# oopsnotaurllol"
    let genericUrlString = "https://www.adobe.com/"
    let inAppUrlString = "adbinapp://dismiss?interaction=testing&link=https://www.adobe.com/"
    let dismissUrlString = "adbinapp://dismiss"
    let animationOverrideUrlString = "adbinapp://dismiss?animate=left"
    let animationOverrideUnknownUrlString = "adbinapp://dismiss?animate=notarealanimation"
    let animationOverrideEmptyUrlString = "adbinapp://dismiss?animate="

    override func setUp() {
        mockMessaging = MockMessaging(runtime: mockRuntime)
        mockEvent = Event(name: "Message Test", type: "type", source: "source", data: nil)
        message = Message(parent: mockMessaging, triggeringEvent: mockEvent)
        mockMessage = MockMessage(parent: mockMessaging, triggeringEvent: mockEvent)
        mockFullscreenMessage = MockFullscreenMessage(parent: mockMessage)
        mockMessage.fullscreenMessage = mockFullscreenMessage
    }

    func testOnDismiss() throws {
        // test
        message.onDismiss(message: mockFullscreenMessage)

        // verify
        XCTAssertTrue(mockMessage.dismissCalled)
    }

    func testOnDismissNoParentOnMessage() throws {
        // setup
        mockFullscreenMessage = MockFullscreenMessage()
        mockMessage.fullscreenMessage = mockFullscreenMessage

        // test
        message.onDismiss(message: mockFullscreenMessage)

        // verify
        XCTAssertFalse(mockMessage.dismissCalled)
    }
    
    func testOverrideUrlLoadNilUrlParam() throws {
        // test
        let result = message.overrideUrlLoad(message: mockFullscreenMessage, url: nil)

        // verify
        XCTAssertTrue(result)
    }

    func testOverrideUrlLoadGenericUrl() throws {
        // test
        let result = message.overrideUrlLoad(message: mockFullscreenMessage, url: genericUrlString)

        // verify
        XCTAssertTrue(result)
    }

    func testOverrideUrlLoadInvalidUrl() throws {
        // test
        let result = message.overrideUrlLoad(message: mockFullscreenMessage, url: invalidUrlString)

        // verify
        XCTAssertTrue(result)
    }

    func testOverrideUrlLoadInAppUrl() throws {
        // test
        let result = message.overrideUrlLoad(message: mockFullscreenMessage, url: inAppUrlString)

        // verify
        XCTAssertFalse(result)
        XCTAssertTrue(mockMessage.trackCalled)
        XCTAssertEqual("testing", mockMessage.paramTrackInteraction)
        XCTAssertEqual(.interact, mockMessage.paramTrackEventType)
        XCTAssertTrue(mockMessage.dismissCalled)
    }

    func testOverrideUrlLoadDismissUrl() throws {
        // test
        let result = message.overrideUrlLoad(message: mockFullscreenMessage, url: dismissUrlString)

        // verify
        XCTAssertFalse(result)
        XCTAssertFalse(mockMessage.trackCalled)
        XCTAssertTrue(mockMessage.dismissCalled)
    }

    func testOverrideUrlLoadAnimationOverride() throws {
        // test
        let result = message.overrideUrlLoad(message: mockFullscreenMessage, url: animationOverrideUrlString)
        
        // verify
        XCTAssertFalse(result)
        XCTAssertNil(mockMessage.paramTrackInteraction)
        XCTAssertEqual(.left, mockMessage.fullscreenMessage?.settings?.dismissAnimation)
        XCTAssertTrue(mockMessage.dismissCalled)
    }
    
    func testOverrideUrlLoadAnimationOverrideUnknownAnimation() throws {
        // test
        let result = message.overrideUrlLoad(message: mockFullscreenMessage, url: animationOverrideUnknownUrlString)
        
        // verify
        XCTAssertFalse(result)
        XCTAssertNil(mockMessage.paramTrackInteraction)
        XCTAssertEqual(MessageAnimation.none, mockMessage.fullscreenMessage?.settings?.dismissAnimation)
        XCTAssertTrue(mockMessage.dismissCalled)
    }
    
    func testOverrideUrlLoadAnimationOverrideEmpty() throws {
        // test
        let result = message.overrideUrlLoad(message: mockFullscreenMessage, url: animationOverrideEmptyUrlString)
        
        // verify
        XCTAssertFalse(result)
        XCTAssertNil(mockMessage.paramTrackInteraction)
        XCTAssertEqual(MessageAnimation.none, mockMessage.fullscreenMessage?.settings?.dismissAnimation)
        XCTAssertTrue(mockMessage.dismissCalled)
    }
    
    func testOnShowNoParent() throws {
        // setup
        let messageNoParent: FullscreenMessage = MockFullscreenMessage(parent: nil)
        
        // test
        message.onShow(message: messageNoParent)
        
        // verify
        XCTAssertFalse(mockMessage.trackCalled)
    }
    
    func testOnShowCallableAutoTrackEnabled() throws {
        // setup
        mockMessage.autoTrack = true
        
        // test
        message.onShow(message: mockFullscreenMessage)
        
        // verify
        XCTAssertTrue(mockMessage.trackCalled)
    }
    
    func testOnShowCallableAutoTrackDisabled() throws {
        // setup
        mockMessage.autoTrack = false
        
        // test
        message.onShow(message: mockFullscreenMessage)
        
        // verify
        XCTAssertFalse(mockMessage.trackCalled)
    }

    func testOnShowFailureCallable() throws {
        message.onShowFailure()
    }
}
