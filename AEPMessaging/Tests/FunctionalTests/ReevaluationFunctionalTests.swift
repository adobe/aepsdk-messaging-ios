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

@testable import AEPCore
@testable import AEPMessaging
@testable import AEPRulesEngine
@testable import AEPServices
import AEPTestUtils
import XCTest

class ReevaluationFunctionalTests: XCTestCase {
    
    var messaging: Messaging!
    var mockRuntime: TestableExtensionRuntime!
    
    override func setUp() {
        super.setUp()
        mockRuntime = TestableExtensionRuntime()
        mockRuntime.ignoreEvent(type: EventType.rulesEngine, source: EventSource.requestReset)
        messaging = Messaging(runtime: mockRuntime)
        messaging?.onRegistered()
    }
    
    override func tearDown() {
        messaging = nil
        mockRuntime = nil
        super.tearDown()
    }
    
    // MARK: - Reevaluation Interceptor Tests
    
    /// Verifies that MessagingRuleEngineInterceptor conforms to RuleReevaluationInterceptor protocol
    func testMessagingRuleEngineInterceptorConformsToProtocol() {
        // Setup
        let interceptor = MessagingRuleEngineInterceptor()
        
        // Verify - interceptor should conform to the protocol
        XCTAssertNotNil(interceptor as RuleReevaluationInterceptor,
                        "MessagingRuleEngineInterceptor should conform to RuleReevaluationInterceptor protocol")
    }
    
    /// Verifies that MessagingRuleEngineInterceptor can be instantiated
    func testMessagingRuleEngineInterceptorInstantiation() {
        // Setup & Test
        let interceptor = MessagingRuleEngineInterceptor()
        
        // Verify
        XCTAssertNotNil(interceptor, "MessagingRuleEngineInterceptor should be instantiable")
    }
    
    /// Verifies that Messaging extension initializes successfully with runtime
    func testMessagingInitializesSuccessfully() {
        // Verify - messaging should be initialized in setUp
        XCTAssertNotNil(messaging, "Messaging should initialize successfully with runtime")
    }
    
    /// Verifies that onReevaluationTriggered can be called without crashing
    func testOnReevaluationTriggeredDoesNotCrash() {
        // Setup
        RefreshInAppHandler.shared.reset()
        let interceptor = MessagingRuleEngineInterceptor()
        let event = Event(name: "Test Event", type: EventType.genericTrack, source: EventSource.requestContent, data: nil)
        
        // Create a rule consequence
        let consequence = RuleConsequence(id: "testConsequence", type: "schema", details: [:])
        
        // Create a simple condition using ComparisonExpression from AEPRulesEngine
        let condition = ComparisonExpression(lhs: "true", operationName: "equals", rhs: "true")
        let rule = LaunchRule(condition: condition, consequences: [consequence])
        
        let expectation = XCTestExpectation(description: "Completion should be called")
        
        // Test - this should not crash
        interceptor.onReevaluationTriggered(event: event, reevaluableRules: [rule]) { _ in
            expectation.fulfill()
        }
        
        // Simulate completion from the handler
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            RefreshInAppHandler.shared.handleRefreshComplete(success: true)
        }
        
        // Verify - completion should be called
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Verifies that onReevaluationTriggered handles empty rules array gracefully
    func testOnReevaluationTriggeredWithEmptyRules() {
        // Setup
        RefreshInAppHandler.shared.reset()
        let interceptor = MessagingRuleEngineInterceptor()
        let event = Event(name: "Test Event", type: EventType.genericTrack, source: EventSource.requestContent, data: nil)
        
        let expectation = XCTestExpectation(description: "Completion should be called")
        
        // Test - this should not crash even with empty rules
        interceptor.onReevaluationTriggered(event: event, reevaluableRules: []) { _ in
            expectation.fulfill()
        }
        
        // Simulate completion from the handler
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            RefreshInAppHandler.shared.handleRefreshComplete(success: true)
        }
        
        // Verify - completion should be called
        wait(for: [expectation], timeout: 1.0)
    }
}

