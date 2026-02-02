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
        interceptor = MessagingRuleEngineInterceptor()
        mockRuntime = TestableExtensionRuntime()
        mockCache = MockCache(name: "mockCache")
        mockLaunchRulesEngine = MockLaunchRulesEngine(name: "mockLaunchRulesEngine", extensionRuntime: mockRuntime)
        mockMessagingRulesEngine = MockMessagingRulesEngine(extensionRuntime: mockRuntime, launchRulesEngine: mockLaunchRulesEngine, cache: mockCache)
        mockContentCardRulesEngine = MockContentCardRulesEngine(extensionRuntime: mockRuntime, launchRulesEngine: mockLaunchRulesEngine)
    }
    
    override func tearDown() {
        interceptor = nil
        mockRuntime = nil
        mockLaunchRulesEngine = nil
        mockMessagingRulesEngine = nil
        mockContentCardRulesEngine = nil
        mockCache = nil
        messaging = nil
        super.tearDown()
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
}
