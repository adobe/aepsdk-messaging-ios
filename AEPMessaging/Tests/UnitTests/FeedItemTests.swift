/*
 Copyright 2023 Adobe. All rights reserved.
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

class FeedItemTests: XCTestCase {
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
        let feedItemData = """
{
    "title": "\(mockTitle)",
    "body": "\(mockBody)",
    "imageUrl": "\(mockImageUrl)",
    "actionUrl": "\(mockActionUrl)",
    "actionTitle": "\(mockActionTitle)"
}
""".data(using: .utf8)!
        
        // test
        guard let feedItem = try? decoder.decode(FeedItem.self, from: feedItemData) else {
            XCTFail("unable to decode FeedItem JSON")
            return
        }
        
        // verify
        XCTAssertNotNil(feedItem)
        XCTAssertEqual(mockTitle, feedItem.title)
        XCTAssertEqual(mockBody, feedItem.body)
        XCTAssertEqual(mockImageUrl, feedItem.imageUrl)
        XCTAssertEqual(mockActionUrl, feedItem.actionUrl)
        XCTAssertEqual(mockActionTitle, feedItem.actionTitle)
    }
    
    func testIsEncodable() throws {
        // setup
        let decoder = JSONDecoder()
        let feedItemData = """
{
    "title": "\(mockTitle)",
    "body": "\(mockBody)",
    "imageUrl": "\(mockImageUrl)",
    "actionUrl": "\(mockActionUrl)",
    "actionTitle": "\(mockActionTitle)"
}
""".data(using: .utf8)!
        
        // test
        guard let feedItem = try? decoder.decode(FeedItem.self, from: feedItemData) else {
            XCTFail("unable to decode FeedItem JSON")
            return
        }
        
        let encoder = JSONEncoder()

        // test
        guard let encodedFeedItem = try? encoder.encode(feedItem) else {
            XCTFail("unable to encode the FeedItem")
            return
        }
        
        // verify
        guard let encodedFeedItemString = String(data: encodedFeedItem, encoding: .utf8) else {
            XCTFail("unable to encode the FeedItem")
            return
        }
        XCTAssertTrue(encodedFeedItemString.contains("\"title\":\"\(mockTitle)\""))
        XCTAssertTrue(encodedFeedItemString.contains("\"body\":\"\(mockBody)\""))
        XCTAssertTrue(encodedFeedItemString.contains("\"imageUrl\":\"\(mockImageUrl)\""))
        XCTAssertTrue(encodedFeedItemString.contains("\"actionUrl\":\"\(mockActionUrl)\""))
        XCTAssertTrue(encodedFeedItemString.contains("\"actionTitle\":\"\(mockActionTitle)\""))
    }
    

    
    // MARK: - test required properties
    func testTitleIsRequired() throws {
        // setup
        let decoder = JSONDecoder()
        let feedItemData = """
{
    "body": "\(mockBody)",
    "imageUrl": "\(mockImageUrl)",
    "actionUrl": "\(mockActionUrl)",
    "actionTitle": "\(mockActionTitle)"
}
""".data(using: .utf8)!
        
        // test
        let feedItem = try? decoder.decode(FeedItem.self, from: feedItemData)
        
        // verify
        XCTAssertNil(feedItem)
    }
    
    func testBodyIsRequired() throws {
        // setup
        let decoder = JSONDecoder()
        let feedItemData = """
{
    "title": "\(mockTitle)",
    "imageUrl": "\(mockImageUrl)",
    "actionUrl": "\(mockActionUrl)",
    "actionTitle": "\(mockActionTitle)"
}
""".data(using: .utf8)!
        
        // test
        let feedItem = try? decoder.decode(FeedItem.self, from: feedItemData)
        
        // verify
        XCTAssertNil(feedItem)
    }
    
    // MARK: - test optional properties
    
    func testImageUrlIsNotRequired() throws {
        // setup
        let decoder = JSONDecoder()
        let feedItemData = """
{
    "title": "\(mockTitle)",
    "body": "\(mockBody)",
    "actionUrl": "\(mockActionUrl)",
    "actionTitle": "\(mockActionTitle)"
}
""".data(using: .utf8)!
        
        // test
        guard let feedItem = try? decoder.decode(FeedItem.self, from: feedItemData) else {
            XCTFail("unable to decode FeedItem JSON")
            return
        }
        
        // verify
        XCTAssertNotNil(feedItem)
        XCTAssertEqual(mockTitle, feedItem.title)
        XCTAssertEqual(mockBody, feedItem.body)
        XCTAssertNil(feedItem.imageUrl)
        XCTAssertEqual(mockActionUrl, feedItem.actionUrl)
        XCTAssertEqual(mockActionTitle, feedItem.actionTitle)
    }
    
    func testActionUrlIsNotRequired() throws {
        // setup
        let decoder = JSONDecoder()
        let feedItemData = """
{
    "title": "\(mockTitle)",
    "body": "\(mockBody)",
    "imageUrl": "\(mockImageUrl)",
    "actionTitle": "\(mockActionTitle)"
}
""".data(using: .utf8)!
        
        // test
        guard let feedItem = try? decoder.decode(FeedItem.self, from: feedItemData) else {
            XCTFail("unable to decode FeedItem JSON")
            return
        }
        
        // verify
        XCTAssertNotNil(feedItem)
        XCTAssertEqual(mockTitle, feedItem.title)
        XCTAssertEqual(mockBody, feedItem.body)
        XCTAssertEqual(mockImageUrl, feedItem.imageUrl)
        XCTAssertNil(feedItem.actionUrl)
        XCTAssertEqual(mockActionTitle, feedItem.actionTitle)
    }
    
    func testActionTitleIsNotRequired() throws {
        // setup
        let decoder = JSONDecoder()
        let feedItemData = """
{
    "title": "\(mockTitle)",
    "body": "\(mockBody)",
    "imageUrl": "\(mockImageUrl)",
    "actionUrl": "\(mockActionUrl)"
}
""".data(using: .utf8)!
        
        // test
        guard let feedItem = try? decoder.decode(FeedItem.self, from: feedItemData) else {
            XCTFail("unable to decode FeedItem JSON")
            return
        }
        
        // verify
        XCTAssertNotNil(feedItem)
        XCTAssertEqual(mockTitle, feedItem.title)
        XCTAssertEqual(mockBody, feedItem.body)
        XCTAssertEqual(mockImageUrl, feedItem.imageUrl)
        XCTAssertEqual(mockActionUrl, feedItem.actionUrl)
        XCTAssertNil(feedItem.actionTitle)
    }
}
