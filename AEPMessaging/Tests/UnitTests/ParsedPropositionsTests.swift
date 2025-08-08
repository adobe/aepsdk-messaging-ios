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
import AEPTestUtils
@testable import AEPMessaging
@testable import AEPServices

class ParsedPropositionTests: XCTestCase {
    var mockSurface: Surface!
    var mockRuntime: TestableExtensionRuntime!
    
    let rulesetSchema: SchemaType = .ruleset
    let jsonSchema: SchemaType = .jsonContent
    let htmlSchema: SchemaType = .htmlContent
    
    var mockInAppPropositionItemv2: PropositionItem!
    var mockInAppPropositionv2: Proposition!
    var mockInAppSurfacev2: Surface!
    let mockInAppMessageIdv2 = "6ac78390-84e3-4d35-b798-8e7080e69a67"
    
    var mockFeedPropositionItem: PropositionItem!
    var mockFeedProposition: Proposition!
    var mockFeedSurface: Surface!
    let mockFeedMessageId = "183639c4-cb37-458e-a8ef-4e130d767ebf"
    var mockFeedContent: [String: Any]!
    
    var mockCodeBasedPropositionItem: PropositionItem!
    var mockCodeBasedProposition: Proposition!
    var mockCodeBasedSurface: Surface!
    var mockCodeBasedContent: [String: Any]!
        
    override func setUp() {
        mockSurface = Surface(uri: "mobileapp://some.not.matching.surface/path")
        mockRuntime = TestableExtensionRuntime()
        
        let inappPropositionV2Content = JSONFileLoader.getRulesJsonFromFile("inappPropositionV2Content")
        mockInAppPropositionItemv2 = PropositionItem(itemId: "inapp2", schema: rulesetSchema, itemData: inappPropositionV2Content)
        mockInAppPropositionv2 = Proposition(uniqueId: "inapp2", scope: "inapp2", scopeDetails: ["key": "value"], items: [mockInAppPropositionItemv2])
        mockInAppSurfacev2 = Surface(uri: "inapp2")
        
        mockFeedContent = JSONFileLoader.getRulesJsonFromFile("feedPropositionContent")
        mockFeedPropositionItem = PropositionItem(itemId: "feed", schema: rulesetSchema, itemData: mockFeedContent)
        mockFeedProposition = Proposition(uniqueId: "feed", scope: "feed", scopeDetails: ["key":"value"], items: [mockFeedPropositionItem])
        mockFeedSurface = Surface(uri: "feed")
        
        mockCodeBasedContent = JSONFileLoader.getRulesJsonFromFile("codeBasedPropositionHtmlContent")
        mockCodeBasedPropositionItem = PropositionItem(itemId: "codebased", schema: htmlSchema, itemData: mockCodeBasedContent)
        mockCodeBasedProposition = Proposition(uniqueId: "codebased", scope: "codebased", scopeDetails: ["key":"value"], items: [mockCodeBasedPropositionItem])
        mockCodeBasedSurface = Surface(uri: "codebased")
    }
    
    func testInitWithEmptyPropositions() throws {
        // setup
        let propositions: [Surface: [Proposition]] = [mockSurface: []]
        
        // test
        let result = ParsedPropositions(with: propositions, requestedSurfaces: [mockSurface], runtime: mockRuntime)
        
        // verify
        XCTAssertNotNil(result)
        XCTAssertEqual(0, result.propositionInfoToCache.count)
        XCTAssertEqual(0, result.propositionsToCache.count)
        XCTAssertEqual(0, result.propositionsToPersist.count)
        XCTAssertEqual(0, result.surfaceRulesBySchemaType.count)
    }
    
    func testInitWithPropositionScopeNotMatchingRequestedSurfaces() throws {
        // setup
        let propositions: [Surface: [Proposition]] = [
            mockFeedSurface: [mockFeedProposition],
            mockCodeBasedSurface: [mockCodeBasedProposition]
        ]
        
        // test
        let result = ParsedPropositions(with: propositions, requestedSurfaces: [mockSurface], runtime: mockRuntime)
        
        // verify
        XCTAssertNotNil(result)
        XCTAssertEqual(0, result.propositionInfoToCache.count)
        XCTAssertEqual(0, result.propositionsToCache.count)
        XCTAssertEqual(0, result.propositionsToPersist.count)
        XCTAssertEqual(0, result.surfaceRulesBySchemaType.count)
    }
    
