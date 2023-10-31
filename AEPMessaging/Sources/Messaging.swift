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

    // Operation orderer used to maintain the order of update and get propositions events.
    // It ensures any update propositions requests issued before a get propositions call are completed
    // and the get propositions request is fulfilled from the latest cached content.
    private let eventsQueue = OperationOrderer<Event>("MessagingEvents")

    // MARK: - Messaging State
    var cache: Cache = .init(name: MessagingConstants.Caches.CACHE_NAME)
    var appSurface: String {
        Bundle.main.mobileappSurface
    }

    private var initialLoadComplete = false
    let rulesEngine: MessagingRulesEngine
    let feedRulesEngine: FeedRulesEngine

    /// stores CBE propositions (json-content, html-content, default-content)
    var propositions: [Surface: [MessagingProposition]] = [:]
    /// propositionInfo stored by RuleConsequence.id
    var propositionInfo: [String: PropositionInfo] = [:]
    /// keeps a list of all surfaces requested per personalization request event by event id
    private var requestedSurfacesForEventId: [String: [Surface]] = [:]
    /// used while processing streaming payloads for a single request
    private var inProgressPropositions: [Surface: [MessagingProposition]] = [:]

    private var inAppRulesBySurface: [Surface: [LaunchRule]] = [:]
    /// used to manage feed rules between multiple surfaces and multiple requests
    private var feedRulesBySurface: [Surface: [LaunchRule]] = [:]

    /// Array containing the schema strings for the proposition items supported by the SDK, sent in the personalization query request.
    static let supportedSchemas = [
        MessagingConstants.Event.Data.Values.Inbound.SCHEMA_HTML_CONTENT,
        MessagingConstants.Event.Data.Values.Inbound.SCHEMA_JSON_CONTENT,
        MessagingConstants.Event.Data.Values.Inbound.SCHEMA_RULESET_ITEM
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
    init(runtime: ExtensionRuntime, rulesEngine: MessagingRulesEngine, feedRulesEngine: FeedRulesEngine, expectedSurfaceUri _: String, cache: Cache) {
        self.runtime = runtime
        self.rulesEngine = rulesEngine
        self.feedRulesEngine = feedRulesEngine
        self.cache = cache
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

        // register listener for handling personalization request complete events
        registerListener(type: EventType.messaging,
                         source: EventSource.contentComplete,
                         listener: handleProcessCompletedEvent(_:))

        // Handler function called for each queued event. If the queued event is a get propositions event, process it
        // otherwise if it is an Edge event to update propositions, process it only if it is completed.
        eventsQueue.setHandler { event -> Bool in
            if event.isGetPropositionsEvent {
                self.retrieveMessages(for: event.surfaces ?? [], event: event)
            } else if event.type == EventType.edge {
                return !self.requestedSurfacesForEventId.keys.contains(event.id.uuidString)
            }
            return true
        }
        eventsQueue.start()
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
            fetchMessages(event)
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
    /// - Parameters:
    /// - event - do this
    ///   - surfaces: an array of surface path strings for fetching feed messages, if available.
    private func fetchMessages(_ event: Event, for surfaces: [Surface]? = nil) {
        var requestedSurfaces: [Surface] = []

        // if surfaces are provided, use them - otherwise assume the request is for base surface (mobileapp://{bundle identifier})
        if let surfaces = surfaces {
            requestedSurfaces = surfaces.filter { $0.isValid }

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

        // begin construction of event data
        var eventData: [String: Any] = [:]

        // add `query` parameters containing supported schemas and requested surfaces
        eventData[MessagingConstants.XDM.Inbound.Key.QUERY] = [
            MessagingConstants.XDM.Inbound.Key.PERSONALIZATION: [
                MessagingConstants.XDM.Inbound.Key.SCHEMAS: Messaging.supportedSchemas,
                MessagingConstants.XDM.Inbound.Key.SURFACES: requestedSurfaces.compactMap { $0.uri }
            ]
        ]

        // add `xdm` with an event type of `personalization.request`
        eventData[MessagingConstants.XDM.Key.XDM] = [
            MessagingConstants.XDM.Key.EVENT_TYPE: MessagingConstants.XDM.Inbound.EventType.PERSONALIZATION_REQUEST
        ]

        // add a `data` object to the request specifying the format desired in the response from XAS
        eventData[MessagingConstants.DATA.Key.DATA] = [
            MessagingConstants.DATA.AdobeKeys.NAMESPACE: [
                MessagingConstants.DATA.AdobeKeys.AJO: [
                    MessagingConstants.DATA.AdobeKeys.INAPP_RESPONSE_FORMAT: MessagingConstants.XDM.Inbound.Value.IAM_RESPONSE_FORMAT
                ]
            ]
        ]

        // add a `request` object so we get a response event from edge when the propositions stream is closed for this event
        eventData[MessagingConstants.XDM.Key.REQUEST] = [
            MessagingConstants.XDM.Key.SEND_COMPLETION: true
        ]
        // end construction of event data

        let newEvent = event.createChainedEvent(name: MessagingConstants.Event.Name.RETRIEVE_MESSAGE_DEFINITIONS,
                                                type: EventType.edge,
                                                source: EventSource.requestContent,
                                                data: eventData)

        // create entries in our local containers for managing streamed responses from edge
        beginRequestFor(newEvent, with: requestedSurfaces)

        // dispatch the event and implement handler for the completion event
        MobileCore.dispatch(event: newEvent, timeout: 10.0) { responseEvent in
            // responseEvent is the event dispatched by Edge extension when a request's stream has been closed
            guard let responseEvent = responseEvent,
                  let endingEventId = responseEvent.requestEventId
            else {
                // response event failed or timed out, need to remove this event from the queue
                self.requestedSurfacesForEventId.removeValue(forKey: newEvent.id.uuidString)
                self.eventsQueue.start()

                Log.warning(label: MessagingConstants.LOG_TAG, "Unable to run completion logic for a personalization request event - unable to obtain parent event ID")
                return
            }

            // dispatch an event signaling messaging extension needs to finalize this event
            // it must be dispatched to the event queue to avoid a race with the events containing propositions
            let processCompletedEvent = responseEvent.createChainedEvent(name: MessagingConstants.Event.Name.FINALIZE_PROPOSITIONS_RESPONSE,
                                                                         type: EventType.messaging,
                                                                         source: EventSource.contentComplete,
                                                                         data: [MessagingConstants.Event.Data.Key.ENDING_EVENT_ID: endingEventId])
            self.dispatch(event: processCompletedEvent)
        }
    }

    func handleProcessCompletedEvent(_ event: Event) {
        defer {
            // kick off processing the internal events queue after processing is completed for an update propositions request
            eventsQueue.start()
        }

        guard let endingEventId = event.data?[MessagingConstants.Event.Data.Key.ENDING_EVENT_ID] as? String,
              let requestedSurfaces = requestedSurfacesForEventId[endingEventId]
        else {
            // shouldn't ever get here, but if we do, we don't have anything to process so we should bail
            return
        }

        Log.trace(label: MessagingConstants.LOG_TAG, "End of streaming response events for requesting event '\(endingEventId)'")
        endRequestFor(eventId: endingEventId)

        // TODO: why do we need to cache these?
        // check for new feed items from recently updated rules engine
//        if let propositionItemsBySurface = feedRulesEngine.evaluate(event: event) {
//            cachePropositionsFor(propositionItemsBySurface)
//            
//        }

        // dispatch notification event for request
        dispatchNotificationEventFor(event, requestedSurfaces: requestedSurfaces)
    }
    
    private func getPropositionsFromFeedRulesEngine(_ event: Event) -> [Surface: [MessagingProposition]] {
        var surfacePropositions: [Surface: [MessagingProposition]] = [:]
        
        if let propositionItemsBySurface = feedRulesEngine.evaluate(event: event) {
            for (surface, propositionItemsArray) in propositionItemsBySurface {
                var tempPropositions: [MessagingProposition] = []
                for propositionItem in propositionItemsArray {
                    // TODO: REVERT THIS
                    guard let propositionInfo = propositionInfo.first?.value else { //propositionInfo[propositionItem.propositionId] else {
                        continue
                    }
                    
                    // get proposition that this item belongs to
                    let proposition = MessagingProposition(
                        // TODO: REVERT THIS TOO
                        uniqueId: UUID().uuidString, // propositionInfo.id,
                        scope: propositionInfo.scope,
                        scopeDetails: propositionInfo.scopeDetails,
                        items: [propositionItem]
                    )
                    
                    // check to see if that proposition is already in the array (based on ID)
                    // if yes, append the propositionItem.  if not, create a new entry for the
                    // proposition with the new item.
                    
                    if let existingProposition = tempPropositions.first(where: { $0.uniqueId == proposition.uniqueId }) {
                        propositionItem.proposition = existingProposition
                        existingProposition.items.append(propositionItem)
                    } else {
                        propositionItem.proposition = proposition
                        tempPropositions.append(proposition)
                    }
                }
                
                surfacePropositions.addArray(tempPropositions, forKey: surface)
            }
        }
        
        return surfacePropositions
    }

    private func dispatchNotificationEventFor(_ event: Event, requestedSurfaces: [Surface]) {
        let requestedPropositions = retrieveCachedPropositions(for: requestedSurfaces)
        guard !requestedPropositions.isEmpty else {
            Log.trace(label: MessagingConstants.LOG_TAG, "Not dispatching a notification event, personalization:decisions response does not contain propositions.")
            return
        }

        // dispatch an event with the propositions received from the remote
        let eventData = [MessagingConstants.Event.Data.Key.PROPOSITIONS: requestedPropositions.flatMap { $0.value }].asDictionary()

        let notificationEvent = event.createChainedEvent(name: MessagingConstants.Event.Name.MESSAGE_PROPOSITIONS_NOTIFICATION,
                                                         type: EventType.messaging,
                                                         source: EventSource.notification,
                                                         data: eventData)

        dispatch(event: notificationEvent)
    }

    private func beginRequestFor(_ event: Event, with surfaces: [Surface]) {
        requestedSurfacesForEventId[event.id.uuidString] = surfaces

        // add the Edge request event to update propositions in the events queue.
        eventsQueue.add(event)
    }

    private func endRequestFor(eventId: String) {
        // update in memory propositions
        applyPropositionChangeFor(eventId: eventId)

        // remove event from surfaces dictionary
        requestedSurfacesForEventId.removeValue(forKey: eventId)

        // clear pending propositions
        inProgressPropositions.removeAll()
    }

    private func applyPropositionChangeFor(eventId: String) {
        // get the list of requested surfaces for this event
        guard let requestedSurfaces = requestedSurfacesForEventId[eventId] else {
            return
        }

        let parsedPropositions = ParsedPropositions(with: inProgressPropositions, requestedSurfaces: requestedSurfaces)

        // we need to preserve cache for any surfaces that were not a part of this request
        // any requested surface that is absent from the response needs to be removed from cache and persistence
        let returnedSurfaces = Array(inProgressPropositions.keys) as [Surface]
        let surfacesToRemove = requestedSurfaces.minus(returnedSurfaces)

        // update persistence, reporting data cache, and finally rules engine for in-app messages
        // order matters here because the rules engine must be a full replace, and when we update
        // persistence we will be removing empty surfaces and making sure unrequested surfaces
        // continue to have their rules active
        updatePropositions(parsedPropositions.propositionsToCache, removing: surfacesToRemove)
        updatePropositionInfo(parsedPropositions.propositionInfoToCache, removing: surfacesToRemove)
        cache.updatePropositions(parsedPropositions.propositionsToPersist, removing: surfacesToRemove)

        // apply rules
        updateRulesEngines(with: parsedPropositions.surfaceRulesBySchemaType, requestedSurfaces: requestedSurfaces)
    }

    private func updateRulesEngines(with rules: [SchemaType: [Surface: [LaunchRule]]], requestedSurfaces: [Surface]) {
        for (inboundType, newRules) in rules {
            let surfacesToRemove = requestedSurfaces.minus(Array(newRules.keys))
            switch inboundType {
            case .inapp:
                Log.trace(label: MessagingConstants.LOG_TAG, "Updating in-app message definitions for surfaces \(newRules.compactMap { $0.key.uri }).")

                // replace rules for each in-app surface we got back
                inAppRulesBySurface.merge(newRules) { _, new in new }

                // remove any surfaces that were requested but had no in-app content returned
                for surface in surfacesToRemove {
                    // calls for a dictionary extension?
                    inAppRulesBySurface.removeValue(forKey: surface)
                }

                // combine all our rules
                let allInAppRules = inAppRulesBySurface.flatMap { $0.value }

                // pre-fetch the assets for this message if there are any defined
                rulesEngine.cacheRemoteAssetsFor(allInAppRules)

                // update rules in in-app engine
                rulesEngine.launchRulesEngine.replaceRules(with: allInAppRules)

            case .feed:
                Log.trace(label: MessagingConstants.LOG_TAG, "Updating feed definitions for surfaces \(newRules.compactMap { $0.key.uri }).")

                // replace rules for each feed surface we got back
                feedRulesBySurface.merge(newRules) { _, new in new }

                // remove any surfaces that were requested but had no in-app content returned
                for surface in surfacesToRemove {
                    feedRulesBySurface.removeValue(forKey: surface)
                }

                // update rules in feed rules engine
                feedRulesEngine.launchRulesEngine.replaceRules(with: feedRulesBySurface.flatMap { $0.value })

            default:
                // no-op
                Log.trace(label: MessagingConstants.LOG_TAG, "No action will be taken updating messaging rules - the InboundType provided is not supported.")
            }
        }
    }

    /// Dispatch an event containing all propositions for the given surface
    private func retrieveMessages(for surfaces: [Surface], event: Event) {
        let requestedSurfaces = surfaces.filter { $0.isValid }

        guard !requestedSurfaces.isEmpty else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Unable to retrieve feed messages, no valid surface paths found.")
            dispatch(event: event.createErrorResponseEvent(AEPError.invalidRequest))
            return
        }
        
        // get propositions from rules engine where conditions are met by this event
        let ruleConsequencePropositions = getPropositionsFromFeedRulesEngine(event)
        // get cached propositions
        var requestedPropositions = retrieveCachedPropositions(for: requestedSurfaces)
        
        for (surface, propositions) in ruleConsequencePropositions {
            requestedPropositions.addArray(propositions, forKey: surface)
        }
        
        let eventData = [MessagingConstants.Event.Data.Key.PROPOSITIONS: requestedPropositions.flatMap { $0.value }].asDictionary()

        let responseEvent = event.createResponseEvent(
            name: MessagingConstants.Event.Name.MESSAGE_PROPOSITIONS_RESPONSE,
            type: EventType.messaging,
            source: EventSource.responseContent,
            data: eventData
        )
        dispatch(event: responseEvent)
    }

    /// Validates that the received event contains in-app message definitions and loads them in the `MessagingRulesEngine`.
    /// - Parameter event: an `Event` containing an in-app message definition in its data
    private func handleEdgePersonalizationNotification(_ event: Event) {
        // validate this is one of our events
        guard event.isPersonalizationDecisionResponse,
              let requestEventId = event.requestEventId,
              requestedSurfacesForEventId.contains(where: { $0.key == requestEventId })
        else {
            // either this isn't the type of response we are waiting for, or it's not a response to one of our requests
            return
        }

        Log.trace(label: MessagingConstants.LOG_TAG, "Processing propositions from personalization:decisions network response for event '\(requestEventId)'.")
        updateInProgressPropositionsWith(event)
    }

    private func updateInProgressPropositionsWith(_ event: Event) {
        guard event.requestEventId != nil else {
            Log.trace(label: MessagingConstants.LOG_TAG, "Ignoring personalization:decisions response with no requesting Event ID.")
            return
        }
        guard let eventPropositions = event.payload else {
            Log.trace(label: MessagingConstants.LOG_TAG, "Ignoring personalization:decisions response with no propositions.")
            return
        }

        // loop through propositions for this event and add them to existing props by surface
        for proposition in eventPropositions {
            let surface = Surface(uri: proposition.scope)
            inProgressPropositions.add(proposition, forKey: surface)
        }
    }

    /// Returns propositions by surface from `propositions` matching the provided `surfaces`
    private func retrieveCachedPropositions(for surfaces: [Surface]) -> [Surface: [MessagingProposition]] {
        return propositions.filter { surface, _ in
            surfaces.contains(where: { $0.uri == surface.uri })
        }
    }

    /// Handles Rules Consequence events containing message definitions.
    private func handleRulesResponse(_ event: Event) {
        if event.data == nil {
            Log.warning(label: MessagingConstants.LOG_TAG, "Unable to process a Rules Consequence Event. Event data is null.")
            return
        }

        if event.isCjmIamConsequence {
            showMessageForEvent(event)
        } else if event.isSchemaConsequence {
            handleSchemaConsequence(event)
        } else {
            Log.trace(label: MessagingConstants.LOG_TAG, "Ignoring rule consequence event which is not of type 'cjmiam' nor 'schema'.")
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
    
    private func handleSchemaConsequence(_ event: Event) {
        guard let propositionItem = MessagingPropositionItem.fromRuleConsequenceEvent(event) else {
            return
        }
        
        switch propositionItem.schema {
        case .inapp:
            if let message = Message.fromPropositionItem(propositionItem, with: self, triggeringEvent: event),
               let propositionInfo = propositionInfoForMessageId(propositionItem.propositionId) {
                message.propositionInfo = propositionInfo
                message.trigger()
                message.show(withMessagingDelegateControl: true)
            }
        default:
            return
        }
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
            fetchMessages(event, for: event.surfaces ?? [])
            return
        }

        // handle an event to get cached message feeds in the SDK
        if event.isGetPropositionsEvent {
            Log.debug(label: MessagingConstants.LOG_TAG, "Processing request to get message propositions cached in the SDK.")
            // Queue the get propositions event in internal events queue to ensure any prior update requests are completed
            // before it is processed.
            eventsQueue.add(event)
            return
        }

        // handle an event for refreshing in-app messages from the remote
        if event.isRefreshMessageEvent {
            Log.debug(label: MessagingConstants.LOG_TAG, "Processing manual request to refresh In-App Message definitions from the remote.")
            fetchMessages(event)
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
        propositionInfo[messageId]
    }

    #if DEBUG
        /// For testing purposes only
        func propositionInfoCount() -> Int {
            propositionInfo.count
        }

        /// For testing purposes only
        func inMemoryPropositionsCount() -> Int {
            propositions.count
        }

        /// Used for testing only
        func setRequestedSurfacesforEventId(_ eventId: String, expectedSurfaces: [Surface]) {
            requestedSurfacesForEventId[eventId] = expectedSurfaces
        }
    #endif
}
