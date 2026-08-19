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

    var contentCardPropositions: [Surface: [Proposition]]? {
        guard let cachedPropositions = get(key: MessagingConstants.Caches.CONTENT_CARD_PROPOSITIONS) else {
            Log.trace(label: MessagingConstants.LOG_TAG, "Unable to load cached content card propositions, cache file not found.")
            return nil
        }
        let decoder = JSONDecoder()
        guard let propositionsDict: [String: [Proposition]] = try? decoder.decode([String: [Proposition]].self, from: cachedPropositions.data) else {
            Log.debug(label: MessagingConstants.LOG_TAG, "No content card proposition definitions found in cache.")
            return nil
        }
        var retrievedPropositions: [Surface: [Proposition]] = [:]
        for (key, value) in propositionsDict {
            retrievedPropositions[Surface(uri: key)] = value
        }
        return retrievedPropositions
    }

    // MARK: setters

    func updatePropositions(_ newPropositions: [Surface: [Proposition]]?, removing surfaces: [Surface]? = nil) {
        updatePropositionsByKey(MessagingConstants.Caches.PROPOSITIONS,
                                existing: propositions,
                                new: newPropositions,
                                removing: surfaces,
                                cacheCreatedMessage: "In-app messaging cache has been created.",
                                encodeErrorMessage: "Error creating in-app messaging cache, unable to encode proposition.",
                                writeErrorPrefix: "Error creating in-app messaging cache")
    }

    func updateContentCardPropositions(_ newPropositions: [Surface: [Proposition]]?, removing surfaces: [Surface]? = nil) {
        updatePropositionsByKey(MessagingConstants.Caches.CONTENT_CARD_PROPOSITIONS,
                                existing: contentCardPropositions,
                                new: newPropositions,
                                removing: surfaces,
                                cacheCreatedMessage: "Content card messaging cache has been created.",
                                encodeErrorMessage: "Error creating content card messaging cache, unable to encode proposition.",
                                writeErrorPrefix: "Error creating content card messaging cache")
    }

    // MARK: - Private helpers

    private func updatePropositionsByKey(
        _ key: String,
        existing: [Surface: [Proposition]]?,
        new newPropositions: [Surface: [Proposition]]?,
        removing surfaces: [Surface]?,
        cacheCreatedMessage: String,
        encodeErrorMessage: String,
        writeErrorPrefix: String
    ) {
        let existingPropositions = existing ?? [:]
        var updatedPropositions = existingPropositions.merging(newPropositions ?? [:]) { _, new in new }
        if let surfaces = surfaces {
            updatedPropositions = updatedPropositions.filter {
                !surfaces.contains($0.key)
            }
        }

        guard !updatedPropositions.isEmpty else {
            // Only remove if there was data in cache that needs to be cleared.
            // Avoids spurious remove calls when no existing entry exists and nothing was added.
            if !existingPropositions.isEmpty {
                try? remove(key: key)
            }
            return
        }

        var propositionsToCache: [String: [Proposition]] = [:]
        for (surface, value) in updatedPropositions {
            propositionsToCache[surface.uri] = value
        }

        let encoder = JSONEncoder()
        guard let cacheData = try? encoder.encode(propositionsToCache) else {
            Log.warning(label: MessagingConstants.LOG_TAG, encodeErrorMessage)
            return
        }
        let cacheEntry = CacheEntry(data: cacheData, expiry: .never, metadata: nil)
        do {
            try set(key: key, entry: cacheEntry)
            Log.trace(label: MessagingConstants.LOG_TAG, cacheCreatedMessage)
        } catch {
            Log.warning(label: MessagingConstants.LOG_TAG, "\(writeErrorPrefix): \(error).")
        }
    }
}
