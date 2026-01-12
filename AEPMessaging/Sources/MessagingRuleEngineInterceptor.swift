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
/// extracts the activity ID from the matched rules and can pass it to an API for targeted refresh.
class MessagingRuleEngineInterceptor: RuleReevaluationInterceptor {
    
    private let LOG_TAG = "MessagingRuleEngineInterceptor"
    
    /// Callback to look up PropositionInfo by consequence ID.
    /// Set by the Messaging extension when registering the interceptor.
    var propositionInfoProvider: ((String) -> PropositionInfo?)?
    
    // MARK: - RuleReevaluationInterceptor
    
    func onReevaluationTriggered(
        event: Event,
        reevaluableRules: [LaunchRule],
        completion: @escaping () -> Void
    ) {
        Log.trace(label: LOG_TAG, "Reevaluation triggered for event '\(event.id)' with \(reevaluableRules.count) reevaluable rule(s).")
        
        // Extract activity IDs from the reevaluable rules
        let activityIds = extractActivityIds(from: reevaluableRules)
        
        if !activityIds.isEmpty {
            Log.debug(label: LOG_TAG, "Extracted activity ID(s): \(activityIds)")
            // TODO: Pass activityIds to new API when backend is ready
            // For now, just log and use existing surface-based refresh
        }
        
        // Refresh messages and call completion
        refreshMessagesThenComplete(completion: completion)
    }
    
    // MARK: - Private Methods
    
    /// Extracts activity IDs from the reevaluable rules by looking up PropositionInfo.
    ///
    /// Flow:
    /// 1. Get consequence ID from each rule
    /// 2. Look up PropositionInfo using the consequence ID
    /// 3. Extract activityId from PropositionInfo.scopeDetails.activity.id
    ///
    /// - Parameter rules: The reevaluable rules that triggered this flow
    /// - Returns: Array of unique activity IDs (format: campaignId#actionId)
    private func extractActivityIds(from rules: [LaunchRule]) -> [String] {
        var activityIds = Set<String>()
        
        for rule in rules {
            for consequence in rule.consequences {
                let consequenceId = consequence.id
                
                // Use the provider to look up PropositionInfo
                guard let propositionInfo = propositionInfoProvider?(consequenceId) else {
                    Log.trace(label: LOG_TAG, "No PropositionInfo found for consequence ID: \(consequenceId)")
                    continue
                }
                
                let activityId = propositionInfo.activityId
                if !activityId.isEmpty {
                    activityIds.insert(activityId)
                    Log.trace(label: LOG_TAG, "Found activityId: \(activityId) for consequence: \(consequenceId)")
                }
            }
        }
        
        return Array(activityIds)
    }
    
    /// Refreshes messages and calls the completion handler.
    private func refreshMessagesThenComplete(completion: @escaping () -> Void) {
        Messaging.updatePropositionsForSurfaces([Surface()]) { success in
            if success {
                completion()
            }
        }
    }
}

