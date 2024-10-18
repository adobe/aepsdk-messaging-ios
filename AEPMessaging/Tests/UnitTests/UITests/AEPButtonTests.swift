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

import XCTest
@testable import AEPMessaging

@available(iOS 15.0, *)
final class AEPButtonTests: XCTestCase {
    
    let mockTemplate : MockTemplate = MockTemplate(ContentCardSchemaData.getEmpty())!
    
    func testInit_validData() {
        // setup
        let data = [
            UIConstants.CardTemplate.UIElement.Button.TEXT: [
                UIConstants.CardTemplate.UIElement.Text.CONTENT: "Button Yes"
            ],
            UIConstants.CardTemplate.UIElement.Button.INTERACTION_ID: "yes"
        ] as [String : Any]
        
        // test
        let button = AEPButton(data, mockTemplate)
        
        // verify
        XCTAssertNotNil(button)
        XCTAssertEqual(button?.text.content, "Button Yes")
        XCTAssertEqual(button?.interactId, "yes")
    }
    
    func testInit_emptyData() {
        // setup
        let data: [String: Any] = [:]
        
        // test
        let button = AEPButton(data, mockTemplate)
        
        // verify
        XCTAssertNil(button)
    }
    
    func testInit_noText() {
        // setup
        let data = [
            UIConstants.CardTemplate.UIElement.Button.INTERACTION_ID: "yes"
        ] as [String : Any]
        
        // test
        let button = AEPButton(data, mockTemplate)
        
        // verify
        XCTAssertNil(button)
    }
    
    func testInit_noInteractId() {
        // setup
        let data = [
            UIConstants.CardTemplate.UIElement.Button.TEXT: [
                UIConstants.CardTemplate.UIElement.Text.CONTENT: "Button Yes"
            ]
        ] as [String : Any]
        
        // test
        let button = AEPButton(data, mockTemplate)
        
        // verify
        XCTAssertNil(button)
    }
    
    func test_viewProperty() {
        // setup
        let data = [
            UIConstants.CardTemplate.UIElement.Button.TEXT: [
                UIConstants.CardTemplate.UIElement.Text.CONTENT: "Button Yes"
            ],
            UIConstants.CardTemplate.UIElement.Button.INTERACTION_ID: "yes"
        ] as [String : Any]
        
        // test
        let button = AEPButton(data, mockTemplate)
        
        // verify
        XCTAssertNotNil(button?.view)
        XCTAssertNoThrow(
            button?.view.body
        )
    }
    
}
