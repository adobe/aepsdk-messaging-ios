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

extension Messaging {
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
        let edgeResponseManager = EdgeResponseManager(propositions, requestedSurfaces: [expectedSurface], parent: self)
        if let handler = edgeResponseManager.generateResponseHandlers(for: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE).first {
            handler.loadRules(clearExisting: false, persistChanges: false)
        }
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
