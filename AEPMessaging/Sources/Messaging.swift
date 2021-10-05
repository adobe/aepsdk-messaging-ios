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
    // =================================================================================================================
    // MARK: - Class members
    // =================================================================================================================
    public static var extensionVersion: String = MessagingConstants.EXTENSION_VERSION
    public var name = MessagingConstants.EXTENSION_NAME
    public var friendlyName = MessagingConstants.FRIENDLY_NAME
    public var metadata: [String: String]?
    public var runtime: ExtensionRuntime

    private var initialLoadComplete = false
    private var currentMessage: Message?
    private let messagingHandler = MessagingHandler()
    private let rulesEngine: MessagingRulesEngine

    // =================================================================================================================
    // MARK: - Extension protocol methods
    // =================================================================================================================
    public required init?(runtime: ExtensionRuntime) {
        self.runtime = runtime
        self.rulesEngine = MessagingRulesEngine(name: MessagingConstants.RULES_ENGINE_NAME,
                                                extensionRuntime: runtime)

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
              configurationSharedState.status == .set else {
            Log.trace(label: MessagingConstants.LOG_TAG, "Event processing is paused - waiting for valid configuration.")
            return false
        }

        // hard dependency on edge identity module for ecid
        guard let edgeIdentitySharedState = getXDMSharedState(extensionName: MessagingConstants.SharedState.EdgeIdentity.NAME, event: event),
              edgeIdentitySharedState.status == .set else {
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

    // =================================================================================================================
    // MARK: - In-app Messaging methods
    // =================================================================================================================

    /// Called on every event, used to allow processing of the Messaging rules engine
    private func handleWildcardEvent(_ event: Event) {
        rulesEngine.process(event: event)
    }

    /// Generates and dispatches an event prompting the Personalization extension to fetch in-app messages.
    private func fetchMessages() {
        // activity and placement are both required for message definition retrieval
        let offersConfig = getActivityAndPlacement()
        guard let activityId = offersConfig.0, let placementId = offersConfig.1 else {
            Log.trace(label: MessagingConstants.LOG_TAG, "Unable to retrieve message definitions - activity and placement ids are both required.")
            return
        }

        // create event to be handled by optimize
        guard let decisionScope = getEncodedDecisionScopeFor(activityId: activityId, placementId: placementId) else {
            Log.trace(label: MessagingConstants.LOG_TAG, "Unable to retrieve message definitions - error encoding the decision scope.")
            return
        }

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
        if !event.isPersonalizationDecisionResponse {
            return
        }

        let offersConfig = getActivityAndPlacement(forEvent: event)
        let activityId = offersConfig.0
        let placementId = offersConfig.1

        if event.offerActivityId != activityId || event.offerPlacementId != placementId {
            return
        }
        
        guard let json = event.rulesJson?.first, json != MessagingConstants.XDM.IAM.Value.EMPTY_CONTENT else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Empty content returned in call to retrieve in-app messages.")
            return
        }

        rulesEngine.loadRules(rules: event.rulesJson)
    }

    /// Handles Rules Consequence events containing message definitions.
    private func handleRulesResponse(_ event: Event) {
        if event.data == nil {
            Log.warning(label: MessagingConstants.LOG_TAG, "Unable to process a Rules Consequence Event. Event data is null.")
            return
        }

        if event.isInAppMessage && event.containsValidInAppMessage {
            showMessageForEvent(event)
        } else {
            Log.warning(label: MessagingConstants.LOG_TAG, "Unable to process In-App Message - template and html properties are required.")
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
    /// by the Optimize extension for retrieving offers
    ///
    /// - Parameters:
    ///   - activityId: the activityId for the decision scope
    ///   - placementId: the placementId for the decision scope
    /// - Returns: a base64 encoded JSON string to be used by the Optimize extension
    private func getEncodedDecisionScopeFor(activityId: String, placementId: String) -> String? {
        let decisionScopeString = "{\"activityId\":\"\(activityId)\",\"placementId\":\"\(placementId)\",\"itemCount\":\(MessagingConstants.DefaultValues.Optimize.MAX_ITEM_COUNT)}"

        guard let decisionScopeData = decisionScopeString.data(using: .utf8) else {
            return nil
        }

        return decisionScopeData.base64EncodedString()
    }

    /// Retrieves the activityId and placementId used to request the correct in-app messages from offers
    ///
    /// The decision scope for the offer that contains the correct in-app messages for this user is created by
    /// combining the IMS Org ID for the activity and the app's bundle identifier for the placement.
    ///
    /// - Parameters:
    ///   - event: the `Event` used for getting configuration shared state
    /// - Returns: a tuple containing (activityId, placementId) needed to generate the correct decision scope
    private func getActivityAndPlacement(forEvent event: Event? = nil) -> (String?, String?) {
        // activityId = IMS OrgID
        let configuration = getSharedState(extensionName: MessagingConstants.SharedState.Configuration.NAME, event: event)?.value
        let orgId = configuration?[MessagingConstants.SharedState.Configuration.EXPERIENCE_CLOUD_ORG] as? String

        var activity: String? = orgId

        // placementId = bundle identifier
        var placement = Bundle.main.bundleIdentifier

        // TODO: remove the temp code here prior to release
        // hack to allow overriding of activity and placement from plist
        var nsDictionary: NSDictionary?
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            nsDictionary = NSDictionary(contentsOfFile: path)
            activity = nsDictionary?.value(forKey: "MESSAGING_ACTIVITY_ID") as? String
            placement = nsDictionary?.value(forKey: "MESSAGING_PLACEMENT_ID") as? String
        }

        return (activity, placement)
    }

    // =================================================================================================================
    // MARK: - Event Handers
    // =================================================================================================================

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
                  !ecid.isEmpty else {
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
