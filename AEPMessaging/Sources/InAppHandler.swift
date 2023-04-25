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
import Foundation

class InAppHandler: EdgeResponseHandler {
    let propositionsDict: [String: PropositionPayload]
    let rulesDict: [String: [LaunchRule]]
    let requestedSurfaces: [String]
    weak var parent: Messaging?

    var shouldProcessRules: Bool {
        false
    }

    required init(propositionsDict: [String: PropositionPayload], rulesDict: [String: [LaunchRule]], requestedSurfaces: [String], parent: Messaging) {
        self.propositionsDict = propositionsDict
        self.rulesDict = rulesDict
        self.requestedSurfaces = requestedSurfaces
        self.parent = parent
    }

    func loadRules(clearExisting: Bool, persistChanges: Bool = true) {
        let rules = rulesDict.reduce(into: [LaunchRule]()) { $0.append(contentsOf: $1.value) }

        if rules.isEmpty {
            if clearExisting {
                parent?.inMemoryPropositions.removeAll()
                parent?.propositionInfo.removeAll()
                parent?.cachePropositions(shouldReset: true)
            }
        } else {
            // pre-fetch the assets for this message if there are any defined
            parent?.rulesEngine.cacheRemoteAssetsFor(rules)

            let newPropositionInfo = propositionsDict.mapValues { value in
                value.propositionInfo
            }
            if clearExisting {
                parent?.propositionInfo = newPropositionInfo
                parent?.inMemoryPropositions = Array(propositionsDict.values)
            } else {
                parent?.propositionInfo.merge(newPropositionInfo) { _, new in new }
                parent?.inMemoryPropositions.append(contentsOf: propositionsDict.values)
            }

            if persistChanges {
                parent?.cachePropositions()
            }
        }
        parent?.rulesEngine.launchRulesEngine.loadRules(rules, clearExisting: clearExisting)
    }

    func processRules(event _: Event, _ completion: (([String: Any]?) -> Void)? = nil) {
        completion?(nil)
        // no-op
    }
}