    func testInitWithInAppPropositionV2() throws {
        // setup
        let propositions: [Surface: [Proposition]] = [
            mockInAppSurfacev2: [mockInAppPropositionv2]
        ]
        
        // test
        let result = ParsedPropositions(with: propositions, requestedSurfaces: [mockInAppSurfacev2], runtime: mockRuntime)
        
        // verify
        XCTAssertNotNil(result)
        XCTAssertEqual(1, result.propositionInfoToCache.count, "should have one IAM in propositionInfo for tracking purposes")
        let iamPropInfo = result.propositionInfoToCache[mockInAppMessageIdv2]
        XCTAssertEqual("inapp2", iamPropInfo?.id)
        XCTAssertEqual(0, result.propositionsToCache.count)
        XCTAssertEqual(1, result.propositionsToPersist.count, "should have one entry for persistence")
        let iamPersist = result.propositionsToPersist[mockInAppSurfacev2]
        XCTAssertEqual(1, iamPersist?.count)
        XCTAssertEqual("inapp2", iamPersist?.first?.uniqueId)
        XCTAssertEqual(1, result.surfaceRulesBySchemaType.count, "should have one rule to insert in the IAM rules engine")
        let iamRules = result.surfaceRulesBySchemaType[.inapp]
        XCTAssertEqual(1, iamRules?.count)
        let firstConsequence = iamRules?.first?.value.first?.consequences.first
        XCTAssertNotNil(firstConsequence)
        let consequenceAsPropositionItem = PropositionItem.fromRuleConsequence(firstConsequence!)
        let inappSchemaData = consequenceAsPropositionItem?.inappSchemaData
        XCTAssertEqual("text/html", inappSchemaData?.contentType.toString())
        XCTAssertEqual("<html><body>Is this thing even on?</body></html>", inappSchemaData?.content as? String)
        XCTAssertEqual(1691541497, inappSchemaData?.publishedDate)
        XCTAssertEqual(1723163897, inappSchemaData?.expiryDate)
        XCTAssertEqual(1, inappSchemaData?.meta?.count)
        XCTAssertEqual("metaValue", inappSchemaData?.meta?["metaKey"] as? String)
        XCTAssertEqual(13, inappSchemaData?.mobileParameters?.count)
        XCTAssertEqual(1, inappSchemaData?.webParameters?.count)
        XCTAssertEqual("webParamValue", inappSchemaData?.webParameters?["webParamKey"] as? String)
        XCTAssertEqual(1, inappSchemaData?.remoteAssets?.count)
        XCTAssertEqual("urlToAnImage", inappSchemaData?.remoteAssets?.first)
    }
    
    func testInitWithFeedProposition() throws {
        // setup
        let propositions: [Surface: [Proposition]] = [
            mockFeedSurface: [mockFeedProposition]
        ]
        
        // test
        let result = ParsedPropositions(with: propositions, requestedSurfaces: [mockFeedSurface], runtime: mockRuntime)
        
        // verify
        XCTAssertNotNil(result)
        XCTAssertEqual(1, result.propositionInfoToCache.count, "should have one entry in proposition info for tracking purposes")
        let feedPropositionInfo = result.propositionInfoToCache[mockFeedMessageId]
        XCTAssertNotNil(feedPropositionInfo)
        XCTAssertEqual("feed", feedPropositionInfo?.id)
        XCTAssertEqual(0, result.propositionsToCache.count)
        XCTAssertEqual(0, result.propositionsToPersist.count)
        XCTAssertEqual(1, result.surfaceRulesBySchemaType.count, "should have one rule to insert in the feeds rules engine")
        let feedRules = result.surfaceRulesBySchemaType[.contentCard]
        XCTAssertNotNil(feedRules)
        XCTAssertEqual(1, feedRules?.count)
    }
    
    func testInitWithCodeBasedProposition() throws {
        // setup
        let propositions: [Surface: [Proposition]] = [
            mockCodeBasedSurface: [mockCodeBasedProposition]
        ]
        
        // test
        let result = ParsedPropositions(with: propositions, requestedSurfaces: [mockCodeBasedSurface], runtime: mockRuntime)
        
        // verify
        XCTAssertNotNil(result)
        XCTAssertEqual(0, result.propositionInfoToCache.count)
        XCTAssertEqual(1, result.propositionsToCache.count, "code based proposition should be cached")
        let codeBasedPropItem = result.propositionsToCache[mockCodeBasedSurface]?.first?.items.first
        XCTAssertEqual(mockCodeBasedContent["content"] as? String, codeBasedPropItem?.htmlContent)
        XCTAssertEqual(0, result.propositionsToPersist.count)
        XCTAssertEqual(0, result.surfaceRulesBySchemaType.count)
    }
    
