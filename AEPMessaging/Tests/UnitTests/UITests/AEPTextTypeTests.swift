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
import SwiftUI
@testable import AEPMessaging

@available(iOS 15.0, *)
final class AEPTextTypeTests: XCTestCase {
    
    // font tests
    
    func test_titleDefaultFont() {
        XCTAssertEqual(AEPTextType.title.defaultFont, UIConstants.CardTemplate.DefaultStyle.Text.TITLE_FONT)
    }

    func test_bodyDefaultFont() {
        XCTAssertEqual(AEPTextType.body.defaultFont, UIConstants.CardTemplate.DefaultStyle.Text.BODY_FONT)
    }

    func test_buttonDefaultFont() {
        XCTAssertEqual(AEPTextType.button.defaultFont, UIConstants.CardTemplate.DefaultStyle.Text.BUTTON_FONT)
    }
    
    // font tests

    func test_titleDefaultColor() {
        XCTAssertEqual(AEPTextType.title.defaultColor, UIConstants.CardTemplate.DefaultStyle.Text.TITLE_COLOR)
    }

    func test_bodyDefaultColor() {
        XCTAssertEqual(AEPTextType.body.defaultColor, UIConstants.CardTemplate.DefaultStyle.Text.BODY_COLOR)
    }

    func test_buttonDefaultColor() {
        XCTAssertEqual(AEPTextType.button.defaultColor, UIConstants.CardTemplate.DefaultStyle.Text.BUTTON_COLOR)
    }

}
