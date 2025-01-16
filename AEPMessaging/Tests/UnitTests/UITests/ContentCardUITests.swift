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

@available(iOS 15.0, *)
class ContentCardUITests : XCTestCase, ContentCardUIEventListening {
    private var templateHandler : TemplateEventHandler?
    
    // Expectations
    var displayExpectation: XCTestExpectation?
    var dismissExpectation: XCTestExpectation?
    var interactExpectation: XCTestExpectation?
    var capturedInteractionID: String?
            
    func test_contentCardUI_createInstance_happy() throws {
        // setup
        let proposition =  ContentCardTestUtil.createProposition(fromFile: "SmallImageTemplate")
        
        // test
        let contentCardUI = ContentCardUI.createInstance(with: proposition, customizer: nil , listener: nil)
        
        // verify
        XCTAssertNotNil(contentCardUI)
        XCTAssertEqual(contentCardUI?.template.templateType, .smallImage)
        XCTAssertEqual(contentCardUI?.proposition, proposition)
        XCTAssertNotNil(contentCardUI?.view)
        XCTAssertNil(contentCardUI?.listener)
    }
    
    func test_contentCardUI_createInstance_priority() throws {
        // setup
        let proposition =  ContentCardTestUtil.createProposition(fromFile: "SmallImageTemplate", priority: 37)
        
        // test
        let contentCardUI = ContentCardUI.createInstance(with: proposition, customizer: nil , listener: nil)
        
        // verify        
        XCTAssertEqual(37, contentCardUI?.priority)
    }
    
    func test_contentCardUI_verifyMeta() throws {
        // setup
        let proposition =  ContentCardTestUtil.createProposition(fromFile: "SmallImageTemplate")
        
        // test
        let contentCardUI = ContentCardUI.createInstance(with: proposition, customizer: nil , listener: nil)
        
        // verify
        let meta = contentCardUI?.meta
        XCTAssertNotNil(meta)
        XCTAssertEqual(meta?["customKey"] as? String, "customValue")
    }
    
    func test_contentCardUI_InvalidProposition() throws {
        // setup
        let proposition: Proposition = ContentCardTestUtil.createProposition(fromFile: "InvalidTemplate")
        
        // test
        let contentCardUI = ContentCardUI.createInstance(with: proposition, customizer: nil , listener: nil)
        
        // verify
        XCTAssertNil(contentCardUI)
    }
    
    func onDisplay(_ card: ContentCardUI) {
        displayExpectation?.fulfill()
    }
    
    func onDismiss(_ card: ContentCardUI) {
        dismissExpectation?.fulfill()
    }
    
    func onInteract(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool {
        interactExpectation?.fulfill()
        capturedInteractionID = interactionId
        return false
    }
    
    func test_contentCardUI_verifyListenerMethodCalled() throws {
        // setup
        let proposition: Proposition = ContentCardTestUtil.createProposition(fromFile: "SmallImageTemplate")
        displayExpectation = expectation(description: "onDisplay method called")
        dismissExpectation = expectation(description: "onDismiss method called")
        interactExpectation = expectation(description: "onInteract method called")
        
        // test
        templateHandler = ContentCardUI.createInstance(with: proposition, customizer: nil, listener: self)
        templateHandler?.onDisplay()
        templateHandler?.onDismiss()
        templateHandler?.onInteract(interactionId: "InteractionId", actionURL: nil)

        // verify
        // Wait for expectations to be fulfilled
        waitForExpectations(timeout: 2.0) { error in
            if let error = error {
                XCTFail("Expectations were not fulfilled: \(error)")
            }
        }
        
        XCTAssertNotNil(templateHandler)
    }
    
    func test_contentCardUI_schemaData_Accessible() throws {
        // setup
        let proposition: Proposition = ContentCardTestUtil.createProposition(fromFile: "SmallImageTemplate")
        
        // test
        let card = ContentCardUI.createInstance(with: proposition, customizer: nil, listener: self)
        
        // verify
        XCTAssertNotNil(card?.schemaData)
    }
}


