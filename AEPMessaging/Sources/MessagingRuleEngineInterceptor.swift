/*
 Copyright 2024 Adobe. All rights reserved.
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

/// Interceptor that handles rule re-evaluation for the Messaging extension.
///
/// When a reevaluable rule (e.g., fullscreen in-app message) is triggered, this interceptor
/// dispatches a request to refresh message propositions from the server. Once the refresh
/// completes and new rules are loaded, the completion callback is invoked to trigger
/// re-evaluation of all rules against the original event.
class MessagingRuleEngineInterceptor: RuleReevaluationInterceptor {
    
    private let LOG_TAG = "MessagingRuleEngineInterceptor"
    
    // MARK: - RuleReevaluationInterceptor
    
    func onReevaluationTriggered(
        event: Event,
        reevaluableRules: [LaunchRule],
        completion: @escaping () -> Void
    ) {
        Log.trace(label: LOG_TAG, "Reevaluation triggered for event '\(event.id)' with \(reevaluableRules.count) reevaluable rule(s). Refreshing messages...")
        refreshMessagesThenComplete(completion: completion)
    }
    
    // MARK: - Private Methods
    
    /// Dispatches a refresh messages event and calls the completion handler when the refresh is done.
    ///
    /// This method:
    /// 1. Creates a "Refresh in-app messages" event with the refresh flag set
    /// 2. Registers a completion handler to be notified when the refresh completes
    /// 3. Dispatches the event to trigger message proposition fetch from Edge
    /// 4. Calls the completion callback once new propositions are loaded
    ///
    /// - Parameter completion: Closure to call when message refresh is complete
    private func refreshMessagesThenComplete(completion: @escaping () -> Void) {
        // Build the refresh messages event
        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.REFRESH_MESSAGES: true
        ]
        
        let refreshMessageEvent = Event(
            name: "Refresh in-app messages",
            type: EventType.messaging,
            source: EventSource.requestContent,
            data: eventData
        )
        
        // Create a completion handler that will be called when refresh finishes
        let updateHandler: (Bool) -> Void = { _ in
            Log.trace(label: self.LOG_TAG, "Message refresh completed, triggering rule re-evaluation")
            completion()
        }
        
        // Register the completion handler with the Messaging extension
        let handler = CompletionHandler(originatingEvent: refreshMessageEvent, handler: updateHandler)
        Messaging.completionHandlers.append(handler)
        
        // Dispatch the refresh event
        MobileCore.dispatch(event: refreshMessageEvent)
    }
}

