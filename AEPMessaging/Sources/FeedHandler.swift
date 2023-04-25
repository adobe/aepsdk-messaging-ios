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

class FeedHandler: EdgeResponseHandler {
    let propositionsDict: [String: PropositionPayload]
    let rulesDict: [String: [LaunchRule]]
    let requestedSurfaces: [String]
    weak var parent: Messaging?

    var shouldProcessRules: Bool {
        true
    }

    required init(propositionsDict: [String: PropositionPayload], rulesDict: [String: [LaunchRule]], requestedSurfaces: [String], parent: Messaging) {
        self.propositionsDict = propositionsDict
        self.rulesDict = rulesDict
        self.requestedSurfaces = requestedSurfaces
        self.parent = parent
    }

    func loadRules(clearExisting: Bool, persistChanges _: Bool = true) {
        let rules = rulesDict.reduce(into: [LaunchRule]()) { $0.append(contentsOf: $1.value) }
        if rules.isEmpty,
           clearExisting {
            parent?.inMemoryFeeds.removeAll()
            parent?.feedsInfo.removeAll()
        } else {
            let newFeedsInfo = propositionsDict.mapValues { value in
                value.propositionInfo
            }
            if clearExisting {
                parent?.inMemoryFeeds.removeAll()
                parent?.feedsInfo = newFeedsInfo
            } else {
                parent?.feedsInfo.merge(newFeedsInfo) { _, new in new }
            }
        }
        parent?.feedRulesEngine.launchRulesEngine.loadRules(rules, clearExisting: clearExisting)
    }

    func processRules(event: Event, _ completion: (([String: Feed]?) -> Void)? = nil) {
        parent?.feedRulesEngine.process(event: event) { feedsDict in
            let feedsDict = feedsDict ?? [:]
            self.parent?.mergeFeedsInMemory(feedsDict, requestedSurfaces: self.requestedSurfaces)

            var requestedFeedsDict: [String: Feed] = [:]
            for (key, value) in feedsDict {
                let appSurface = self.parent?.appSurface ?? "unknown"
                if key.hasPrefix(appSurface) {
                    requestedFeedsDict[String(key.dropFirst(appSurface.count + 1))] = value
                } else {
                    requestedFeedsDict[key] = value
                }
            }
            completion?(requestedFeedsDict)
        }
    }
}
