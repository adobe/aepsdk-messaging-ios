/*
 Copyright 2025 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
*/

import AEPServices

final class LiveActivityUpdateTokenStore {

    init() {
        load()
    }

    /// Returns the token for the given attribute and live activity ID.
    func token(for attribute: LiveActivity.AttributeTypeName,
               id: LiveActivity.ID) -> LiveActivity.Token? {
        cache.tokens[attribute]?[id]
    }

    /// Sets the token for the given attribute and live activity ID, and persists if changed.
    ///
    /// - Returns: `true` if the token was new or different and was updated, `false` if unchanged.
    @discardableResult
    func set(_ token: LiveActivity.Token,
             attribute: LiveActivity.AttributeTypeName,
             id: LiveActivity.ID) -> Bool {
        var didChange = false

        // Safely get or create inner dictionary
        var inner = cache.tokens[attribute, default: [:]]
        let previous = inner.updateValue(token, forKey: id)
        if previous != token {
            cache.tokens[attribute] = inner
            persist()
            didChange = true
        }

        return didChange
    }

    /// Removes the token at the given attribute + activity ID, if it exists.
    ///
    /// - Returns: `true` if a value was removed, `false` if not found.
    @discardableResult
    func remove(attribute: LiveActivity.AttributeTypeName,
                id: LiveActivity.ID) -> Bool {
        guard var inner = cache.tokens[attribute] else { return false }
        let removed = inner.removeValue(forKey: id)
        if removed != nil {
            if inner.isEmpty {
                cache.tokens.removeValue(forKey: attribute)
            } else {
                cache.tokens[attribute] = inner
            }
            persist()
            return true
        }
        return false
    }

    /// Returns the entire update token map.
    func all() -> LiveActivity.UpdateTokenMap {
        cache
    }

    // MARK: - Private helpers

    private var cache = LiveActivity.UpdateTokenMap(tokens: [:])

    private func load() {
        if let map = Self.readFromDisk() {
            cache = map
        }
    }

    private func persist() {
        if let dict = cache.asDictionary() {
            ServiceProvider.shared.namedKeyValueService.set(
                collectionName: MessagingConstants.DATA_STORE_NAME,
                key: MessagingConstants.NamedCollectionKeys
                    .LIVE_ACTIVITY_UPDATE_TOKENS,
                value: dict)
        }
    }

    private static func readFromDisk() -> LiveActivity.UpdateTokenMap? {
        guard let dict = ServiceProvider.shared.namedKeyValueService.get(
                collectionName: MessagingConstants.DATA_STORE_NAME,
                key: MessagingConstants.NamedCollectionKeys
                    .LIVE_ACTIVITY_UPDATE_TOKENS) as? [String: Any]
        else {
            return nil
        }

        return LiveActivity.UpdateTokenMap.from(dict)
    }
}
