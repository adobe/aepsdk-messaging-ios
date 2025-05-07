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

final class LiveActivityUpdateTokenStore: PersistedMapStoreBase<LiveActivity.UpdateTokenMap> {
    init() {
        super.init(storeKey: MessagingConstants.NamedCollectionKeys.LIVE_ACTIVITY_UPDATE_TOKENS)
    }

    /// Retrieves the token associated with a specific Live Activity attribute and ID.
    ///
    /// - Parameters:
    ///   - attribute: The Live Activity attribute type associated with the token.
    ///   - id: The Live Activity ID associated with the token.
    /// - Returns: The associated ``LiveActivity.Token`` if one exists; otherwise, `nil`.
    func token(for attribute: LiveActivity.AttributeTypeName, id: LiveActivity.ID) -> LiveActivity.Token? {
        _persistedMap.tokens[attribute]?[id]
    }

    /// Sets or updates the token for the specified Live Activity attribute and Live Activity ID.
    ///
    /// If the given `token` is new or different from the existing one for the specified
    /// `attribute` and `id`, it is stored in the token map and the change is persisted.
    /// If the token is unchanged, no persistence occurs.
    ///
    /// - Parameters:
    ///   - token: The ``LiveActivity.Token`` to store.
    ///   - attribute: The Live Activity attribute type associated with the token.
    ///   - id: The Live Activity ID associated with the token.
    /// - Returns: `true` if the token was new or different and was stored; `false` if the token was unchanged.
    @discardableResult
    func set(
        _ token: LiveActivity.Token,
        attribute: LiveActivity.AttributeTypeName,
        id: LiveActivity.ID
    ) -> Bool {
        var workingMap = _persistedMap
        var attributeTokens = workingMap.tokens[attribute, default: [:]]
        let previousToken = attributeTokens.updateValue(token, forKey: id)
        let didChange = previousToken != token
        if didChange {
            workingMap.tokens[attribute] = attributeTokens
            _persistedMap = workingMap
        }
        return didChange
    }

    /// Removes the token associated with the given attribute and Live Activity ID, if it exists.
    ///
    /// If a token exists for the specified `attribute` and `id`, it is removed. If the resulting
    /// token map for the attribute becomes empty, the entire attribute entry is removed from the map.
    ///
    /// - Parameters:
    ///   - attribute: The Live Activity attribute type associated with the token.
    ///   - id: The Live Activity ID associated with the token.
    /// - Returns: `true` if a token was found and removed; `false` if no such token existed.
    @discardableResult
    func remove(attribute: LiveActivity.AttributeTypeName, id: LiveActivity.ID) -> Bool {
        var workingMap = _persistedMap
        guard var attributeTokens = workingMap.tokens[attribute],
              attributeTokens.removeValue(forKey: id) != nil
        else {
            return false
        }
        // Cleans up the map by removing the attribute key if no tokens exist for it.
        if attributeTokens.isEmpty {
            workingMap.tokens.removeValue(forKey: attribute)
        } else {
            workingMap.tokens[attribute] = attributeTokens
        }
        _persistedMap = workingMap
        return true
    }
}
