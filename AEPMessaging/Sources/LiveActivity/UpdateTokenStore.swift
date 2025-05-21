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

final class UpdateTokenStore: PersistenceStoreBase<LiveActivity.UpdateTokenMap> {
    init() {
        super.init(storeKey: MessagingConstants.NamedCollectionKeys.LIVE_ACTIVITY_UPDATE_TOKENS)
        // This always triggers a lazy load from persisted storage.
        // If any tokens are expired, they will be removed and the updated map will be written back.
        removeExpiredEntries()
    }

    /// Returns the current update token map after removing any expired tokens.
    ///
    /// - Returns: A ``UpdateTokenMap`` containing only non-expired update tokens.
    /// - SeeAlso: ``removeExpiredEntries()``
    override func all() -> LiveActivity.UpdateTokenMap {
        removeExpiredEntries()
        return _persistedMap
    }

    /// Retrieves the token associated with a specific Live Activity ID, if it exists and has not expired.
    ///
    /// If the associated entry is expired, it is opportunistically removed from the store.
    ///
    /// - Parameter id: The Live Activity ID associated with the token.
    /// - Returns: The associated ``LiveActivity.UpdateToken`` if it exists and is not expired; `nil` otherwise.
    func token(id: LiveActivity.ID) -> LiveActivity.UpdateToken? {
        guard let token = _persistedMap.tokens[id] else {
            return nil
        }
        guard !isExpired(token) else {
            _persistedMap.tokens.removeValue(forKey: id)
            return nil
        }
        return token
    }

    /// Sets or updates the token for the specified Live Activity ID.
    ///
    /// If the given `token` is new, or if its value or attribute type differ from an existing
    /// token for the specified `id`, it is stored in the token map and the change is persisted.
    /// If the token is unchanged or is already expired, no persistence occurs.
    ///
    /// - Parameters:
    ///   - token: The ``LiveActivity.UpdateToken`` to store.
    ///   - id: The Live Activity ID associated with the token.
    /// - Returns: `true` if the token was new or different and was stored; `false` otherwise.
    @discardableResult
    func set(_ token: LiveActivity.UpdateToken, id: LiveActivity.ID) -> Bool {
        guard !isExpired(token) else {
            return false
        }

        var workingMap = _persistedMap
        let previousToken = workingMap.tokens.updateValue(token, forKey: id)
        // Compare the actual token values excluding date
        let didChange = previousToken?.value != token.value || previousToken?.attributeType != token.attributeType
        if didChange {
            _persistedMap = workingMap
        }
        return didChange
    }

    /// Removes the token associated with the specified Live Activity ID, if it exists.
    ///
    /// - Parameter id: The Live Activity ID associated with the token to remove.
    /// - Returns: `true` if a token was removed; `false` otherwise.
    @discardableResult
    func remove(id: LiveActivity.ID) -> Bool {
        var workingMap = _persistedMap
        guard workingMap.tokens.removeValue(forKey: id) != nil else {
            return false
        }
        _persistedMap = workingMap
        return true
    }

    // MARK: - Private helpers

    /// Returns whether the given update token is expired based on the configured TTL and reference time.
    ///
    /// - Parameters:
    ///   - token: The update token to check.
    ///   - referenceDate: The reference time used for expiration comparison. Defaults to the current time.
    /// - Returns: `true` if the token has expired; `false` otherwise.
    private func isExpired(_ token: LiveActivity.UpdateToken, referenceDate: Date = Date()) -> Bool {
        let ttl = MessagingConstants.LiveActivity.UPDATE_TOKEN_MAX_TTL
        return referenceDate.timeIntervalSince(token.firstIssued) > ttl
    }

    /// Removes any update tokens whose `firstIssued` date is older than the allowed TTL.
    ///
    /// Expired entries are removed based on `MessagingConstants.LiveActivity.UPDATE_TOKEN_MAX_TTL`.
    private func removeExpiredEntries() {
        let now = Date()
        var tokens = _persistedMap.tokens

        let nonExpiredTokens = tokens.filter { _, token in
            !isExpired(token, referenceDate: now)
        }

        guard nonExpiredTokens.count != tokens.count else {
            // No tokens expired
            return
        }
        _persistedMap.tokens = nonExpiredTokens
    }
}
