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
class AEPDismissButtonTests: XCTestCase {

    let mockTemplate : MockTemplate = MockTemplate(ContentCardSchemaData.getEmpty())!

    func test_initSimpleStyleDismissButton() {
        // setup
        let data = ["style": "simple"]
        
        // test
        let dismissButton = AEPDismissButton(data, mockTemplate)
        
        // verify
        XCTAssertNotNil(dismissButton)
        XCTAssertEqual(dismissButton?.alignment, UIConstants.CardTemplate.DefaultStyle.DismissButton.ALIGNMENT)
        XCTAssertNotNil(dismissButton?.image)
        XCTAssertEqual(dismissButton?.image.icon, DismissButtonStyle.simple.iconName)
        XCTAssertNotNil(dismissButton?.parentTemplate)
    }
    
    func test_initCircleStyleDismissButton() {
        // setup
        let data = ["style": "circle"]
        
        // test
        let dismissButton = AEPDismissButton(data, mockTemplate)
        
        // verify
        XCTAssertNotNil(dismissButton)
        XCTAssertEqual(dismissButton?.alignment, UIConstants.CardTemplate.DefaultStyle.DismissButton.ALIGNMENT)
        XCTAssertNotNil(dismissButton?.image)
        XCTAssertEqual(dismissButton?.image.icon, DismissButtonStyle.circle.iconName)
        XCTAssertNotNil(dismissButton?.parentTemplate)
    }
    
    func test_initNoneStyleDismissButton() {
        // setup
        let data = ["style": "none"]
        
        // test
        let dismissButton = AEPDismissButton(data, mockTemplate)
        
        // verify
        XCTAssertNil(dismissButton)
    }
    
    func test_initWithInvalidStyle() {
        // setup
        let data = ["style": "invalid_style"]
        
        // test
        let dismissButton = AEPDismissButton(data, mockTemplate)
        
        // verify
        XCTAssertNil(dismissButton)
    }
    
    func test_initWithMissingStyle() {
        // setup
        let data: [String: Any] = [:]
        
        // test
        let dismissButton = AEPDismissButton(data, mockTemplate)
        
        // verify
        XCTAssertNil(dismissButton)
    }
    
}