    func testInitWithDefaultContentProposition() throws {
        
    }
    
    func testInitPropositionItemEmptyContentString() throws {
        // setup
        mockInAppPropositionItemv2 = PropositionItem(itemId: "inapp", schema: .inapp, itemData: [:])
        mockInAppPropositionv2 = Proposition(uniqueId: "inapp", scope: "inapp", scopeDetails: ["key": "value"], items: [mockInAppPropositionItemv2])
        let propositions: [Surface: [Proposition]] = [
            mockInAppSurfacev2: [mockInAppPropositionv2]
        ]
        
        // test
        let result = ParsedPropositions(with: propositions, requestedSurfaces: [mockInAppSurfacev2], runtime: mockRuntime)
        
        // verify
        XCTAssertNotNil(result)
        XCTAssertEqual(0, result.propositionInfoToCache.count)
        XCTAssertEqual(0, result.propositionsToCache.count)
        XCTAssertEqual(0, result.propositionsToPersist.count)
        XCTAssertEqual(0, result.surfaceRulesBySchemaType.count)
    }
    
    func testInitPropositionRuleHasNoConsequence() throws {
        // setup
        let noConsequenceRule = JSONFileLoader.getRulesJsonFromFile("ruleWithNoConsequence")
        let pi = PropositionItem(itemId: "inapp", schema: .ruleset, itemData: noConsequenceRule)
        let prop = Proposition(uniqueId: "inapp", scope: "inapp", scopeDetails: ["key": "value"], items: [pi])
        let propositions: [Surface: [Proposition]] = [
            mockInAppSurfacev2: [prop]
        ]
        
        // test
        let result = ParsedPropositions(with: propositions, requestedSurfaces: [mockInAppSurfacev2], runtime: mockRuntime)
        
        // verify
        XCTAssertNotNil(result)
        XCTAssertEqual(0, result.propositionInfoToCache.count)
        XCTAssertEqual(0, result.propositionsToCache.count)
        XCTAssertEqual(0, result.propositionsToPersist.count)
        XCTAssertEqual(0, result.surfaceRulesBySchemaType.count)
    }
    
    func testInitPropositionRulesetConsequenceHasUnknownSchema() throws {
        // setup
        let content = JSONFileLoader.getRulesJsonFromFile("ruleWithUnknownConsequenceSchema")
        let pi = PropositionItem(itemId: "inapp", schema: .ruleset, itemData: content)
        let prop = Proposition(uniqueId: "inapp", scope: "inapp", scopeDetails: ["key": "value"], items: [pi])
        let propositions: [Surface: [Proposition]] = [
            mockInAppSurfacev2: [prop]
        ]
        
        // test
        let result = ParsedPropositions(with: propositions, requestedSurfaces: [mockInAppSurfacev2], runtime: mockRuntime)
        
        // verify
        XCTAssertNotNil(result)
        XCTAssertEqual(0, result.propositionInfoToCache.count)
        XCTAssertEqual(0, result.propositionsToCache.count)
        XCTAssertEqual(0, result.propositionsToPersist.count)
        XCTAssertEqual(0, result.surfaceRulesBySchemaType.count)
    }
    
    func testInitPropositionUnknownSchema() throws {
        // setup
        let pi = PropositionItem(itemId: "inapp", schema: .unknown, itemData: [:])
        let prop = Proposition(uniqueId: "inapp", scope: "inapp", scopeDetails: ["key": "value"], items: [pi])
        let propositions: [Surface: [Proposition]] = [
            mockInAppSurfacev2: [prop]
        ]
        
        // test
        let result = ParsedPropositions(with: propositions, requestedSurfaces: [mockInAppSurfacev2], runtime: mockRuntime)
        
        // verify
        XCTAssertNotNil(result)
        XCTAssertEqual(0, result.propositionInfoToCache.count)
        XCTAssertEqual(0, result.propositionsToCache.count)
        XCTAssertEqual(0, result.propositionsToPersist.count)
        XCTAssertEqual(0, result.surfaceRulesBySchemaType.count)
    }
    
