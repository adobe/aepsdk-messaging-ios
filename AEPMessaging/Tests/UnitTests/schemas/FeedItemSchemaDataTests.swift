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
import AEPTestUtils

class FeedItemSchemaDataTests: XCTestCase, AnyCodableAsserts {
    
    let mockExpiry = 1723163897
    let mockPublished = 1691541497
    let mockContentType = ContentType.applicationJson
    let mockContentKey = "contentKey"
    let mockContentValue = "value"
    let mockMetaKey = "metaKey"
    let mockMetaValue = "value"
        
    func getDecodedFeedItem(fromString: String) -> FeedItemSchemaData? {
        let decoder = JSONDecoder()
        let feedItemData = fromString.data(using: .utf8)!
        guard let feedItem = try? decoder.decode(FeedItemSchemaData.self, from: feedItemData) else {
            return nil
        }
        return feedItem
    }
    
    func testIsDecodable() throws {
        // test
        let feedJson = "{\"expiryDate\":\(mockExpiry),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"content\":{\"\(mockContentKey)\":\"\(mockContentValue)\"},\"contentType\":\"\(mockContentType.toString())\",\"publishedDate\":\(mockPublished)}"
        guard let feedItem = getDecodedFeedItem(fromString: feedJson) else {
            XCTFail("unable to decode feedJson")
            return
        }
        
        // verify
        XCTAssertNotNil(feedItem)
        XCTAssertEqual(mockExpiry, feedItem.expiryDate)
        XCTAssertEqual(mockPublished, feedItem.publishedDate)
        XCTAssertEqual(mockContentType, feedItem.contentType)
        let content = feedItem.content as? [String: String]
        XCTAssertEqual(mockContentValue, content?[mockContentKey])
        XCTAssertEqual(mockMetaValue, feedItem.meta?[mockMetaKey] as? String)
    }
    
    func testIsDecodableStringContent() throws {
        // test
        let feedJson = "{\"expiryDate\":\(mockExpiry),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"content\":\"\(mockContentValue)\",\"contentType\":\"\(ContentType.textPlain.toString())\",\"publishedDate\":\(mockPublished)}"
        guard let feedItem = getDecodedFeedItem(fromString: feedJson) else {
            XCTFail("unable to decode feedJson")
            return
        }
        
        // verify
        XCTAssertNotNil(feedItem)
        XCTAssertEqual(mockExpiry, feedItem.expiryDate)
        XCTAssertEqual(mockPublished, feedItem.publishedDate)
        XCTAssertEqual(.textPlain, feedItem.contentType)
        XCTAssertEqual(mockContentValue, feedItem.content as? String)
        XCTAssertEqual(mockMetaValue, feedItem.meta?[mockMetaKey] as? String)
    }
    
    func testIsDecodableBadJson() throws {
        // test
        let feedJson = "{\"expiryDate\":\(mockExpiry),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"content\":\"I AM NOT JSON\",\"contentType\":\"\(mockContentType.toString())\",\"publishedDate\":\(mockPublished)}"
        let feedItem = getDecodedFeedItem(fromString: feedJson)
        
        // verify
        XCTAssertNil(feedItem)
    }
    
    func testIsEncodable() throws {
        // setup
        let feedJson = "{\"expiryDate\":\(mockExpiry),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"content\":{\"\(mockContentKey)\":\"\(mockContentValue)\"},\"contentType\":\"\(mockContentType.toString())\",\"publishedDate\":\(mockPublished)}"
        guard let feedItem = getDecodedFeedItem(fromString: feedJson) else {
            XCTFail("unable to decode feedJson")
            return
        }
        let encoder = JSONEncoder()
        let expected = "{\"expiryDate\":\(mockExpiry),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"content\":{\"\(mockContentKey)\":\"\(mockContentValue)\"},\"contentType\":\"\(mockContentType.toString())\",\"publishedDate\":\(mockPublished)}".toAnyCodable() ?? "fail"

        // test
        guard let encodedFeedItem = try? encoder.encode(feedItem) else {
            XCTFail("unable to encode FeedItemSchemaData")
            return
        }

        // verify
        let actual = String(data: encodedFeedItem, encoding: .utf8)?.toAnyCodable() ?? ""
        assertExactMatch(expected: expected, actual: actual, pathOptions: [])
    }
    
