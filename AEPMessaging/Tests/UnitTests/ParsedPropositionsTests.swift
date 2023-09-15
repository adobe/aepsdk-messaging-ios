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
    
    var mockFeedPropositionItem: PropositionItem!
    var mockFeedProposition: Proposition!
    var mockFeedSurface: Surface!
    let mockFeedMessageId = "183639c4-cb37-458e-a8ef-4e130d767ebf"
    
    var mockCodeBasedPropositionItem: PropositionItem!
    var mockCodeBasedProposition: Proposition!
    var mockCodeBasedSurface: Surface!
        
    override func setUp() {
        mockSurface = Surface(uri: "mobileapp://some.not.matching.surface/path")
        
        mockInAppPropositionItem = PropositionItem(uniqueId: "inapp", schema: "mobileapp://com.apple.dt.xctest.tool", content: "content")
        mockInAppProposition = Proposition(uniqueId: "inapp", scope: "mobileapp://com.apple.dt.xctest.tool", scopeDetails: ["key": "value"], items: [mockInAppPropositionItem])
        mockInAppSurface = Surface(uri: "mobileapp://com.apple.dt.xctest.tool")
        
        let feedContent = JSONFileLoader.getRulesStringFromFile("feedPropositionContent")
        mockFeedPropositionItem = PropositionItem(uniqueId: "feed", schema: "feed", content: feedContent)
        mockFeedProposition = Proposition(uniqueId: "feed", scope: "feed", scopeDetails: ["key":"value"], items: [mockFeedPropositionItem])
        mockFeedSurface = Surface(uri: "feed")
        
        mockCodeBasedPropositionItem = PropositionItem(uniqueId: "codebased", schema: "codebased", content: "content")
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
    
    func testInitWithInAppProposition() throws {
        // setup
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
}
