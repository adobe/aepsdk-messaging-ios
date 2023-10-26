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
@testable import AEPServices

class ParsedPropositionTests: XCTestCase {
    var mockSurface: Surface!
    
    let rulesetSchema: SchemaType = .ruleset
    let jsonSchema: SchemaType = .jsonContent
    let htmlSchema: SchemaType = .htmlContent
    
    var mockInAppPropositionItem: PropositionItem!
    var mockInAppProposition: Proposition!
    var mockInAppSurface: Surface!
    let mockInAppMessageId = "6ac78390-84e3-4d35-b798-8e7080e69a66"
    
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
        
        let inappPropositionV1Content = JSONFileLoader.getRulesJsonFromFile("inappPropositionV1Content")
        mockInAppPropositionItem = PropositionItem(propositionId: "inapp", schema: jsonSchema, propositionData: inappPropositionV1Content)
        mockInAppProposition = Proposition(uniqueId: "inapp", scope: "inapp", scopeDetails: ["key": "value"], items: [mockInAppPropositionItem])
        mockInAppSurface = Surface(uri: "inapp")
        
        let inappPropositionV2Content = JSONFileLoader.getRulesJsonFromFile("inappPropositionV2Content")
        mockInAppPropositionItemv2 = PropositionItem(propositionId: "inapp2", schema: rulesetSchema, propositionData: inappPropositionV2Content)
        mockInAppPropositionv2 = Proposition(uniqueId: "inapp2", scope: "inapp2", scopeDetails: ["key": "value"], items: [mockInAppPropositionItemv2])
        mockInAppSurfacev2 = Surface(uri: "inapp2")
        
        mockFeedContent = JSONFileLoader.getRulesJsonFromFile("feedPropositionContent")
        mockFeedPropositionItem = PropositionItem(propositionId: "feed", schema: rulesetSchema, propositionData: mockFeedContent)
        mockFeedProposition = Proposition(uniqueId: "feed", scope: "feed", scopeDetails: ["key":"value"], items: [mockFeedPropositionItem])
        mockFeedSurface = Surface(uri: "feed")
        
