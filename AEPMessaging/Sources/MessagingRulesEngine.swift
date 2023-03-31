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

import AEPCore
import AEPServices
import Foundation

/// Wrapper class around `LaunchRulesEngine` that provides a different implementation for loading rules
class MessagingRulesEngine {
    let rulesEngine: LaunchRulesEngine
    let runtime: ExtensionRuntime
    let cache: Cache

    /// Initialize this class, creating a new rules engine with the provided name and runtime
    init(name: String, extensionRuntime: ExtensionRuntime, cache: Cache) {
        runtime = extensionRuntime
        rulesEngine = LaunchRulesEngine(name: name, extensionRuntime: extensionRuntime)
        self.cache = cache
    }

    /// INTERNAL ONLY
    /// Initializer to provide a mock rules engine for testing
    init(extensionRuntime: ExtensionRuntime, rulesEngine: LaunchRulesEngine, cache: Cache) {
        runtime = extensionRuntime
        self.rulesEngine = rulesEngine
        self.cache = cache
    }

    /// if we have rules loaded, then we simply process the event.
    /// if rules are not yet loaded, add the event to the waitingEvents array to
    func process(event: Event) {
        _ = rulesEngine.process(event: event)
    }

    func parseRule(_ rule: String) -> [LaunchRule]? {
        JSONRulesParser.parse(rule.data(using: .utf8) ?? Data(), runtime: runtime)
    }

    func loadRules(_ rules: [LaunchRule], clearExisting: Bool) {
        if clearExisting {
            rulesEngine.replaceRules(with: rules)
            Log.debug(label: MessagingConstants.LOG_TAG, "Successfully loaded \(rules.count) message(s) into the rules engine.")
        } else {
            if rules.isEmpty {
                Log.debug(label: MessagingConstants.LOG_TAG, "Ignoring request to load in-app messages, the provided rules array is empty.")
                return
            }

            rulesEngine.addRules(rules)
            Log.debug(label: MessagingConstants.LOG_TAG, "Successfully added \(rules.count) message(s) into the rules engine.")
        }
    }
}
