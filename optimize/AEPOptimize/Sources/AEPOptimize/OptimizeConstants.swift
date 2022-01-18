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

enum OptimizeConstants {
    static let EXTENSION_NAME = "com.adobe.optimize"
    static let FRIENDLY_NAME = "Optimize"
    static let EXTENSION_VERSION = "1.0.0"
    static let LOG_TAG = FRIENDLY_NAME

    static let DECISION_SCOPE_NAME = "name"
    static let ACTIVITY_ID = "activityId"
    static let XDM_ACTIVITY_ID = "xdm:activityId"
    static let PLACEMENT_ID = "placementId"
    static let XDM_PLACEMENT_ID = "xdm:placementId"
    static let ITEM_COUNT = "itemCount"
    static let XDM_ITEM_COUNT = "xdm:itemCount"

    static let ERROR_UNKNOWN = "unknown"

    enum EventNames {
        static let UPDATE_PROPOSITIONS_REQUEST = "Optimize Update Propositions Request"
        static let GET_PROPOSITIONS_REQUEST = "Optimize Get Propositions Request"
        static let TRACK_PROPOSITIONS_REQUEST = "Optimize Track Propositions Request"
        static let CLEAR_PROPOSITIONS_REQUEST = "Optimize Clear Propositions Request"
        static let OPTIMIZE_NOTIFICATION = "Optimize Notification"
        static let EDGE_PERSONALIZATION_REQUEST = "Edge Optimize Personalization Request"
        static let EDGE_PROPOSITION_INTERACTION_REQUEST = "Edge Optimize Proposition Interaction Request"
        static let OPTIMIZE_RESPONSE = "Optimize Response"
    }

    enum EventSource {
        static let EDGE_PERSONALIZATION_DECISIONS = "personalization:decisions"
        static let EDGE_ERROR_RESPONSE = "com.adobe.eventSource.errorResponseContent"
    }

    enum EventDataKeys {
        static let REQUEST_TYPE = "requesttype"
        static let DECISION_SCOPES = "decisionscopes"
        static let XDM = "xdm"
        static let DATA = "data"
        static let PROPOSITIONS = "propositions"
        static let RESPONSE_ERROR = "responseerror"
        static let PROPOSITION_INTERACTIONS = "propositioninteractions"
    }

    enum EventDataValues {
        static let REQUEST_TYPE_UPDATE = "updatepropositions"
        static let REQUEST_TYPE_GET = "getpropositions"
        static let REQUEST_TYPE_TRACK = "trackpropositions"
    }

    enum Edge {
        static let EXTENSION_NAME = "com.adobe.edge"
        static let EVENT_HANDLE = "type"
        static let EVENT_HANDLE_TYPE_PERSONALIZATION = "personalization:decisions"
        static let PAYLOAD = "payload"
        enum ErrorKeys {
            static let TYPE = "type"
            static let DETAIL = "detail"
        }
    }

    enum Configuration {
        static let EXTENSION_NAME = "com.adobe.module.configuration"
        static let OPTIMIZE_OVERRIDE_DATASET_ID = "optimize.datasetId"
    }

    enum JsonKeys {
        static let DECISION_SCOPES = "decisionScopes"
        static let XDM = "xdm"
        static let QUERY = "query"
        static let QUERY_PERSONALIZATION = "personalization"
        static let DATA = "data"
        static let DATASET_ID = "datasetId"
        static let EXPERIENCE_EVENT_TYPE = "eventType"
        static let EXPERIENCE = "_experience"
        static let EXPERIENCE_DECISIONING = "decisioning"
        static let DECISIONING_PROPOSITION_ID = "propositionID"
        static let DECISIONING_PROPOSITIONS = "propositions"
        static let DECISIONING_PROPOSITIONS_ID = "id"
        static let DECISIONING_PROPOSITIONS_SCOPE = "scope"
        static let DECISIONING_PROPOSITIONS_SCOPEDETAILS = "scopeDetails"
        static let DECISIONING_PROPOSITIONS_ITEMS = "items"
        static let DECISIONING_PROPOSITIONS_ITEMS_ID = "id"
    }

    enum JsonValues {
        static let EE_EVENT_TYPE_PERSONALIZATION = "personalization.request"
        static let EE_EVENT_TYPE_PROPOSITION_DISPLAY = "decisioning.propositionDisplay"
        static let EE_EVENT_TYPE_PROPOSITION_INTERACT = "decisioning.propositionInteract"
    }
}
