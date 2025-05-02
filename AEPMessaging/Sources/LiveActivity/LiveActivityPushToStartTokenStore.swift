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

final class LiveActivityPushToStartTokenStore {

    init() {
        load()
    }

    /// Returns the token for the given attribute type, if it exists.
    func token(for attribute: LiveActivity.AttributeTypeName) -> LiveActivity.Token? {
        cache.tokens[attribute]
    }

    /// Sets the token for the given attribute type and persists if the value changed.
    ///
    /// - Parameters:
    ///   - token: The new `LiveActivityToken` to store.
    ///   - attribute: The `AttributeType` key under which to store the token.
    /// - Returns: `true` if the value was changed (new or updated), `false` if unchanged.
    @discardableResult
    func set(_ token: LiveActivity.Token,
             attribute: LiveActivity.AttributeTypeName) -> Bool {
        let previous = cache.tokens.updateValue(token, forKey: attribute)
        let didChange = previous != token
        if didChange {
            persist()
        }
        return didChange
    }

    /// Removes the token for the given attribute type.
    func remove(attribute: LiveActivity.AttributeTypeName) {
        cache.tokens.removeValue(forKey: attribute)
        persist()
    }

    /// Returns the full push-to-start token map.
    func all() -> LiveActivity.PushToStartTokenMap {
        cache
    }

    // MARK: - Private helpers

    private var cache = LiveActivity.PushToStartTokenMap(tokens: [:])

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
                    .LIVE_ACTIVITY_PUSH_TO_START_TOKENS,
                value: dict)
        }
    }

    private static func readFromDisk() -> LiveActivity.PushToStartTokenMap? {
        guard let dict = ServiceProvider.shared.namedKeyValueService.get(
                collectionName: MessagingConstants.DATA_STORE_NAME,
                key: MessagingConstants.NamedCollectionKeys
                    .LIVE_ACTIVITY_PUSH_TO_START_TOKENS) as? [String: Any]
        else {
            return nil
        }

        return LiveActivity.PushToStartTokenMap.from(dict)
    }
}
