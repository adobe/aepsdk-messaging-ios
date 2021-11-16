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

import Foundation
import XCTest
import AEPCore
@testable import AEPMessaging

class MessagingRulesEngineTests: XCTestCase {
    var messagingRulesEngine: MessagingRulesEngine!
    var mockRulesEngine: MockLaunchRulesEngine!
    var mockRuntime: TestableExtensionRuntime!
    
    override func setUp() {
        mockRuntime = TestableExtensionRuntime()
        mockRulesEngine = MockLaunchRulesEngine(name: "mockRulesEngine", extensionRuntime: mockRuntime)
        messagingRulesEngine = MessagingRulesEngine(extensionRuntime: mockRuntime, rulesEngine: mockRulesEngine)
    }

    private func getRulesStringFromFile(_ fileName: String) -> String {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let jsonString = String(data: data, encoding: .utf8) else {
                  return ""
              }
        
        return jsonString
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
    
    func testLoadRulesHappy() throws {
        // setup
        let rules = [
            getRulesStringFromFile("eventSequenceRule"),
            getRulesStringFromFile("showOnceRule")
        ]
        
        // test
        messagingRulesEngine.loadRules(rules: rules)
        
        // verify
        XCTAssertTrue(mockRulesEngine.replaceRulesCalled)
        XCTAssertEqual(2, mockRulesEngine.paramRules?.count)
    }
    
    func testLoadRulesNilParam() throws {
        // setup
        let rules: [String]? = nil
        
        // test
        messagingRulesEngine.loadRules(rules: rules)
        
        // verify
        XCTAssertFalse(mockRulesEngine.replaceRulesCalled)
    }
    
    func testLoadRulesInvalidJsonRule() throws {
        // setup
        let rules: [String]? = ["i am not json"]
        
        // test
        messagingRulesEngine.loadRules(rules: rules)
        
        // verify
        XCTAssertTrue(mockRulesEngine.replaceRulesCalled)
        XCTAssertEqual(0, mockRulesEngine.paramRules?.count)
    }
}
