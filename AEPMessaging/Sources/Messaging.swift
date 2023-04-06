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

    private var messagesRequestEventId: String = ""
    private var lastProcessedRequestEventId: String = ""
    private var initialLoadComplete = false
    private(set) var currentMessage: Message?
    let rulesEngine: MessagingRulesEngine
    let feedRulesEngine: FeedRulesEngine
    private(set) var cache: Cache
    var inMemoryPropositions: [PropositionPayload] = []
    var propositionInfo: [String: PropositionInfo] = [:]
    var inMemoryFeeds: [String: Feed] = [:]
    var feedsInfo: [String: PropositionInfo] = [:]
    private var requestedSurfacesforEventId: [String: [String]] = [:]

    // MARK: - Extension protocol methods

    public required init?(runtime: ExtensionRuntime) {
        self.runtime = runtime
        cache = Cache(name: MessagingConstants.Caches.CACHE_NAME)
        rulesEngine = MessagingRulesEngine(name: MessagingConstants.RULES_ENGINE_NAME, extensionRuntime: runtime, cache: cache)
        feedRulesEngine = FeedRulesEngine(name: MessagingConstants.FEED_RULES_ENGINE_NAME, extensionRuntime: runtime)
        super.init()
        loadCachedPropositions(for: appSurface)
    }

    /// INTERNAL ONLY
    /// used for testing
    init(runtime: ExtensionRuntime, rulesEngine: MessagingRulesEngine, feedRulesEngine: FeedRulesEngine, expectedSurface: String, cache: Cache) {
        self.runtime = runtime
        self.cache = cache
        self.rulesEngine = rulesEngine
        self.feedRulesEngine = feedRulesEngine

        super.init()
        loadCachedPropositions(for: expectedSurface)
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

    /// Generates and dispatches an event prompting the Edge extension to fetch in-app or feed messages.
    ///
    /// The surface URIs used in the request are generated using the `bundleIdentifier` for the app.
    /// If the `bundleIdentifier` is unavailable, calling this method will do nothing.
    ///
    /// - Parameter surfacePaths: an array of surface path strings for fetching feed messages, if available.
    private func fetchMessages(for surfacePaths: [String]? = nil) {
        guard appSurface != "unknown" else {
            Log.warning(label: MessagingConstants.LOG_TAG, "Unable to update in-app or feed messages, cannot read the bundle identifier.")
            return
        }

        var surfaceUri: [String] = []
        if let surfacePaths = surfacePaths {
            surfaceUri = surfacePaths
                .filter { !$0.isEmpty }
                .map { appSurface + MessagingConstants.PATH_SEPARATOR + $0 }
                .filter { isValidSurface($0) }

            if surfaceUri.isEmpty {
                Log.debug(label: MessagingConstants.LOG_TAG, "Unable to update feed messages, no valid surface paths found.")
                return
            }
        } else {
            surfaceUri = [appSurface]
        }

        var eventData: [String: Any] = [:]

        let messageRequestData: [String: Any] = [
            MessagingConstants.XDM.IAM.Key.PERSONALIZATION: [
                MessagingConstants.XDM.IAM.Key.SURFACES: surfaceUri
            ]
        ]
        eventData[MessagingConstants.XDM.IAM.Key.QUERY] = messageRequestData

        let xdmData: [String: Any] = [
            MessagingConstants.XDM.Key.EVENT_TYPE: MessagingConstants.XDM.IAM.EventType.PERSONALIZATION_REQUEST
        ]
        eventData[MessagingConstants.XDM.Key.XDM] = xdmData

        let event = Event(name: MessagingConstants.Event.Name.RETRIEVE_MESSAGE_DEFINITIONS,
                          type: EventType.edge,
                          source: EventSource.requestContent,
                          data: eventData)

        // equal to `requestEventId` in aep response handles
        // used for ensuring that the messaging extension is responding to the correct handle
        messagesRequestEventId = event.id.uuidString
        requestedSurfacesforEventId[messagesRequestEventId] = surfaceUri

        // send event
        runtime.dispatch(event: event)
    }

    private func retrieveMessages(for surfacePaths: [String], event: Event) {
        guard appSurface != "unknown" else {
            Log.warning(label: MessagingConstants.LOG_TAG, "Unable to retrieve feed messages, cannot read the bundle identifier.")
            return
        }

        var surfaceUri = surfacePaths
            .filter { !$0.isEmpty }
            .map { appSurface + MessagingConstants.PATH_SEPARATOR + $0 }
            .filter { isValidSurface($0) }

        if surfaceUri.isEmpty {
            Log.debug(label: MessagingConstants.LOG_TAG, "Unable to retrieve feed messages, no valid surface paths found.")
            dispatch(event: event.createErrorResponseEvent(AEPError.invalidRequest))
            return
        }

        feedRulesEngine.process(event: event) { feeds in
            self.mergeFeedsInMemory(feeds ?? [:], requestedSurfaces: surfaceUri)
            let requestedFeeds = self.inMemoryFeeds
                .filter { surfaceUri.contains($0.key) }
                .reduce([String: Feed]()) {
                    var result = $0
                    if $1.key.hasPrefix(self.appSurface) {
                        result[String($1.key.dropFirst(self.appSurface.count + 1))] = $1.value
                    } else {
                        result[$1.key] = $1.value
                    }
                    return result
                }

            let eventData = [MessagingConstants.Event.Data.Key.FEEDS: requestedFeeds].asDictionary()

            let responseEvent = event.createResponseEvent(
                name: MessagingConstants.Event.Name.MESSAGE_FEEDS_RESPONSE,
                type: EventType.messaging,
                source: EventSource.responseContent,
                data: eventData
            )
            self.dispatch(event: responseEvent)
        }
    }

    private var appSurface: String {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier, !bundleIdentifier.isEmpty else {
            return "unknown"
        }

        return MessagingConstants.XDM.IAM.SURFACE_BASE + bundleIdentifier
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
        Log.trace(label: MessagingConstants.LOG_TAG, "Loading in-app or feed message definitions from personalization:decisions network response.")
        let rules = parsePropositions(event.payload, expectedSurfaces: requestedSurfacesforEventId[messagesRequestEventId] ?? [], clearExisting: clearExistingRules)
        rulesEngine.launchRulesEngine.loadRules(rules, clearExisting: clearExistingRules)

        if rules.first?.consequences.first?.isFeedItem == true {
            feedRulesEngine.process(event: event) { feeds in
                let feeds = feeds ?? [:]
                self.mergeFeedsInMemory(feeds, requestedSurfaces: self.requestedSurfacesforEventId[self.lastProcessedRequestEventId] ?? [])
                let requestedFeeds = feeds
                    .reduce([String: Feed]()) {
                        var result = $0
                        if $1.key.hasPrefix(self.appSurface) {
                            result[String($1.key.dropFirst(self.appSurface.count + 1))] = $1.value
                        } else {
                            result[$1.key] = $1.value
                        }
                        return result
                    }
                // dispatch an event with the feeds received from the remote
                let eventData = [MessagingConstants.Event.Data.Key.FEEDS: requestedFeeds].asDictionary()

                let event = Event(name: MessagingConstants.Event.Name.MESSAGE_FEEDS_NOTIFICATION,
                                  type: EventType.messaging,
                                  source: EventSource.notification,
                                  data: eventData)
                self.dispatch(event: event)
            }
        }
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
            // swiftlint:disable line_length
            Log.warning(label: MessagingConstants.LOG_TAG, "Preparing to show a message that does not contain information necessary for tracking with Adobe Journey Optimizer. If you are spoofing this message from the AJO authoring UI or from Assurance, ignore this message.")
            // swiftlint:enable line_length
        }

        message.trigger()
        message.show(withMessagingDelegateControl: true)
        currentMessage = message
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

        // handle an event to request message feeds from the remote
        if event.isUpdateFeedsEvent {
            Log.debug(label: MessagingConstants.LOG_TAG, "Processing request to update message feed definitions from the remote.")
            fetchMessages(for: event.surfaces ?? [])
            return
        }

        // handle an event to get cached message feeds in the SDK
        if event.isGetFeedsEvent {
            Log.debug(label: MessagingConstants.LOG_TAG, "Processing request to get message feed definitions cached in the SDK.")
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
        propositionInfo[messageId]
    }

    // swiftlint:disable function_body_length
    func parsePropositions(_ propositions: [PropositionPayload]?, expectedSurfaces: [String], clearExisting: Bool, persistChanges: Bool = true) -> [LaunchRule] {
        var rules: [LaunchRule] = []
        var tempPropInfo: [String: PropositionInfo] = [:]
        var tempPropositions: [PropositionPayload] = []
        var tempFeedsInfo: [String: PropositionInfo] = [:]
        var isFeedConsequence = false

        guard let propositions = propositions, !propositions.isEmpty else {
            if clearExisting {
                if expectedSurfaces == [appSurface] {
                    inMemoryPropositions.removeAll()
                    propositionInfo.removeAll()
                    cachePropositions(shouldReset: true)
                } else {
                    inMemoryFeeds.removeAll()
                    feedsInfo.removeAll()
                }
            }
            return rules
        }

        for proposition in propositions {
            guard expectedSurfaces.contains(proposition.propositionInfo.scope) else {
                Log.debug(label: MessagingConstants.LOG_TAG,
                          "Ignoring proposition where scope (\(proposition.propositionInfo.scope)) does not match one of the expected surfaces (\(expectedSurfaces)).")
                continue
            }

            guard let rulesString = proposition.items.first?.data.content, !rulesString.isEmpty else {
                Log.debug(label: MessagingConstants.LOG_TAG, "Skipping proposition with no in-app message content.")
                continue
            }

            guard let parsedRules = rulesEngine.launchRulesEngine.parseRule(rulesString, runtime: runtime) else {
                Log.debug(label: MessagingConstants.LOG_TAG, "Skipping proposition with malformed in-app message content.")
                continue
            }

            var propInfo: [String: PropositionInfo] = [:]
            if let messageId = parsedRules.first?.consequences.first?.id {
                propInfo[messageId] = proposition.propositionInfo
            }

            isFeedConsequence = parsedRules.first?.consequences.first?.isFeedItem ?? false
            if !isFeedConsequence {
                // pre-fetch the assets for this message if there are any defined
                rulesEngine.cacheRemoteAssetsFor(parsedRules)

                // store reporting data for this payload
                tempPropInfo.merge(propInfo) { _, new in new }
            } else {
                tempFeedsInfo.merge(propInfo) { _, new in new }
            }

            tempPropositions.append(proposition)
            rules.append(contentsOf: parsedRules)
        }

        if !isFeedConsequence {
            if clearExisting {
                propositionInfo = tempPropInfo
                inMemoryPropositions = tempPropositions
            } else {
                propositionInfo.merge(tempPropInfo) { _, new in new }
                inMemoryPropositions.append(contentsOf: tempPropositions)
            }

            if persistChanges {
                cachePropositions()
            }
        } else {
            if clearExisting {
                inMemoryFeeds.removeAll()
                feedsInfo = tempFeedsInfo
            } else {
                feedsInfo.merge(tempFeedsInfo) { _, new in new }
            }
        }

        return rules
    }

    private func isValidSurface(_ surfaceUri: String) -> Bool {
        guard URL(string: surfaceUri) != nil else {
            return false
        }

        return true
    }

    private func mergeFeedsInMemory(_ feeds: [String: Feed], requestedSurfaces: [String]) {
        for surface in requestedSurfaces {
            if feeds[surface] != nil {
                inMemoryFeeds[surface] = feeds[surface]
            } else {
                inMemoryFeeds.removeValue(forKey: surface)
            }
        }
    }

    #if DEBUG
    /// For testing purposes only
    internal func propositionInfoCount() -> Int {
        propositionInfo.count
    }

    /// For testing purposes only
    internal func inMemoryPropositionsCount() -> Int {
        inMemoryPropositions.count
    }

    /// For testing purposes only
    internal func inMemoryFeedsCount() -> Int {
        inMemoryFeeds.count
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
    internal func setRequestedSurfacesforEventId(_ eventId: String, expectedSurfaces: [String]) {
        requestedSurfacesforEventId[eventId] = expectedSurfaces
    }
    #endif
}
