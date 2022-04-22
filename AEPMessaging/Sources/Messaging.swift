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

@objc(AEPMobileMessaging)
public class Messaging: NSObject, Extension {
    // MARK: - Class members

    public static var extensionVersion: String = MessagingConstants.EXTENSION_VERSION
    public var name = MessagingConstants.EXTENSION_NAME
    public var friendlyName = MessagingConstants.FRIENDLY_NAME
    public var metadata: [String: String]?
    public var runtime: ExtensionRuntime

    private var initialLoadComplete = false
    private(set) var currentMessage: Message?
    private let rulesEngine: MessagingRulesEngine

    // MARK: - Extension protocol methods

    public required init?(runtime: ExtensionRuntime) {
        self.runtime = runtime
        rulesEngine = MessagingRulesEngine(name: MessagingConstants.RULES_ENGINE_NAME,
                                           extensionRuntime: runtime)

        super.init()
    }

    /// INTERNAL ONLY
    /// used for testing
    init(runtime: ExtensionRuntime, rulesEngine: MessagingRulesEngine) {
        self.runtime = runtime
        self.rulesEngine = rulesEngine

        super.init()
    }

    public func onRegistered() {
        // register listener for set push identifier event
        registerListener(type: EventType.genericIdentity,
                         source: EventSource.requestContent,
                         listener: handleProcessEvent)

        // register listener for Messaging request content event
        registerListener(type: MessagingConstants.Event.EventType.messaging,
                         source: EventSource.requestContent,
                         listener: handleProcessEvent)

        // register wildcard listener for messaging rules engine
        registerListener(type: EventType.wildcard,
                         source: EventSource.wildcard,
                         listener: handleWildcardEvent)

        // register listener for rules consequences with in-app messages
        registerListener(type: EventType.rulesEngine,
                         source: EventSource.responseContent,
                         listener: handleRulesResponse)

        // register listener for offer notifications
        registerListener(type: EventType.edge,
                         source: MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS,
                         listener: handleOfferNotification)
    }

    public func onUnregistered() {
        Log.debug(label: MessagingConstants.LOG_TAG, "Extension unregistered from MobileCore: \(MessagingConstants.FRIENDLY_NAME)")
    }

    public func readyForEvent(_ event: Event) -> Bool {
        guard let configurationSharedState = getSharedState(extensionName: MessagingConstants.SharedState.Configuration.NAME, event: event),
              configurationSharedState.status == .set
        else {
            Log.trace(label: MessagingConstants.LOG_TAG, "Event processing is paused - waiting for valid configuration.")
            return false
        }

        // hard dependency on edge identity module for ecid
        guard let edgeIdentitySharedState = getXDMSharedState(extensionName: MessagingConstants.SharedState.EdgeIdentity.NAME, event: event),
              edgeIdentitySharedState.status == .set
        else {
            Log.trace(label: MessagingConstants.LOG_TAG, "Event processing is paused - waiting for valid XDM shared state from Edge Identity extension.")
            return false
        }

        // once we have valid configuration, fetch message definitions from offers if we haven't already
        if !initialLoadComplete {
            initialLoadComplete = true
            fetchMessages()
        }

        return true
    }

    // MARK: - In-app Messaging methods

    /// Called on every event, used to allow processing of the Messaging rules engine
    private func handleWildcardEvent(_ event: Event) {
        rulesEngine.process(event: event)
    }

    /// Generates and dispatches an event prompting the Personalization extension to fetch in-app messages.
    /// If the config contains both an activity and a placement (retrieved from the app's plist), use that
    /// decision scope.  Otherwise, use the bundleIdentifier for the app.
    private func fetchMessages() {
        var decisionScope = ""
        let offersConfig = getOffersMessageConfig()

        // check for activity and placement provided by info.plist
        if let activityId = offersConfig.0, let placementId = offersConfig.1 {
            Log.trace(label: MessagingConstants.LOG_TAG, "Fetching messages using ActivityID (\(activityId)) and PlacementID (\(placementId)) values found in Info.plist.")
            decisionScope = getEncodedDecisionScopeFor(activityId: activityId, placementId: placementId)
        } else if let bundleIdentifier = offersConfig.1 {
            Log.trace(label: MessagingConstants.LOG_TAG, "Fetching messages using BundleIdentifier (\(bundleIdentifier)).")
            decisionScope = getEncodedDecisionScopeFor(bundleIdentifier: bundleIdentifier)
        }

        // create event to be handled by optimize
        let optimizeData: [String: Any] = [
            MessagingConstants.Event.Data.Key.Optimize.REQUEST_TYPE: MessagingConstants.Event.Data.Values.Optimize.UPDATE_PROPOSITIONS,
            MessagingConstants.Event.Data.Key.Optimize.DECISION_SCOPES: [
                [
                    MessagingConstants.Event.Data.Key.Optimize.NAME: "\(decisionScope)"
                ]
            ]
        ]
        let event = Event(name: MessagingConstants.Event.Name.RETRIEVE_MESSAGE_DEFINITIONS,
                          type: EventType.optimize,
                          source: EventSource.requestContent,
                          data: optimizeData)

        // send event
        runtime.dispatch(event: event)
    }

