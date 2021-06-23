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
@_implementationOnly import AEPRulesEngine
import AEPServices
import Foundation

class MessagingRulesEngine {

    let rulesEngine: LaunchRulesEngine

    init(name: String, extensionRuntime: ExtensionRuntime) {
        self.rulesEngine = LaunchRulesEngine(name: name,
                                             extensionRuntime: extensionRuntime)
    }

    /// if we have rules loaded, then we simply process the event.
    /// if rules are not yet loaded, add the event to the waitingEvents array to
    func process(event: Event) {
        _ = rulesEngine.process(event: event)
    }

    func loadRules(rules: [String]?) {
        guard let rules = rules else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Unable to load messages, array of rules was empty.")
            return
        }

        var messagingRules: [LaunchRule] = []
        for rule in rules {

            guard let processedRule = JSONRulesParser.parse(rule.data(using: .utf8) ?? Data()) else {
                continue
            }

            // TODO: handle remote assets caching (here or in UIServices?)

            messagingRules.append(contentsOf: processedRule)
        }

        rulesEngine.replaceRules(with: messagingRules)
        Log.debug(label: MessagingConstants.LOG_TAG, "Successfully loaded \(messagingRules.count) message(s) into the rules engine.")
    }
}
