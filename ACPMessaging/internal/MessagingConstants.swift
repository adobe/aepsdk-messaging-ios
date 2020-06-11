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

struct MessagingConstants {
    
    static let logTag = "Messaging"
    static let name = "com.adobe.messaging"
    static let version = "0.0.1"
    
    struct Defaults {
        
        
        private init() {}
    }
    
    struct EventDataKeys {
        
        struct Identity {
            static let pushIdentifier = "pushidentifier"
            
            private init() {}
        }
        
        private init() {}
    }
    
    struct EventType {
        static let hub = "com.adobe.eventType.hub"
        static let genericIdentity = "com.adobe.eventType.generic.identity"
        static let genericData = "com.adobe.eventType.generic.data"
        
        private init() {}
    }
    
    struct EventSource {
        static let sharedState = "com.adobe.eventSource.sharedState"
        static let requestContent = "com.adobe.eventSource.requestContent"
        static let responseContent = "com.adobe.eventSource.responseContent"
        static let os = "com.adobe.eventSource.os"
        
        private init() {}
    }
    
    struct SharedState {
                
        static let stateOwner = "stateowner"
        
        struct Configuration {
            static let name = "com.adobe.module.configuration"
            static let privacyStatus = "global.privacy"
            
            private init() {}
        }
        
        struct Identity {
            static let name = "com.adobe.module.identity"
            
            private init() {}
        }
        
        private init() {}
    }
    
    private init() {}
}
