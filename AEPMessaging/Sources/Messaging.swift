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
    // MARK: - Messaging State
    
    var propositions: [Surface: [Proposition]] = [:]
    var propositionInfo: [String: PropositionInfo] = [:]
    var inboundMessages: [Surface: [Inbound]] = [:]
    var cache: Cache = Cache(name: MessagingConstants.Caches.CACHE_NAME)
    
    private var messagesRequestEventId: String = ""
    private var lastProcessedRequestEventId: String = ""
    private var initialLoadComplete = false
    let rulesEngine: MessagingRulesEngine
    let feedRulesEngine: FeedRulesEngine
    
    private var requestedSurfacesforEventId: [String: [Surface]] = [:]

    /// Array containing the schema strings for the proposition items supported by the SDK, sent in the personalization query request.
    static let supportedSchemas = [
        MessagingConstants.XDM.Inbound.Value.SCHEMA_AJO_HTML,
        MessagingConstants.XDM.Inbound.Value.SCHEMA_AJO_JSON
    ]

    // MARK: - Extension protocol methods

    public required init?(runtime: ExtensionRuntime) {
        self.runtime = runtime
        MessagingMigrator.migrate(cache: cache)
        rulesEngine = MessagingRulesEngine(name: MessagingConstants.RULES_ENGINE_NAME, extensionRuntime: runtime, cache: cache)
        feedRulesEngine = FeedRulesEngine(name: MessagingConstants.FEED_RULES_ENGINE_NAME, extensionRuntime: runtime)
        super.init()
        loadCachedPropositions()
    }

    /// INTERNAL ONLY
    /// used for testing
    init(runtime: ExtensionRuntime, rulesEngine: MessagingRulesEngine, feedRulesEngine: FeedRulesEngine, expectedSurfaceUri _: String) {
        self.runtime = runtime
        self.rulesEngine = rulesEngine
        self.feedRulesEngine = feedRulesEngine
        super.init()
        loadCachedPropositions()
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

        // register listener for edge personalization notifications
        registerListener(type: EventType.edge,
                         source: MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS,
                         listener: handleEdgePersonalizationNotification)
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

    /// Generates and dispatches an event prompting the Edge extension to fetch in-app or feed messages or code-based experiences.
    ///
    /// The surface URIs used in the request are generated using the `bundleIdentifier` for the app.
    /// If the `bundleIdentifier` is unavailable, calling this method will do nothing.
    ///
    /// - Parameter surfacePaths: an array of surface path strings for fetching feed messages, if available.
    private func fetchMessages(for surfaces: [Surface]? = nil) {
        var requestedSurfaces: [Surface] = []
        if let surfaces = surfaces {
            requestedSurfaces = surfaces
                .filter { $0.isValid }

            guard !requestedSurfaces.isEmpty else {
                Log.debug(label: MessagingConstants.LOG_TAG, "Unable to update messages, no valid surfaces found.")
                return
            }
        } else {
            guard appSurface != "unknown" else {
                Log.warning(label: MessagingConstants.LOG_TAG, "Unable to update messages, cannot read the bundle identifier.")
                return
            }
            requestedSurfaces = [Surface(uri: appSurface)]
        }

        var eventData: [String: Any] = [:]

        let messageRequestData: [String: Any] = [
            MessagingConstants.XDM.Inbound.Key.PERSONALIZATION: [
                MessagingConstants.XDM.Inbound.Key.SCHEMAS: Messaging.supportedSchemas,
                MessagingConstants.XDM.Inbound.Key.SURFACES: requestedSurfaces.compactMap { $0.uri }
            ]
        ]
        eventData[MessagingConstants.XDM.Inbound.Key.QUERY] = messageRequestData

        let xdmData: [String: Any] = [
            MessagingConstants.XDM.Key.EVENT_TYPE: MessagingConstants.XDM.Inbound.EventType.PERSONALIZATION_REQUEST
        ]
        eventData[MessagingConstants.XDM.Key.XDM] = xdmData

        let event = Event(name: MessagingConstants.Event.Name.RETRIEVE_MESSAGE_DEFINITIONS,
                          type: EventType.edge,
                          source: EventSource.requestContent,
                          data: eventData)

        // equal to `requestEventId` in aep response handles
        // used for ensuring that the messaging extension is responding to the correct handle
        messagesRequestEventId = event.id.uuidString
        requestedSurfacesforEventId[messagesRequestEventId] = requestedSurfaces

        // send event
        runtime.dispatch(event: event)
    }

    private func retrieveMessages(for surfaces: [Surface], event: Event) {
        let requestedSurfaces = surfaces
            .filter { $0.isValid }

        guard !requestedSurfaces.isEmpty else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Unable to retrieve feed messages, no valid surface paths found.")
            dispatch(event: event.createErrorResponseEvent(AEPError.invalidRequest))
            return
        }

        if let inboundMessages = feedRulesEngine.evaluate(event: event) {
            messagingState.updateInboundMessages(inboundMessages, surfaces: requestedSurfaces)
        }

        let requestedPropositions = retrievePropositions(surfaces: requestedSurfaces)
        let eventData = [MessagingConstants.Event.Data.Key.PROPOSITIONS: requestedPropositions.flatMap { $0.value }].asDictionary()

        let responseEvent = event.createResponseEvent(
            name: MessagingConstants.Event.Name.MESSAGE_PROPOSITIONS_RESPONSE,
            type: EventType.messaging,
            source: EventSource.responseContent,
            data: eventData
        )
        dispatch(event: responseEvent)
    }

    var appSurface: String {
        Bundle.main.mobileappSurface
    }

    /// Validates that the received event contains in-app message definitions and loads them in the `MessagingRulesEngine`.
    /// - Parameter event: an `Event` containing an in-app message definition in its data
    private func handleEdgePersonalizationNotification(_ event: Event) {
        // validate the event
        guard event.isPersonalizationDecisionResponse, event.requestEventId == messagesRequestEventId else {
            // either this isn't the type of response we are waiting for, or it's not a response for our request
            return
        }

        // if this is an event for a new request, purge cache and update lastProcessedRequestEventId
        var clearExistingRules = false
        if lastProcessedRequestEventId != event.requestEventId {
            clearExistingRules = true
            lastProcessedRequestEventId = event.requestEventId ?? ""
        }

        // parse and load message rules
        Log.trace(label: MessagingConstants.LOG_TAG, "Loading message definitions from personalization:decisions network response.")
        let requestedSurfaces = requestedSurfacesforEventId[messagesRequestEventId] ?? []
        let propositions = event.payload
        let rules = parsePropositions(propositions, expectedSurfaces: requestedSurfaces, clearExisting: clearExistingRules)

        if let inAppRules = rules[InboundType.inapp] {
            Log.trace(label: MessagingConstants.LOG_TAG, "The personalization:decisions response contains InApp message definitions.")
            rulesEngine.launchRulesEngine.loadRules(inAppRules, clearExisting: clearExistingRules)
        }

        if let feedItemRules = rules[InboundType.feed] {
            Log.trace(label: MessagingConstants.LOG_TAG, "The personalization:decisions response contains feed message definitions.")
            feedRulesEngine.launchRulesEngine.loadRules(feedItemRules, clearExisting: clearExistingRules)
            if let inboundMessages = feedRulesEngine.evaluate(event: event) {
                messagingState.updateInboundMessages(inboundMessages, surfaces: requestedSurfaces)
            }
        }

        let requestedPropositions = retrievePropositions(surfaces: requestedSurfaces)
        guard !requestedPropositions.isEmpty else {
            Log.trace(label: MessagingConstants.LOG_TAG, "Not dispatching a notification event, personalization:decisions response does not contain propositions.")
            return
        }

        // dispatch an event with the propositions received from the remote
        let eventData = [MessagingConstants.Event.Data.Key.PROPOSITIONS: requestedPropositions.flatMap { $0.value }].asDictionary()

        let event = Event(name: MessagingConstants.Event.Name.MESSAGE_PROPOSITIONS_NOTIFICATION,
                          type: EventType.messaging,
                          source: EventSource.notification,
                          data: eventData)
        dispatch(event: event)
    }

    private func retrievePropositions(surfaces: [Surface]) -> [Surface: [Proposition]] {
        var propositionsDict: [Surface: [Proposition]] = [:]
        for surface in surfaces {
            // add code-based propositions
            if let propositionsArray = messagingState.propositions[surface] {
                propositionsDict[surface] = propositionsArray
            }

            guard let inboundArray = messagingState.inboundMessages[surface] else {
                continue
            }

            var inboundPropositions: [Proposition] = []
            for message in inboundArray {
                guard let propositionInfo = propositionInfo[message.uniqueId] else {
                    continue
                }

                let jsonData = (try? JSONEncoder().encode(message)) ?? Data()
                let itemContent = String(data: jsonData, encoding: .utf8)

                let propositionItem = PropositionItem(
                    uniqueId: UUID().uuidString, // revisit this if item.id is used for reporting in future
                    schema: "https://ns.adobe.com/personalization/json-content-item",
                    content: itemContent ?? ""
                )

                let proposition = Proposition(
                    uniqueId: propositionInfo.id,
                    scope: propositionInfo.scope,
                    scopeDetails: propositionInfo.scopeDetails,
                    items: [propositionItem]
                )

                inboundPropositions.append(proposition)
            }
            propositionsDict.addArray(inboundPropositions, forKey: surface)
        }
        return propositionsDict
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

        let message = Message(parent: self, event: event)
        message.propositionInfo = propositionInfoForMessageId(message.id)
        if message.propositionInfo == nil {
            Log.warning(label: MessagingConstants.LOG_TAG, "Preparing to show a message that does not contain information necessary for tracking with Adobe Journey Optimizer. If you are spoofing this message from the AJO authoring UI or from Assurance, ignore this message.")
        }

        message.trigger()
        message.show(withMessagingDelegateControl: true)
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

        // handle an event to request propositions from the remote
        if event.isUpdatePropositionsEvent {
            Log.debug(label: MessagingConstants.LOG_TAG, "Processing request to update propositions from the remote.")
            fetchMessages(for: event.surfaces ?? [])
            return
        }

        // handle an event to get cached message feeds in the SDK
        if event.isGetPropositionsEvent {
            Log.debug(label: MessagingConstants.LOG_TAG, "Processing request to get message propositions cached in the SDK.")
            retrieveMessages(for: event.surfaces ?? [], event: event)
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

    func propositionInfoForMessageId(_ messageId: String) -> PropositionInfo? {
        messagingState.propositionInfo[messageId]
    }

    // swiftlint:disable function_body_length
    func parsePropositions(_ propositions: [Proposition]?, expectedSurfaces: [Surface], clearExisting: Bool, persistChanges: Bool = true) -> [InboundType: [LaunchRule]] {
        var rules: [InboundType: [LaunchRule]] = [:]
        var tempPropInfo: [String: PropositionInfo] = [:]
        var tempPropositions: [Surface: [Proposition]] = [:]
        var inAppPropositions: [Surface: [Proposition]] = [:]

        if clearExisting {
            clear(surfaces: expectedSurfaces)
        }

        if let propositions = propositions {
            for proposition in propositions {
                guard let surface = expectedSurfaces.first(where: { $0.uri == proposition.scope }) else {
                    Log.debug(label: MessagingConstants.LOG_TAG,
                              "Ignoring proposition where scope (\(proposition.scope)) does not match one of the expected surfaces.")
                    continue
                }

                guard let contentString = proposition.items.first?.content, !contentString.isEmpty else {
                    Log.debug(label: MessagingConstants.LOG_TAG, "Not parsing rules in proposition with empty content.")
                    tempPropositions.add(proposition, forKey: surface)
                    continue
                }

                guard let parsedRules = rulesEngine.launchRulesEngine.parseRule(contentString, runtime: runtime) else {
                    Log.debug(label: MessagingConstants.LOG_TAG, "Parsing rules did not succeed for the proposition.")
                    tempPropositions.add(proposition, forKey: surface)
                    continue
                }

                let consequence = parsedRules.first?.consequences.first
                if let messageId = consequence?.id {
                    // store reporting data for this payload
                    tempPropInfo[messageId] = PropositionInfo.fromProposition(proposition)
                }

                let isInAppConsequence = consequence?.isInApp ?? false
                if isInAppConsequence {
                    inAppPropositions.add(proposition, forKey: surface)

                    // pre-fetch the assets for this message if there are any defined
                    rulesEngine.cacheRemoteAssetsFor(parsedRules)
                } else {
                    let isFeedConsequence = consequence?.isFeedItem ?? false
                    if !isFeedConsequence {
                        tempPropositions.add(proposition, forKey: surface)
                    }
                }

                let inboundType = isInAppConsequence ? InboundType.inapp : InboundType(from: consequence?.detailSchema ?? "")
                rules.addArray(parsedRules, forKey: inboundType)
            }
        }

        updatePropositions(tempPropositions)
        updatePropositionInfo(tempPropInfo)

        if persistChanges {
            cachePropositions(inAppPropositions)
        }
        return rules
    }

    // swiftlint:enable function_body_length

    #if DEBUG
        /// For testing purposes only
        internal func propositionInfoCount() -> Int {
            propositionInfo.count
        }

        /// For testing purposes only
        internal func inMemoryPropositionsCount() -> Int {
            propositions.count
        }

        /// Used for testing only
        internal func setMessagesRequestEventId(_ newId: String) {
            messagesRequestEventId = newId
        }

        /// Used for testing only
        internal func setLastProcessedRequestEventId(_ newId: String) {
            lastProcessedRequestEventId = newId
        }

        /// Used for testing only
        internal func setRequestedSurfacesforEventId(_ eventId: String, expectedSurfaces: [Surface]) {
            requestedSurfacesforEventId[eventId] = expectedSurfaces
        }
    #endif
}
