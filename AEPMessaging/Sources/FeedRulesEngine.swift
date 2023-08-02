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

class FeedRulesEngine {
    let launchRulesEngine: LaunchRulesEngine
    let runtime: ExtensionRuntime

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

    /// if we have rules loaded, then we simply process the event.
    /// if rules are not yet loaded, add the event to the waitingEvents array to
    func evaluate(event: Event) -> [Surface: [Inbound]]? {
        let consequences = launchRulesEngine.evaluate(event: event)
        guard let consequences = consequences else {
            return nil
        }

        var inboundMessages: [Surface: [Inbound]] = [:]
        for consequence in consequences {
            let detail = consequence.details as [String: Any]

            guard let inboundMessage = Inbound.from(consequenceDetail: detail, id: consequence.id) else {
                continue
            }

            let surfaceUri = inboundMessage.meta?[MessagingConstants.Event.Data.Key.Feed.SURFACE] as? String ?? ""
            let surface = Surface(uri: surfaceUri)

            if inboundMessages[surface] != nil {
                inboundMessages[surface]?.append(inboundMessage)
            } else {
                inboundMessages[surface] = [inboundMessage]
            }
        }
        return inboundMessages
    }
}
