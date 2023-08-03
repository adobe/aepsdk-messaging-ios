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

extension MessagingState {
    func retrieveCachedPropositions() -> [Surface: [Proposition]]? {
        guard let cachedPropositions = cache.get(key: MessagingConstants.Caches.PROPOSITIONS) else {
            Log.trace(label: MessagingConstants.LOG_TAG, "Unable to load cached messages, cache file not found.")
            return nil
        }

        let decoder = JSONDecoder()
        guard let propositionsDict: [String: [Proposition]] = try? decoder.decode([String: [Proposition]].self, from: cachedPropositions.data) else {
            Log.debug(label: MessagingConstants.LOG_TAG, "No message definitions found in cache.")
            return nil
        }

        var retrievedPropositions: [Surface: [Proposition]] = [:]
        for (key, value) in propositionsDict {
            retrievedPropositions[Surface(uri: key)] = value
        }
        return retrievedPropositions
    }

    func removeCachedPropositions(surfaces: [Surface]) {
        guard var propositionsDict = retrieveCachedPropositions(), !propositionsDict.isEmpty else {
            return
        }

        for surface in surfaces {
            propositionsDict.removeValue(forKey: surface)
        }

        cachePropositions(propositionsDict)
    }

    func cachePropositions(_ propositionsDict: [Surface: [Proposition]]) {
        var cachePropositions: [String: [Proposition]] = [:]
        for (key, value) in propositionsDict {
            cachePropositions[key.uri] = value
        }

        let encoder = JSONEncoder()
        guard let cacheData = try? encoder.encode(cachePropositions) else {
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
