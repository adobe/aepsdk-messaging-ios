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
@testable import AEPCore

class MockLaunchRulesEngine: LaunchRulesEngine {
    override init(name: String, extensionRuntime: ExtensionRuntime) {
        super.init(name: name, extensionRuntime: extensionRuntime)
    }
    
    var processCalled: Bool = false
    var paramProcessedEvent: Event? = nil
    override func process(event: Event) -> Event {
        processCalled = true
        paramProcessedEvent = event
        return event
    }
    
    var replaceRulesCalled: Bool = false
    var paramRules: [LaunchRule]? = nil
    override func replaceRules(with rules: [LaunchRule]) {
        replaceRulesCalled = true
        paramRules = rules
        
    }
}
