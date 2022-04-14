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

import AEPCore
import AEPServices
import Foundation

extension Event {
    // MARK: - In-app Message Consequence Event Handling

    // MARK: Internal

    var isInAppMessage: Bool {
        consequenceType == MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE
    }

    // MARK: In-app Message Properties

    /// Grabs the messageExecutionID value from XDM
    var messageId: String? {
        xdmMessageExecution?[MessagingConstants.XDM.AdobeKeys.MESSAGE_EXECUTION_ID] as? String
    }

    var template: String? {
        details?[MessagingConstants.Event.Data.Key.IAM.TEMPLATE] as? String
    }

    var html: String? {
        details?[MessagingConstants.Event.Data.Key.IAM.HTML] as? String
    }

    var remoteAssets: [String]? {
        details?[MessagingConstants.Event.Data.Key.IAM.REMOTE_ASSETS] as? [String]
    }

    /// Returns the `_experience` dictionary from the `_xdm.mixins` object for Experience Event tracking
    var experienceInfo: [String: Any]? {
        guard let xdm = details?[MessagingConstants.XDM.AdobeKeys._XDM] as? [String: Any],
              let xdmMixins = xdm[MessagingConstants.XDM.AdobeKeys.MIXINS] as? [String: Any]
        else {
            return nil
        }

        return xdmMixins[MessagingConstants.XDM.AdobeKeys.EXPERIENCE] as? [String: Any]
    }

    /*
     "mobileParameters": {
     "schemaVersion": "1.0",
     "width": 80,
     "height": 50,
     "verticalAlign": "center",
     "verticalInset": 0,
     "horizontalAlign": "center",
     "horizontalInset": 0,
     "uiTakeover": true,
     "displayAnimation": "top",
     "dismissAnimation": "top",
     "backdropColor": "000000",    // RRGGBB
     "backdropOpacity: 0.3,
     "cornerRadius": 15,
     "gestures": {
     "swipeUp": "adbinapp://dismiss",
     "swipeDown": "adbinapp://dismiss",
     "swipeLeft": "adbinapp://dismiss?interaction=negative",
     "swipeRight": "adbinapp://dismiss?interaction=positive",
     "tapBackground": "adbinapp://dismiss"
     }
     }
     */
    func getMessageSettings(withParent parent: Any?) -> MessageSettings {
        let settings = MessageSettings(parent: parent)
            .setWidth(messageWidth)
            .setHeight(messageHeight)
            .setVerticalAlign(messageVAlign)
            .setVerticalInset(messageVInset)
            .setHorizontalAlign(messageHAlign)
            .setHorizontalInset(messageHInset)
            .setUiTakeover(messageUiTakeover)
            .setBackdropColor(messageBackdropColor)
            .setBackdropOpacity(messageBackdropOpacity)
            .setCornerRadius(messageCornerRadius != nil ? CGFloat(messageCornerRadius ?? 0) : nil)
            .setDisplayAnimation(messageDisplayAnimation)
            .setDismissAnimation(messageDismissAnimation)
            .setGestures(messageGestures)

        return settings
    }

    private var mobileParametersDictionary: [String: Any]? {
        details?[MessagingConstants.Event.Data.Key.IAM.MOBILE_PARAMETERS] as? [String: Any]
    }

    private var messageWidth: Int? {
        mobileParametersDictionary?[MessagingConstants.Event.Data.Key.IAM.WIDTH] as? Int
    }

    private var messageHeight: Int? {
        mobileParametersDictionary?[MessagingConstants.Event.Data.Key.IAM.HEIGHT] as? Int
    }

    private var messageVAlign: MessageAlignment {
        if let alignmentString = mobileParametersDictionary?[MessagingConstants.Event.Data.Key.IAM.VERTICAL_ALIGN] as? String {
            return MessageAlignment.fromString(alignmentString)
        }

        return .center
    }

    private var messageVInset: Int? {
        mobileParametersDictionary?[MessagingConstants.Event.Data.Key.IAM.VERTICAL_INSET] as? Int
    }

