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
class TemplateBuilderTests: XCTestCase {
    

    func test_buildTemplate_smallImageTemplate() {
        // setup
        let schema = ContentCardTestUtil.createContentCardSchemaData(fromFile: "SmallImageTemplate")
        
        // test
        let template = TemplateBuilder.buildTemplate(from: schema, customizer: nil)
        
        // verify
        XCTAssertNotNil(template)
        XCTAssertEqual(template?.templateType, .smallImage)
    }
    
    func test_buildTemplate_largeImageTemplate() {
        // setup
        let schema = ContentCardTestUtil.createContentCardSchemaData(fromFile: "LargeImageTemplate")
        
        // test
        let template = TemplateBuilder.buildTemplate(from: schema, customizer: nil)
        
        // verify
        XCTAssertNotNil(template)
        XCTAssertEqual(template?.templateType, .largeImage)
    }
    
    func test_buildTemplate_invalidTemplate() {
        // setup
        let schema = ContentCardTestUtil.createContentCardSchemaData(fromFile: "InvalidTemplate")
        
        // test
        let template = TemplateBuilder.buildTemplate(from: schema, customizer: nil)
        
        // verify
        XCTAssertNil(template)
    }
    
    func test_buildTemplate_imageOnlyTemplate() {
        // setup
        let schema = ContentCardTestUtil.createContentCardSchemaData(fromFile: "ImageOnlyTemplate")
        
        // test
        let template = TemplateBuilder.buildTemplate(from: schema, customizer: nil)
        
        // verify
        XCTAssertNotNil(template)
        XCTAssertEqual(template?.templateType, .imageOnly)
        XCTAssertTrue(template is ImageOnlyTemplate)
    }
    
    func test_buildTemplate_imageOnlyTemplate_onlyImage() {
        // setup
        let schema = ContentCardTestUtil.createContentCardSchemaData(fromFile: "ImageOnlyTemplate_onlyImage")
        
        // test
        let template = TemplateBuilder.buildTemplate(from: schema, customizer: nil)
        
        // verify
        XCTAssertNotNil(template)
        XCTAssertEqual(template?.templateType, .imageOnly)
        XCTAssertTrue(template is ImageOnlyTemplate)
    }
    
    func test_buildTemplate_imageOnlyTemplate_noImage() {
        // setup
        let schema = ContentCardTestUtil.createContentCardSchemaData(fromFile: "ImageOnlyTemplate_noImage")
        
        // test
        let template = TemplateBuilder.buildTemplate(from: schema, customizer: nil)
        
        // verify
        XCTAssertNil(template)
    }
    
    func test_buildTemplate_imageOnlyTemplate_invalidImage() {
        // setup
        let schema = ContentCardTestUtil.createContentCardSchemaData(fromFile: "ImageOnlyTemplate_invalidImage")
        
        // test
        let template = TemplateBuilder.buildTemplate(from: schema, customizer: nil)
        
        // verify
        XCTAssertNil(template)
    }
        
}
