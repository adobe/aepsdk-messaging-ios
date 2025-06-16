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
final class ContentCardSchemaDataTemplateTests: XCTestCase {
    
    let smallImageSchema = ContentCardTestUtil.createContentCardSchemaData(fromFile: "SmallImageTemplate")
    let largeImageSchema = ContentCardTestUtil.createContentCardSchemaData(fromFile: "LargeImageTemplate")
    let emptySchema = ContentCardSchemaData.getEmpty()
    let invalidSchema = ContentCardTestUtil.createContentCardSchemaData(fromFile: "InvalidTemplate")
    let mockTemplate : MockTemplate = MockTemplate(ContentCardSchemaData.getEmpty())!

    func test_templateType() {
        XCTAssertEqual(emptySchema.templateType, .unknown)
        XCTAssertEqual(smallImageSchema.templateType, .smallImage)
        XCTAssertEqual(largeImageSchema.templateType, .largeImage)
    }

    func test_titleExtraction() {
        XCTAssertNil(emptySchema.title)
        XCTAssertNil(invalidSchema.title)
        let title = smallImageSchema.title
        XCTAssertNotNil(title)
        XCTAssertEqual(title?.content, "Card Title")
        
        let largeImageTitle = largeImageSchema.title
        XCTAssertNotNil(largeImageTitle)
        XCTAssertEqual(largeImageTitle?.content, "Card Title")
    }

    func test_bodyExtraction() {
        XCTAssertNil(emptySchema.body)
        XCTAssertNil(invalidSchema.body)
        let body = smallImageSchema.body
        XCTAssertNotNil(body)
        XCTAssertEqual(body?.content, "Card Body")
        
        let largeImageBody = largeImageSchema.body
        XCTAssertNotNil(largeImageBody)
        XCTAssertEqual(largeImageBody?.content, "body")
    }
    
    func test_imageExtraction() {
        XCTAssertNil(emptySchema.image)
        XCTAssertNil(invalidSchema.image)
        let image = smallImageSchema.image
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.url?.absoluteString, "https://imagetoDownload.com/cardimage")
        
        let largeImage = largeImageSchema.image
        XCTAssertNotNil(largeImage)
        XCTAssertEqual(largeImage?.url?.absoluteString, "https://imagetoDownload.com/cardimage")
        XCTAssertEqual(largeImage?.darkUrl?.absoluteString, "https://imagetoDownload.com/darkimage")
    }
    
    func test_buttonsExtraction() {
        // test with empty schema
        XCTAssertNil(emptySchema.getButtons(forTemplate: mockTemplate))
        XCTAssertNil(invalidSchema.getButtons(forTemplate: mockTemplate))
        
        // test with small image template schema
        let buttons = smallImageSchema.getButtons(forTemplate: mockTemplate)
        XCTAssertNotNil(buttons)
        XCTAssertEqual(buttons?.count, 2)
        
        // verify each button
        XCTAssertEqual(buttons?[0].interactId, "purchaseID")
        XCTAssertEqual(buttons?[1].interactId, "cancelID")
        
        // test with large image template schema
        let largeImageButtons = largeImageSchema.getButtons(forTemplate: mockTemplate)
        XCTAssertNotNil(largeImageButtons)
        XCTAssertEqual(largeImageButtons?.count, 2)
        
        // verify each button
        XCTAssertEqual(largeImageButtons?[0].interactId, "purchaseID")
        XCTAssertEqual(largeImageButtons?[1].interactId, "cancelID")
    }

    func test_actionUrlExtraction() {
        XCTAssertNil(emptySchema.actionUrl)
        let actionUrl = smallImageSchema.actionUrl
        XCTAssertNotNil(actionUrl)
        XCTAssertEqual(actionUrl?.absoluteString, "https://actionUrl.com")
        
        let largeImageActionUrl = largeImageSchema.actionUrl
        XCTAssertNotNil(largeImageActionUrl)
        XCTAssertEqual(largeImageActionUrl?.absoluteString, "https://luma.com/sale")
    }

}

