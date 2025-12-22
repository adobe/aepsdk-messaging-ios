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
import AEPTestUtils
@testable import AEPMessaging
@testable import AEPServices
@testable import AEPCore

class MessagingInboxPropositionsTests: XCTestCase {
    var mockRuntime: TestableExtensionRuntime!
    var messaging: Messaging!
    var mockCache: MockCache!
    var mockLaunchRulesEngine: MockLaunchRulesEngine!
    var mockMessagingRulesEngine: MockMessagingRulesEngine!
    var mockContentCardRulesEngine: MockContentCardRulesEngine!
    var messagingProperties: MessagingProperties!
    
    override func setUp() {
        EventHub.shared.start()
        mockRuntime = TestableExtensionRuntime()
        mockCache = MockCache(name: "test.cache")
        mockLaunchRulesEngine = MockLaunchRulesEngine(name: "mockLaunchRulesEngine", extensionRuntime: mockRuntime)
        mockContentCardRulesEngine = MockContentCardRulesEngine(extensionRuntime: mockRuntime, launchRulesEngine: mockLaunchRulesEngine)
        mockMessagingRulesEngine = MockMessagingRulesEngine(extensionRuntime: mockRuntime, launchRulesEngine: mockLaunchRulesEngine, cache: mockCache)
        messagingProperties = MessagingProperties()
        
        messaging = Messaging(
            runtime: mockRuntime,
            rulesEngine: mockMessagingRulesEngine,
            contentCardRulesEngine: mockContentCardRulesEngine,
            expectedSurfaceUri: "mobileapp://test",
            cache: mockCache,
            messagingProperties: messagingProperties
        )
    }
    
    override func tearDown() {
        mockCache = nil
        mockLaunchRulesEngine = nil
        mockMessagingRulesEngine = nil
        mockContentCardRulesEngine = nil
        messaging = nil
        messagingProperties = nil
        mockRuntime = nil
    }
    
    // MARK: - updateInboxPropositions Tests
    
    func testUpdateInboxPropositionsAddsNewSurface() throws {
        // setup
        let surface = Surface(uri: "mobileapp://test/inbox")
        let propositionItem = PropositionItem(itemId: "item1", schema: .containerItem, itemData: ["content": ["heading": ["content": "Test"]]])
        let proposition = Proposition(uniqueId: "prop1", scope: surface.uri, scopeDetails: [:], items: [propositionItem])
        let newPropositions: [Surface: [Proposition]] = [surface: [proposition]]
        
        // test
        messaging.updateInboxPropositions(newPropositions)
        
        // wait for async queue to complete
        Thread.sleep(forTimeInterval: 0.1)
        
        // verify
        XCTAssertEqual(1, messaging.inboxPropositionsBySurface.count)
        XCTAssertEqual(1, messaging.inboxPropositionsBySurface[surface]?.count)
        XCTAssertEqual("prop1", messaging.inboxPropositionsBySurface[surface]?.first?.uniqueId)
    }
    
    func testUpdateInboxPropositionsReplacesExistingSurface() throws {
        // setup
        let surface = Surface(uri: "mobileapp://test/inbox")
        let propositionItem1 = PropositionItem(itemId: "item1", schema: .containerItem, itemData: ["content": ["heading": ["content": "Test1"]]])
        let proposition1 = Proposition(uniqueId: "prop1", scope: surface.uri, scopeDetails: [:], items: [propositionItem1])
        messaging.inboxPropositionsBySurface = [surface: [proposition1]]
        
        let propositionItem2 = PropositionItem(itemId: "item2", schema: .containerItem, itemData: ["content": ["heading": ["content": "Test2"]]])
        let proposition2 = Proposition(uniqueId: "prop2", scope: surface.uri, scopeDetails: [:], items: [propositionItem2])
        let newPropositions: [Surface: [Proposition]] = [surface: [proposition2]]
        
        // test
        messaging.updateInboxPropositions(newPropositions)
        
        // wait for async queue to complete
        Thread.sleep(forTimeInterval: 0.1)
        
        // verify - old proposition should be replaced
        XCTAssertEqual(1, messaging.inboxPropositionsBySurface.count)
        XCTAssertEqual(1, messaging.inboxPropositionsBySurface[surface]?.count)
        XCTAssertEqual("prop2", messaging.inboxPropositionsBySurface[surface]?.first?.uniqueId)
    }
    
    func testUpdateInboxPropositionsRemovesSurfaces() throws {
        // setup
        let surface1 = Surface(uri: "mobileapp://test/inbox1")
        let surface2 = Surface(uri: "mobileapp://test/inbox2")
        let propositionItem1 = PropositionItem(itemId: "item1", schema: .containerItem, itemData: [:])
        let proposition1 = Proposition(uniqueId: "prop1", scope: surface1.uri, scopeDetails: [:], items: [propositionItem1])
        let propositionItem2 = PropositionItem(itemId: "item2", schema: .containerItem, itemData: [:])
        let proposition2 = Proposition(uniqueId: "prop2", scope: surface2.uri, scopeDetails: [:], items: [propositionItem2])
        messaging.inboxPropositionsBySurface = [surface1: [proposition1], surface2: [proposition2]]
        
        // test - remove surface1
        messaging.updateInboxPropositions([:], removing: [surface1])
        
        // wait for async queue to complete
        Thread.sleep(forTimeInterval: 0.1)
        
        // verify
        XCTAssertEqual(1, messaging.inboxPropositionsBySurface.count)
        XCTAssertNil(messaging.inboxPropositionsBySurface[surface1])
        XCTAssertNotNil(messaging.inboxPropositionsBySurface[surface2])
    }
    
