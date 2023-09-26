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

extension Cache {
    // MARK: - getters

    var propositions: [Surface: [Proposition]]? {
        guard let cachedPropositions = get(key: MessagingConstants.Caches.PROPOSITIONS) else {
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

    // MARK: setters

    // update entries for surfaces already existing
    // remove surfaces listed by `surfaces`
    // write or remove cache file based on result
    func updatePropositions(_ newPropositions: [Surface: [Proposition]]?, removing surfaces: [Surface]? = nil) {
        var updatedPropositions = propositions?.merging(newPropositions ?? [:]) { _, new in new }
        if let surfaces = surfaces {
            updatedPropositions = updatedPropositions?.filter {
                !surfaces.contains($0.key)
            }
        }

        guard let propositions = updatedPropositions, !propositions.isEmpty else {
            try? remove(key: MessagingConstants.Caches.PROPOSITIONS)
            return
        }

        var propositionsToCache: [String: [Proposition]] = [:]
        for (key, value) in propositions {
            propositionsToCache[key.uri] = value
        }

        if propositionsToCache.isEmpty {
            Log.trace(label: MessagingConstants.LOG_TAG, "No new messages are available to update in-app messaging cache.")
            return
        }

        let encoder = JSONEncoder()
        guard let cacheData = try? encoder.encode(propositionsToCache) else {
            Log.warning(label: MessagingConstants.LOG_TAG, "Error creating in-app messaging cache, unable to encode proposition.")
            return
        }
        let cacheEntry = CacheEntry(data: cacheData, expiry: .never, metadata: nil)
        do {
            try set(key: MessagingConstants.Caches.PROPOSITIONS, entry: cacheEntry)
            Log.trace(label: MessagingConstants.LOG_TAG, "In-app messaging cache has been created.")
        } catch {
            Log.warning(label: MessagingConstants.LOG_TAG, "Error creating in-app messaging cache: \(error).")
        }
    }
}
