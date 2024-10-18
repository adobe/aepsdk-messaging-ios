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
final class AEPImageTests: XCTestCase {
    
    private struct TestConstants {
        static let MOCK_URL = "https://imagesite.com/image.jpg"
        static let MOCK_DARK_URL = "https://imagesite.com/darkimage.jpg"
    }

    func testInit_emptyData() {
        // setup
        let data: [String: Any] = [:]
     
        // test
        let image = AEPImage(data)
     
        // verify
        XCTAssertNil(image)
    }

    func testInit_InvalidData() {
        // setup
        let data = [
            "InvalidKey" : 223
        ] as [String : Any]
        
        // test
        let image = AEPImage(data)
        
        // verify
        XCTAssertNil(image)
    }

    //********************************************
    // Image with URL tests
    //********************************************

    func testInit_imageWithUrl() {
        // setup
        let data = [
            UIConstants.CardTemplate.UIElement.Image.URL: TestConstants.MOCK_URL
        ] as [String : Any]
        
        // test
        let image = AEPImage(data)
        
        // verify
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.imageSourceType, .url)
        XCTAssertEqual(image?.url?.absoluteString, TestConstants.MOCK_URL)
        XCTAssertNil(image?.darkUrl)        
    }

    func testInit_imageWithLightAndDarkModeUrl() {
        // setup
        let data = [
            UIConstants.CardTemplate.UIElement.Image.URL: TestConstants.MOCK_URL,
            UIConstants.CardTemplate.UIElement.Image.DARK_URL: TestConstants.MOCK_DARK_URL
        ] as [String : Any]
        
        // test
        let image = AEPImage(data)
        
        // verify
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.imageSourceType, .url)
        XCTAssertEqual(image?.url?.absoluteString, TestConstants.MOCK_URL)
        XCTAssertEqual(image?.darkUrl?.absoluteString, TestConstants.MOCK_DARK_URL)
    }

    func testInit_imageWithInvalidLightUrl() {
        // setup
        let data = [
            UIConstants.CardTemplate.UIElement.Image.URL: 123,
        ] as [String : Any]
        
        // test
        let image = AEPImage(data)
        
        // verify
        XCTAssertNil(image)
    }

    func testInit_imageWithInvalidDarkUrl() {
        // setup
        let data = [
            UIConstants.CardTemplate.UIElement.Image.URL: TestConstants.MOCK_URL,
            UIConstants.CardTemplate.UIElement.Image.DARK_URL: 123
        ] as [String : Any]
        
        // test
        let image = AEPImage(data)
        
        // verify
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.imageSourceType, .url)
        XCTAssertEqual(image?.url?.absoluteString, TestConstants.MOCK_URL)
        XCTAssertNil(image?.darkUrl)   
    }

    //********************************************
    // Image with Bundled Resource tests
    //********************************************

    func testInit_imageWithBundledResource() {
        // setup
        let data = [
            UIConstants.CardTemplate.UIElement.Image.BUNDLE: "image.jpg"
        ] as [String : Any]
        
        // test
        let image = AEPImage(data)
        
        // verify
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.bundle, "image.jpg")
        XCTAssertEqual(image?.imageSourceType, .bundle)
    }

    func testInit_imageWithLightAndDarkModeBundle() {
        // setup
        let data = [
            UIConstants.CardTemplate.UIElement.Image.BUNDLE: "image.jpg",
            UIConstants.CardTemplate.UIElement.Image.DARK_BUNDLE: "darkimage.jpg"
        ] as [String : Any]
        
        // test
        let image = AEPImage(data)
        
        // verify
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.bundle, "image.jpg")
        XCTAssertEqual(image?.darkBundle, "darkimage.jpg")
        XCTAssertEqual(image?.imageSourceType, .bundle)
    }

}
