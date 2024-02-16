//
// Copyright 2023 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

@testable import AEPCore
@testable import AEPServices
@testable import AEPMessaging
import AEPTestUtils
import XCTest

class MessagingPlusStateTests: XCTestCase {
    var mockRuntime: TestableExtensionRuntime!
    var messaging: Messaging!
    var mockMessagingRulesEngine: MockMessagingRulesEngine!
    var mockLaunchRulesEngineForIAM: MockLaunchRulesEngine!
    var mockFeedRulesEngine: MockFeedRulesEngine!
    var mockLaunchRulesEngineForFeeds: MockLaunchRulesEngine!
    var mockCache: MockCache!
    let mockIamSurface = Surface(uri: "mobileapp://com.apple.dt.xctest.tool")
    var mockProposition: MessagingProposition!
    var mockPropositionItem: MessagingPropositionItem!
    var mockPropositionInfo: PropositionInfo!

    // Mock constants
    let MOCK_ECID = "mock_ecid"
    let MOCK_EVENT_DATASET = "mock_event_dataset"
    let MOCK_EXP_ORG_ID = "mock_exp_org_id"
    let MOCK_PUSH_TOKEN = "mock_pushToken"
    let MOCK_PUSH_PLATFORM = "apns"

    override func setUp() {
        mockRuntime = TestableExtensionRuntime()
        mockCache = MockCache(name: "mockCache")
        mockLaunchRulesEngineForIAM = MockLaunchRulesEngine(name: "mockLaunchRulesEngineIAM", extensionRuntime: mockRuntime)
        mockMessagingRulesEngine = MockMessagingRulesEngine(extensionRuntime: mockRuntime, launchRulesEngine: mockLaunchRulesEngineForIAM, cache: mockCache)
        mockLaunchRulesEngineForFeeds = MockLaunchRulesEngine(name: "mockLaunchRulesEngineFeeds", extensionRuntime: mockRuntime)
        mockFeedRulesEngine = MockFeedRulesEngine(extensionRuntime: mockRuntime, launchRulesEngine: mockLaunchRulesEngineForFeeds)
        messaging = Messaging(runtime: mockRuntime, rulesEngine: mockMessagingRulesEngine, feedRulesEngine: mockFeedRulesEngine, expectedSurfaceUri: mockIamSurface.uri, cache: mockCache)
        
        mockPropositionItem = MessagingPropositionItem(itemId: "propItemId", schema: .defaultContent, itemData: [:])
        mockProposition = MessagingProposition(uniqueId: "propId", scope: mockIamSurface.uri, scopeDetails: [:], items: [mockPropositionItem])
        mockPropositionInfo = PropositionInfo(id: "propInfoId", scope: mockIamSurface.uri, scopeDetails: [:])
    }

    func testLoadCachedPropositionsCacheContainsPropositions() throws {
        // setup
        let propositionData = JSONFileLoader.getRulesStringFromFile("cachedProposition").data(using: .utf8)!
        mockCache.getReturnValue = CacheEntry(data: propositionData, expiry: .never, metadata: nil)
                
        // test
        messaging.loadCachedPropositions()
        
        // verify
        XCTAssertTrue(mockLaunchRulesEngineForIAM.replaceRulesCalled)
    }
    
    func testLoadCachedPropositionsCacheDoesNotContainPropositions() throws {
        // setup
        mockCache.getReturnValue = nil
        
        // test
        messaging.loadCachedPropositions()
        
        // verify
        XCTAssertFalse(mockLaunchRulesEngineForIAM.replaceRulesCalled)
    }
    
    func testUpdatePropositionInfo() throws {
        // setup
        messaging.propositionInfo = [ "id1": mockPropositionInfo ]
        let propInfo2 = PropositionInfo(id: "propInfoId2", scope: "newScope", scopeDetails: [:])
        let newPropInfoDictionary = [ "id2": propInfo2 ]
        
        // test
        messaging.updatePropositionInfo(newPropInfoDictionary)
        
        // verify
        XCTAssertEqual(2, messaging.propositionInfoCount())
    }
    
    func testUpdatePropositionInfoRemovingSurfaces() throws {
        // setup
        messaging.propositionInfo = [ "id1": mockPropositionInfo ]
        let propInfo2 = PropositionInfo(id: "propInfoId2", scope: "newScope", scopeDetails: [:])
        let newPropInfoDictionary = [ "id2": propInfo2 ]
        
        // test
        messaging.updatePropositionInfo(newPropInfoDictionary, removing: [mockIamSurface])
        
        // verify
        XCTAssertEqual(1, messaging.propositionInfoCount())
        XCTAssertNil(messaging.propositionInfo["id1"])
    }
    
    func testUpdatePropositionInfoNewOverrides() throws {
        // setup
        messaging.propositionInfo = [ "id1": mockPropositionInfo ]
        let propInfo2 = PropositionInfo(id: "propInfoId2", scope: "newScope", scopeDetails: [:])
        let newPropInfoDictionary = [ "id1": propInfo2 ]
        
        // test
        messaging.updatePropositionInfo(newPropInfoDictionary, removing: [mockIamSurface])
        
        // verify
        XCTAssertEqual(1, messaging.propositionInfoCount())
        let propInfo = messaging.propositionInfo["id1"]
        XCTAssertEqual("newScope", propInfo?.scope)
    }
    
    func testUpdatePropositions() throws {
        // setup
        messaging.propositions = [ mockIamSurface: [mockProposition] ]
        let newProp = MessagingProposition(uniqueId: "newId", scope: "newScope", scopeDetails: [:], items: [])
        let newPropositions = [Surface(uri: "newScope"): [newProp]]
        
        // test
        messaging.updatePropositions(newPropositions)
        
        // verify
        XCTAssertEqual(2, messaging.propositions.count)
    }
    
    func testUpdatePropositionsRemovingSurfaces() throws {
        // setup
        messaging.propositions = [ mockIamSurface: [mockProposition] ]
        let newProp = MessagingProposition(uniqueId: "newId", scope: "newScope", scopeDetails: [:], items: [])
        let newPropositions = [Surface(uri: "newScope"): [newProp]]
        
        // test
        messaging.updatePropositions(newPropositions, removing: [mockIamSurface])
        
        // verify
        XCTAssertEqual(1, messaging.propositions.count)
        XCTAssertNil(messaging.propositions[mockIamSurface])
    }
}
