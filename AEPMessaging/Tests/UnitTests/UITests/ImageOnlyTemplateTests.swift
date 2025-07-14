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
final class ImageOnlyTemplateTests: XCTestCase {
    
    var emptyCustomizer = EmptyCustomizer()

    func testImageOnlyTemplate_happy() {
        // setup
        let schema = ContentCardTestUtil.createContentCardSchemaData(fromFile: "ImageOnlyTemplate")

        // test
        let imageOnlyTemplate = ImageOnlyTemplate(schema, emptyCustomizer)

        // verify
        XCTAssertNotNil(imageOnlyTemplate)
        XCTAssertEqual(imageOnlyTemplate?.templateType, .imageOnly)
        XCTAssertEqual(imageOnlyTemplate?.image.url?.absoluteString, "https://imagetoDownload.com/cardimage")
        XCTAssertEqual(imageOnlyTemplate?.image.darkUrl?.absoluteString, "https://imagetoDownload.com/darkimage")
        XCTAssertEqual(imageOnlyTemplate?.image.altText, "flight offer")
        XCTAssertEqual(imageOnlyTemplate?.actionURL?.absoluteString, "https://google.com")
        XCTAssertNotNil(imageOnlyTemplate?.dismissButton)
        XCTAssertNotNil(imageOnlyTemplate?.view)
    }

    func testImageOnlyTemplate_emptySchema() {
        // setup
        let schema = ContentCardSchemaData.getEmpty()

        // test and verify
        XCTAssertNil(ImageOnlyTemplate(schema, emptyCustomizer))
    }

    func testImageOnlyTemplate_schemaWithNoImage() {
        // setup
        let schema = ContentCardTestUtil.createContentCardSchemaData(fromFile: "ImageOnlyTemplate_noImage")
        
        // test and verify
        XCTAssertNil(ImageOnlyTemplate(schema, emptyCustomizer))
    }

    func testImageOnlyTemplate_schemaWithOnlyImage() {
        // setup
        let schema = ContentCardTestUtil.createContentCardSchemaData(fromFile: "ImageOnlyTemplate_onlyImage")
        
        // test
        let imageOnlyTemplate = ImageOnlyTemplate(schema, emptyCustomizer)

        // verify
        XCTAssertNotNil(imageOnlyTemplate)
        XCTAssertEqual(imageOnlyTemplate?.templateType, .imageOnly)
        XCTAssertEqual(imageOnlyTemplate?.image.url?.absoluteString, "https://imagetoDownload.com/cardimage")
        XCTAssertNil(imageOnlyTemplate?.image.darkUrl)
        XCTAssertNil(imageOnlyTemplate?.image.altText)
        XCTAssertNil(imageOnlyTemplate?.actionURL)
        XCTAssertNil(imageOnlyTemplate?.dismissButton)
        XCTAssertNotNil(imageOnlyTemplate?.view)
    }
    
    func testImageOnlyTemplate_noActionUrl() {
        // setup
        let schema = ContentCardTestUtil.createContentCardSchemaData(fromFile: "ImageOnlyTemplate_noActionUrl")
        
        // test
        let imageOnlyTemplate = ImageOnlyTemplate(schema, emptyCustomizer)
        
        // verify
        XCTAssertNotNil(imageOnlyTemplate)
        XCTAssertEqual(imageOnlyTemplate?.templateType, .imageOnly)
        XCTAssertEqual(imageOnlyTemplate?.image.url?.absoluteString, "https://imagetoDownload.com/cardimage")
        XCTAssertEqual(imageOnlyTemplate?.image.darkUrl?.absoluteString, "https://imagetoDownload.com/darkimage")
        XCTAssertEqual(imageOnlyTemplate?.image.altText, "flight offer")
        XCTAssertNil(imageOnlyTemplate?.actionURL)
        XCTAssertNotNil(imageOnlyTemplate?.dismissButton)
        XCTAssertNotNil(imageOnlyTemplate?.view)
    }
    
    func testImageOnlyTemplate_validImage_invalidOther() {
        // setup
        let schema = ContentCardTestUtil.createContentCardSchemaData(fromFile: "ImageOnlyTemplate_validImage_invalidOther")
        
        // test
        let imageOnlyTemplate = ImageOnlyTemplate(schema, emptyCustomizer)
        
        // verify
        XCTAssertNotNil(imageOnlyTemplate)
        XCTAssertEqual(imageOnlyTemplate?.templateType, .imageOnly)
        XCTAssertEqual(imageOnlyTemplate?.image.url?.absoluteString, "https://imagetoDownload.com/cardimage")
        XCTAssertEqual(imageOnlyTemplate?.image.darkUrl?.absoluteString, "https://imagetoDownload.com/darkimage")
        XCTAssertEqual(imageOnlyTemplate?.actionURL?.absoluteString, "https://actionUrl.com")
        XCTAssertNil(imageOnlyTemplate?.dismissButton) // Should be nil due to invalid key
        XCTAssertNotNil(imageOnlyTemplate?.view)
    }
    
    func testImageOnlyTemplate_invalidImage() {
        // setup
        let schema = ContentCardTestUtil.createContentCardSchemaData(fromFile: "ImageOnlyTemplate_invalidImage")
        
        // test and verify
        XCTAssertNil(ImageOnlyTemplate(schema, emptyCustomizer))
    }
}