    /// Validates that the received event contains in-app message definitions and loads them in the `MessagingRulesEngine`.
    /// - Parameter event: an `Event` containing an in-app message definition in its data
    private func handleOfferNotification(_ event: Event) {
        // validate the event
        guard event.isPersonalizationDecisionResponse else {
            return
        }

        let offersConfig = getOffersMessageConfig()

        // validate that the offer contains messages by either matching the activity/placement from plist or bundle id
        if let activityId = offersConfig.0, let placementId = offersConfig.1 {
            guard event.offerActivityId == activityId, event.offerPlacementId == placementId else {
                // no need to log here, as this case will be common if the app is using the optimize extension outside
                // of in-app messaging
                return
            }
        } else if let bundleIdentifier = offersConfig.1 {
            guard bundleIdentifier == event.offerDecisionScope else {
                // no need to log here, as this case will be common if the app is using the optimize extension outside
                // of in-app messaging
                return
            }
        } else {
            Log.warning(label: MessagingConstants.LOG_TAG, "Unable to handle Offer notification - an unknown error has occurred.")
            return
        }

        guard let messages = event.rulesJson,
              let json = event.rulesJson?.first,
              json != MessagingConstants.XDM.IAM.Value.EMPTY_CONTENT
        else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Empty content returned in call to retrieve in-app messages.")
            rulesEngine.clearMessagingCache()
            return
        }

