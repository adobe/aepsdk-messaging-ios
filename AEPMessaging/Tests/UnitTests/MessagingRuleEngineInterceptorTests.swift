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
import AEPServices
import AEPTestUtils
import XCTest

class MessagingRuleEngineInterceptorTests: XCTestCase {
    
    var interceptor: MessagingRuleEngineInterceptor!
    var mockRuntime: TestableExtensionRuntime!
    var mockLaunchRulesEngine: MockLaunchRulesEngine!
    var mockMessagingRulesEngine: MockMessagingRulesEngine!
    var mockContentCardRulesEngine: MockContentCardRulesEngine!
    var mockCache: MockCache!
    var messaging: Messaging!
    
    override func setUp() {
        super.setUp()
        EventHub.shared.start()
        RefreshInAppHandler.shared.reset()
        interceptor = MessagingRuleEngineInterceptor()
        mockRuntime = TestableExtensionRuntime()
        mockCache = MockCache(name: "mockCache")
        mockLaunchRulesEngine = MockLaunchRulesEngine(name: "mockLaunchRulesEngine", extensionRuntime: mockRuntime)
        mockMessagingRulesEngine = MockMessagingRulesEngine(extensionRuntime: mockRuntime, launchRulesEngine: mockLaunchRulesEngine, cache: mockCache)
        mockContentCardRulesEngine = MockContentCardRulesEngine(extensionRuntime: mockRuntime, launchRulesEngine: mockLaunchRulesEngine)
    }
    
    override func tearDown() {
        RefreshInAppHandler.shared.reset()
        interceptor = nil
        mockRuntime = nil
        mockLaunchRulesEngine = nil
        mockMessagingRulesEngine = nil
        mockContentCardRulesEngine = nil
        mockCache = nil
        messaging = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    func createTestEvent(name: String = "Test Event") -> Event {
        return Event(name: name, type: EventType.genericTrack, source: EventSource.requestContent, data: nil)
    }
    
    func createTestRule() -> LaunchRule {
        let consequence = RuleConsequence(id: "testConsequence", type: "schema", details: [:])
        let condition = ComparisonExpression(lhs: "true", operationName: "equals", rhs: "true")
        return LaunchRule(condition: condition, consequences: [consequence])
    }
    
    // MARK: - Messaging Extension Interceptor Registration Tests
    
    func testMessagingInit_registersReevaluationInterceptor() {
        // Setup & Test
        let messagingProperties = MessagingProperties()
        messaging = Messaging(runtime: mockRuntime,
                             rulesEngine: mockMessagingRulesEngine,
                             contentCardRulesEngine: mockContentCardRulesEngine,
                             expectedSurfaceUri: "mobileapp://test",
                             cache: mockCache,
                             messagingProperties: messagingProperties)
        
        // Verify - the interceptor should be set on the launch rules engine
        XCTAssertTrue(mockLaunchRulesEngine.setReevaluationInterceptorCalled,
                      "setReevaluationInterceptor should be called during Messaging initialization")
        XCTAssertNotNil(mockLaunchRulesEngine.paramReevaluationInterceptor,
                        "Reevaluation interceptor should not be nil")
    }
    
    func testMessagingInit_interceptorIsCorrectType() {
        // Setup & Test
        let messagingProperties = MessagingProperties()
        messaging = Messaging(runtime: mockRuntime,
                             rulesEngine: mockMessagingRulesEngine,
                             contentCardRulesEngine: mockContentCardRulesEngine,
                             expectedSurfaceUri: "mobileapp://test",
                             cache: mockCache,
                             messagingProperties: messagingProperties)
        
        // Verify
        guard let interceptor = mockLaunchRulesEngine.paramReevaluationInterceptor else {
            XCTFail("Interceptor should be set")
            return
        }
        
        XCTAssertTrue(interceptor is MessagingRuleEngineInterceptor,
                      "Registered interceptor should be MessagingRuleEngineInterceptor")
    }
    
    func testInterceptorConformsToRuleReevaluationInterceptor() {
        // Verify the interceptor conforms to the protocol
        XCTAssertTrue(interceptor is RuleReevaluationInterceptor,
                      "MessagingRuleEngineInterceptor should conform to RuleReevaluationInterceptor")
    }
    
    // MARK: - Single Request Tests
    
    func testOnReevaluationTriggered_singleRequest_completionCalledOnSuccess() {
        // Setup
        let completionExpectation = expectation(description: "Completion should be called")
        var refreshCallCount = 0
        
        interceptor.refreshPropositions = { completion in
            refreshCallCount += 1
            // Simulate successful refresh
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                completion(true)
            }
        }
        
        let event = createTestEvent()
        let rule = createTestRule()
        
        // Test
        interceptor.onReevaluationTriggered(event: event, reevaluableRules: [rule]) {
            completionExpectation.fulfill()
        }
        
        // Verify
        wait(for: [completionExpectation], timeout: 2.0)
        XCTAssertEqual(refreshCallCount, 1, "Refresh should be called exactly once")
    }
    
