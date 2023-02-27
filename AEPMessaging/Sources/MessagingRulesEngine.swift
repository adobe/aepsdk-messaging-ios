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
    private var propositionInfo: [String: PropositionInfo] = [:]

    /// Initialize this class, creating a new rules engine with the provided name and runtime
    init(name: String, extensionRuntime: ExtensionRuntime) {
        runtime = extensionRuntime
        rulesEngine = LaunchRulesEngine(name: name,
                                        extensionRuntime: extensionRuntime)
        cache = Cache(name: MessagingConstants.Caches.CACHE_NAME)
        loadCachedPropositions()
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

    func loadPropositions(_ propositions: [PropositionPayload]) {
        var rules: [LaunchRule] = []
        for proposition in propositions {
            guard let ruleString = proposition.items.first?.data.content else {
                Log.debug(label: MessagingConstants.LOG_TAG, "Skipping proposition with no in-app message content.")
                continue

            }

            guard let rule = processRule(ruleString) else {
                Log.debug(label: MessagingConstants.LOG_TAG, "Skipping proposition with malformed in-app message content.")
                continue
            }

            // pre-fetch the assets for this message if there are any defined
            cacheRemoteAssetsFor(rule)
            // store reporting data for this payload for later use
            storePropositionInfo(proposition, forMessageId: rule.first?.consequences.first?.id)

            rules.append(contentsOf: rule)
        }

        rulesEngine.replaceRules(with: rules)
        Log.debug(label: MessagingConstants.LOG_TAG, "Successfully loaded \(rules.count) message(s) into the rules engine.")
    }
    
    func clearPropositions() {
        propositionInfo.removeAll()
        clearPropositionsCache()
        rulesEngine.replaceRules(with: [])        
        Log.debug(label: MessagingConstants.LOG_TAG, "In-app messages cleared from Messaging rules engine and NSUserDefaults.")
    }

    func storePropositionInfo(_ proposition: PropositionPayload, forMessageId messageId: String?) {
        guard let messageId = messageId else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Unable to associate proposition information for in-app message. MessageId unavailable in rule consequence.")
            return
        }
        propositionInfo[messageId] = proposition.propositionInfo
    }

    func processRule(_ rule: String) -> [LaunchRule]? {
        return JSONRulesParser.parse(rule.data(using: .utf8) ?? Data(), runtime: runtime)
    }

    func propositionInfoForMessageId(_ messageId: String) -> PropositionInfo? {
        return propositionInfo[messageId]
    }
    
    func propositionInfoCount() -> Int {
        return propositionInfo.count
    }
}
