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

class ParsedPropositionTests: XCTestCase {
    var mockSurface: Surface!
    
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
    var mockFeedContent: String!
    
    var mockCodeBasedPropositionItem: PropositionItem!
    var mockCodeBasedProposition: Proposition!
    var mockCodeBasedSurface: Surface!
    var mockCodeBasedContent: String!
        
    override func setUp() {
        mockSurface = Surface(uri: "mobileapp://some.not.matching.surface/path")
        
        let inappPropositionV1Content = JSONFileLoader.getRulesStringFromFile("inappPropositionV1Content")
        mockInAppPropositionItem = PropositionItem(uniqueId: "inapp", schema: "inapp", content: inappPropositionV1Content)
        mockInAppProposition = Proposition(uniqueId: "inapp", scope: "inapp", scopeDetails: ["key": "value"], items: [mockInAppPropositionItem])
        mockInAppSurface = Surface(uri: "inapp")
        
        let inappPropositionV2Content = JSONFileLoader.getRulesStringFromFile("inappPropositionV2Content")
        mockInAppPropositionItemv2 = PropositionItem(uniqueId: "inapp2", schema: "inapp2", content: inappPropositionV2Content)
        mockInAppPropositionv2 = Proposition(uniqueId: "inapp2", scope: "inapp2", scopeDetails: ["key": "value"], items: [mockInAppPropositionItemv2])
        mockInAppSurfacev2 = Surface(uri: "inapp2")
        
        mockFeedContent = JSONFileLoader.getRulesStringFromFile("feedPropositionContent")
        mockFeedPropositionItem = PropositionItem(uniqueId: "feed", schema: "feed", content: mockFeedContent)
        mockFeedProposition = Proposition(uniqueId: "feed", scope: "feed", scopeDetails: ["key":"value"], items: [mockFeedPropositionItem])
        mockFeedSurface = Surface(uri: "feed")
        
        mockCodeBasedContent = JSONFileLoader.getRulesStringFromFile("codeBasedPropositionContent")
        mockCodeBasedPropositionItem = PropositionItem(uniqueId: "codebased", schema: "codebased", content: mockCodeBasedContent)
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
        XCTAssertEqual(0, result.surfaceRulesByInboundType.count)
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
        XCTAssertEqual(0, result.surfaceRulesByInboundType.count)
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
        XCTAssertEqual(1, result.surfaceRulesByInboundType.count, "should have one rule to insert in the IAM rules engine")
        let iamRules = result.surfaceRulesByInboundType[.inapp]
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
        XCTAssertEqual(1, result.surfaceRulesByInboundType.count, "should have one rule to insert in the IAM rules engine")
        let iamRules = result.surfaceRulesByInboundType[.inapp]
        XCTAssertEqual(1, iamRules?.count)
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
        XCTAssertEqual(1, result.surfaceRulesByInboundType.count, "should have two rules to insert in the IAM rules engine")
        let iamRules = result.surfaceRulesByInboundType[.inapp]
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
        XCTAssertEqual(1, result.surfaceRulesByInboundType.count, "should have one rule to insert in the feeds rules engine")
        let feedRules = result.surfaceRulesByInboundType[.feed]
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
        let codeBasedProp = result.propositionsToCache[mockCodeBasedSurface]?.first
        XCTAssertEqual(mockCodeBasedContent, codeBasedProp?.items.first?.content)
        XCTAssertEqual(0, result.propositionsToPersist.count)
        XCTAssertEqual(0, result.surfaceRulesByInboundType.count)
    }
    
    func testInitPropositionItemEmptyContentString() throws {
        // setup
        mockInAppPropositionItem = PropositionItem(uniqueId: "inapp", schema: "inapp", content: "")
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
        XCTAssertEqual(0, result.surfaceRulesByInboundType.count)
    }
    
    func testInitPropositionRuleHasNoConsequence() throws {
        // setup
        let noConsequenceRule = JSONFileLoader.getRulesStringFromFile("ruleWithNoConsequence")
        let pi = PropositionItem(uniqueId: "inapp", schema: "inapp", content: noConsequenceRule)
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
        XCTAssertEqual(0, result.surfaceRulesByInboundType.count)
    }
    
    func testInitPropositionConsequenceHasUnknownSchema() throws {
        // setup
        let content = JSONFileLoader.getRulesStringFromFile("ruleWithUnknownConsequenceSchema")
        let pi = PropositionItem(uniqueId: "inapp", schema: "inapp", content: content)
        let prop = Proposition(uniqueId: "inapp", scope: "inapp", scopeDetails: ["key": "value"], items: [pi])
        let propositions: [Surface: [Proposition]] = [
            mockInAppSurface: [prop]
        ]
        
        // test
        let result = ParsedPropositions(with: propositions, requestedSurfaces: [mockInAppSurface])
        
        // verify
        XCTAssertNotNil(result)
        XCTAssertEqual(1, result.propositionInfoToCache.count)
        XCTAssertEqual(1, result.propositionsToCache.count)
        XCTAssertEqual(0, result.propositionsToPersist.count)
        XCTAssertEqual(1, result.surfaceRulesByInboundType.count)
        let unknownRules = result.surfaceRulesByInboundType[.unknown]
        XCTAssertNotNil(unknownRules)
        XCTAssertEqual(1, unknownRules?.count)
    }
}
