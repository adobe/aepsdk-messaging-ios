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
import AEPServices

@available(*, deprecated)
class ContentCardTests: XCTestCase {
    let mockTitle = "mockTitle"
    let mockBody = "mockBody"
    let mockImageUrl = "mockImageUrl"
    let mockActionUrl = "mockActionUrl"
    let mockActionTitle = "mockActionTitle"
            
    override func setUp() {
        
    }
    
    // MARK: - Helpers
    func dictionariesAreEqual (_ lhs: [String: Any]?, _ rhs: [String: Any]?) -> Bool {
        if let l = lhs, let r = rhs {
            return NSDictionary(dictionary: l).isEqual(to: r)
        }
        return lhs == nil && rhs == nil
    }

    // MARK: - Happy path
    
    func testIsDecodable() throws {
        // setup
        let decoder = JSONDecoder()
        let contentCardData = """
{
    "title": "\(mockTitle)",
    "body": "\(mockBody)",
    "imageUrl": "\(mockImageUrl)",
    "actionUrl": "\(mockActionUrl)",
    "actionTitle": "\(mockActionTitle)"
}
""".data(using: .utf8)!
        
        // test
        guard let contentCard = try? decoder.decode(ContentCard.self, from: contentCardData) else {
            XCTFail("unable to decode ContentCard JSON")
            return
        }
        
        // verify
        XCTAssertNotNil(contentCard)
        XCTAssertEqual(mockTitle, contentCard.title)
        XCTAssertEqual(mockBody, contentCard.body)
        XCTAssertEqual(mockImageUrl, contentCard.imageUrl)
        XCTAssertEqual(mockActionUrl, contentCard.actionUrl)
        XCTAssertEqual(mockActionTitle, contentCard.actionTitle)
    }
    
    func testIsEncodable() throws {
        // setup
        let decoder = JSONDecoder()
        let contentCardData = """
{
    "title": "\(mockTitle)",
    "body": "\(mockBody)",
    "imageUrl": "\(mockImageUrl)",
    "actionUrl": "\(mockActionUrl)",
    "actionTitle": "\(mockActionTitle)"
}
""".data(using: .utf8)!
        
        // test
        guard let contentCard = try? decoder.decode(ContentCard.self, from: contentCardData) else {
            XCTFail("unable to decode ContentCard JSON")
            return
        }
        
        let encoder = JSONEncoder()

        // test
        guard let encodedContentCard = try? encoder.encode(contentCard) else {
            XCTFail("unable to encode the ContentCard")
            return
        }
        
        // verify
        guard let encodedContentCardString = String(data: encodedContentCard, encoding: .utf8) else {
            XCTFail("unable to encode the ContentCard")
            return
        }
        XCTAssertTrue(encodedContentCardString.contains("\"title\":\"\(mockTitle)\""))
        XCTAssertTrue(encodedContentCardString.contains("\"body\":\"\(mockBody)\""))
        XCTAssertTrue(encodedContentCardString.contains("\"imageUrl\":\"\(mockImageUrl)\""))
        XCTAssertTrue(encodedContentCardString.contains("\"actionUrl\":\"\(mockActionUrl)\""))
        XCTAssertTrue(encodedContentCardString.contains("\"actionTitle\":\"\(mockActionTitle)\""))
    }
    

    
    // MARK: - test required properties
    func testTitleIsRequired() throws {
        // setup
        let decoder = JSONDecoder()
        let contentCardData = """
{
    "body": "\(mockBody)",
    "imageUrl": "\(mockImageUrl)",
    "actionUrl": "\(mockActionUrl)",
    "actionTitle": "\(mockActionTitle)"
}
""".data(using: .utf8)!
        
        // test
        let contentCard = try? decoder.decode(ContentCard.self, from: contentCardData)
        
        // verify
        XCTAssertNil(contentCard)
    }
    
    func testBodyIsRequired() throws {
        // setup
        let decoder = JSONDecoder()
        let contentCardData = """
{
    "title": "\(mockTitle)",
    "imageUrl": "\(mockImageUrl)",
    "actionUrl": "\(mockActionUrl)",
    "actionTitle": "\(mockActionTitle)"
}
""".data(using: .utf8)!
        
        // test
        let contentCard = try? decoder.decode(ContentCard.self, from: contentCardData)
        
        // verify
        XCTAssertNil(contentCard)
    }
    
    // MARK: - test optional properties
    
    func testImageUrlIsNotRequired() throws {
        // setup
        let decoder = JSONDecoder()
        let contentCardData = """
{
    "title": "\(mockTitle)",
    "body": "\(mockBody)",
    "actionUrl": "\(mockActionUrl)",
    "actionTitle": "\(mockActionTitle)"
}
""".data(using: .utf8)!
        
        // test
        guard let contentCard = try? decoder.decode(ContentCard.self, from: contentCardData) else {
            XCTFail("unable to decode ContentCard JSON")
            return
        }
        
        // verify
        XCTAssertNotNil(contentCard)
        XCTAssertEqual(mockTitle, contentCard.title)
        XCTAssertEqual(mockBody, contentCard.body)
        XCTAssertNil(contentCard.imageUrl)
        XCTAssertEqual(mockActionUrl, contentCard.actionUrl)
        XCTAssertEqual(mockActionTitle, contentCard.actionTitle)
    }
    
    func testActionUrlIsNotRequired() throws {
        // setup
        let decoder = JSONDecoder()
        let contentCardData = """
{
    "title": "\(mockTitle)",
    "body": "\(mockBody)",
    "imageUrl": "\(mockImageUrl)",
    "actionTitle": "\(mockActionTitle)"
}
""".data(using: .utf8)!
        
        // test
        guard let contentCard = try? decoder.decode(ContentCard.self, from: contentCardData) else {
            XCTFail("unable to decode ContentCard JSON")
            return
        }
        
        // verify
        XCTAssertNotNil(contentCard)
        XCTAssertEqual(mockTitle, contentCard.title)
        XCTAssertEqual(mockBody, contentCard.body)
        XCTAssertEqual(mockImageUrl, contentCard.imageUrl)
        XCTAssertNil(contentCard.actionUrl)
        XCTAssertEqual(mockActionTitle, contentCard.actionTitle)
    }
    
    func testActionTitleIsNotRequired() throws {
        // setup
        let decoder = JSONDecoder()
        let contentCardData = """
{
    "title": "\(mockTitle)",
    "body": "\(mockBody)",
    "imageUrl": "\(mockImageUrl)",
    "actionUrl": "\(mockActionUrl)"
}
""".data(using: .utf8)!
        
        // test
        guard let contentCard = try? decoder.decode(ContentCard.self, from: contentCardData) else {
            XCTFail("unable to decode ContentCard JSON")
            return
        }
        
        // verify
        XCTAssertNotNil(contentCard)
        XCTAssertEqual(mockTitle, contentCard.title)
        XCTAssertEqual(mockBody, contentCard.body)
        XCTAssertEqual(mockImageUrl, contentCard.imageUrl)
        XCTAssertEqual(mockActionUrl, contentCard.actionUrl)
        XCTAssertNil(contentCard.actionTitle)
    }
}
