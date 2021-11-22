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

import Foundation
import AEPServices

extension MessagingRulesEngine {
    func loadCachedMessages() {
        guard let cachedMessages = cache.get(key: cachedMessages) else {
            Log.trace(label: MessagingConstants.LOG_TAG, "Unable to load cached messages - cache file not found.")
            return
        }
        
        let cachedMessagesString = String(data: cachedMessages.data, encoding: .utf8)
        guard let messagesStringArray = cachedMessagesString?.components(separatedBy: cachedMessagesDelimiter) else {
            return
        }
        
        Log.trace(label: MessagingConstants.LOG_TAG, "Loading in-app message definition from cache.")
        loadRules(rules: messagesStringArray)
    }
    
    func setMessagingCache(_ messages: [String]) {
        cacheMessages(messages)
    }
    
    func clearMessagingCache() {
        cacheMessages(nil)
    }
    
    /// Uses the provided messages to create or overwrite a cache entry for in-app messages
    private func cacheMessages(_ messages: [String]?) {
        // remove cached messages if param is nil
        guard let messages = messages else {
            do {
                try cache.remove(key: cachedMessages)
                Log.trace(label: MessagingConstants.LOG_TAG, "In-app messaging cache has been deleted.")
            } catch {
                Log.warning(label: MessagingConstants.LOG_TAG, "Error removing in-app messaging cache: \(error).")
            }
            
            return
        }
        
        guard let cacheData = messages.joined(separator: cachedMessagesDelimiter).data(using: .utf8) else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Unable to create data for caching in-app messages.")
            return
        }
        
        let cacheEntry = CacheEntry(data: cacheData, expiry: .never, metadata: nil)
        do {
            try cache.set(key: cachedMessages, entry: cacheEntry)
            Log.trace(label: MessagingConstants.LOG_TAG, "In-app messaging cache has been created.")
        } catch {
            Log.warning(label: MessagingConstants.LOG_TAG, "Error creating in-app messaging cache: \(error).")
        }
    }
}
