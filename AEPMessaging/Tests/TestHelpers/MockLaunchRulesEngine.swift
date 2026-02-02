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
import Foundation

class MockLaunchRulesEngine: LaunchRulesEngine {
    var ruleConsequences: [RuleConsequence] = []
    
    override init(name: String, extensionRuntime: ExtensionRuntime) {
        super.init(name: name, extensionRuntime: extensionRuntime)
    }

    var processCalled: Bool = false
    var paramProcessedEvent: Event?
    override func process(event: Event) -> Event {
        processCalled = true
        paramProcessedEvent = event
        return event
    }

    var evaluateCalled: Bool = false
    var paramEvaluateEvent: Event?
    override func evaluate(event: Event) -> [RuleConsequence]? {
        evaluateCalled = true
        paramEvaluateEvent = event
        return ruleConsequences
    }
        
    var replaceRulesCalled: Bool = false
    var paramReplaceRulesRules: [LaunchRule]?
    override func replaceRules(with rules: [LaunchRule]) {
        replaceRulesCalled = true
        paramReplaceRulesRules = rules
    }
    
    var addRulesCalled: Bool = false
    var paramAddRulesRules: [LaunchRule]?
    override func addRules(_ rules: [LaunchRule]) {
        addRulesCalled = true
        paramAddRulesRules = rules
    }
    
    var setReevaluationInterceptorCalled: Bool = false
    var paramReevaluationInterceptor: RuleReevaluationInterceptor?
    override func setReevaluationInterceptor(_ interceptor: RuleReevaluationInterceptor?) {
        setReevaluationInterceptorCalled = true
        paramReevaluationInterceptor = interceptor
    }
}
