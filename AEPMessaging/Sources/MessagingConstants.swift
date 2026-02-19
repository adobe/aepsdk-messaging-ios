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

    static let EXTENSION_VERSION = "5.10.0"
    static let FRIENDLY_NAME = "Messaging"
    static let RULES_ENGINE_NAME = EXTENSION_NAME + ".rulesengine"
    static let CONTENT_CARD_RULES_ENGINE_NAME = EXTENSION_NAME + "ContentCard" + ".rulesengine"
    static let THIRTY_DAYS_IN_SECONDS = TimeInterval(60 * 60 * 24 * 30)
    static let PATH_SEPARATOR = "/"
    static let DATA_STORE_NAME = EXTENSION_NAME
    static let IGNORE_PUSH_SYNC_TIMEOUT_SECONDS = TimeInterval(1) // 1 second
    static let OPTIMIZE_PUSH_SYNC_ENABLED = "Push token sync optimization is enabled"
    static let OPTIMIZE_PUSH_SYNC_DISABLED_SYNC_WITHIN_TIMEOUT = "Push registration sync optimization is disabled but the sync is within the 1 second timeout"

    enum ContentTypes {
        static let APPLICATION_JSON = "application/json"
        static let TEXT_HTML = "text/html"
        static let TEXT_XML = "text/xml"
        static let TEXT_PLAIN = "text/plain"
    }

    enum Caches {
        static let CACHE_NAME = "com.adobe.messaging.cache"
        static let CONTENT_CARD_UI_CACHE_NAME = "com.adobe.messaging.contentcard.ui.cache"
        static let PROPOSITIONS = "propositions"
        static let PATH = "PATH"
    }

    enum ConsequenceTypes {
        static let SCHEMA = "schema"
    }

    enum PersonalizationSchemas {
        static let HTML_CONTENT = "https://ns.adobe.com/personalization/html-content-item"
        static let JSON_CONTENT = "https://ns.adobe.com/personalization/json-content-item"
        static let RULESET_ITEM = "https://ns.adobe.com/personalization/ruleset-item"
        static let DEFAULT_CONTENT = "https://ns.adobe.com/personalization/default-content-item"
        static let IN_APP = "https://ns.adobe.com/personalization/message/in-app"
        static let CONTENT_CARD = "https://ns.adobe.com/personalization/message/content-card"
        static let NATIVE_ALERT = "https://ns.adobe.com/personalization/message/native-alert"
        static let EVENT_HISTORY_OPERATION = "https://ns.adobe.com/personalization/eventHistoryOperation"

        @available(*, deprecated, renamed: "CONTENT_CARD")
        static let FEED_ITEM = "https://ns.adobe.com/personalization/message/feed-item"
    }

    enum Event {
        enum Name {
            static let MESSAGE_INTERACTION = "Messaging interaction event"
            static let PUSH_NOTIFICATION_INTERACTION = "Push notification interaction event"
            static let PUSH_PROFILE_EDGE = "Push notification profile edge event"
            static let PUSH_TRACKING_EDGE = "Push tracking edge event"
            static let REFRESH_MESSAGES = "Refresh in-app messages"
            static let RETRIEVE_MESSAGE_DEFINITIONS = "Retrieve message definitions"
            static let UPDATE_PROPOSITIONS = "Update propositions"
            static let GET_PROPOSITIONS = "Get propositions"
            static let TRACK_PROPOSITIONS = "Track propositions"
            static let MESSAGE_PROPOSITIONS_RESPONSE = "Message propositions response"
            static let MESSAGE_PROPOSITIONS_NOTIFICATION = "Message propositions notification"
            static let FINALIZE_PROPOSITIONS_RESPONSE = "Finalize propositions response"
            static let PUSH_TRACKING_STATUS = "Push tracking status event"
            static let EVENT_HISTORY_WRITE = "Write IAM event to history"
            static let PUSH_TO_IN_APP = "Push to in-app"
        }

        enum Source {
            static let EVENT_HISTORY_WRITE = "com.adobe.eventSource.eventHistoryWrite"
            static let PERSONALIZATION_DECISIONS = "personalization:decisions"
        }

        enum Data {
            enum AdobeKeys {
                static let NAMESPACE = "__adobe"
                static let AJO = "ajo"
                static let INAPP_RESPONSE_FORMAT = "in-app-response-format"
            }

            enum Key {
                static let PUSH_IDENTIFIER = "pushidentifier"
                static let EVENT_TYPE = "eventType"
                static let APPLICATION_OPENED = "applicationOpened"
                static let ACTION_ID = "actionId"
                static let REFRESH_MESSAGES = "refreshmessages"
                static let PUSH_CLICK_THROUGH_URL = "clickThroughUrl"
                static let ADOBE_XDM = "adobe_xdm"
                static let REQUEST_EVENT_ID = "requestEventId"
                static let IAM_HISTORY = "iam"
                static let UPDATE_PROPOSITIONS = "updatepropositions"
                static let GET_PROPOSITIONS = "getpropositions"
                static let TRACK_PROPOSITIONS = "trackpropositions"
                static let PROPOSITION_INTERACTION = "propositioninteraction"
                static let SURFACES = "surfaces"
                static let PROPOSITIONS = "propositions"
                static let RESPONSE_ERROR = "responseerror"
                static let ENDING_EVENT_ID = "endingEventId"
                static let PUSH_NOTIFICATION_TRACKING_STATUS = "pushTrackingStatus"
                static let PUSH_NOTIFICATION_TRACKING_MESSAGE = "pushTrackingStatusMessage"
                static let TRIGGERED_CONSEQUENCE = "triggeredconsequence"
                static let ID = "id"
                static let DETAIL = "detail"
                static let TYPE = "type"
                static let SCHEMA = "schema"
                static let DATA = "data"

                enum Feed {
                    static let SURFACE = "surface"
                }

                // In-App Messages
                enum IAM {
                    static let REMOTE_ASSETS = "remoteAssets"

                    // layout keys
                    static let WIDTH = "width"
                    static let MAX_WIDTH = "maxWidth"
                    static let HEIGHT = "height"
                    static let VERTICAL_ALIGN = "verticalAlign"
                    static let VERTICAL_INSET = "verticalInset"
                    static let HORIZONTAL_ALIGN = "horizontalAlign"
                    static let HORIZONTAL_INSET = "horizontalInset"
                    static let UI_TAKEOVER = "uiTakeover"
                    static let FIT_TO_CONTENT = "fitToContent"
                    static let DISPLAY_ANIMATION = "displayAnimation"
                    static let DISMISS_ANIMATION = "dismissAnimation"
                    static let GESTURES = "gestures"
                    static let BACKDROP_COLOR = "backdropColor"
                    static let BACKDROP_OPACITY = "backdropOpacity"
                    static let CORNER_RADIUS = "cornerRadius"
                }

                enum Personalization {
                    static let PAYLOAD = "payload"
                    static let CORRELATION_ID = "correlationID"
                    static let ACTIVITY = "activity"
                    static let RANK = "rank"
                    static let PRIORITY = "priority"
                    static let ID = "id"
                }
            }
        }

        enum History {
            enum Keys {
                // these kvps are embedded in an object named `iam`,
                // so the mask path to them is e.g. "iam.eventType"
                static let EVENT_TYPE = "eventType"
                static let MESSAGE_ID = "id"
                static let TRACKING_ACTION = "action"
            }

            enum Mask {
                static let EVENT_TYPE = "iam.eventType"
                static let MESSAGE_ID = "iam.id"
                static let TRACKING_ACTION = "iam.action"
            }

            enum OperationKeys {
                static let MESSAGE_ID = "iam.id"
                static let EVENT_TYPE = "iam.eventType"
            }
        }
    }

    enum IAM {
        enum HTML {
            static let SCHEME = "adbinapp"
            static let INTERACTION = "interaction"
            static let DISMISS = "dismiss"
            static let LINK = "link"
            static let ANIMATE = "animate"
        }
    }

    enum XDM {
        enum AdobeKeys {
            static let _XDM = "_xdm"
            static let CJM = "cjm"
            static let MIXINS = "mixins"
            static let EXPERIENCE = "_experience"
            static let CUSTOMER_JOURNEY_MANAGEMENT = "customerJourneyManagement"
            static let APPLICATION = "application"
            static let LAUNCHES = "launches"
            static let LAUNCHES_VALUE = "value"

            /// messageProfile for push tracking in AJO
            static let MESSAGE_PROFILE = "messageProfile"
            static let CHANNEL = "channel"
            static let _ID = "_id"
            static let PUSH_CHANNEL_ID = "https://ns.adobe.com/xdm/channels/push"
            static let PUSH_CHANNEL_CONTEXT = "pushChannelContext"
            static let PLATFORM = "platform"
            static let APNS = "apns"
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
            static let REQUEST = "request"
            static let SEND_COMPLETION = "sendCompletion"
        }

        enum Inbound {
            static let SURFACE_BASE = "mobileapp://"

            enum EventType {
                static let TRIGGER = "decisioning.propositionTrigger"
                static let DISPLAY = "decisioning.propositionDisplay"
                static let INTERACT = "decisioning.propositionInteract"
                static let DISMISS = "decisioning.propositionDismiss"
                static let DISQUALIFY = "decisioning.propositionDisqualify"
                static let SUPPRESSED_DISPLAY = "decisioning.propositionSuppressDisplay"
                static let PERSONALIZATION_REQUEST = "personalization.request"
            }

            enum PropositionEventType {
                static let TRIGGER = "trigger"
                static let DISPLAY = "display"
                static let INTERACT = "interact"
                static let DISMISS = "dismiss"
                static let DISQUALIFY = "disqualify"
                static let UNQUALIFY = "unqualify"
                static let SUPPRESSED_DISPLAY = "suppressDisplay"
            }

            enum Key {
                static let PERSONALIZATION = "personalization"
                static let QUERY = "query"
                static let SURFACES = "surfaces"
                static let SCHEMAS = "schemas"
                static let DECISIONING = "decisioning"
                static let PROPOSITION_ACTION = "propositionAction"
                static let LABEL = "label"
                static let ID = "id"
                static let REASON = "reason"
                static let PROPOSITION_EVENT_TYPE = "propositionEventType"
                static let PROPOSITIONS = "propositions"
                static let SCOPE = "scope"
                static let SCOPE_DETAILS = "scopeDetails"
                static let ITEMS = "items"
                static let CHARACTERISTICS = "characteristics"
                static let TOKENS = "tokens"
                static let EXPERIENCE_DECISIONING_REQUEST_ID = "exdRequestID"
            }

            enum Value {
                /// enum (int) representing desired format returned by IDS for in-app message propositions
                static let IAM_RESPONSE_FORMAT = 2
            }
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
    }

    enum SharedState {
        enum Messaging {
            static let PUSH_IDENTIFIER = "pushidentifier"
        }

        enum Configuration {
            static let NAME = "com.adobe.module.configuration"

            // Messaging dataset ids
            static let EXPERIENCE_EVENT_DATASET = "messaging.eventDataset"

            // config for whether to useSandbox or not
            static let USE_SANDBOX = "messaging.useSandbox"

            // config for disabling the push token sync optimization
            static let OPTIMIZE_PUSH_SYNC = "messaging.optimizePushSync"
        }

        enum EdgeIdentity {
            static let NAME = "com.adobe.edge.identity"
            static let IDENTITY_MAP = "identityMap"
            static let ECID = "ECID"
            static let ID = "id"
        }
    }

    enum PushNotification {
        enum UserInfoKey {
            static let ACTION_URL = "adb_uri"
            static let PUSH_TO_INAPP = "adb_iam_id"
        }
    }

    enum NamedCollectionKeys {
        static let PUSH_IDENTIFIER = "pushidentifier"
    }
}
