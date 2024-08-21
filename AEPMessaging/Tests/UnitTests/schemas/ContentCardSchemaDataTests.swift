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
@testable import AEPCore
import AEPServices
import AEPTestUtils

class ContentCardSchemaDataTests: XCTestCase, AnyCodableAsserts {
    
    let mockExpiry = 1723163897
    let mockPublished = 1691541497
    let mockContentType = ContentType.applicationJson
    let mockContentKey = "contentKey"
    let mockContentValue = "value"
    let mockMetaKey = "metaKey"
    let mockMetaValue = "value"
    let mockPropositionItem = MockPropositionItem(itemId: "itemId", schema: .contentCard, itemData: [:])
    let mockProposition = MockProposition(uniqueId: "", scope: "", scopeDetails: [:], items: [])
    let mockRuntime = TestableExtensionRuntime()
        
    override func setUp() {
        EventHub.shared.start()
    }
    
    func getDecodedContentCard(fromString: String) -> ContentCardSchemaData? {
        let decoder = JSONDecoder()
        let contentCardData = fromString.data(using: .utf8)!
        guard let contentCard = try? decoder.decode(ContentCardSchemaData.self, from: contentCardData) else {
            return nil
        }
        return contentCard
    }
    
    func testIsDecodable() throws {
        // test
        let feedJson = "{\"expiryDate\":\(mockExpiry),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"content\":{\"\(mockContentKey)\":\"\(mockContentValue)\"},\"contentType\":\"\(mockContentType.toString())\",\"publishedDate\":\(mockPublished)}"
        guard let contentCard = getDecodedContentCard(fromString: feedJson) else {
            XCTFail("unable to decode feedJson")
            return
        }
        
        // verify
        XCTAssertNotNil(contentCard)
        XCTAssertEqual(mockExpiry, contentCard.expiryDate)
        XCTAssertEqual(mockPublished, contentCard.publishedDate)
        XCTAssertEqual(mockContentType, contentCard.contentType)
        let content = contentCard.content as? [String: String]
        XCTAssertEqual(mockContentValue, content?[mockContentKey])
        XCTAssertEqual(mockMetaValue, contentCard.meta?[mockMetaKey] as? String)
    }
    
    func testIsDecodableStringContent() throws {
        // test
        let feedJson = "{\"expiryDate\":\(mockExpiry),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"content\":\"\(mockContentValue)\",\"contentType\":\"\(ContentType.textPlain.toString())\",\"publishedDate\":\(mockPublished)}"
        guard let contentCard = getDecodedContentCard(fromString: feedJson) else {
            XCTFail("unable to decode feedJson")
            return
        }
        
        // verify
        XCTAssertNotNil(contentCard)
        XCTAssertEqual(mockExpiry, contentCard.expiryDate)
        XCTAssertEqual(mockPublished, contentCard.publishedDate)
        XCTAssertEqual(.textPlain, contentCard.contentType)
        XCTAssertEqual(mockContentValue, contentCard.content as? String)
        XCTAssertEqual(mockMetaValue, contentCard.meta?[mockMetaKey] as? String)
    }
    
    func testIsDecodableBadJson() throws {
        // test
        let feedJson = "{\"expiryDate\":\(mockExpiry),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"content\":\"I AM NOT JSON\",\"contentType\":\"\(mockContentType.toString())\",\"publishedDate\":\(mockPublished)}"
        let contentCard = getDecodedContentCard(fromString: feedJson)
        
        // verify
        XCTAssertNil(contentCard)
    }
    
    func testIsEncodable() throws {
        // setup
        let feedJson = "{\"expiryDate\":\(mockExpiry),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"content\":{\"\(mockContentKey)\":\"\(mockContentValue)\"},\"contentType\":\"\(mockContentType.toString())\",\"publishedDate\":\(mockPublished)}"
        guard let contentCard = getDecodedContentCard(fromString: feedJson) else {
            XCTFail("unable to decode feedJson")
            return
        }
        let encoder = JSONEncoder()
        let expected = "{\"expiryDate\":\(mockExpiry),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"content\":{\"\(mockContentKey)\":\"\(mockContentValue)\"},\"contentType\":\"\(mockContentType.toString())\",\"publishedDate\":\(mockPublished)}".toAnyCodable() ?? "fail"

        // test
        guard let encodedContentCard = try? encoder.encode(contentCard) else {
            XCTFail("unable to encode ContentCardSchemaData")
            return
        }

        // verify
        let actual = String(data: encodedContentCard, encoding: .utf8)?.toAnyCodable() ?? ""
        assertExactMatch(expected: expected, actual: actual, pathOptions: [])
    }
    
    func testIsEncodableStringContent() throws {
        // setup
        let feedJson = "{\"expiryDate\":\(mockExpiry),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"content\":\"\(mockContentValue)\",\"contentType\":\"\(ContentType.textPlain.toString())\",\"publishedDate\":\(mockPublished)}"
        guard let contentCard = getDecodedContentCard(fromString: feedJson) else {
            XCTFail("unable to decode feedJson")
            return
        }
        let encoder = JSONEncoder()
        let expected = "{\"expiryDate\":\(mockExpiry),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"content\":\"\(mockContentValue)\",\"contentType\":\"\(ContentType.textPlain.toString())\",\"publishedDate\":\(mockPublished)}".toAnyCodable() ?? "fail"

        // test
        guard let encodedContentCard = try? encoder.encode(contentCard) else {
            XCTFail("unable to encode ContentCardSchemaData")
            return
        }

        // verify
        let actual = String(data: encodedContentCard, encoding: .utf8)?.toAnyCodable() ?? ""
        assertExactMatch(expected: expected, actual: actual, pathOptions: [])
    }
    
