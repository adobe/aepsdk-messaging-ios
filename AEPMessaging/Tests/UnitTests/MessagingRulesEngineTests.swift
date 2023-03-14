/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

@testable import AEPCore
@testable import AEPMessaging
@testable import AEPRulesEngine
@testable import AEPServices
import Foundation
import XCTest

class MessagingRulesEngineTests: XCTestCase {
    var messagingRulesEngine: MessagingRulesEngine!
    var mockRulesEngine: MockLaunchRulesEngine!
    var mockRuntime: TestableExtensionRuntime!
    var mockCache: MockCache!

    override func setUp() {
        mockRuntime = TestableExtensionRuntime()
        mockRulesEngine = MockLaunchRulesEngine(name: "mockRulesEngine", extensionRuntime: mockRuntime)
        mockCache = MockCache(name: "mockCache")
        messagingRulesEngine = MessagingRulesEngine(extensionRuntime: mockRuntime, rulesEngine: mockRulesEngine, cache: mockCache)
    }

    func testInitializer() throws {
        // setup
        let propString = JSONFileLoader.getRulesStringFromFile("showOnceRule")
        let cacheEntry = CacheEntry(data: propString.data(using: .utf8)!, expiry: .never, metadata: nil)
        let cache = Cache(name: "com.adobe.messaging.cache")
        try? cache.set(key: "propositions", entry: cacheEntry)

        // test
        let mre = MessagingRulesEngine(name: "mockRE", extensionRuntime: TestableExtensionRuntime())

        // verify
        // launch rules engine loads asynchronously with no callback mechanism, so we have to pause this thread for a second
        sleep(1)
        XCTAssertEqual(1, mre.rulesEngine.rulesEngine.rules.count)
    }

    func testProcess() throws {
        // setup
        let event = Event(name: "testEvent", type: "type", source: "source", data: nil)

        // test
        messagingRulesEngine.process(event: event)

        // verify
        XCTAssertTrue(mockRulesEngine.processCalled)
        XCTAssertEqual(event, mockRulesEngine.paramProcessedEvent)
    }

    func testLoadPropositionsHappy() throws {
        // setup
        let decoder = JSONDecoder()
        let propString: String = JSONFileLoader.getRulesStringFromFile("showOnceRule")
        let propositions = try decoder.decode([PropositionPayload].self, from: propString.data(using: .utf8)!)
        
        // test
        messagingRulesEngine.loadPropositions(propositions, clearExisting: false)

        // verify
        XCTAssertTrue(mockRulesEngine.addRulesCalled)
        XCTAssertEqual(1, mockRulesEngine.paramAddRulesRules?.count)
    }
    
    func testLoadPropositionsClearExisting() throws {
        // setup
        let decoder = JSONDecoder()
        let propString: String = JSONFileLoader.getRulesStringFromFile("showOnceRule")
        let propositions = try decoder.decode([PropositionPayload].self, from: propString.data(using: .utf8)!)
        
        // test
        messagingRulesEngine.loadPropositions(propositions, clearExisting: true)

        // verify
        XCTAssertTrue(mockRulesEngine.replaceRulesCalled)
        XCTAssertEqual(1, mockRulesEngine.paramRules?.count)
    }
    
    func testLoadPropositionsNoItemsInPayload() throws {
        // setup
        let propInfo = PropositionInfo(id: "a", scope: "a", scopeDetails: [:])
        let propPayload = PropositionPayload(propositionInfo: propInfo, items: [])
        
        // test
        messagingRulesEngine.loadPropositions([propPayload], clearExisting: false)
        
        // verify
        XCTAssertTrue(mockRulesEngine.addRulesCalled)
        XCTAssertEqual(0, mockRulesEngine.paramAddRulesRules?.count)
    }
    
    func testLoadPropositionsEmptyContentInPayload() throws {
        // setup
        let itemData = ItemData(content: "")
        let payloadItem = PayloadItem(data: itemData)
        let propInfo = PropositionInfo(id: "a", scope: "a", scopeDetails: [:])
        let propPayload = PropositionPayload(propositionInfo: propInfo, items: [payloadItem])
        
        // test
        messagingRulesEngine.loadPropositions([propPayload], clearExisting: false)
        
        // verify
        XCTAssertTrue(mockRulesEngine.addRulesCalled)
        XCTAssertEqual(0, mockRulesEngine.paramAddRulesRules?.count)
    }
    
    func testLoadPropositionsEventSequence() throws {
        // setup
        let decoder = JSONDecoder()
        let propString: String = JSONFileLoader.getRulesStringFromFile("eventSequenceRule")
        let propositions = try decoder.decode([PropositionPayload].self, from: propString.data(using: .utf8)!)
        
        // test
        messagingRulesEngine.loadPropositions(propositions, clearExisting: false)

        // verify
        XCTAssertTrue(mockRulesEngine.addRulesCalled)
        XCTAssertEqual(1, mockRulesEngine.paramAddRulesRules?.count)
    }

    func testLoadPropositionsEmptyPropositions() throws {
        // setup
        let propositions: [PropositionPayload] = []

        // test
        messagingRulesEngine.loadPropositions(propositions, clearExisting: true)

        // verify
        XCTAssertTrue(mockRulesEngine.replaceRulesCalled)
        XCTAssertEqual(0, mockRulesEngine.paramRules?.count)
    }
}
