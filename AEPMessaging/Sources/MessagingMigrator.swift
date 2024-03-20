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

import AEPServices
import Foundation

enum MessagingMigrator {
    static func migrate(cache: Cache) {
        guard let cachedPropositions = cache.get(key: MessagingConstants.Caches.PROPOSITIONS) else {
            Log.trace(label: MessagingConstants.LOG_TAG, "Unable to load cached messages, cache file not found.")
            return
        }

        let decoder = JSONDecoder()
        guard let propositions: [PropositionPayload] = try? decoder.decode([PropositionPayload].self, from: cachedPropositions.data) else {
            Log.trace(label: MessagingConstants.LOG_TAG, "Unable to decode cached messages.")
            return
        }

        let mappedPropositions = propositions.map { $0.convertToProposition() }
        guard !mappedPropositions.isEmpty else {
            return
        }

        let encoder = JSONEncoder()
        guard let cacheData = try? encoder.encode(mappedPropositions.toDictionary { $0.scope }) else {
            Log.warning(label: MessagingConstants.LOG_TAG, "Error creating in-app messaging cache, unable to encode proposition.")
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