        rulesEngine.setMessagingCache(messages)
        Log.trace(label: MessagingConstants.LOG_TAG, "Loading in-app message definition from network response.")
        rulesEngine.loadRules(rules: messages)
    }

    /// Handles Rules Consequence events containing message definitions.
    private func handleRulesResponse(_ event: Event) {
        if event.data == nil {
            Log.warning(label: MessagingConstants.LOG_TAG, "Unable to process a Rules Consequence Event. Event data is null.")
            return
        }

        if event.isInAppMessage, event.containsValidInAppMessage {
            showMessageForEvent(event)
        } else {
            Log.warning(label: MessagingConstants.LOG_TAG, "Unable to process In-App Message - html property is required.")
            return
        }
    }

    /// Creates and shows a fullscreen message as defined by the contents of the provided `Event`'s data.
    /// - Parameter event: the `Event` containing data necessary to create the message and report on it
    private func showMessageForEvent(_ event: Event) {
        guard event.html != nil else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Unable to show message for event \(event.id) - it contains no HTML defining the message.")
            return
        }

        guard event.experienceInfo != nil else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Ignoring message that does not contain information necessary for tracking with Adobe Journey Optimizer.")
            return
        }

        currentMessage = Message(parent: self, event: event)

        currentMessage?.trigger()
        currentMessage?.show()
    }

    /// Takes an activity and placement and returns an encoded string in the format expected
    /// by the Optimize extension for retrieving offers by activity and placement.
    ///
    /// If encoding of the decision scope fails, empty string will be returned.
    ///
    /// - Parameters:
    ///   - activityId: the activityId for the decision scope
    ///   - placementId: the placementId for the decision scope
    /// - Returns: a base64 encoded JSON string to be used by the Optimize extension
    private func getEncodedDecisionScopeFor(activityId: String, placementId: String) -> String {
        let decisionScopeString = "{\"activityId\":\"\(activityId)\",\"placementId\":\"\(placementId)\",\"itemCount\":\(MessagingConstants.DefaultValues.Optimize.MAX_ITEM_COUNT)}"

        guard let decisionScopeData = decisionScopeString.data(using: .utf8) else {
            return ""
        }

        return decisionScopeData.base64EncodedString()
    }

    /// Takes a bundle identifier and returns an encoded string in the format expected
    /// by the Optimize extension for retrieving offers by xdm:name.
    ///
    /// If encoding of the decision scope fails, empty string will be returned.
    ///
    /// - Parameters:
    ///   - bundleIdentifier: the bundleIdentifier of the app
    /// - Returns: a base64 encoded JSON string to be used by the Optimize extension
    private func getEncodedDecisionScopeFor(bundleIdentifier: String) -> String {
        let decisionScopeString = "{\"\(MessagingConstants.Event.Data.Key.Optimize.XDM_NAME)\":\"\(bundleIdentifier)\"}"

        guard let decisionScopeData = decisionScopeString.data(using: .utf8) else {
            return ""
        }

        return decisionScopeData.base64EncodedString()
    }

    /// Retrieves the correct configuration to retrieve in-app messages from offers
    ///
    /// If an activityId/placementId are in the plist, those values will be used to generate the decision scope.
    /// Otherwise, the bundle identifier will be used to generate the decision scope.
    ///
    /// - Returns: a tuple containing either (nil, bundleIdentifier) or (activityId, placementId)
    private func getOffersMessageConfig() -> (String?, String?) {
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"), let plistDictionary = NSDictionary(contentsOfFile: path) {
            guard let activity = plistDictionary.value(forKey: MessagingConstants.IAM.Plist.ACTIVITY_ID) as? String,
                  let placement = plistDictionary.value(forKey: MessagingConstants.IAM.Plist.PLACEMENT_ID) as? String
            else {
                return (nil, Bundle.main.bundleIdentifier)
            }
            return (activity, placement)
        }

        return (nil, Bundle.main.bundleIdentifier)
    }

    // MARK: - Event Handers

    /// Processes the events in the event queue in the order they were received.
    ///
    /// A valid `Configuration` and `EdgeIdentity` shared state is required for processing events.
    ///
    /// - Parameters:
    ///   - event: An `Event` to be processed
    func handleProcessEvent(_ event: Event) {
        if event.data == nil {
            Log.debug(label: MessagingConstants.LOG_TAG, "Process event handling ignored as event does not have any data - `\(event.id)`.")
            return
        }

        // hard dependency on configuration shared state
        guard let configSharedState = getSharedState(extensionName: MessagingConstants.SharedState.Configuration.NAME, event: event)?.value else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Event processing is paused, waiting for valid configuration - '\(event.id.uuidString)'.")
            return
        }

        // handle an event for refreshing in-app messages from the remote
        if event.isRefreshMessageEvent {
            Log.debug(label: MessagingConstants.LOG_TAG, "Processing manual request to refresh In-App Message definitions from the remote.")
            fetchMessages()
            return
        }

        // hard dependency on edge identity module for ecid
        guard let edgeIdentitySharedState = getXDMSharedState(extensionName: MessagingConstants.SharedState.EdgeIdentity.NAME, event: event)?.value else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Event processing is paused, for valid xdm shared state from edge identity - '\(event.id.uuidString)'.")
            return
        }

        if event.isGenericIdentityRequestContentEvent {
            guard let token = event.token, !token.isEmpty else {
                Log.debug(label: MessagingConstants.LOG_TAG, "Ignoring event with missing or invalid push identifier - '\(event.id.uuidString)'.")
                return
            }

            // If the push token is valid update the shared state.
            runtime.createSharedState(data: [MessagingConstants.SharedState.Messaging.PUSH_IDENTIFIER: token], event: event)

            // get identityMap from the edge identity xdm shared state
            guard let identityMap = edgeIdentitySharedState[MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP] as? [AnyHashable: Any] else {
                Log.warning(label: MessagingConstants.LOG_TAG, "Cannot process event that identity map is not available" +
                                "from edge identity xdm shared state - '\(event.id.uuidString)'.")
                return
            }

            // get the ECID array from the identityMap
            guard let ecidArray = identityMap[MessagingConstants.SharedState.EdgeIdentity.ECID] as? [[AnyHashable: Any]],
                  !ecidArray.isEmpty, let ecid = ecidArray[0][MessagingConstants.SharedState.EdgeIdentity.ID] as? String,
                  !ecid.isEmpty
            else {
                Log.warning(label: MessagingConstants.LOG_TAG, "Cannot process event as ecid is not available in the identity map - '\(event.id.uuidString)'.")
                return
            }

            sendPushToken(ecid: ecid, token: token, platform: getPushPlatform(forEvent: event))
        }

        // Check if the event type is `MessagingConstants.Event.EventType.messaging` and
        // eventSource is `EventSource.requestContent` handle processing of the tracking information
        if event.isMessagingRequestContentEvent, configSharedState.keys.contains(MessagingConstants.SharedState.Configuration.EXPERIENCE_EVENT_DATASET) {
            handleTrackingInfo(event: event)
            return
        }
    }
}
