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
    func evaluate(event: Event) -> [String: Feed]? {
        let consequences = launchRulesEngine.evaluate(event: event)
        guard let consequences = consequences else {
            return nil
        }

        var feeds: [String: Feed] = [:]
        for consequence in consequences {
            let details = consequence.details as [String: Any]

            if let mobileParams = details[MessagingConstants.Event.Data.Key.FEED.MOBILE_PARAMETERS] as? [String: Any],
               let feedItem = FeedItem.from(data: mobileParams, id: consequence.id) {
                let surfacePath = feedItem.surface ?? ""

                // find the feed to insert the feed item else create a new feed for it
                if let feed = feeds[surfacePath] {
                    feed.items.append(feedItem)
                } else {
                    feeds[surfacePath] = Feed(surfaceUri: surfacePath, items: [feedItem])
                }
            }
        }
        return feeds
    }
}
