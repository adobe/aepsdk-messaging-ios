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

import AEPCore
import AEPServices
import Foundation

extension LaunchRulesEngine {
    // MARK: - Parse and load rules

    func parseRule(_ rule: String, runtime: ExtensionRuntime) -> [LaunchRule]? {
        JSONRulesParser.parse(rule.data(using: .utf8) ?? Data(), runtime: runtime)
    }

    func loadRules(_ rules: [LaunchRule]) {
        replaceRules(with: rules)
        
//        if clearExisting {
//            replaceRules(with: rules)
//            Log.debug(label: MessagingConstants.LOG_TAG, "Successfully loaded \(rules.count) message(s) into the rules engine.")
//        } else {
//            if rules.isEmpty {
//                Log.debug(label: MessagingConstants.LOG_TAG, "Ignoring request to load message rules, the provided rules array is empty.")
//                return
//            }
//
//            addRules(rules)
//            Log.debug(label: MessagingConstants.LOG_TAG, "Successfully added \(rules.count) message(s) into the rules engine.")
//        }
    }
}
