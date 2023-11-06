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


@testable import AEPCore
@testable import AEPMessaging
@testable import AEPServices
import Foundation
import XCTest

class LaunchRulesEngineMessagingTests: XCTestCase {
    var launchRulesEngine: MockLaunchRulesEngine!
    var mockRuntime: TestableExtensionRuntime!
    
    override func setUp() {
        mockRuntime = TestableExtensionRuntime()
        launchRulesEngine = MockLaunchRulesEngine(name: "mockLaunchRulesEngine", extensionRuntime: mockRuntime)
    }
    
    func testLoadRulesHappy() throws {
        
        // setup
        let decoder = JSONDecoder()
        let propString: String = JSONFileLoader.getRulesStringFromFile("showOnceRule")
        let propositions = try decoder.decode([PropositionPayload].self, from: propString.data(using: .utf8)!)
        let ruleString = propositions.first?.items.first?.propositionData?["content"] as? String
        let rulesArray = JSONRulesParser.parse(ruleString?.data(using: .utf8) ?? Data(), runtime: mockRuntime) ?? []

        // test
        launchRulesEngine.replaceRules(with: rulesArray)

        // verify
        XCTAssertTrue(launchRulesEngine.replaceRulesCalled)
        XCTAssertEqual(1, launchRulesEngine.paramReplaceRulesRules?.count)
   }

    func testLoadRulesClearExisting() throws {
        // setup
        let decoder = JSONDecoder()
        let propString: String = JSONFileLoader.getRulesStringFromFile("showOnceRule")
        let propositions = try decoder.decode([PropositionPayload].self, from: propString.data(using: .utf8)!)
        let ruleString = propositions.first?.items.first?.propositionData?["content"] as? String
        let rulesArray = JSONRulesParser.parse(ruleString?.data(using: .utf8) ?? Data(), runtime: mockRuntime) ?? []

        // test
        launchRulesEngine.replaceRules(with: rulesArray)

        // verify
        XCTAssertTrue(launchRulesEngine.replaceRulesCalled)
        XCTAssertEqual(1, launchRulesEngine.paramReplaceRulesRules?.count)
   }

    func testLoadRulesEmptyStringContent() throws {
        // setup
        let decoder = JSONDecoder()
        let propString: String = JSONFileLoader.getRulesStringFromFile("emptyContentStringRule")
        let propositions = try decoder.decode([PropositionPayload].self, from: propString.data(using: .utf8)!)
        let ruleString = propositions.first?.items.first?.propositionData?["content"] as? String
        let rulesArray = JSONRulesParser.parse(ruleString?.data(using: .utf8) ?? Data(), runtime: mockRuntime) ?? []

        // test
        launchRulesEngine.replaceRules(with: rulesArray)

        // verify
        XCTAssertFalse(launchRulesEngine.addRulesCalled)
    }

    func testLoadRulesMalformedContent() throws {
        // setup
        let decoder = JSONDecoder()
        let propString: String = JSONFileLoader.getRulesStringFromFile("malformedContentRule")
        let propositions = try decoder.decode([PropositionPayload].self, from: propString.data(using: .utf8)!)
        let ruleString = propositions.first?.items.first?.propositionData?["content"] as? String
        let rulesArray = JSONRulesParser.parse(ruleString?.data(using: .utf8) ?? Data(), runtime: mockRuntime) ?? []

        // test
        launchRulesEngine.replaceRules(with: rulesArray)

        // verify
        XCTAssertFalse(launchRulesEngine.addRulesCalled)
    }

    func testLoadRulesEventSequence() throws {
        // setup
        let decoder = JSONDecoder()
        let propString: String = JSONFileLoader.getRulesStringFromFile("eventSequenceRule")
        let propositions = try decoder.decode([PropositionPayload].self, from: propString.data(using: .utf8)!)
        let ruleString = propositions.first?.items.first?.propositionData?["content"] as? String
        let rulesArray = JSONRulesParser.parse(ruleString?.data(using: .utf8) ?? Data(), runtime: mockRuntime) ?? []


        // test
        launchRulesEngine.replaceRules(with: rulesArray)

        // verify
        XCTAssertTrue(launchRulesEngine.replaceRulesCalled)
        XCTAssertEqual(1, launchRulesEngine.paramReplaceRulesRules?.count)
    }
}