    func testInitPropositionConsequenceNoPropositionItem() throws {
        // setup
        let prop = Proposition(uniqueId: "inapp", scope: "inapp", scopeDetails: ["key": "value"], items: [])
        let propositions: [Surface: [Proposition]] = [
            mockInAppSurfacev2: [prop]
        ]
        
        // test
        let result = ParsedPropositions(with: propositions, requestedSurfaces: [mockInAppSurfacev2], runtime: mockRuntime)
        
        // verify
        XCTAssertNotNil(result)
        XCTAssertEqual(0, result.propositionInfoToCache.count)
        XCTAssertEqual(0, result.propositionsToCache.count)
        XCTAssertEqual(0, result.propositionsToPersist.count)
        XCTAssertEqual(0, result.surfaceRulesBySchemaType.count)
    }
    
    func testInitPropositionRulesetDoesNotParseToRules() throws {
        
    }
        
    func testInitPropositionRulesetConsequenceIsNotSchemaType() throws {
        
    }
    
    func testSortByRankSourceIsReverseOrder() throws {
        // setup
        let propRank1Priority100 = Proposition(uniqueId: "rank1", scope: "inapp2", scopeDetails: ["rank": 1, "activity": [ "priority": 100 ]], items: [ getPropItemFile("inAppMessagePriority100")])
        let propRank2Priority60 = Proposition(uniqueId: "rank2", scope: "inapp2", scopeDetails: ["rank": 2, "activity": [ "priority": 60 ]], items: [getPropItemFile("inAppMessagePriority60")])
        let propRank3Priority20 = Proposition(uniqueId: "rank3", scope: "inapp2", scopeDetails: ["rank": 3, "activity": [ "priority": 20 ]], items: [getPropItemFile("inAppMessagePriority20")])
        let propsPerSurface = [mockInAppSurfacev2!: [propRank3Priority20, propRank2Priority60, propRank1Priority100]]
        
        // test
        let result = ParsedPropositions(with: propsPerSurface, requestedSurfaces: [mockInAppSurfacev2], runtime: mockRuntime)
        
        // verify
        XCTAssertNotNil(result)
        
        // surfaceRulesBySchemaType is sorted properly
        guard let inAppRules = result.surfaceRulesBySchemaType[.inapp],
              let inAppRulesForSurface = inAppRules[mockInAppSurfacev2] else {
            XCTFail("Unable to get rules for the requested surface.")
            return
        }
        let firstRule = inAppRulesForSurface[0]
        XCTAssertEqual("priority100", firstRule.consequences.first?.id)
        let secondRule = inAppRulesForSurface[1]
        XCTAssertEqual("priority60", secondRule.consequences.first?.id)
        let thirdRule = inAppRulesForSurface[2]
        XCTAssertEqual("priority20", thirdRule.consequences.first?.id)
        
        // propositionsToPersist is sorted properly
        guard let propsForSurface = result.propositionsToPersist[mockInAppSurfacev2] else {
            XCTFail("Unable to get propositions to persist for the requested surface.")
            return
        }
        let firstProp = propsForSurface[0]
        XCTAssertEqual(1, firstProp.rank)
        let secondProp = propsForSurface[1]
        XCTAssertEqual(2, secondProp.rank)
        let thirdProp = propsForSurface[2]
        XCTAssertEqual(3, thirdProp.rank)
    }
    
    func testSortByRankSourceIsCorrectOrder() throws {
        // setup
        let propRank1Priority100 = Proposition(uniqueId: "rank1", scope: "inapp2", scopeDetails: ["rank": 1, "activity": [ "priority": 100 ]], items: [ getPropItemFile("inAppMessagePriority100")])
        let propRank2Priority60 = Proposition(uniqueId: "rank2", scope: "inapp2", scopeDetails: ["rank": 2, "activity": [ "priority": 60 ]], items: [getPropItemFile("inAppMessagePriority60")])
        let propRank3Priority20 = Proposition(uniqueId: "rank3", scope: "inapp2", scopeDetails: ["rank": 3, "activity": [ "priority": 20 ]], items: [getPropItemFile("inAppMessagePriority20")])
        let propsPerSurface = [mockInAppSurfacev2!: [propRank1Priority100, propRank2Priority60, propRank3Priority20]]
        
        // test
        let result = ParsedPropositions(with: propsPerSurface, requestedSurfaces: [mockInAppSurfacev2], runtime: mockRuntime)
        
        // verify
        XCTAssertNotNil(result)
        
        // surfaceRulesBySchemaType is sorted properly
        guard let inAppRules = result.surfaceRulesBySchemaType[.inapp],
              let inAppRulesForSurface = inAppRules[mockInAppSurfacev2] else {
            XCTFail("Unable to get rules for the requested surface.")
            return
        }
        let firstRule = inAppRulesForSurface[0]
        XCTAssertEqual("priority100", firstRule.consequences.first?.id)
        let secondRule = inAppRulesForSurface[1]
        XCTAssertEqual("priority60", secondRule.consequences.first?.id)
        let thirdRule = inAppRulesForSurface[2]
        XCTAssertEqual("priority20", thirdRule.consequences.first?.id)
        
        // propositionsToPersist is sorted properly
        guard let propsForSurface = result.propositionsToPersist[mockInAppSurfacev2] else {
            XCTFail("Unable to get propositions to persist for the requested surface.")
            return
        }
        let firstProp = propsForSurface[0]
        XCTAssertEqual(1, firstProp.rank)
        let secondProp = propsForSurface[1]
        XCTAssertEqual(2, secondProp.rank)
        let thirdProp = propsForSurface[2]
        XCTAssertEqual(3, thirdProp.rank)
    }
    
