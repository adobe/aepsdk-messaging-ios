/*
 Copyright 2026 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import AEPCore
import AEPServices
import Foundation

/// Handles refresh of in-app messages with deduplication.
/// Ensures only one refresh is in progress at a time, queuing subsequent requests.
/// This prevents redundant network calls when multiple components request a refresh simultaneously.
/// Dispatches the REFRESH_MESSAGES event and manages completion handlers.
class RefreshInAppHandler {
    
    /// Shared instance for use by public API and internal components
    static let shared = RefreshInAppHandler()
    
    /// Serial queue for thread-safe access to state
    private let queue = DispatchQueue(label: "com.adobe.messaging.refresh.queue")
    
    /// Indicates whether a refresh operation is currently in progress
    private var isRefreshInProgress = false
    
    /// Completion handlers waiting for the current refresh to complete
    private var pendingCompletions: [(Bool) -> Void] = []
    
    /// Requests a refresh of in-app messages.
    /// If a refresh is already in progress, the completion is queued and will be called
    /// when the current refresh completes. All queued completions receive the same result.
    ///
    /// - Parameter completion: Optional callback with `true` on success, `false` on failure
    func refresh(completion: ((Bool) -> Void)? = nil) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Add completion to queue if provided
            if let completion = completion {
                self.pendingCompletions.append(completion)
            }
            
            // If refresh already in progress, just queue the completion and return
            if self.isRefreshInProgress {
                Log.trace(label: MessagingConstants.LOG_TAG,
                          "Refresh already in progress, queuing completion handler. Total pending: \(self.pendingCompletions.count)")
                return
            }
            
            // Mark refresh as in progress
            self.isRefreshInProgress = true
            
            Log.trace(label: MessagingConstants.LOG_TAG, "Starting in-app message refresh.")
            
            // Dispatch the refresh event
            self.dispatchRefreshEvent()
        }
    }
    
    /// Called by Messaging extension when refresh completes
    /// - Parameter success: Whether the refresh succeeded
    func handleRefreshComplete(success: Bool) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let completionsToCall = self.pendingCompletions
            self.pendingCompletions = []
            self.isRefreshInProgress = false
            
            Log.trace(label: MessagingConstants.LOG_TAG,
                      "Refresh completed (success: \(success)), calling \(completionsToCall.count) completion handler(s).")
            
            // Call all queued completions with the result
            completionsToCall.forEach { $0(success) }
        }
    }
    
    /// Dispatches the REFRESH_MESSAGES event
    private func dispatchRefreshEvent() {
        let eventData: [String: Any] = [MessagingConstants.Event.Data.Key.REFRESH_MESSAGES: true]
        let event = Event(name: MessagingConstants.Event.Name.REFRESH_MESSAGES,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)
        
        MobileCore.dispatch(event: event)
    }
    
    /// Resets the handler state. Used for testing.
    #if DEBUG
    func reset() {
        queue.sync {
            pendingCompletions.removeAll()
            isRefreshInProgress = false
        }
    }
    #endif
}

