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

class PropositionItemTests: XCTestCase, AnyCodableAsserts {
    let ASYNC_TIMEOUT = 5.0
    let mockPropositionId = "mockPropositionId"
    let mockScope = "mockScope"
    let mockScopeDetails = ["key": "value"]
    
    let mockItemId = "mockItemId"
    let mockHtmlSchema: SchemaType = .htmlContent
    let mockJsonSchema: SchemaType = .jsonContent
    let mockDefaultContentSchema: SchemaType = .defaultContent
    let mockContent = "customContent"
    let mockFormat: ContentType = .textHtml
    
    override func setUp() {
        EventHub.shared.start()
        registerMockExtension(MockExtension.self)
    }

    override func tearDown() {
        MockExtension.reset()
        EventHub.reset()
    }

    func getDecodedObject(fromString: String) -> PropositionItem? {
        let decoder = JSONDecoder()
        let objectData = fromString.data(using: .utf8)!
        guard let propositionItem = try? decoder.decode(PropositionItem.self, from: objectData) else {
            return nil
        }
        return propositionItem
    }
    
    func parseRuleConsequences(_ rule: [String: Any]) -> [RuleConsequence]? {
        guard
            let ruleData = try? JSONSerialization.data(withJSONObject: rule, options: .prettyPrinted),
            let parsedRules = JSONRulesParser.parse(ruleData) else {
            return nil
        }
        return parsedRules.first?.consequences
    }
    
    func testPropositionItemInitHtml() {
        // setup
        let mockCodeBasedContent = JSONFileLoader.getRulesJsonFromFile("codeBasedPropositionHtmlContent")
        
        // test
        let propositionItem = PropositionItem(itemId: mockItemId, schema: .htmlContent, itemData: mockCodeBasedContent)

        // verify
        XCTAssertEqual(mockItemId, propositionItem.itemId)
        XCTAssertEqual(mockHtmlSchema, propositionItem.schema)
        XCTAssertEqual(mockCodeBasedContent["content"] as? String, propositionItem.htmlContent)
    }
    
    func testPropositionItemInitJson() {
        // setup
        let mockCodeBasedContent = JSONFileLoader.getRulesJsonFromFile("codeBasedPropositionJsonContent")
        
        // test
        let propositionItem = PropositionItem(itemId: mockItemId, schema: .jsonContent, itemData: mockCodeBasedContent)

        // verify
        XCTAssertEqual(mockItemId, propositionItem.itemId)
        XCTAssertEqual(mockJsonSchema, propositionItem.schema)
        assertExactMatch(expected: AnyCodable(mockCodeBasedContent["content"] as? [String: Any]), actual: AnyCodable(propositionItem.jsonContentDictionary))
    }

    func testPropositionItemIsDecodable() {
        // setup
        let json = "{\"id\":\"\(mockItemId)\",\"schema\":\"\(mockHtmlSchema.toString())\",\"data\":{\"content\":\"\(mockContent)\",\"format\":\"\(mockFormat.toString())\"}}"
        
        // test
        guard let propositionItem = getDecodedObject(fromString: json) else {
            XCTFail("PropositionItem object should be decodable.")
            return
        }
        
        // verify
        XCTAssertEqual(mockItemId, propositionItem.itemId)
        XCTAssertEqual(mockHtmlSchema, propositionItem.schema)
        XCTAssertEqual(mockContent, propositionItem.htmlContent)
    }
    
    func testPropositionItemDecodeEmptyData() {
        // setup
        let json = "{\"id\":\"\(mockItemId)\",\"schema\":\"\(mockDefaultContentSchema.toString())\",\"data\":{}}"
        
        // test
        guard let propositionItem = getDecodedObject(fromString: json) else {
            XCTFail("PropositionItem object should be decodable.")
            return
        }
        
        // verify
        XCTAssertEqual(mockItemId, propositionItem.itemId)
        XCTAssertEqual(mockDefaultContentSchema, propositionItem.schema)
        XCTAssertTrue(propositionItem.itemData.isEmpty)
    }
    