    func testSortByRankSourceIsRandomOrder() throws {
        // setup
        let propRank1Priority100 = Proposition(uniqueId: "rank1", scope: "inapp2", scopeDetails: ["rank": 1, "activity": [ "priority": 100 ]], items: [ getPropItemFile("inAppMessagePriority100")])
        let propRank2Priority60 = Proposition(uniqueId: "rank2", scope: "inapp2", scopeDetails: ["rank": 2, "activity": [ "priority": 60 ]], items: [getPropItemFile("inAppMessagePriority60")])
        let propRank3Priority20 = Proposition(uniqueId: "rank3", scope: "inapp2", scopeDetails: ["rank": 3, "activity": [ "priority": 20 ]], items: [getPropItemFile("inAppMessagePriority20")])
        let propsPerSurface = [mockInAppSurfacev2!: [propRank2Priority60, propRank1Priority100, propRank3Priority20]]
        
        // test
        let result = ParsedPropositions(with: propsPerSurface, requestedSurfaces: [mockInAppSurfacev2], runtime: mockRuntime)
        
        // verify
        XCTAssertNotNil(result)
        
        // surfaceRulesBySchemaType is sorted properly
        guard let inAppRules = result.surfaceRulesBySchemaType[.inapp],
              let inAppRulesForSurface = inAppRules[mockInAppSurfacev2] else {
            XCTFail("Unable to get rules for the requested surface.")
            return
        }
        let firstRule = inAppRulesForSurface[0]
        XCTAssertEqual("priority100", firstRule.consequences.first?.id)
        let secondRule = inAppRulesForSurface[1]
        XCTAssertEqual("priority60", secondRule.consequences.first?.id)
        let thirdRule = inAppRulesForSurface[2]
        XCTAssertEqual("priority20", thirdRule.consequences.first?.id)
        
        // propositionsToPersist is sorted properly
        guard let propsForSurface = result.propositionsToPersist[mockInAppSurfacev2] else {
            XCTFail("Unable to get propositions to persist for the requested surface.")
            return
        }
        let firstProp = propsForSurface[0]
        XCTAssertEqual(1, firstProp.rank)
        let secondProp = propsForSurface[1]
        XCTAssertEqual(2, secondProp.rank)
        let thirdProp = propsForSurface[2]
        XCTAssertEqual(3, thirdProp.rank)
    }
    
    func testInitPropositionRulesetConsequenceInvalidDetail() throws {
        // setup – rule has a schema consequence whose `data` block is empty
        let content = JSONFileLoader.getRulesJsonFromFile("ruleWithInvalidConsequenceDetail")
        let pi = PropositionItem(itemId: "inapp", schema: .ruleset, itemData: content)
        let prop = Proposition(uniqueId: "inapp", scope: "inapp", scopeDetails: ["key": "value"], items: [pi])
        let propositions: [Surface: [Proposition]] = [
            mockInAppSurfacev2: [prop]
        ]

        // test
        let result = ParsedPropositions(with: propositions, requestedSurfaces: [mockInAppSurfacev2], runtime: mockRuntime)

        // verify – nothing should be cached or persisted and no rules should be produced
        XCTAssertNotNil(result)
        XCTAssertEqual(0, result.propositionInfoToCache.count)
        XCTAssertEqual(0, result.propositionsToCache.count)
        XCTAssertEqual(0, result.propositionsToPersist.count)
        XCTAssertEqual(0, result.surfaceRulesBySchemaType.count)
    }
    
    private func getPropItemFile(_ fileName: String) -> PropositionItem {
        let itemData = JSONFileLoader.getRulesJsonFromFile(fileName)
        return PropositionItem(itemId: "inapp2", schema: rulesetSchema, itemData: itemData)
    }
}