    func testUpdateInboxPropositionsWithMultiplePropositionsForSameSurface() throws {
        // setup
        let surface = Surface(uri: "mobileapp://test/inbox")
        let propositionItem1 = PropositionItem(itemId: "item1", schema: .containerItem, itemData: [:])
        let proposition1 = Proposition(uniqueId: "prop1", scope: surface.uri, scopeDetails: [:], items: [propositionItem1])
        let propositionItem2 = PropositionItem(itemId: "item2", schema: .containerItem, itemData: [:])
        let proposition2 = Proposition(uniqueId: "prop2", scope: surface.uri, scopeDetails: [:], items: [propositionItem2])
        let newPropositions: [Surface: [Proposition]] = [surface: [proposition1, proposition2]]
        
        // test
        messaging.updateInboxPropositions(newPropositions)
        
        // wait for async queue to complete
        Thread.sleep(forTimeInterval: 0.1)
        
        // verify - both propositions should be stored
        XCTAssertEqual(1, messaging.inboxPropositionsBySurface.count)
        XCTAssertEqual(2, messaging.inboxPropositionsBySurface[surface]?.count)
    }
    
    // MARK: - Direct Storage Verification Tests
    
    func testInboxPropositionsStoredInSeparateContainer() throws {
        // setup
        let surface = Surface(uri: "mobileapp://test/inbox")
        let propositionItem = PropositionItem(itemId: "item1", schema: .containerItem, itemData: ["content": ["heading": ["content": "Test"]]])
        let inboxProposition = Proposition(uniqueId: "inbox1", scope: surface.uri, scopeDetails: [:], items: [propositionItem])
        
        // test - directly set inbox propositions
        messaging.inboxPropositionsBySurface = [surface: [inboxProposition]]
        
        // wait for async queue
        Thread.sleep(forTimeInterval: 0.1)
        
        // verify - inbox propositions are stored separately from other types
        XCTAssertEqual(1, messaging.inboxPropositionsBySurface.count)
        XCTAssertNotNil(messaging.inboxPropositionsBySurface[surface])
        XCTAssertEqual("inbox1", messaging.inboxPropositionsBySurface[surface]?.first?.uniqueId)
        
        // verify they're not in other storage
        XCTAssertEqual(0, messaging.inMemoryPropositions.count)
        XCTAssertEqual(0, messaging.qualifiedContentCardsBySurface.count)
    }
    
    func testMixedPropositionTypesStoredIndependently() throws {
        // setup - add inbox, content card, and CBE propositions
        let surface = Surface(uri: "mobileapp://test/mixed")
        
        // Inbox proposition
        let inboxItem = PropositionItem(itemId: "inbox1", schema: .containerItem, itemData: ["content": ["heading": ["content": "Inbox"]]])
        let inboxProposition = Proposition(uniqueId: "inbox-prop", scope: surface.uri, scopeDetails: [:], items: [inboxItem])
        
        // CBE proposition
        let cbeItem = PropositionItem(itemId: "cbe1", schema: .htmlContent, itemData: ["content": "<html>test</html>"])
        let cbeProposition = Proposition(uniqueId: "cbe-prop", scope: surface.uri, scopeDetails: [:], items: [cbeItem])
        
        // Content card proposition (qualified)
        let cardItem = PropositionItem(itemId: "card1", schema: .contentCard, itemData: ["content": ["title": ["content": "Card"]]])
        let cardProposition = Proposition(uniqueId: "card-prop", scope: surface.uri, scopeDetails: [:], items: [cardItem])
        
        // test - set all three types
        messaging.inboxPropositionsBySurface = [surface: [inboxProposition]]
        messaging.inMemoryPropositions = [surface: [cbeProposition]]
        messaging.qualifiedContentCardsBySurface = [surface: [cardProposition]]
        
        // wait for async queue
        Thread.sleep(forTimeInterval: 0.1)
        
        // verify - all three types stored independently
        XCTAssertEqual(1, messaging.inboxPropositionsBySurface.count)
        XCTAssertEqual(1, messaging.inMemoryPropositions.count)
        XCTAssertEqual(1, messaging.qualifiedContentCardsBySurface.count)
        
        XCTAssertEqual("inbox-prop", messaging.inboxPropositionsBySurface[surface]?.first?.uniqueId)
        XCTAssertEqual("cbe-prop", messaging.inMemoryPropositions[surface]?.first?.uniqueId)
        XCTAssertEqual("card-prop", messaging.qualifiedContentCardsBySurface[surface]?.first?.uniqueId)
    }
    
    func testInboxPropositionsDoNotInterfereWithOtherTypes() throws {
        // setup - only inbox, no other proposition types
        let surface = Surface(uri: "mobileapp://test/inbox-only")
        let inboxItem = PropositionItem(itemId: "inbox1", schema: .containerItem, itemData: [:])
        let inboxProposition = Proposition(uniqueId: "inbox-only", scope: surface.uri, scopeDetails: [:], items: [inboxItem])
        
        // test - set only inbox
        messaging.inboxPropositionsBySurface = [surface: [inboxProposition]]
        
        // wait for async queue
        Thread.sleep(forTimeInterval: 0.1)
        
        // verify - only inbox is populated, others remain empty
        XCTAssertEqual(1, messaging.inboxPropositionsBySurface.count)
        XCTAssertEqual(0, messaging.inMemoryPropositions.count)
        XCTAssertEqual(0, messaging.qualifiedContentCardsBySurface.count)
    }
}

