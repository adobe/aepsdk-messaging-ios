/*
 Copyright 2021 Adobe. All rights reserved.
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
import AEPCore

/// Helper methods for caching and loading previously retrieved in-app message definitions
extension MessagingRulesEngine {    
    /// Attempts to load in-app message definitions from cache into the `MessagingRulesEngine`.
    func loadCachedMessages() {
        guard let cachedMessages = cache.get(key: cachedMessagesName) else {
            Log.trace(label: MessagingConstants.LOG_TAG, "Unable to load cached messages - cache file not found.")
            return
        }

        // the below call to String(data:encoding:) never fails when using .utf8 encoding
        // https://forums.swift.org/t/can-encoding-string-to-data-with-utf8-fail/22437
        guard let cachedMessagesString = String(data: cachedMessages.data, encoding: .utf8) else { return }
        let messagesStringArray = cachedMessagesString.components(separatedBy: cachedMessagesDelimiter)

        Log.trace(label: MessagingConstants.LOG_TAG, "Loading in-app message definition from cache.")
        loadRules(rules: messagesStringArray)
    }

    /// Uses the provided messages to create or overwrite a cache entry for in-app messages.
    ///
    /// - Parameter messages: a `[String]` where each element is JSON representation of a `LaunchRule`
    func setMessagingCache(_ messages: [String]) {
        cacheMessages(messages)
    }

    /// Removes the cache for in-app messages.
    func clearMessagingCache() {
        cacheMessages(nil)
    }
    
    /// Caches any remote assets for RuleConsequence(s) found in provided rules.
    ///
    /// - Parameter rules: an array of `LaunchRule`s that may contain remote assets in their consequence(s)
    func cacheRemoteAssetsFor(_ rules: [LaunchRule]) {
        var assetsToKeep: [String] = []
        for rule in rules {
            for consequence in rule.consequences {
                if let assets = consequence.details[MessagingConstants.Event.Data.Key.IAM.REMOTE_ASSETS] as? [String] {
                    for asset in assets {
                        guard let url = URL(string: asset) else {
                            Log.debug(label: MessagingConstants.LOG_TAG, "Unable to cache message asset '\(asset)' for consequence id '\(consequence.id)'. Asset is not a valid URL.")
                            continue
                        }
                        let task = URLSession.shared.downloadTask(with: url) { imageUrl, response, error in
                            if let image = imageUrl, let imageData = try? Data(contentsOf: image, options: .mappedIfSafe) {
                                let cacheEntry = CacheEntry(data: imageData,
                                                            expiry: CacheExpiry.seconds(MessagingConstants.THIRTY_DAYS_IN_SECONDS),
                                                            metadata: nil)
                                try? self.cache.set(key: asset, entry: cacheEntry)
                                assetsToKeep.append(asset)
                            }
                        }
                        task.resume()
                    }
                }
            }
        }
    }
    
    /// Uses the provided messages to create or overwrite a cache entry for in-app messages.
    ///
    /// If `messages` is nil, the cache entry for in-app messages will be removed.
    ///
    /// - Parameter messages: a `[String]` where each element is JSON representation of a `LaunchRule`
    private func cacheMessages(_ messages: [String]?) {
        // remove cached messages if param is nil
        guard let messages = messages else {
            do {
                try cache.remove(key: cachedMessagesName)
                Log.trace(label: MessagingConstants.LOG_TAG, "In-app messaging cache has been deleted.")
            } catch let error as NSError {
                if #available(iOS 14.5, *) {
                    guard let underlyingError = error.underlyingErrors.first as NSError? else {
                        Log.trace(label: MessagingConstants.LOG_TAG, "Unable to remove in-app messaging cache: \(error).")
                        return
                    }
                    let NO_SUCH_FILE_OR_DIRECTORY_ERROR_CODE = 2
                    if underlyingError.code != NO_SUCH_FILE_OR_DIRECTORY_ERROR_CODE {
                        Log.warning(label: MessagingConstants.LOG_TAG, "Error removing in-app messaging cache: \(error).")
                    }
                } else {
                    Log.trace(label: MessagingConstants.LOG_TAG, "Unable to remove in-app messaging cache: \(error).")
                }
            }

            return
        }

        let joinedMessagesString = messages.joined(separator: cachedMessagesDelimiter)

        // the below call to String(data:encoding:) never fails when using .utf8 encoding
        // https://forums.swift.org/t/can-encoding-string-to-data-with-utf8-fail/22437
        guard let cacheData = joinedMessagesString.data(using: .utf8) else { return }

        let cacheEntry = CacheEntry(data: cacheData, expiry: .never, metadata: nil)
        do {
            try cache.set(key: cachedMessagesName, entry: cacheEntry)
            Log.trace(label: MessagingConstants.LOG_TAG, "In-app messaging cache has been created.")
        } catch {
            Log.warning(label: MessagingConstants.LOG_TAG, "Error creating in-app messaging cache: \(error).")
        }
    }
}
