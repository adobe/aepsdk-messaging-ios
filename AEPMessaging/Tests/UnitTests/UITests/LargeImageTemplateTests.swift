/*
 Copyright 2025 Adobe. All rights reserved.
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
final class LargeImageTemplateTests: XCTestCase {
    
    var emptyCustomizer = EmptyCustomizer()
    
    func testLargeImageTemplate_happy() {
        // setup
        let schema = ContentCardTestUtil.createContentCardSchemaData(fromFile: "LargeImageTemplate")

        // test
        let largeImageTemplate = LargeImageTemplate(schema, emptyCustomizer)

        // verify
        XCTAssertNotNil(largeImageTemplate)
        XCTAssertEqual(largeImageTemplate?.title.content, "Card Title")
        XCTAssertEqual(largeImageTemplate?.body?.content, "body")
        XCTAssertEqual(largeImageTemplate?.image?.url?.absoluteString, "https://imagetoDownload.com/cardimage")
        XCTAssertEqual(largeImageTemplate?.image?.darkUrl?.absoluteString, "https://imagetoDownload.com/darkimage")
        XCTAssertEqual(largeImageTemplate?.buttons?.count, 2)

        // verify first button
        XCTAssertEqual(largeImageTemplate?.buttons?[0].text.content, "Purchase Now")
        XCTAssertEqual(largeImageTemplate?.buttons?[0].interactId, "purchaseID")
        XCTAssertEqual(largeImageTemplate?.buttons?[0].actionUrl, URL(string: "https://adobe.com/offer"))

        // verify second button
        XCTAssertEqual(largeImageTemplate?.buttons?[1].text.content, "Cancel")
        XCTAssertEqual(largeImageTemplate?.buttons?[1].interactId, "cancelID")
        XCTAssertEqual(largeImageTemplate?.buttons?[1].actionUrl, URL(string: "app://home"))

        // verify stacks (LargeImageTemplate uses rootVStack instead of rootHStack)
        XCTAssertEqual(largeImageTemplate?.buttonHStack.childModels.count, 2)
        XCTAssertEqual(largeImageTemplate?.textVStack.childModels.count, 3)
        XCTAssertEqual(largeImageTemplate?.rootVStack.childModels.count, 2)
    }
    
    func testLargeImageTemplate_emptySchema() {
        // setup
        let schema = ContentCardSchemaData.getEmpty()

        // test and verify
        XCTAssertNil(LargeImageTemplate(schema, emptyCustomizer))
    }
    
    
    func testLargeImageTemplate_schemaWithNoTitle() {
        // setup
        let schema = ContentCardTestUtil.createContentCardSchemaData(fromFile: "LargeImageTemplate_noTitle")
        
        // test and verify
        XCTAssertNil(LargeImageTemplate(schema, emptyCustomizer))
    }

    func testLargeImageTemplate_schemaWithOnlyTitle() {
        // setup
        let schema = ContentCardTestUtil.createContentCardSchemaData(fromFile: "LargeImageTemplate_onlyTitle")
        
        // test
        let largeImageTemplate = LargeImageTemplate(schema, emptyCustomizer)

        // test and verify
        XCTAssertNotNil(largeImageTemplate)
        XCTAssertEqual(largeImageTemplate?.title.content, "Card Title")
        XCTAssertNil(largeImageTemplate?.body)
        XCTAssertNil(largeImageTemplate?.image)
        XCTAssertNil(largeImageTemplate?.buttons)
        
        // verify stack
        XCTAssertEqual(largeImageTemplate?.buttonHStack.childModels.count, 0)
        XCTAssertEqual(largeImageTemplate?.textVStack.childModels.count, 2)
        XCTAssertEqual(largeImageTemplate?.rootVStack.childModels.count, 1)
    }
    
    func testLargeImageTemplate_validTitle_invalidOther() {
        // setup
        let schema = ContentCardTestUtil.createContentCardSchemaData(fromFile: "LargeImageTemplate_validTitle_invalidOther")
        
        // test
        let largeImageTemplate = LargeImageTemplate(schema, emptyCustomizer)
        
        // test and verify
        XCTAssertNotNil(largeImageTemplate)
        XCTAssertEqual(largeImageTemplate?.title.content, "Card Title")
        XCTAssertNil(largeImageTemplate?.body)
        XCTAssertNil(largeImageTemplate?.image)
        XCTAssertEqual(largeImageTemplate?.buttons?.count, 0)
        
        // verify stack
        XCTAssertEqual(largeImageTemplate?.buttonHStack.childModels.count, 0)
        XCTAssertEqual(largeImageTemplate?.textVStack.childModels.count, 2)
        XCTAssertEqual(largeImageTemplate?.rootVStack.childModels.count, 1)
    }
} 
