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
import AEPRulesEngine
import AEPServices
import Foundation

class ContentCardRulesEngine {
    let launchRulesEngine: LaunchRulesEngine
    let runtime: ExtensionRuntime
    private weak var parent: Messaging?

    /// Initialize this class, creating a new rules engine with the provided name and runtime
    init(name: String, extensionRuntime: ExtensionRuntime) {
        runtime = extensionRuntime
        launchRulesEngine = LaunchRulesEngine(name: name,
                                              extensionRuntime: extensionRuntime)
    }

    /// INTERNAL ONLY
    /// Initializer to provide a mock rules engine for testing
    init(extensionRuntime: ExtensionRuntime, launchRulesEngine: LaunchRulesEngine) {
        runtime = extensionRuntime
        self.launchRulesEngine = launchRulesEngine
    }
    
    func setParent(_ parent: Messaging?) {
        self.parent = parent
    }

    /// if we have rules loaded, then we simply process the event.
    func evaluate(event: Event) -> [Surface: [PropositionItem]]? {
        let consequences = launchRulesEngine.evaluate(event: event)
        guard let consequences = consequences else {
            return nil
        }

        var propositionItemsBySurface: [Surface: [PropositionItem]] = [:]
        for consequence in consequences {
            guard let propositionItem = PropositionItem.fromRuleConsequence(consequence),
                  let propositionAsContentCard = propositionItem.contentCardSchemaData
            else {
                continue
            }

            // surface is automatically added to the metadata for content cards
            let surfaceUri = propositionAsContentCard.meta?[MessagingConstants.Event.Data.Key.Feed.SURFACE] as? String ?? ""
            let surface = Surface(uri: surfaceUri)

            if propositionItemsBySurface[surface] != nil {
                propositionItemsBySurface[surface]?.append(propositionItem)
            } else {
                propositionItemsBySurface[surface] = [propositionItem]
            }
        }
        return propositionItemsBySurface
    }
}
