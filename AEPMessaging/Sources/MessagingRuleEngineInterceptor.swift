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

/// Interceptor that handles reevaluation of rules by refreshing in-app messages.
/// When a reevaluable rule matches, this interceptor triggers a refresh of message
/// definitions from the remote before allowing the rule consequences to be processed.
class MessagingRuleEngineInterceptor: RuleReevaluationInterceptor {
    
    func onReevaluationTriggered(
        event: Event,
        reevaluableRules: [LaunchRule],
        completion: @escaping () -> Void
    ) {
        Log.trace(label: MessagingConstants.LOG_TAG,
                  "Reevaluation triggered for event '\(event.id)' with \(reevaluableRules.count) reevaluable rule(s). Refreshing messages.")
        
        Messaging.updatePropositionsForSurfaces([Surface()]) { success in
            if success {
                completion()
            }
        }
    }
}

