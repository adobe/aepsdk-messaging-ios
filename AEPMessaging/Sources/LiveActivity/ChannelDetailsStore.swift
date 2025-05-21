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

import Foundation

final class ChannelDetailsStore: PersistenceStoreBase<LiveActivity.ChannelMap> {
    init() {
        super.init(storeKey: MessagingConstants.NamedCollectionKeys.LIVE_ACTIVITY_CHANNEL_DETAILS)
        // This always triggers a lazy load from persisted storage.
        // If any details are expired, they will be removed and the updated map will be written back.
        removeExpiredEntries()
    }

    /// Returns the current channel map after removing any expired entries.
    ///
    /// - Returns: A `ChannelMap` containing only non-expired channel Live Activity entries.
    /// - SeeAlso: ``removeExpiredEntries()``
    override func all() -> LiveActivity.ChannelMap {
        removeExpiredEntries()
        return _persistedMap
    }

    /// Returns the Live Activity details for the specified channel ID, if it exists and has not expired.
    ///
    /// If the associated entry is expired, it is opportunistically removed from the store.
    ///
    /// - Parameter channelID: The channel ID associated with the Live Activity details to retrieve.
    /// - Returns: The associated `ChannelActivity` if it exists and hasn’t expired; `nil` otherwise.
    func activity(channelID: LiveActivity.ID) -> LiveActivity.ChannelActivity? {
        guard let activity = _persistedMap.channels[channelID] else {
            return nil
        }
        guard !isExpired(activity) else {
            // Remove expired values from the store
            _persistedMap.channels.removeValue(forKey: channelID)
            return nil
        }
        return activity
    }

    /// Sets or updates the Live Activity details for the specified channel ID, unless the details have already expired.
    ///
    /// - Parameters:
    ///   - activity: The Live Activity details to store.
    ///   - channelID: The channel ID to associate with the Live Activity.
    /// - Returns: `true` if the details were stored; `false` otherwise.
    @discardableResult
    func set(activity: LiveActivity.ChannelActivity, channelID: LiveActivity.ID) -> Bool {
        guard !isExpired(activity) else {
            return false
        }
        _persistedMap.channels.updateValue(activity, forKey: channelID)
        return true
    }

    /// Removes the Live Activity details associated with the specified channel ID.
    ///
    /// - Parameter channelID: The channel ID whose Live Activity details should be removed.
    /// - Returns: `true` if an entry was removed; `false` otherwise.
    @discardableResult
    func remove(channelID: LiveActivity.ID) -> Bool {
        var workingMap = _persistedMap
        guard workingMap.channels.removeValue(forKey: channelID) != nil else {
            return false
        }
        _persistedMap = workingMap
        return true
    }

    // MARK: - Private helpers

    /// Returns whether the given channel's Live Activity details are expired based on the configured TTL and reference time.
    ///
    /// - Parameters:
    ///   - activity: The Live Activity details to check.
    ///   - referenceDate: The reference time used for expiration comparison. Defaults to the current time.
    /// - Returns: `true` if the details have expired; `false` otherwise.
    private func isExpired(_ activity: LiveActivity.ChannelActivity, referenceDate: Date = Date()) -> Bool {
        let ttl = MessagingConstants.LiveActivity.CHANNEL_DETAIL_MAX_TTL
        return referenceDate.timeIntervalSince(activity.startedAt) > ttl
    }

    /// Removes all channel Live Activity details whose `startedAt` date is older than the allowed TTL.
    ///
    /// The TTL is defined by `MessagingConstants.LiveActivity.CHANNEL_DETAIL_MAX_TTL`.
    private func removeExpiredEntries() {
        let now = Date()
        let channels = _persistedMap.channels

        let nonExpiredChannels = channels.filter { _, activity in
            !isExpired(activity, referenceDate: now)
        }

        guard nonExpiredChannels.count != channels.count else {
            // No channels expired
            return
        }
        _persistedMap.channels = nonExpiredChannels
    }
}