        mockCodeBasedContent = JSONFileLoader.getRulesJsonFromFile("codeBasedPropositionContent")
        mockCodeBasedPropositionItem = PropositionItem(propositionId: "codebased", schema: htmlSchema, propositionData: mockCodeBasedContent)
        mockCodeBasedProposition = Proposition(uniqueId: "codebased", scope: "codebased", scopeDetails: ["key":"value"], items: [mockCodeBasedPropositionItem])
        mockCodeBasedSurface = Surface(uri: "codebased")
    }
    
    func testInitWithEmptyPropositions() throws {
        // setup
        let propositions: [Surface: [Proposition]] = [mockSurface: []]
        
        // test
        let result = ParsedPropositions(with: propositions, requestedSurfaces: [mockSurface])
        
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
            mockInAppSurface: [mockInAppProposition],
            mockFeedSurface: [mockFeedProposition],
            mockCodeBasedSurface: [mockCodeBasedProposition]
        ]
        
        // test
        let result = ParsedPropositions(with: propositions, requestedSurfaces: [mockSurface])
        
        // verify
        XCTAssertNotNil(result)
        XCTAssertEqual(0, result.propositionInfoToCache.count)
        XCTAssertEqual(0, result.propositionsToCache.count)
        XCTAssertEqual(0, result.propositionsToPersist.count)
        XCTAssertEqual(0, result.surfaceRulesBySchemaType.count)
    }
    
    func testInitWithInAppPropositionV1() throws {
        // setup
        let propositions: [Surface: [Proposition]] = [
            mockInAppSurface: [mockInAppProposition]
        ]
        
        // test
        let result = ParsedPropositions(with: propositions, requestedSurfaces: [mockInAppSurface])
        
        // verify
        XCTAssertNotNil(result)
        XCTAssertEqual(1, result.propositionInfoToCache.count, "should have one IAM in propositionInfo for tracking purposes")
        let iamPropInfo = result.propositionInfoToCache[mockInAppMessageId]
        XCTAssertEqual("inapp", iamPropInfo?.id)
        XCTAssertEqual(0, result.propositionsToCache.count)
        XCTAssertEqual(1, result.propositionsToPersist.count, "should have one entry for persistence")
        let iamPersist = result.propositionsToPersist[mockInAppSurface]
        XCTAssertEqual(1, iamPersist?.count)
        XCTAssertEqual("inapp", iamPersist?.first?.uniqueId)
        XCTAssertEqual(1, result.surfaceRulesBySchemaType.count, "should have one rule to insert in the IAM rules engine")
        let iamRules = result.surfaceRulesBySchemaType[.inapp]
        XCTAssertEqual(1, iamRules?.count)
    }
    
    func testInitWithInAppPropositionV2() throws {
        // setup
        let propositions: [Surface: [Proposition]] = [
            mockInAppSurfacev2: [mockInAppPropositionv2]
        ]
        
        // test
        let result = ParsedPropositions(with: propositions, requestedSurfaces: [mockInAppSurfacev2])
        
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
    
    func testInitWithMultipleInAppPropositionTypes() throws {
        // setup
        let propositions: [Surface: [Proposition]] = [
            mockInAppSurface: [mockInAppProposition],
            mockInAppSurfacev2: [mockInAppPropositionv2]
        ]
        
        // test
        let result = ParsedPropositions(with: propositions, requestedSurfaces: [mockInAppSurface, mockInAppSurfacev2])
        
        // verify
        XCTAssertNotNil(result)
        XCTAssertEqual(2, result.propositionInfoToCache.count, "should have two IAM in propositionInfo for tracking purposes")
        XCTAssertEqual(0, result.propositionsToCache.count)
        XCTAssertEqual(2, result.propositionsToPersist.count, "should have two entries for persistence")
        XCTAssertEqual(1, result.surfaceRulesBySchemaType.count, "should have two rules to insert in the IAM rules engine")
        let iamRules = result.surfaceRulesBySchemaType[.inapp]
        XCTAssertEqual(2, iamRules?.count)
    }
    
    func testInitWithFeedProposition() throws {
        // setup
        let propositions: [Surface: [Proposition]] = [
            mockFeedSurface: [mockFeedProposition]
        ]
        
        // test
        let result = ParsedPropositions(with: propositions, requestedSurfaces: [mockFeedSurface])
        
        // verify
        XCTAssertNotNil(result)
        XCTAssertEqual(1, result.propositionInfoToCache.count, "should have one entry in proposition info for tracking purposes")
        let feedPropositionInfo = result.propositionInfoToCache[mockFeedMessageId]
        XCTAssertNotNil(feedPropositionInfo)
        XCTAssertEqual("feed", feedPropositionInfo?.id)
        XCTAssertEqual(0, result.propositionsToCache.count)
        XCTAssertEqual(0, result.propositionsToPersist.count)
        XCTAssertEqual(1, result.surfaceRulesBySchemaType.count, "should have one rule to insert in the feeds rules engine")
        let feedRules = result.surfaceRulesBySchemaType[.feed]
        XCTAssertNotNil(feedRules)
        XCTAssertEqual(1, feedRules?.count)
    }
    
    func testInitWithCodeBasedProposition() throws {
        // setup
        let propositions: [Surface: [Proposition]] = [
            mockCodeBasedSurface: [mockCodeBasedProposition]
        ]
        
        // test
        let result = ParsedPropositions(with: propositions, requestedSurfaces: [mockCodeBasedSurface])
        
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
        mockInAppPropositionItem = PropositionItem(propositionId: "inapp", schema: .inapp, propositionData: nil)
        mockInAppProposition = Proposition(uniqueId: "inapp", scope: "inapp", scopeDetails: ["key": "value"], items: [mockInAppPropositionItem])
        let propositions: [Surface: [Proposition]] = [
            mockInAppSurface: [mockInAppProposition]
        ]
        
        // test
        let result = ParsedPropositions(with: propositions, requestedSurfaces: [mockInAppSurface])
        
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
        let pi = PropositionItem(propositionId: "inapp", schema: .ruleset, propositionData: noConsequenceRule)
        let prop = Proposition(uniqueId: "inapp", scope: "inapp", scopeDetails: ["key": "value"], items: [pi])
        let propositions: [Surface: [Proposition]] = [
            mockInAppSurface: [prop]
        ]
        
        // test
        let result = ParsedPropositions(with: propositions, requestedSurfaces: [mockInAppSurface])
        
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
        let pi = PropositionItem(propositionId: "inapp", schema: .ruleset, propositionData: content)
        let prop = Proposition(uniqueId: "inapp", scope: "inapp", scopeDetails: ["key": "value"], items: [pi])
        let propositions: [Surface: [Proposition]] = [
            mockInAppSurface: [prop]
        ]
        
        // test
        let result = ParsedPropositions(with: propositions, requestedSurfaces: [mockInAppSurface])
        
        // verify
        XCTAssertNotNil(result)
        XCTAssertEqual(0, result.propositionInfoToCache.count)
        XCTAssertEqual(0, result.propositionsToCache.count)
        XCTAssertEqual(0, result.propositionsToPersist.count)
        XCTAssertEqual(0, result.surfaceRulesBySchemaType.count)
    }
    
    func testInitPropositionUnknownSchema() throws {
        // setup
        let pi = PropositionItem(propositionId: "inapp", schema: .unknown, propositionData: nil)
        let prop = Proposition(uniqueId: "inapp", scope: "inapp", scopeDetails: ["key": "value"], items: [pi])
        let propositions: [Surface: [Proposition]] = [
            mockInAppSurface: [prop]
        ]
        
        // test
        let result = ParsedPropositions(with: propositions, requestedSurfaces: [mockInAppSurface])
        
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
            mockInAppSurface: [prop]
        ]
        
        // test
        let result = ParsedPropositions(with: propositions, requestedSurfaces: [mockInAppSurface])
        
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
}
