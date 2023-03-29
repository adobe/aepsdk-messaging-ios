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

extension Messaging {
    func parsePropositions(_ propositions: [PropositionPayload]?, expectedSurfaces: [String], clearExisting: Bool, persistChanges: Bool = true) -> [LaunchRule] {
        var rules: [LaunchRule] = []
        var tempPropInfo: [String: PropositionInfo] = [:]
        var consequenceType: String = ""
        var feedsReset: Bool = false
        
        guard let propositions = propositions, !propositions.isEmpty else {
            if clearExisting {
                inMemoryFeeds.removeAll()
                inMemoryPropositions.removeAll()
                cachePropositions(shouldReset: true)
            }
            return rules
        }
        
        for proposition in propositions {
            guard expectedSurfaces.contains(proposition.propositionInfo.scope)  else {
                Log.debug(label: MessagingConstants.LOG_TAG, "Ignoring proposition where scope (\(proposition.propositionInfo.scope)) does not match one of the expected surfaces (\(expectedSurfaces)).")
                continue
            }

            guard let ruleString = proposition.items.first?.data.content, !ruleString.isEmpty else {
                Log.debug(label: MessagingConstants.LOG_TAG, "Skipping proposition with no in-app message content.")
                continue
            }
            
            guard let rule = rulesEngine.parseRule(ruleString) else {
                Log.debug(label: MessagingConstants.LOG_TAG, "Skipping proposition with malformed in-app message content.")
                continue
            }
            
            // pre-fetch the assets for this message if there are any defined
            rulesEngine.cacheRemoteAssetsFor(rule)
            
            // store reporting data for this payload
            if let messageId = rule.first?.consequences.first?.id {
                tempPropInfo[messageId] = proposition.propositionInfo
            }
            
            consequenceType = rule.first?.consequences.first?.type ?? ""
            if consequenceType == MessagingConstants.ConsequenceTypes.FEED_ITEM {
                // clear existing feeds as needed
                if clearExisting && !feedsReset {
                    inMemoryFeeds.removeAll()
                    feedsReset = true
                }
                updateFeeds(rule.first?.consequences.first?.details as? [String: Any], scope: proposition.propositionInfo.scope, scopeDetails: proposition.propositionInfo.scopeDetails)
            }

            rules.append(contentsOf: rule)
        }
        
        if consequenceType == MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE {
            updateAndCachePropositions(propositions, propInfo: tempPropInfo,clearExisting: clearExisting, persistChanges: persistChanges)
        }
        
        return rules
    }
    
    func updateFeeds(_ data: [String: Any]?, scope: String, scopeDetails: [String: Any]) {
        if let feedItem = FeedItem.from(data: data) {
            // set scope details for reporting purposes
            feedItem.scopeDetails = scopeDetails
            
            // find the feed to insert the feed item else create a new feed for it
            if let feed = inMemoryFeeds.first(where: { $0.surfaceUri == scope }) {
                feed.items.append(feedItem)
            } else {
                inMemoryFeeds.append(Feed(surfaceUri: scope, items: [feedItem]))
            }
        }
    }
    
    func updateAndCachePropositions(_ propositions: [PropositionPayload], propInfo: [String: PropositionInfo], clearExisting: Bool, persistChanges: Bool = true) {
        if clearExisting {
            propositionInfo = propInfo
            inMemoryPropositions = propositions
        } else {
            propositionInfo.merge(propInfo) { _, new in new }
            inMemoryPropositions.append(contentsOf: propositions)
        }
        
        if persistChanges {
            cachePropositions()
        }
    }
    
    /// Loads propositions from persistence into memory then hydrates the messaging rules engine
    func loadCachedPropositions(for expectedSurface: String) {
        guard let cachedPropositions = cache.get(key: MessagingConstants.Caches.PROPOSITIONS) else {
            Log.trace(label: MessagingConstants.LOG_TAG, "Unable to load cached messages - cache file not found.")
            return
        }

        let decoder = JSONDecoder()
        guard let propositions: [PropositionPayload] = try? decoder.decode([PropositionPayload].self, from: cachedPropositions.data) else {
            return
        }

        Log.trace(label: MessagingConstants.LOG_TAG, "Loading in-app message definition from cache.")
        var rules = parsePropositions(propositions, expectedSurfaces: [expectedSurface], clearExisting: false, persistChanges: false)
        rulesEngine.loadRules(rules, clearExisting: false)
    }

    func cachePropositions(shouldReset: Bool = false) {
        // remove cached propositions if shouldReset is true
        guard !shouldReset else {
            do {
                try cache.remove(key: MessagingConstants.Caches.PROPOSITIONS)
                Log.trace(label: MessagingConstants.LOG_TAG, "In-app messaging cache has been deleted.")
            } catch let error as NSError {
                Log.trace(label: MessagingConstants.LOG_TAG, "Unable to remove in-app messaging cache: \(error).")
            }

            return
        }

        let encoder = JSONEncoder()
        guard let cacheData = try? encoder.encode(inMemoryPropositions) else {
            Log.warning(label: MessagingConstants.LOG_TAG, "Error creating in-app messaging cache: unable to encode proposition.")
            return
        }
        let cacheEntry = CacheEntry(data: cacheData, expiry: .never, metadata: nil)
        do {
            try cache.set(key: MessagingConstants.Caches.PROPOSITIONS, entry: cacheEntry)
            Log.trace(label: MessagingConstants.LOG_TAG, "In-app messaging cache has been created.")
        } catch {
            Log.warning(label: MessagingConstants.LOG_TAG, "Error creating in-app messaging cache: \(error).")
        }
    }
}
