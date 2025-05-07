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

final class PushToStartTokenStore: TokenStoreBase<LiveActivity.PushToStartTokenMap> {
    init() {
        super.init(storeKey: MessagingConstants.NamedCollectionKeys.LIVE_ACTIVITY_PUSH_TO_START_TOKENS)
    }

    /// Retrieves the token associated with a specific Live Activity attribute.
    ///
    /// - Parameters:
    ///   - attribute: The Live Activity attribute type associated with the token.
    /// - Returns: The associated ``LiveActivity.Token`` if one exists; otherwise, `nil`.
    func token(for attribute: LiveActivity.AttributeTypeName) -> LiveActivity.Token? {
        _persistedMap.tokens[attribute]
    }

    /// Sets or updates the token for the specified Live Activity attribute.
    ///
    /// If the given `token` is new or different from the existing one for the specified
    /// `attribute`, it is stored in the token map and the change is persisted.
    /// If the token is unchanged, no persistence occurs.
    ///
    /// - Parameters:
    ///   - token: The ``LiveActivity.Token`` to store.
    ///   - attribute: The Live Activity attribute type associated with the token.
    /// - Returns: `true` if the token was new or different and was stored; `false` if the token was unchanged.
    @discardableResult
    func set(_ token: LiveActivity.Token, attribute: LiveActivity.AttributeTypeName) -> Bool {
        var workingMap = _persistedMap
        let previousToken = workingMap.tokens.updateValue(token, forKey: attribute)
        let didChange = previousToken != token
        if didChange {
            _persistedMap = workingMap
        }
        return didChange
    }

    /// Removes the token associated with the given attribute, if it exists.
    ///
    /// - Parameters:
    ///   - attribute: The Live Activity attribute type associated with the token.
    /// - Returns: `true` if a token was found and removed; `false` if no such token existed.
    @discardableResult
    func remove(attribute: LiveActivity.AttributeTypeName) -> Bool {
        var workingMap = _persistedMap
        let wasRemoved = workingMap.tokens.removeValue(forKey: attribute) != nil
        if wasRemoved {
            _persistedMap = workingMap
        }
        return wasRemoved
    }
}