    func testPropositionItemIsEncodable() {
        // setup
        let json = "{\"id\":\"\(mockItemId)\",\"schema\":\"\(mockHtmlSchema.toString())\",\"data\":{\"content\":\"\(mockContent)\",\"format\":\"\(mockFormat.toString())\"}}"
        
        guard let propositionItem = getDecodedObject(fromString: json) else {
            XCTFail("PropositionItem object should be decodable.")
            return
        }
        
        let encoder = JSONEncoder()
        let expected = getAnyCodable(json) ?? "fail"

        // test
        guard let encodedObject = try? encoder.encode(propositionItem) else {
            XCTFail("PropositionItem object should be encodable.")
            return
        }

        // verify
        let actual = getAnyCodable(String(data: encodedObject, encoding: .utf8) ?? "")
        assertExactMatch(expected: expected, actual: actual)
    }
    
    func testPropositionItemIdIsRequired() {
        // setup
        let json = "{\"schema\":\"\(mockHtmlSchema.toString())\",\"data\":{\"content\":\"\(mockContent)\",\"format\":\"\(mockFormat.toString())\"}}"
        
        // test
        let propositionItem = getDecodedObject(fromString: json)
        
        // verify
        XCTAssertNil(propositionItem)
    }
    
    func testPropositionItemSchemaIsRequired() {
        // setup
        let json = "{\"id\":\"\(mockItemId)\",\"data\":{\"content\":\"\(mockContent)\",\"format\":\"\(mockFormat.toString())\"}}"
        
        // test
        let propositionItem = getDecodedObject(fromString: json)
        
        // verify
        XCTAssertNil(propositionItem)
    }
    
    func testPropositionItemDataIsRequired() {
        // setup
        let json = "{\"id\":\"\(mockItemId)\",\"schema\":\"\(mockHtmlSchema.toString())\"}"
        
        // test
        let propositionItem = getDecodedObject(fromString: json)
        
        // verify
        XCTAssertNil(propositionItem)
    }
    
