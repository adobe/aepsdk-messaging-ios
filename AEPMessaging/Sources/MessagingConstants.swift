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

enum MessagingConstants {

    static let LOG_TAG = "Messaging"
    static let EXTENSION_NAME = "com.adobe.messaging"
    static let EXTENSION_VERSION = "1.0.0-alpha-2"
    static let FRIENDLY_NAME = EXTENSION_NAME
    static let RULES_ENGINE_NAME = EXTENSION_NAME + ".rulesengine"

    enum EventDataKeys {
        static let PUSH_IDENTIFIER = "pushidentifier"
        static let EVENT_TYPE = "eventType"
        static let MESSAGE_ID = "id"
        static let APPLICATION_OPENED = "applicationOpened"
        static let ACTION_ID = "actionId"
        static let FETCH_MESSAGES = "fetchmessages"
        
        static let TRIGGERED_CONSEQUENCE = "triggeredconsequence"
        static let ID = "id"
        static let DETAIL = "detail"
        static let TYPE = "type"
        static let SOURCE = "source"
        
        enum InAppMessages {
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
        
        enum Offers {
            static let PROPOSITIONS = "propositions"
            static let DECISION_SCOPES = "decisionscopes"
            static let ACTIVITY_ID = "activityId"
            static let PLACEMENT_ID = "placementId"
            static let ITEM_COUNT = "itemCount"
            static let ERROR = "error"
            static let TYPE = "type"
            static let PERSONALIZATION_DECISIONS = "personalization:decisions"
            static let PREFETCH = "prefetch"
            static let RETRIEVE = "retrieve"
            static let REQUEST_EVENT_ID = "requestEventId"
            static let XDM_QUERY = "query"
            static let XDM = "xdm"
            static let DATA = "data"
            static let DATASET_ID = "datasetId"
            static let XDM_EVENT_TYPE = "eventType"
            static let PERSONALIZATION_REQUEST = "personalization.request"
            static let PAYLOAD = "payload"
            static let ACTIVITY = "activity"
            static let PLACEMENT = "placement"
            static let ID = "id"
            static let ITEMS = "items"
            static let CONTENT = "content"
        }
    }
    
    enum EventNames {
        static let OFFERS_REQUEST = "Offer Decisioning Request"
    }
    
    enum EventSource {
        static let PERSONALIZATION_DECISIONS = "personalization:decisions"
    }
    
    enum EventType {
        static let MESSAGING = "com.adobe.eventType.messaging"
    }
    
    enum InAppMessageTemplates {
        static let FULLSCREEN = "fullscreen"
        static let LOCAL = "local"
    }
    
    enum ConsequenceTypes {
        static let IN_APP_MESSAGE = "cjmiam"
    }
    
    enum AdobeTrackingKeys {
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

    enum XDM {
        enum DataKeys {
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
        }
        
        enum EventTypes {
            static let PUSH_TRACKING_APPLICATION_OPENED = "pushTracking.applicationOpened"
            static let PUSH_TRACKING_CUSTOM_ACTION = "pushTracking.customAction"
        }
    }

    /*
     we'll be temproarily using the json structure until platform extension is ready.
     at that point, we'll rely on xdm tool and platform to send this profile event,
     and the keys below can be safely removed.

     https://github.com/adobe/xdm/blob/master/schemas/context/profile-push-notification-details.example.1.json
     {
     "xdm:pushNotificationDetails": [
     {
     "xdm:appID": "75eafb7e-fa44-4514-86fc-221e32c5aef9",
     "xdm:token": "99156313-c9df-4e54-9c6c-5740f940c3ca",
     "xdm:platform": "apns",
     "xdm:denylisted": false,
     "xdm:identity": {
     "xdm:namespace": {
     "xdm:code": "ECID"
     },
     "xdm:xid":"92312748749128"
     }
     }
     ]
     }
     */

    enum Temp {
        static let postBodyBase = "{\n" +
            "    \"header\" : {\n" +
            "        \"imsOrgId\": \"%@\",\n" +
            "        \"source\": {\n" +
            "            \"name\": \"mobile\"\n" +
            "        },\n" +
            "        \"datasetId\": \"%@\"\n" +
            "    },\n" +
            "    \"body\": {\n" +
            "        \"xdmEntity\": {\n" +
            "            \"identityMap\": {\n" +
            "                \"ECID\": [\n" +
            "                    {\n" +
            "                        \"id\" : \"%@\"\n" +
            "                    }\n" +
            "                ]\n" +
            "            },\n" +
            "            \"pushNotificationDetails\": [\n" +
            "                {\n" +
            "                    \"appID\": \"%@\",\n" +
            "                    \"platform\": \"%@\",\n" +
            "                    \"token\": \"%@\",\n" +
            "                    \"denylisted\": false,\n" +
            "                    \"identity\": {\n" +
            "                        \"namespace\": {\n" +
            "                            \"code\": \"ECID\"\n" +
            "                        },\n" +
            "                        \"id\": \"%@\"\n" +
            "                    }\n" +
            "                }\n" +
            "            ]\n" +
            "        }\n" +
            "    }\n" +
            "}"

        // push
        static let pushNotificationDetails = "pushNotificationDetails"
        static let appId = "appID"
        static let token = "token"
        static let platform = "platform"
        static let denylisted = "denylisted"
        static let identity = "identiy"
        static let namespace = "namespace"
        static let code = "code"
        static let xid = "xid"
    }

    enum JsonValues {
        static let ecid = "ECID"
        static let apns = "apns"
        static let apnsSandbox = "apnsSandbox"
    }

    struct SharedState {

        static let stateOwner = "stateowner"

        enum Configuration {
            static let name = "com.adobe.module.configuration"
            static let privacyStatus = "global.privacy"
            static let dccsEndpoint = "messaging.dccs"
            static let experienceCloudOrgId = "experienceCloud.org"

            // Messaging dataset ids
            static let profileDatasetId = "messaging.profileDataset"
            static let experienceEventDatasetId = "messaging.eventDataset"

            // config for whether to useSandbox or not
            static let useSandbox = "messaging.useSandbox"
        }

        enum Identity {
            static let name = "com.adobe.module.identity"
            static let ecid = "mid"
        }

        private init() {}
    }
}