    private var messageHAlign: MessageAlignment {
        if let alignmentString = mobileParametersDictionary?[MessagingConstants.Event.Data.Key.IAM.HORIZONTAL_ALIGN] as? String {
            return MessageAlignment.fromString(alignmentString)
        }

        return .center
    }

    private var messageHInset: Int? {
        mobileParametersDictionary?[MessagingConstants.Event.Data.Key.IAM.HORIZONTAL_INSET] as? Int
    }

    private var messageUiTakeover: Bool {
        if let takeover = mobileParametersDictionary?[MessagingConstants.Event.Data.Key.IAM.UI_TAKEOVER] as? Bool {
            return takeover
        }

        return true
    }

    private var messageBackdropColor: String? {
        mobileParametersDictionary?[MessagingConstants.Event.Data.Key.IAM.BACKDROP_COLOR] as? String
    }

    private var messageBackdropOpacity: CGFloat? {
        if let opacity = mobileParametersDictionary?[MessagingConstants.Event.Data.Key.IAM.BACKDROP_OPACITY] as? Double {
            return CGFloat(opacity)
        }

        return nil
    }

    private var messageCornerRadius: Int? {
        mobileParametersDictionary?[MessagingConstants.Event.Data.Key.IAM.CORNER_RADIUS] as? Int
    }

    private var messageDisplayAnimation: MessageAnimation {
        if let animate = mobileParametersDictionary?[MessagingConstants.Event.Data.Key.IAM.DISPLAY_ANIMATION] as? String {
            return MessageAnimation.fromString(animate)
        }

        return .none
    }

    private var messageDismissAnimation: MessageAnimation {
        if let animate = mobileParametersDictionary?[MessagingConstants.Event.Data.Key.IAM.DISMISS_ANIMATION] as? String {
            return MessageAnimation.fromString(animate)
        }

        return .none
    }

    private var messageGestures: [MessageGesture: URL]? {
        if let gesturesJson = mobileParametersDictionary?[MessagingConstants.Event.Data.Key.IAM.GESTURES] as? [String: String] {
            var gestures: [MessageGesture: URL] = [:]
            for gesture in gesturesJson {
                if let gestureEnum = MessageGesture.fromString(gesture.key), let url = URL(string: gesture.value) {
                    gestures[gestureEnum] = url
                }
            }

            return gestures.isEmpty ? nil : gestures
        }

        return nil
    }

    // MARK: Message Object Validation

    var containsValidInAppMessage: Bool {
        // remoteAssets are always optional.
        // template is currently optional as it's not being used,
        // but may be used later if new kinds of messages are introduced
        html != nil
    }

    // MARK: Private

    // MARK: Consequence EventData Processing

    private var consequence: [String: Any]? {
        data?[MessagingConstants.Event.Data.Key.TRIGGERED_CONSEQUENCE] as? [String: Any]
    }

    private var consequenceType: String? {
        consequence?[MessagingConstants.Event.Data.Key.TYPE] as? String
    }

    private var details: [String: Any]? {
        consequence?[MessagingConstants.Event.Data.Key.DETAIL] as? [String: Any]
    }

    // MARK: - AEP Response Event Handling

    // MARK: Public

    var isPersonalizationDecisionResponse: Bool {
        isEdgeType && isPersonalizationSource
    }

    var offerActivityId: String? {
        activity?[MessagingConstants.Event.Data.Key.Optimize.ID] as? String
    }

    var offerPlacementId: String? {
        placement?[MessagingConstants.Event.Data.Key.Optimize.ID] as? String
    }

    var offerDecisionScope: String? {
        guard let payload = payload, !payload.isEmpty else {
            return nil
        }

        guard let b64EncodedScope = payload.first?[MessagingConstants.Event.Data.Key.Optimize.SCOPE] as? String else {
            return nil
        }

        guard let scopeData = Data(base64Encoded: b64EncodedScope), let scopeDictionary = try? JSONSerialization.jsonObject(with: scopeData, options: .mutableContainers) as? [String: Any] else {
            return nil
        }

        return scopeDictionary[MessagingConstants.Event.Data.Key.Optimize.XDM_NAME] as? String
    }

