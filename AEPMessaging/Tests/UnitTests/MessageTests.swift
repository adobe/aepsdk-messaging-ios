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

@testable import AEPCore
@testable import AEPMessaging
@testable import AEPServices
import WebKit

class MessageTests: XCTestCase, FullscreenMessageDelegate {
    
    var mockMessaging: MockMessaging!
    var mockRuntime = TestableExtensionRuntime()
    var mockEvent: Event!
    var mockEventData: [String: Any]?
    let mockMessageId = "552"
    var mockExperienceInfo: [String: Any] = ["experience": "present"]
    var testExpectation: XCTestExpectation?
    
    override func setUp() {
        mockMessaging = MockMessaging(runtime: mockRuntime)
        
        mockEventData = [
            MessagingConstants.Event.Data.Key.IAM.ID: mockMessageId,
            MessagingConstants.Event.Data.Key.TRIGGERED_CONSEQUENCE: [
                MessagingConstants.Event.Data.Key.DETAIL: [
                    MessagingConstants.Event.Data.Key.IAM.MOBILE_PARAMETERS: TestableMobileParameters.mobileParameters,
                    MessagingConstants.XDM.AdobeKeys._XDM: [
                        MessagingConstants.XDM.AdobeKeys.MIXINS: [
                            MessagingConstants.XDM.AdobeKeys.EXPERIENCE: mockExperienceInfo
                        ]
                    ]
                ]
            ]
        ]
        
        mockEvent = Event(name: "Message Test", type: "type", source: "source", data: mockEventData)
    }
    
    func testMessageInitHappy() throws {
        // test
        let message = Message(parent: mockMessaging, event: mockEvent)
        
        // verify
        XCTAssertEqual(mockMessaging, message.parent)
        XCTAssertEqual(mockEvent, message.triggeringEvent)
        XCTAssertEqual(mockMessageId, message.id)
        XCTAssertEqual(1, message.experienceInfo.count)
        XCTAssertEqual("present", message.experienceInfo["experience"] as? String)
        XCTAssertNotNil(message.fullscreenMessage)
    }
    
    func testShow() throws {
        // setup
        let message = Message(parent: mockMessaging, event: mockEvent)
        message.fullscreenMessage?.listener = self
        testExpectation = XCTestExpectation(description: "onShow called")
        
        // test
        message.show()
        
        // verify
        wait(for: [testExpectation!], timeout: 1.0)
    }
    
    func testDismiss() throws {
        // setup
        let message = Message(parent: mockMessaging, event: mockEvent)
        message.show()  // onDismiss will not get called if the message isn't currently being shown
        message.fullscreenMessage?.listener = self
        testExpectation = XCTestExpectation(description: "onDismiss called")
        
        // test
        message.dismiss()
        
        // verify
        wait(for: [testExpectation!], timeout: 1.0)
    }
    
    func testHandleJavascriptMessage() throws {
        // setup
        let message = Message(parent: mockMessaging, event: mockEvent)
        let mockFullscreenMessage = MockFullscreenMessage()
        mockFullscreenMessage.paramJavascriptHandlerReturnValue = "abc"
        message.fullscreenMessage = mockFullscreenMessage
        testExpectation = XCTestExpectation(description: "jsHandler called")
        
        // test
        message.handleJavascriptMessage("test") { body in
            XCTAssertEqual("abc", body as? String)
            self.testExpectation?.fulfill()
        }
        
        // verify
        wait(for: [testExpectation!], timeout: 1.0)
        XCTAssertTrue(mockFullscreenMessage.handleJavascriptMessageCalled)
        XCTAssertEqual("test", mockFullscreenMessage.paramJavascriptMessage)
    }
    
    func testViewAccess() throws {
        // setup
        let message = Message(parent: mockMessaging, event: mockEvent)
        let mockFullscreenMessage = MockFullscreenMessage()        
        message.fullscreenMessage = mockFullscreenMessage
        
        // verify
        XCTAssertNotNil(message.view)
        XCTAssertTrue(message.view is WKWebView)
    }
    
    func testTriggerable() throws {
        // setup
        let message = Message(parent: mockMessaging, event: mockEvent)
        
        // verify
        message.trigger()
    }
    
    // MARK: - FullscreenMessageDelegate
    public func onShow(message: FullscreenMessage) {
        testExpectation?.fulfill()
    }
    public func onShowFailure() {
        testExpectation?.fulfill()
    }
    public func onDismiss(message: FullscreenMessage) {
        testExpectation?.fulfill()
    }
    public func overrideUrlLoad(message: FullscreenMessage, url: String?) -> Bool {
        testExpectation?.fulfill()
        return true
    }
}
