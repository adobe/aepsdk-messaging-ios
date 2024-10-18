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
final class SmallImageTemplateTests: XCTestCase {
    
    var emptyCustomizer = EmptyCustomizer()
    
    func testSmallImageTemplate_happy() {
        // setup
        let schema = ContentCardTestUtil.createContentCardSchemaData(fromFile: "SmallImageTemplate")

        // test
        let smallImageTemplate = SmallImageTemplate(schema, emptyCustomizer)

        // verify
        XCTAssertNotNil(smallImageTemplate)
        XCTAssertEqual(smallImageTemplate?.title.content, "Card Title")
        XCTAssertEqual(smallImageTemplate?.body?.content, "Card Body")
        XCTAssertEqual(smallImageTemplate?.image?.url?.absoluteString, "https://imagetoDownload.com/cardimage")
        XCTAssertEqual(smallImageTemplate?.buttons?.count, 2)
        XCTAssertEqual(smallImageTemplate?.buttons?.count, 2)

        // verify first button
        XCTAssertEqual(smallImageTemplate?.buttons?[0].text.content, "Purchase Now")
        XCTAssertEqual(smallImageTemplate?.buttons?[0].interactId, "purchaseID")
        XCTAssertEqual(smallImageTemplate?.buttons?[0].actionUrl, URL(string: "https://adobe.com/offer"))

        // verify second button
        XCTAssertEqual(smallImageTemplate?.buttons?[1].text.content, "Cancel")
        XCTAssertEqual(smallImageTemplate?.buttons?[1].interactId, "cancelID")
        XCTAssertEqual(smallImageTemplate?.buttons?[1].actionUrl, URL(string: "app://home"))

        // verify stacks
        XCTAssertEqual(smallImageTemplate?.buttonHStack.childModels.count, 2)
        XCTAssertEqual(smallImageTemplate?.textVStack.childModels.count, 3)
        XCTAssertEqual(smallImageTemplate?.rootHStack.childModels.count, 2)
    }
    
    func testSmallImageTemplate_emptySchema() {
        // setup
        let schema = ContentCardSchemaData.getEmpty()

        // test and verify
        XCTAssertNil(SmallImageTemplate(schema, emptyCustomizer))
    }
    
    
    func testSmallImageTemplate_schemaWithNoTitle() {
        // setup
        let schema = ContentCardTestUtil.createContentCardSchemaData(fromFile: "SmallImageTemplate_noTitle")
        
        // test and verify
        XCTAssertNil(SmallImageTemplate(schema, emptyCustomizer))
    }

    func testSmallImageTemplate_schemaWithOnlyTitle() {
        // setup
        let schema = ContentCardTestUtil.createContentCardSchemaData(fromFile: "SmallImageTemplate_onlyTitle")
        
        // test
        let smallImageTemplate = SmallImageTemplate(schema, emptyCustomizer)

        // test and verify
        XCTAssertNotNil(smallImageTemplate)
        XCTAssertEqual(smallImageTemplate?.title.content, "Card Title")
        XCTAssertNil(smallImageTemplate?.body)
        XCTAssertNil(smallImageTemplate?.image)
        XCTAssertNil(smallImageTemplate?.buttons)
        
        // verify stack
        XCTAssertEqual(smallImageTemplate?.buttonHStack.childModels.count, 0)
        XCTAssertEqual(smallImageTemplate?.textVStack.childModels.count, 2)
        XCTAssertEqual(smallImageTemplate?.rootHStack.childModels.count, 1)
    }
    
    func testSmallImageTemplate_validTitle_invalidOther() {
        // setup
        let schema = ContentCardTestUtil.createContentCardSchemaData(fromFile: "SmallImageTemplate_validTitle_invalidOther")
        
        // test
        let smallImageTemplate = SmallImageTemplate(schema, emptyCustomizer)
        
        // test and verify
        XCTAssertNotNil(smallImageTemplate)
        XCTAssertEqual(smallImageTemplate?.title.content, "Card Title")
        XCTAssertNil(smallImageTemplate?.body)
        XCTAssertNil(smallImageTemplate?.image)
        XCTAssertEqual(smallImageTemplate?.buttons?.count, 0)
        
        // verify stack
        XCTAssertEqual(smallImageTemplate?.buttonHStack.childModels.count, 0)
        XCTAssertEqual(smallImageTemplate?.textVStack.childModels.count, 2)
        XCTAssertEqual(smallImageTemplate?.rootHStack.childModels.count, 1)
    }
}