    func testPropositionItemFromRuleConsequence() {
        // setup
        let mockFeedContent = JSONFileLoader.getRulesJsonFromFile("feedPropositionContent")
        guard let feedConsequence = parseRuleConsequences(mockFeedContent)?.first else {
            XCTFail("Feed consequence should be valid.")
            return
        }
        
        // test
        let propositionItem = PropositionItem.fromRuleConsequence(feedConsequence)
        
        let expectedData = #"""
        {
            "expiryDate": 1723163897,
            "meta": {
                "feedName": "testFeed",
                "campaignName": "testCampaign",
                "surface": "mobileapp://com.feeds.testing/feeds/apifeed"
            },
            "content": {
                "title": "Guacamole!",
                "body": "I'm the queen of Nacho Picchu and I'm really glad to meet you. To spice up this big tortilla chip, I command you to find a big dip.",
                "imageUrl": "https://d14dq8eoa1si34.cloudfront.net/2a6ef2f0-1167-11eb-88c6-b512a5ef09a7/urn:aaid:aem:d4b77a01-610a-4c3f-9be6-5ebe1bd13da3/oak:1.0::ci:fa54b394b6f987d974d8619833083519/8933c829-3ab2-38e8-a1ee-00d4f562fff8",
                "actionUrl": "https://luma.com/guacamolethemusical",
                "actionTitle": "guacamole!"
            },
            "contentType": "application/json",
            "publishedDate": 1691541497
        }
        """#
        
        // verify
        XCTAssertNotNil(propositionItem)
        XCTAssertEqual("183639c4-cb37-458e-a8ef-4e130d767ebf", propositionItem?.itemId)
        XCTAssertEqual(.feed, propositionItem?.schema)
        assertExactMatch(expected: getAnyCodable(expectedData)!, actual: AnyCodable(propositionItem?.itemData))
    }
    
    func testPropositionItemFromRuleConsequenceEvent() {
        let testEventData: [String: Any] = [
            "triggeredconsequence": [
                "id": "183639c4-cb37-458e-a8ef-4e130d767ebf",
                "type": "schema",
                "detail": [
                    "id": "183639c4-cb37-458e-a8ef-4e130d767ebf",
                    "schema": "https://ns.adobe.com/personalization/message/feed-item",
                    "data": [
                        "expiryDate": 1723163897,
                        "meta": [
                            "feedName": "testFeed",
                            "campaignName": "testCampaign",
                            "surface": "mobileapp://com.feeds.testing/feeds/apifeed"
                        ],
                        "content": [
                            "title": "Guacamole!",
                            "body": "I'm the queen of Nacho Picchu and I'm really glad to meet you. To spice up this big tortilla chip, I command you to find a big dip.",
                            "imageUrl": "https://d14dq8eoa1si34.cloudfront.net/2a6ef2f0-1167-11eb-88c6-b512a5ef09a7/urn:aaid:aem:d4b77a01-610a-4c3f-9be6-5ebe1bd13da3/oak:1.0::ci:fa54b394b6f987d974d8619833083519/8933c829-3ab2-38e8-a1ee-00d4f562fff8",
                            "actionUrl": "https://luma.com/guacamolethemusical",
                            "actionTitle": "guacamole!"
                        ],
                        "contentType": "application/json",
                        "publishedDate": 1691541497
                    ]
                ]
            ]
        ]
        
        let testEvent = Event(name: "Rules Consequence Event",
                              type: "com.adobe.eventType.rulesEngine",
                              source: "com.adobe.eventSource.responseContent",
                              data: testEventData)
        
        // test
        let propositionItem = PropositionItem.fromRuleConsequenceEvent(testEvent)
        
        let expectedData = #"""
        {
            "expiryDate": 1723163897,
            "meta": {
                "feedName": "testFeed",
                "campaignName": "testCampaign",
                "surface": "mobileapp://com.feeds.testing/feeds/apifeed"
            },
            "content": {
                "title": "Guacamole!",
                "body": "I'm the queen of Nacho Picchu and I'm really glad to meet you. To spice up this big tortilla chip, I command you to find a big dip.",
                "imageUrl": "https://d14dq8eoa1si34.cloudfront.net/2a6ef2f0-1167-11eb-88c6-b512a5ef09a7/urn:aaid:aem:d4b77a01-610a-4c3f-9be6-5ebe1bd13da3/oak:1.0::ci:fa54b394b6f987d974d8619833083519/8933c829-3ab2-38e8-a1ee-00d4f562fff8",
                "actionUrl": "https://luma.com/guacamolethemusical",
                "actionTitle": "guacamole!"
            },
            "contentType": "application/json",
            "publishedDate": 1691541497
        }
        """#
        
        // verify
        XCTAssertNotNil(propositionItem)
        XCTAssertEqual("183639c4-cb37-458e-a8ef-4e130d767ebf", propositionItem?.itemId)
        XCTAssertEqual(.feed, propositionItem?.schema)
        assertExactMatch(expected: getAnyCodable(expectedData)!, actual: AnyCodable(propositionItem?.itemData))
        
    }
    
    func testPropositionItemHasInAppSchemaData() {
        // setup
        let mockInappContent = JSONFileLoader.getRulesJsonFromFile("inappPropositionV2Content")
        guard let inappConsequence = parseRuleConsequences(mockInappContent)?.first else {
            XCTFail("Inapp consequence should be valid.")
            return
        }
        
        // test
        let propositionItem = PropositionItem.fromRuleConsequence(inappConsequence)
        let inappSchemaData = propositionItem?.inappSchemaData
        
        let expectedMobileParameters = #"""
        {
            "verticalAlign": "center",
            "dismissAnimation": "bottom",
            "verticalInset": 0,
            "backdropOpacity": 0.2,
            "cornerRadius": 15,
            "gestures": {},
            "horizontalInset": 0,
            "uiTakeover": true,
            "horizontalAlign": "center",
            "width": 100,
            "displayAnimation": "bottom",
            "backdropColor": "#000000",
            "height": 100
        }
        """#

        // verify
        XCTAssertNotNil(inappSchemaData)
        XCTAssertEqual(1691541497, inappSchemaData?.publishedDate)
        XCTAssertEqual(1723163897, inappSchemaData?.expiryDate)
        XCTAssertEqual(1, inappSchemaData?.meta?.count)
        XCTAssertEqual("metaValue", inappSchemaData?.meta?["metaKey"] as? String)
        XCTAssertEqual("urlToAnImage", inappSchemaData?.remoteAssets?.first)
        XCTAssertEqual(.textHtml, inappSchemaData?.contentType)
        XCTAssertEqual("<html><body>Is this thing even on?</body></html>", inappSchemaData?.content as? String)
        assertExactMatch(expected: getAnyCodable(expectedMobileParameters)!, actual: AnyCodable(inappSchemaData?.mobileParameters))
        XCTAssertEqual("webParamValue", inappSchemaData?.webParameters?["webParamKey"] as? String)
    }

    func testPropositionItemHasFeedItemSchemaData() {
        // setup
        let mockFeedContent = JSONFileLoader.getRulesJsonFromFile("feedPropositionContent")
        guard let feedConsequence = parseRuleConsequences(mockFeedContent)?.first else {
            XCTFail("")
            return
        }
        
        let propositionItem = PropositionItem.fromRuleConsequence(feedConsequence)
        
        // test
        let feedItemSchemaData = propositionItem?.feedItemSchemaData
        
        let expectedContent = #"""
        {
            "title": "Guacamole!",
            "body": "I'm the queen of Nacho Picchu and I'm really glad to meet you. To spice up this big tortilla chip, I command you to find a big dip.",
            "imageUrl": "https://d14dq8eoa1si34.cloudfront.net/2a6ef2f0-1167-11eb-88c6-b512a5ef09a7/urn:aaid:aem:d4b77a01-610a-4c3f-9be6-5ebe1bd13da3/oak:1.0::ci:fa54b394b6f987d974d8619833083519/8933c829-3ab2-38e8-a1ee-00d4f562fff8",
            "actionUrl": "https://luma.com/guacamolethemusical",
            "actionTitle": "guacamole!"
        }
        """#
        
        let expectedMeta = #"""
        {
            "feedName": "testFeed",
            "campaignName": "testCampaign",
            "surface": "mobileapp://com.feeds.testing/feeds/apifeed"
        }
        """#

        // verify
        XCTAssertNotNil(feedItemSchemaData)
        XCTAssertEqual(1723163897, feedItemSchemaData?.expiryDate)
        XCTAssertEqual(1691541497, feedItemSchemaData?.publishedDate)
        XCTAssertEqual(ContentType.applicationJson, feedItemSchemaData?.contentType)
        assertExactMatch(expected: getAnyCodable(expectedContent)!, actual: AnyCodable(feedItemSchemaData?.content as? [String: Any]))
        assertExactMatch(expected: getAnyCodable(expectedMeta)!, actual: AnyCodable(feedItemSchemaData?.meta))
    }
    
   func testPropositionItemGenerateInteractionXdm() throws {
       // setup
       let mockCodeBasedContent = JSONFileLoader.getRulesJsonFromFile("codeBasedPropositionHtmlContent")
       let propositionItem = PropositionItem(itemId: mockItemId, schema: .htmlContent, itemData: mockCodeBasedContent)
       let proposition = Proposition(uniqueId: mockPropositionId, scope: mockScope, scopeDetails: mockScopeDetails, items: [propositionItem])

       // test
       guard let xdm = proposition.items[0].generateInteractionXdm(forEventType: MessagingEdgeEventType.interact) else {
            XCTFail("Interaction XDM should not be nil")
            return
        }

       // verify
       XCTAssertEqual("decisioning.propositionInteract", xdm["eventType"] as? String)
       let experience = try XCTUnwrap(xdm["_experience"] as? [String: Any])
       let decisioning = try XCTUnwrap(experience["decisioning"] as? [String: Any])
       let propositionEventType = try XCTUnwrap(decisioning["propositionEventType"] as? [String: Any])
       XCTAssertEqual(1, propositionEventType["interact"] as? Int)
       
       let propositions = try XCTUnwrap(decisioning["propositions"] as? [[String: Any]])
       XCTAssertEqual(1, propositions.count)
       XCTAssertEqual(proposition.uniqueId, propositions[0]["id"] as? String)
       XCTAssertEqual(proposition.scope, propositions[0]["scope"] as? String)
       assertExactMatch(expected: AnyCodable(proposition.scopeDetails), actual: AnyCodable(propositions[0]["scopeDetails"]))
       
       let items = try XCTUnwrap(propositions[0]["items"] as? [[String: Any]])
       XCTAssertEqual(1, items.count)
       XCTAssertEqual(mockItemId, items[0]["id"] as? String)
    }
    
    func testPropositionItemGenerateInteractionXdmNoPropositionRef() throws {
        // setup
        let mockCodeBasedContent = JSONFileLoader.getRulesJsonFromFile("codeBasedPropositionHtmlContent")
        let propositionItem = PropositionItem(itemId: mockItemId, schema: .htmlContent, itemData: mockCodeBasedContent)

        // test
        let xdm = propositionItem.generateInteractionXdm(forEventType: MessagingEdgeEventType.interact)

        // verify
        XCTAssertNil(xdm)
     }
    
    func testPropositionItemTrack() throws {
        // setup
        let expectation = XCTestExpectation(description: "track should dispatch an event with expected data.")
        expectation.assertForOverFulfill = true

        let testEventData: [String: Any] = [
            "trackpropositions": true,
            "propositioninteraction": [
                "eventType": "decisioning.propositionDisplay",
                "_experience": [
                    "decisioning": [
                        "propositionEventType": [
                            "display": 1
                        ],
                        "propositions": [
                            [
                                "id": "mockPropositionId",
                                "scope": "mockScope",
                                "scopeDetails": [
                                    "key": "value"
                                ],
                                "items": [
                                    [
                                        "id": "mockItemId"
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
        
        let testEvent = Event(name: "Track propositions",
                              type: "com.adobe.eventType.messaging",
                              source: "com.adobe.eventSource.requestContent",
                              data: testEventData)
        
        EventHub.shared.getExtensionContainer(MockExtension.self)?.eventListeners.clear()
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { event in
            // verify
            XCTAssertEqual(testEvent.name, event.name)
            XCTAssertNotNil(event.data)
            self.assertExactMatch(expected: AnyCodable(testEventData), actual: AnyCodable(event.data))

            expectation.fulfill()
        }
        
        let mockCodeBasedContent = JSONFileLoader.getRulesJsonFromFile("codeBasedPropositionHtmlContent")
        let propositionItem = PropositionItem(itemId: mockItemId, schema: .htmlContent, itemData: mockCodeBasedContent)
        let proposition = Proposition(uniqueId: mockPropositionId, scope: mockScope, scopeDetails: mockScopeDetails, items: [propositionItem])

        // test
        proposition.items[0].track(eventType: MessagingEdgeEventType.display)
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
    }
    
    func testPropositionItemTrackNoPropositionRef() throws {
        // setup
        let expectation = XCTestExpectation(description: "track should not dispatch an event with expected data, if proposition reference is not available.")
        expectation.isInverted = true

        let testEventData: [String: Any] = [
            "trackpropositions": true,
            "propositioninteraction": [
                "eventType": "decisioning.propositionDisplay",
                "_experience": [
                    "decisioning": [
                        "propositionEventType": [
                            "display": 1
                        ],
                        "propositions": [
                            [
                                "id": "mockPropositionId",
                                "scope": "mockScope",
                                "scopeDetails": [
                                    "key": "value"
                                ],
                                "items": [
                                    [
                                        "id": "mockItemId"
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
        
        let testEvent = Event(name: "Track propositions",
                              type: "com.adobe.eventType.messaging",
                              source: "com.adobe.eventSource.requestContent",
                              data: testEventData)
        
        EventHub.shared.getExtensionContainer(MockExtension.self)?.eventListeners.clear()
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { event in
            // verify
            expectation.fulfill()
        }
        
        let mockCodeBasedContent = JSONFileLoader.getRulesJsonFromFile("codeBasedPropositionHtmlContent")
        let propositionItem = PropositionItem(itemId: mockItemId, schema: .htmlContent, itemData: mockCodeBasedContent)

        // test
        propositionItem.track(eventType: MessagingEdgeEventType.display)
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
    }
    
    // MARK: Helper functions
    private func registerMockExtension<T: Extension>(_ type: T.Type) {
        let semaphore = DispatchSemaphore(value: 0)
        EventHub.shared.registerExtension(type) { error in
            XCTAssertNil(error)
            semaphore.signal()
        }
        semaphore.wait()
    }
}

