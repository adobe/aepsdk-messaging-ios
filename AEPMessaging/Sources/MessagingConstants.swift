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

enum MessagingConstants {

    static let LOG_TAG = "Messaging"
    static let EXTENSION_NAME = "com.adobe.messaging"

    static let EXTENSION_VERSION = "1.0.0"
    static let FRIENDLY_NAME = "Messaging"
    static let RULES_ENGINE_NAME = EXTENSION_NAME + ".rulesengine"

    enum DefaultValues {
        enum Optimize {
            static let MAX_ITEM_COUNT = 30
        }
    }
    
    enum Event {
        enum Name {
            static let MESSAGE_INTERACTION = "Messaging interaction event"
            static let PUSH_NOTIFICATION_INTERACTION = "Push notification interaction event"
            static let PUSH_PROFILE_EDGE = "Push notification profile edge event"
            static let PUSH_TRACKING_EDGE = "Push tracking edge event"
            static let REFRESH_MESSAGES = "Refresh in-app messages"
            static let RETRIEVE_MESSAGE_DEFINITIONS = "Retrieve message definitions"
        }
        
        enum Source {
            static let PERSONALIZATION_DECISIONS = "personalization:decisions"
        }
        
        enum EventType {
            static let messaging = "com.adobe.eventType.messaging"
        }
        
        enum Data {
            enum Key {
                static let PUSH_IDENTIFIER = "pushidentifier"
                static let EVENT_TYPE = "eventType"
                static let MESSAGE_ID = "id"
                static let APPLICATION_OPENED = "applicationOpened"
                static let ACTION_ID = "actionId"
                static let REFRESH_MESSAGES = "refreshmessages"
                static let ADOBE_XDM = "adobe_xdm"
                
                static let TRIGGERED_CONSEQUENCE = "triggeredconsequence"
                static let ID = "id"
                static let DETAIL = "detail"
                static let TYPE = "type"
                static let SOURCE = "source"
                
                // In-App Messages
                enum IAM {
                    static let ID = "id"
                    static let TEMPLATE = "template"
                    static let HTML = "html"
                    static let REMOTE_ASSETS = "remoteAssets"
                    static let TITLE = "title"
                    static let CONTENT = "content"
                    static let CONFIRM = "confirm"
                    static let CANCEL = "cancel"
                    static let URL = "url"
                    static let WAIT = "wait"
                    static let DATE = "date"
                    static let DEEPLINK = "adb_deeplink"
                    static let USER_DATA = "userData"
                    static let CATEGORY = "category"
                    static let SOUND = "sound"
                }
                
                enum Optimize {
                    static let REQUEST_TYPE = "requesttype"
                    static let DECISION_SCOPES = "decisionscopes"
                    static let NAME = "name"
                    static let ID = "id"
                    static let DATA = "data"
                    static let CONTENT = "content"
                    static let PAYLOAD = "payload"
                    static let ACTIVITY = "activity"
                    static let PLACEMENT = "placement"
                    static let ITEMS = "items"
                }
            }
            
            enum Values {
                enum IAM {
                    enum Template {
                        static let FULLSCREEN = "fullscreen"
                        static let LOCAL = "local"
                    }
                    
                    enum Value {
                        static let TRIGGERED = "triggered"
                        static let VIEWED = "viewed"
                        static let CLICKED = "clicked"
                    }
                }
                
                enum Optimize {
                    static let UPDATE_PROPOSITIONS = "updatepropositions"
                }
            }
        }
    }

    enum ConsequenceTypes {
        static let IN_APP_MESSAGE = "cjmiam"
    }

    enum XDM {
        enum AdobeKeys {
            static let _XDM = "_xdm"
            static let CJM = "cjm"
            static let MIXINS = "mixins"
            static let CUSTOMER_JOURNEY_MANAGEMENT = "customerJourneyManagement"
            static let EXPERIENCE = "_experience"
            static let APPLICATION = "application"
            static let LAUNCHES = "launches"
            static let LAUNCHES_VALUE = "value"
            static let MESSAGE_PROFILE_JSON = "{\n   \"messageProfile\":" +
                "{\n      \"channel\": {\n         \"_id\": \"https://ns.adobe.com/xdm/channels/push\"\n      }\n   }" +
                ",\n   \"pushChannelContext\": {\n      \"platform\": \"apns\"\n   }\n}"
        }
        
        enum Key {
            static let ADOBE_XDM = "adobe_xdm"
            static let XDM = "xdm"
            static let META = "meta"
            static let COLLECT = "collect"
            static let DATASET_ID = "datasetId"
            static let ACTION_ID = "actionID"
            static let CUSTOM_ACTION = "customAction"
            static let PUSH_PROVIDER_MESSAGE_ID = "pushProviderMessageID"
            static let PUSH_PROVIDER = "pushProvider"
            static let EVENT_TYPE = "eventType"
            static let PUSH_NOTIFICATION_TRACKING = "pushNotificationTracking"
            static let DATA = "data"
        }

        enum Push {
            static let PUSH_NOTIFICATION_DETAILS = "pushNotificationDetails"
            static let APP_ID = "appID"
            static let TOKEN = "token"
            static let PLATFORM = "platform"
            static let DENYLISTED = "denylisted"
            static let IDENTITY = "identity"
            static let NAMESPACE = "namespace"
            static let CODE = "code"
            static let ID = "id"
            
            enum EventType {
                static let APPLICATION_OPENED = "pushTracking.applicationOpened"
                static let CUSTOM_ACTION = "pushTracking.customAction"
            }
            
            enum Value {
                static let ECID = "ECID"
                static let APNS = "apns"
                static let APNS_SANDBOX = "apnsSandbox"
            }
        }
        
        enum IAM {
            enum EventType {
                static let DISMISS = "inapp.dismiss"
                static let INTERACT = "inapp.interact"
                static let TRIGGER = "inapp.trigger"
            }
        }
    }

    enum SharedState {
        static let stateOwner = "stateowner"

        enum Messaging {
            static let PUSH_IDENTIFIER = "pushidentifier"
        }

        enum Configuration {
            static let NAME = "com.adobe.module.configuration"
            static let EXPERIENCE_CLOUD_ORG = "experienceCloud.org"

            // Messaging dataset ids
            static let EXPERIENCE_EVENT_DATASET = "messaging.eventDataset"

            // config for whether to useSandbox or not
            static let USE_SANDBOX = "messaging.useSandbox"
        }

        enum EdgeIdentity {
            static let NAME = "com.adobe.edge.identity"
            static let IDENTITY_MAP = "identityMap"
            static let ECID = "ECID"
            static let ID = "id"
        }
    }
}