    func testOnReevaluationTriggered_singleRequest_completionNotCalledOnFailure() {
        // Setup
        let completionExpectation = expectation(description: "Completion should not be called")
        completionExpectation.isInverted = true
        var refreshCallCount = 0
        
        interceptor.refreshPropositions = { completion in
            refreshCallCount += 1
            // Simulate failed refresh
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                completion(false)
            }
        }
        
        let event = createTestEvent()
        let rule = createTestRule()
        
        // Test
        interceptor.onReevaluationTriggered(event: event, reevaluableRules: [rule]) {
            completionExpectation.fulfill()
        }
        
        // Verify
        wait(for: [completionExpectation], timeout: 1.0)
        XCTAssertEqual(refreshCallCount, 1, "Refresh should be called exactly once")
    }
    
    // MARK: - Queueing Behavior Tests
    
    func testOnReevaluationTriggered_multipleRequests_queuesCompletions() {
        // Setup
        let completion1Expectation = expectation(description: "Completion 1 should be called")
        let completion2Expectation = expectation(description: "Completion 2 should be called")
        let completion3Expectation = expectation(description: "Completion 3 should be called")
        
        var refreshCallCount = 0
        var storedCompletion: ((Bool) -> Void)?
        
        interceptor.refreshPropositions = { completion in
            refreshCallCount += 1
            storedCompletion = completion
        }
        
        let event1 = createTestEvent(name: "Event 1")
        let event2 = createTestEvent(name: "Event 2")
        let event3 = createTestEvent(name: "Event 3")
        let rule = createTestRule()
        
        // Test - trigger multiple requests quickly
        interceptor.onReevaluationTriggered(event: event1, reevaluableRules: [rule]) {
            completion1Expectation.fulfill()
        }
        
        // Allow first request to start
        Thread.sleep(forTimeInterval: 0.05)
        
        interceptor.onReevaluationTriggered(event: event2, reevaluableRules: [rule]) {
            completion2Expectation.fulfill()
        }
        
        interceptor.onReevaluationTriggered(event: event3, reevaluableRules: [rule]) {
            completion3Expectation.fulfill()
        }
        
        // Wait a bit for all requests to be queued
        Thread.sleep(forTimeInterval: 0.1)
        
        // Complete the refresh
        storedCompletion?(true)
        
        // Verify
        wait(for: [completion1Expectation, completion2Expectation, completion3Expectation], timeout: 2.0)
        XCTAssertEqual(refreshCallCount, 1, "Refresh should be called only once even with multiple requests")
    }
    
    func testOnReevaluationTriggered_multipleRequests_noCompletionsOnFailure() {
        // Setup
        let completion1Expectation = expectation(description: "Completion 1 should not be called")
        completion1Expectation.isInverted = true
        let completion2Expectation = expectation(description: "Completion 2 should not be called")
        completion2Expectation.isInverted = true
        
        var storedCompletion: ((Bool) -> Void)?
        
        interceptor.refreshPropositions = { completion in
            storedCompletion = completion
        }
        
        let event1 = createTestEvent(name: "Event 1")
        let event2 = createTestEvent(name: "Event 2")
        let rule = createTestRule()
        
        // Test
        interceptor.onReevaluationTriggered(event: event1, reevaluableRules: [rule]) {
            completion1Expectation.fulfill()
        }
        
        Thread.sleep(forTimeInterval: 0.05)
        
        interceptor.onReevaluationTriggered(event: event2, reevaluableRules: [rule]) {
            completion2Expectation.fulfill()
        }
        
        Thread.sleep(forTimeInterval: 0.1)
        
        // Fail the refresh
        storedCompletion?(false)
        
        // Verify - neither completion should be called
        wait(for: [completion1Expectation, completion2Expectation], timeout: 1.0)
    }
    
    // MARK: - Sequential Request Tests
    
    func testOnReevaluationTriggered_sequentialRequests_eachTriggersRefresh() {
        // Setup
        let completion1Expectation = expectation(description: "Completion 1 should be called")
        let completion2Expectation = expectation(description: "Completion 2 should be called")
        
        var refreshCallCount = 0
        
        interceptor.refreshPropositions = { completion in
            refreshCallCount += 1
            // Complete immediately
            DispatchQueue.global().async {
                completion(true)
            }
        }
        
        let event1 = createTestEvent(name: "Event 1")
        let event2 = createTestEvent(name: "Event 2")
        let rule = createTestRule()
        
        // Test - trigger first request and wait for completion
        interceptor.onReevaluationTriggered(event: event1, reevaluableRules: [rule]) {
            completion1Expectation.fulfill()
        }
        
        wait(for: [completion1Expectation], timeout: 2.0)
        
        // Trigger second request after first completes
        interceptor.onReevaluationTriggered(event: event2, reevaluableRules: [rule]) {
            completion2Expectation.fulfill()
        }
        
        wait(for: [completion2Expectation], timeout: 2.0)
        
        // Verify - each sequential request should trigger its own refresh
        XCTAssertEqual(refreshCallCount, 2, "Sequential requests should each trigger refresh")
    }
    
    // MARK: - Empty Rules Tests
    
    func testOnReevaluationTriggered_emptyRules_stillTriggersRefresh() {
        // Setup
        let completionExpectation = expectation(description: "Completion should be called")
        var refreshCallCount = 0
        
        interceptor.refreshPropositions = { completion in
            refreshCallCount += 1
            DispatchQueue.global().async {
                completion(true)
            }
        }
        
        let event = createTestEvent()
        
        // Test - trigger with empty rules
        interceptor.onReevaluationTriggered(event: event, reevaluableRules: []) {
            completionExpectation.fulfill()
        }
        
        // Verify
        wait(for: [completionExpectation], timeout: 2.0)
        XCTAssertEqual(refreshCallCount, 1, "Empty rules should still trigger refresh")
    }
    
    // MARK: - Thread Safety Tests
    
    func testOnReevaluationTriggered_concurrentCalls_handledSafely() {
        // Setup
        let concurrentQueue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
        let completionGroup = DispatchGroup()
        var completionCount = 0
        let countLock = NSLock()
        let numberOfRequests = 10
        
        var storedCompletion: ((Bool) -> Void)?
        var refreshCallCount = 0
        let refreshLock = NSLock()
        
        interceptor.refreshPropositions = { completion in
            refreshLock.lock()
            refreshCallCount += 1
            if storedCompletion == nil {
                storedCompletion = completion
            }
            refreshLock.unlock()
        }
        
        let rule = createTestRule()
        
        // Test - trigger many concurrent requests
        for i in 0..<numberOfRequests {
            completionGroup.enter()
            concurrentQueue.async {
                let event = self.createTestEvent(name: "Event \(i)")
                self.interceptor.onReevaluationTriggered(event: event, reevaluableRules: [rule]) {
                    countLock.lock()
                    completionCount += 1
                    countLock.unlock()
                    completionGroup.leave()
                }
            }
        }
        
        // Wait for all requests to be submitted
        Thread.sleep(forTimeInterval: 0.2)
        
        // Complete the refresh
        storedCompletion?(true)
        
        // Verify
        let result = completionGroup.wait(timeout: .now() + 5.0)
        XCTAssertEqual(result, .success, "All completions should be called")
        XCTAssertEqual(completionCount, numberOfRequests, "All \(numberOfRequests) completions should be called")
        XCTAssertEqual(refreshCallCount, 1, "Only one refresh should be triggered for concurrent requests")
    }
}