    /// each entry in the array represents "content" from an offer, which contains a rule
    var rulesJson: [String]? {
        guard let items = items else {
            return nil
        }

        var rules: [String] = []
        for item in items {
            guard let data = item[MessagingConstants.Event.Data.Key.Optimize.DATA] as? [String: Any] else {
                continue
            }
            if let content = data[MessagingConstants.Event.Data.Key.Optimize.CONTENT] as? String {
                rules.append(content)
            }
        }

        return rules.isEmpty ? nil : rules
    }

    // MARK: Private

    private var isEdgeType: Bool {
        type == EventType.edge
    }

    private var isPersonalizationSource: Bool {
        source == MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS
    }

    /// payload is an array of dictionaries, but since we are only asking for a single DecisionScope
    /// in the messaging sdk, we can assume this array will only have 0-1 items
    private var payload: [[String: Any]]? {
        data?[MessagingConstants.Event.Data.Key.Optimize.PAYLOAD] as? [[String: Any]]
    }

    private var activity: [String: Any]? {
        guard let payload = payload, !payload.isEmpty else {
            return nil
        }

        return payload[0][MessagingConstants.Event.Data.Key.Optimize.ACTIVITY] as? [String: Any]
    }

    private var placement: [String: Any]? {
        guard let payload = payload, !payload.isEmpty else {
            return nil
        }

        return payload[0][MessagingConstants.Event.Data.Key.Optimize.PLACEMENT] as? [String: Any]
    }

    private var items: [[String: Any]]? {
        guard let payload = payload, !payload.isEmpty else {
            return nil
        }

        return payload[0][MessagingConstants.Event.Data.Key.Optimize.ITEMS] as? [[String: Any]]
    }

    private var xdmCustomerJourneyManagement: [String: Any]? {
        guard let experienceInfo = experienceInfo else {
            return nil
        }

        return experienceInfo[MessagingConstants.XDM.AdobeKeys.CUSTOMER_JOURNEY_MANAGEMENT] as? [String: Any]
    }

    private var xdmMessageExecution: [String: Any]? {
        guard let xdmCustomerJourneyManagement = xdmCustomerJourneyManagement else {
            return nil
        }

        return xdmCustomerJourneyManagement[MessagingConstants.XDM.AdobeKeys.MESSAGE_EXECUTION] as? [String: Any]
    }

    // MARK: Refresh Messages Public API Event

    var isRefreshMessageEvent: Bool {
        isMessagingType && isRequestContentSource && refreshMessages
    }

    private var isMessagingType: Bool {
        type == MessagingConstants.Event.EventType.messaging
    }

    private var isRequestContentSource: Bool {
        source == EventSource.requestContent
    }

    private var refreshMessages: Bool {
        data?[MessagingConstants.Event.Data.Key.REFRESH_MESSAGES] as? Bool ?? false
    }

    /// Returns true if this event is a generic identity request content event
    var isGenericIdentityRequestContentEvent: Bool {
        type == EventType.genericIdentity && source == EventSource.requestContent
    }

    var token: String? {
        data?[MessagingConstants.Event.Data.Key.PUSH_IDENTIFIER] as? String
    }

    var xdmEventType: String? {
        data?[MessagingConstants.Event.Data.Key.EVENT_TYPE] as? String
    }

    var messagingId: String? {
        data?[MessagingConstants.Event.Data.Key.MESSAGE_ID] as? String
    }

    var actionId: String? {
        data?[MessagingConstants.Event.Data.Key.ACTION_ID] as? String
    }

    var applicationOpened: Bool {
        data?[MessagingConstants.Event.Data.Key.APPLICATION_OPENED] as? Bool ?? false
    }

    var mixins: [String: Any]? {
        adobeXdm?[MessagingConstants.XDM.AdobeKeys.MIXINS] as? [String: Any]
    }

    var cjm: [String: Any]? {
        adobeXdm?[MessagingConstants.XDM.AdobeKeys.CJM] as? [String: Any]
    }

    var adobeXdm: [String: Any]? {
        data?[MessagingConstants.XDM.Key.ADOBE_XDM] as? [String: Any]
    }

    var isMessagingRequestContentEvent: Bool {
        type == MessagingConstants.Event.EventType.messaging && source == EventSource.requestContent
    }
}
