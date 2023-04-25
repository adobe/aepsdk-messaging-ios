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
    let mockId = "mockId"
    let mockTitle = "mockTitle"
    let mockBody = "mockBody"
    let mockImageUrl = "mockImageUrl"
    let mockActionUrl = "mockActionUrl"
    let mockActionTitle = "mockActionTitle"
    let mockPublishedDate = 123456789
    let mockExpiryDate = 23456789
    let mockMeta: [String: Any] = [
        "stringKey": "value",
        "intKey": 552
    ]
            
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
    "id": "\(mockId)",
    "title": "\(mockTitle)",
    "body": "\(mockBody)",
    "imageUrl": "\(mockImageUrl)",
    "actionUrl": "\(mockActionUrl)",
    "actionTitle": "\(mockActionTitle)",
    "publishedDate": \(mockPublishedDate),
    "expiryDate": \(mockExpiryDate),
    "meta": {
        "stringKey": "value",
        "intKey": 552
    }
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
        XCTAssertEqual(mockPublishedDate, feedItem.publishedDate)
        XCTAssertEqual(mockExpiryDate, feedItem.expiryDate)
        XCTAssertTrue(dictionariesAreEqual(mockMeta, feedItem.meta))
    }
    
    func testIsEncodable() throws {
        // setup
        let decoder = JSONDecoder()
        let feedItemData = """
{
    "id": "\(mockId)",
    "title": "\(mockTitle)",
    "body": "\(mockBody)",
    "imageUrl": "\(mockImageUrl)",
    "actionUrl": "\(mockActionUrl)",
    "actionTitle": "\(mockActionTitle)",
    "publishedDate": \(mockPublishedDate),
    "expiryDate": \(mockExpiryDate),
    "meta": {
        "stringKey": "value",
        "intKey": 552
    }
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
        XCTAssertTrue(encodedFeedItemString.contains("\"publishedDate\":\(mockPublishedDate)"))
        XCTAssertTrue(encodedFeedItemString.contains("\"expiryDate\":\(mockExpiryDate)"))
        let metaV1 = encodedFeedItemString.contains("\"meta\":{\"intKey\":552,\"stringKey\":\"value\"}")
        let metaV2 = encodedFeedItemString.contains("\"meta\":{\"stringKey\":\"value\",\"intKey\":552}")
        XCTAssertTrue(metaV1 || metaV2)
    }
    

    
    // MARK: - test required properties
    func testTitleIsRequired() throws {
        // setup
        let decoder = JSONDecoder()
        let feedItemData = """
{
    "id": "\(mockId)",
    "body": "\(mockBody)",
    "imageUrl": "\(mockImageUrl)",
    "actionUrl": "\(mockActionUrl)",
    "actionTitle": "\(mockActionTitle)",
    "publishedDate": \(mockPublishedDate),
    "expiryDate": \(mockExpiryDate),
    "meta": {
        "stringKey": "value",
        "intKey": 552
    }
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
    "id": "\(mockId)",
    "title": "\(mockTitle)",
    "imageUrl": "\(mockImageUrl)",
    "actionUrl": "\(mockActionUrl)",
    "actionTitle": "\(mockActionTitle)",
    "publishedDate": \(mockPublishedDate),
    "expiryDate": \(mockExpiryDate),
    "meta": {
        "stringKey": "value",
        "intKey": 552
    }
}
""".data(using: .utf8)!
        
        // test
        let feedItem = try? decoder.decode(FeedItem.self, from: feedItemData)
        
        // verify
        XCTAssertNil(feedItem)
    }
    
    func testPublishedDateIsRequired() throws {
        // setup
        let decoder = JSONDecoder()
        let feedItemData = """
{
    "id": "\(mockId)",
    "title": "\(mockTitle)",
    "body": "\(mockBody)",
    "imageUrl": "\(mockImageUrl)",
    "actionUrl": "\(mockActionUrl)",
    "actionTitle": "\(mockActionTitle)",
    "expiryDate": \(mockExpiryDate),
    "meta": {
        "stringKey": "value",
        "intKey": 552
    }
}
""".data(using: .utf8)!
        
        // test
        let feedItem = try? decoder.decode(FeedItem.self, from: feedItemData)
        
        // verify
        XCTAssertNil(feedItem)
    }
    
    func testExpiryDateIsRequired() throws {
        // setup
        let decoder = JSONDecoder()
        let feedItemData = """
{
    "id": "\(mockId)",
    "title": "\(mockTitle)",
    "body": "\(mockBody)",
    "imageUrl": "\(mockImageUrl)",
    "actionUrl": "\(mockActionUrl)",
    "actionTitle": "\(mockActionTitle)",
    "publishedDate": \(mockPublishedDate),
    "meta": {
        "stringKey": "value",
        "intKey": 552
    }
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
    "id": "\(mockId)",
    "title": "\(mockTitle)",
    "body": "\(mockBody)",
    "actionUrl": "\(mockActionUrl)",
    "actionTitle": "\(mockActionTitle)",
    "publishedDate": \(mockPublishedDate),
    "expiryDate": \(mockExpiryDate),
    "meta": {
        "stringKey": "value",
        "intKey": 552
    }
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
        XCTAssertEqual(mockPublishedDate, feedItem.publishedDate)
        XCTAssertEqual(mockExpiryDate, feedItem.expiryDate)
        XCTAssertTrue(dictionariesAreEqual(mockMeta, feedItem.meta))
    }
    
    func testActionUrlIsNotRequired() throws {
        // setup
        let decoder = JSONDecoder()
        let feedItemData = """
{
    "id": "\(mockId)",
    "title": "\(mockTitle)",
    "body": "\(mockBody)",
    "imageUrl": "\(mockImageUrl)",
    "actionTitle": "\(mockActionTitle)",
    "publishedDate": \(mockPublishedDate),
    "expiryDate": \(mockExpiryDate),
    "meta": {
        "stringKey": "value",
        "intKey": 552
    }
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
        XCTAssertEqual(mockPublishedDate, feedItem.publishedDate)
        XCTAssertEqual(mockExpiryDate, feedItem.expiryDate)
        XCTAssertTrue(dictionariesAreEqual(mockMeta, feedItem.meta))
    }
    
    func testActionTitleIsNotRequired() throws {
        // setup
        let decoder = JSONDecoder()
        let feedItemData = """
{
    "id": "\(mockId)",
    "title": "\(mockTitle)",
    "body": "\(mockBody)",
    "imageUrl": "\(mockImageUrl)",
    "actionUrl": "\(mockActionUrl)",
    "publishedDate": \(mockPublishedDate),
    "expiryDate": \(mockExpiryDate),
    "meta": {
        "stringKey": "value",
        "intKey": 552
    }
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
        XCTAssertEqual(mockPublishedDate, feedItem.publishedDate)
        XCTAssertEqual(mockExpiryDate, feedItem.expiryDate)
        XCTAssertTrue(dictionariesAreEqual(mockMeta, feedItem.meta))
    }
    
    func testMetaIsNotRequired() throws {
        // setup
        let decoder = JSONDecoder()
        let feedItemData = """
{
    "id": "\(mockId)",
    "title": "\(mockTitle)",
    "body": "\(mockBody)",
    "imageUrl": "\(mockImageUrl)",
    "actionUrl": "\(mockActionUrl)",
    "actionTitle": "\(mockActionTitle)",
    "publishedDate": \(mockPublishedDate),
    "expiryDate": \(mockExpiryDate)
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
        XCTAssertEqual(mockPublishedDate, feedItem.publishedDate)
        XCTAssertEqual(mockExpiryDate, feedItem.expiryDate)
        XCTAssertNil(feedItem.meta)
    }
}