    // Exception paths
    func testContentIsRequired() throws {
        // setup
        let feedJson = "{\"expiryDate\":\(mockExpiry),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"contentType\":\"\(mockContentType.toString())\",\"publishedDate\":\(mockPublished)}"
        
        
        // test
        let contentCard = getDecodedContentCard(fromString: feedJson)

        // verify
        XCTAssertNil(contentCard)
    }
    
    func testContentTypeIsRequired() throws {
        // setup
        let feedJson = "{\"expiryDate\":\(mockExpiry),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"content\":{\"\(mockContentKey)\":\"\(mockContentValue)\"},\"publishedDate\":\(mockPublished)}"
        
        
        // test
        let contentCard = getDecodedContentCard(fromString: feedJson)

        // verify
        XCTAssertNil(contentCard)
    }
    
    func testPublishedDateExpiryDateMetaAreOptional() throws {
        // setup
        let feedJson = "{\"content\":{\"\(mockContentKey)\":\"\(mockContentValue)\"},\"contentType\":\"\(mockContentType.toString())\"}"
        
        
        // test
        let contentCard = getDecodedContentCard(fromString: feedJson)

        // verify
        XCTAssertNotNil(contentCard)
        XCTAssertEqual(mockContentType, contentCard?.contentType)
        let content = contentCard?.content as? [String: String]
        XCTAssertEqual(mockContentValue, content?[mockContentKey])
    }
    
    // GetContentCard
    @available(*, deprecated)
    func testGetContentCardHappy() throws {
        // setup
        let feedJson = "{\"expiryDate\":\(mockExpiry),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"content\":{\"title\":\"fiTitle\",\"body\":\"fiBody\"},\"contentType\":\"\(mockContentType.toString())\",\"publishedDate\":\(mockPublished)}"
        guard let contentCardSchemaData = getDecodedContentCard(fromString: feedJson) else {
            XCTFail("unable to decode feedJson")
            return
        }
        
        // test
        let result = contentCardSchemaData.getContentCard()
        
        // verify
        XCTAssertNotNil(result)
        XCTAssertEqual("fiTitle", result?.title)
        XCTAssertEqual("fiBody", result?.body)
    }
    
    @available(*, deprecated)
    func testGetContentCardNotApplicationJson() throws {
        // setup
        let feedJson = "{\"expiryDate\":\(mockExpiry),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"content\":\"thisIsContent\",\"contentType\":\"\(ContentType.textPlain.toString())\",\"publishedDate\":\(mockPublished)}"
        guard let contentCardSchemaData = getDecodedContentCard(fromString: feedJson) else {
            XCTFail("unable to decode feedJson")
            return
        }
        
        // test
        let result = contentCardSchemaData.getContentCard()
        
        // verify
        XCTAssertNil(result)
    }
    
    func testTrackInteract() throws {
        // setup
        let feedJson = "{\"expiryDate\":\(mockExpiry),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"content\":{\"title\":\"fiTitle\",\"body\":\"fiBody\"},\"contentType\":\"\(mockContentType.toString())\",\"publishedDate\":\(mockPublished)}"
        guard let contentCardSchemaData = getDecodedContentCard(fromString: feedJson) else {
            XCTFail("unable to decode feedJson")
            return
        }
        contentCardSchemaData.parent = mockPropositionItem
        
        // test
        contentCardSchemaData.track("myInteraction", withEdgeEventType: .interact)
        
        // verify
        XCTAssertTrue(mockPropositionItem.trackCalled)
        XCTAssertEqual("myInteraction", mockPropositionItem.paramTrackInteraction)
        XCTAssertEqual(.interact, mockPropositionItem.paramTrackEventType)
        XCTAssertNil(mockPropositionItem.paramTrackTokens)
    }
    
    func testTrackDismiss() throws {
        // setup
        let feedJson = "{\"expiryDate\":\(mockExpiry),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"content\":{\"title\":\"fiTitle\",\"body\":\"fiBody\"},\"contentType\":\"\(mockContentType.toString())\",\"publishedDate\":\(mockPublished)}"
        guard let contentCardSchemaData = getDecodedContentCard(fromString: feedJson) else {
            XCTFail("unable to decode feedJson")
            return
        }
        contentCardSchemaData.parent = mockPropositionItem
        mockPropositionItem.proposition = mockProposition
        let eventHistoryWriteExpectation = XCTestExpectation(description: "eventHistory write event should be dispatched.")
        MobileCore.registerEventListener(type: EventType.messaging,
                                         source: MessagingConstants.Event.Source.EVENT_HISTORY_WRITE) { event in
            eventHistoryWriteExpectation.fulfill()
        }
                        
        // test
        contentCardSchemaData.track(withEdgeEventType: .dismiss)
        
        
        // verify
        XCTAssertTrue(mockPropositionItem.trackCalled)
        XCTAssertNil(mockPropositionItem.paramTrackInteraction)
        XCTAssertEqual(.dismiss, mockPropositionItem.paramTrackEventType)
        XCTAssertNil(mockPropositionItem.paramTrackTokens)
        wait(for: [eventHistoryWriteExpectation], timeout: 2)
    }
    
    // TEST HELPER
    func testGetEmpty() throws {
        // test
        let result = ContentCardSchemaData.getEmpty()
        
        // verify
        XCTAssertNotNil(result)
        XCTAssertEqual("plain-text content", result.content as? String)
        XCTAssertEqual(.textPlain, result.contentType)
        XCTAssertNil(result.publishedDate)
        XCTAssertNil(result.expiryDate)
        XCTAssertNil(result.meta)
    }
}
