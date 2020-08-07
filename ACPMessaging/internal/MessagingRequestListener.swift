/*
 Copyright 2020 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation
import ACPCore

class MessagingRequestListener : ACPExtensionListener {
    override func hear(_ event: ACPExtensionEvent) {
        
        // get parent extension
        guard let parentExtension = self.extension as? MessagingInternal else {
            ACPCore.log(ACPMobileLogLevel.warning, tag: MessagingConstants.logTag, message: "Unable to process event '\(event.eventUniqueIdentifier)' - parent extension is not instance of MessagingInternal.")
            return
        }
        
        // Handle SharedState events
        if event.eventType == MessagingConstants.EventTypes.hub {
            guard let eventData = event.eventData else {
                ACPCore.log(ACPMobileLogLevel.debug, tag: MessagingConstants.logTag, message: "Ignoring event with no data (\(event.eventUniqueIdentifier)).")
                return
            }
            
            let stateOwner = eventData[MessagingConstants.SharedState.stateOwner] as? String
            if stateOwner == MessagingConstants.SharedState.Configuration.name {
                // kick event queue processing
                parentExtension.kickRequestQueue()
            }
        } else if event.eventType == MessagingConstants.EventTypes.genericIdentity && event.eventSource == MessagingConstants.EventSources.requestContent {
            // handle set push identifier calls
            parentExtension.addToRequestQueue(event)
        } else if event.eventType == MessagingConstants.EventTypes.genericData && event.eventSource == MessagingConstants.EventSources.os {
            // handle collect message info calls
            parentExtension.addToRequestQueue(event)
        }
    }
}