    func testIsEncodableStringContent() throws {
        // setup
        let feedJson = "{\"expiryDate\":\(mockExpiry),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"content\":\"\(mockContentValue)\",\"contentType\":\"\(ContentType.textPlain.toString())\",\"publishedDate\":\(mockPublished)}"
        guard let feedItem = getDecodedFeedItem(fromString: feedJson) else {
            XCTFail("unable to decode feedJson")
            return
        }
        let encoder = JSONEncoder()
        let expected = "{\"expiryDate\":\(mockExpiry),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"content\":\"\(mockContentValue)\",\"contentType\":\"\(ContentType.textPlain.toString())\",\"publishedDate\":\(mockPublished)}".toAnyCodable() ?? "fail"

        // test
        guard let encodedFeedItem = try? encoder.encode(feedItem) else {
            XCTFail("unable to encode FeedItemSchemaData")
            return
        }

        // verify
        let actual = String(data: encodedFeedItem, encoding: .utf8)?.toAnyCodable() ?? ""
        assertExactMatch(expected: expected, actual: actual, pathOptions: [])
    }
    
    // Exception paths
    func testContentIsRequired() throws {
        // setup
        let feedJson = "{\"expiryDate\":\(mockExpiry),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"contentType\":\"\(mockContentType.toString())\",\"publishedDate\":\(mockPublished)}"
        
        
        // test
        let feedItem = getDecodedFeedItem(fromString: feedJson)

        // verify
        XCTAssertNil(feedItem)
    }
    
    func testContentTypeIsRequired() throws {
        // setup
        let feedJson = "{\"expiryDate\":\(mockExpiry),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"content\":{\"\(mockContentKey)\":\"\(mockContentValue)\"},\"publishedDate\":\(mockPublished)}"
        
        
        // test
        let feedItem = getDecodedFeedItem(fromString: feedJson)

        // verify
        XCTAssertNil(feedItem)
    }
    
    func testPublishedDateExpiryDateMetaAreOptional() throws {
        // setup
        let feedJson = "{\"content\":{\"\(mockContentKey)\":\"\(mockContentValue)\"},\"contentType\":\"\(mockContentType.toString())\"}"
        
        
        // test
        let feedItem = getDecodedFeedItem(fromString: feedJson)

        // verify
        XCTAssertNotNil(feedItem)
        XCTAssertEqual(mockContentType, feedItem?.contentType)
        let content = feedItem?.content as? [String: String]
        XCTAssertEqual(mockContentValue, content?[mockContentKey])
    }
    
    // GetFeedItem
    func testGetFeedItemHappy() throws {
        // setup
        let feedJson = "{\"expiryDate\":\(mockExpiry),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"content\":{\"title\":\"fiTitle\",\"body\":\"fiBody\"},\"contentType\":\"\(mockContentType.toString())\",\"publishedDate\":\(mockPublished)}"
        guard let feedItemSchemaData = getDecodedFeedItem(fromString: feedJson) else {
            XCTFail("unable to decode feedJson")
            return
        }
        
        // test
        let result = feedItemSchemaData.getFeedItem()
        
        // verify
        XCTAssertNotNil(result)
        XCTAssertEqual("fiTitle", result?.title)
        XCTAssertEqual("fiBody", result?.body)
    }
    
    func testGetFeedItemNotApplicationJson() throws {
        // setup
        let feedJson = "{\"expiryDate\":\(mockExpiry),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"content\":\"thisIsContent\",\"contentType\":\"\(ContentType.textPlain.toString())\",\"publishedDate\":\(mockPublished)}"
        guard let feedItemSchemaData = getDecodedFeedItem(fromString: feedJson) else {
            XCTFail("unable to decode feedJson")
            return
        }
        
        // test
        let result = feedItemSchemaData.getFeedItem()
        
        // verify
        XCTAssertNil(result)
    }
    
    // TEST HELPER
    func testGetEmpty() throws {
        // test
        let result = FeedItemSchemaData.getEmpty()
        
        // verify
        XCTAssertNotNil(result)
        XCTAssertEqual("plain-text content", result.content as? String)
        XCTAssertEqual(.textPlain, result.contentType)
        XCTAssertNil(result.publishedDate)
        XCTAssertNil(result.expiryDate)
        XCTAssertNil(result.meta)
    }
}
