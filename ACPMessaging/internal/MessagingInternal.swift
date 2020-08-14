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
import ACPCore

class MessagingInternal : ACPExtension {
    // =================================================================================================================
    // MARK: - private constants
    // =================================================================================================================
    typealias EventHandlerMapping = (event: ACPExtensionEvent, handler: (ACPExtensionEvent) -> (Bool))
    private let requestEventQueue = OperationQueue<EventHandlerMapping>("Messaging Requests")
    
    // =================================================================================================================
    // MARK: - initialization
    // =================================================================================================================
    override init() {
        super.init()
        requestEventQueue.setHandler({ return $0.handler($0.event) })
        
        // register listener for shared state events
        do {
            try api.registerListener(MessagingRequestListener.self,
                                     eventType: MessagingConstants.EventTypes.hub,
                                     eventSource: MessagingConstants.EventSources.sharedState)
        } catch {
            ACPCore.log(ACPMobileLogLevel.warning, tag: MessagingConstants.logTag, message: "There was an error registering the listener for shared state events:  \(error.localizedDescription)")
        }
        
        // register listener for set push identifier events
        do {
            try api.registerListener(MessagingRequestListener.self,
                                     eventType: MessagingConstants.EventTypes.genericIdentity,
                                     eventSource: MessagingConstants.EventSources.requestContent)
        } catch {
            ACPCore.log(ACPMobileLogLevel.warning, tag: MessagingConstants.logTag, message: "There was an error registering the listener for the set push identifier event: \(error.localizedDescription)")
        }
        
        // register listener for collect message info (collect data) events
        do {
            try api.registerListener(MessagingRequestListener.self,
                                     eventType: MessagingConstants.EventTypes.genericData,
                                     eventSource: MessagingConstants.EventSources.os)
        } catch {
            ACPCore.log(ACPMobileLogLevel.error, tag: MessagingConstants.logTag, message: "There was an error registering the listener for collect message info events: \(error.localizedDescription)")
        }
        
        requestEventQueue.start()        
    }
    
    
    // =================================================================================================================
    // MARK: - ACPExtension protocol methods
    // =================================================================================================================
    override func name() -> String? {
        MessagingConstants.name
    }
    
    override func version() -> String? {
        MessagingConstants.version
    }
    
    override func onUnregister() {
        super.onUnregister()
        
        // if the shared states are not used in the next registration they can be cleared in this method
        try? api.clearSharedEventStates()
    }
    
    override func unexpectedError(_ error: Error) {
        super.unexpectedError(error)
        
        ACPCore.log(ACPMobileLogLevel.warning, tag: MessagingConstants.logTag, message: "Oh snap! An unexpected error occured: \(error.localizedDescription)")
    }
    
    
    // =================================================================================================================
    // MARK: - protected methods
    // =================================================================================================================
    /// Called by event listeners to kick the processing of the event queue. Event passed to function is not added to queue for processing    
    func kickRequestQueue() {
        requestEventQueue.start()
    }
    
    func addToRequestQueue(_ event: ACPExtensionEvent) {
        requestEventQueue.add((event, handleAddEvent(event:)))
    }
        
    func handleAddEvent(event: ACPExtensionEvent) -> Bool {
        if event.eventData == nil {
            ACPCore.log(ACPMobileLogLevel.debug, tag: MessagingConstants.logTag, message: "Ignoring event with no data - `\(event.eventUniqueIdentifier)`.")
            return true
        }
        
        return handleProcessEvent(event)
    }
    
    /// Processes the events in the event queue in teh order they were received.
    ///
    /// A valid Configuration shared state is required for processing events. If one is not available, the event
    /// will remain in the queue to be processed at a later time.
    ///
    /// - Parameters:
    ///   - event: An ACPExtensionEvent to be processed
    /// - Returns: true if the event was successfully processed or cannot ever be processed,
    ///            which will remove it from the processing queue.
    func handleProcessEvent(_ event: ACPExtensionEvent) -> Bool {
        guard let configSharedState = getSharedState(owner: MessagingConstants.SharedState.Configuration.name, event: event) else {
            ACPCore.log(ACPMobileLogLevel.verbose, tag: MessagingConstants.logTag, message: "Event processing is paused, waiting for valid configuration - '\(event.eventUniqueIdentifier)'.")
            return false
        }

        // if we don't have valid config, we can't process the event
        if !configIsValid(configSharedState) {
            ACPCore.log(ACPMobileLogLevel.verbose, tag: MessagingConstants.logTag, message: "Ignoring event that does not have valid configuration - '\(event.eventUniqueIdentifier)'.")
            return true
        }
        
        // hard dependency on identity module for ecid
        guard let identitySharedState = getSharedState(owner: MessagingConstants.SharedState.Identity.name, event: event) else {
            ACPCore.log(ACPMobileLogLevel.verbose, tag: MessagingConstants.logTag, message: "Event processing is paused, waiting for valid shared state from identity - '\(event.eventUniqueIdentifier)'.")
            return false
        }
        
        
        // eventually we'll use platform extension for this, but until ExEdge supports profile updates, we are forced
        // to go directly to dccs
        
        return tempSendToDccs(configSharedState, identity: identitySharedState, event: event)
    }
    
    private func configIsValid(_ config: [AnyHashable : Any]) -> Bool {
        
        return true
        
        // temporary implementation for dccs hack for collecting push tokens
//        return config.keys.contains(MessagingConstants.SharedState.Configuration.dccsHackEndpoint)
    }
    
    /// Helper to get shared state of another extension.
    /// - Parameters:
    ///   - owner: The name of the shared state owner, typically the registered name of the extension.
    ///   - event: The triggering event used to retieve a specific state version.
    /// - Returns: The shared state of the specified `owner` or nil if the state is pending or an error occurred retrieving the state.
    private func getSharedState(owner: String, event: ACPExtensionEvent) -> [AnyHashable : Any]? {
        let state: [AnyHashable : Any]?
        do {
            state = try api.getSharedEventState(owner, event: event)
        } catch {
            ACPCore.log(ACPMobileLogLevel.debug, tag: MessagingConstants.logTag, message: "Failed to retrieve shared state for `\(owner)`: \(error.localizedDescription)")
            return nil // keep event in queue to process on next trigger
        }
        
        guard let unwrappedState = state else {
            ACPCore.log(ACPMobileLogLevel.verbose, tag: MessagingConstants.logTag, message: "Shared state for \(owner) is pending.")
            return nil // keep event in queue to process on next trigger
        }
        return unwrappedState
    }
    
    private func tempSendToDccs(_ config: [AnyHashable : Any], identity: [AnyHashable : Any], event: ACPExtensionEvent) -> Bool {
        // get the endpoint
        // TODO: if we want to let this be configurable, uncomment below
//        guard let dccsEndpoint = config[MessagingConstants.SharedState.Configuration.dccsHackEndpoint] as? String else {
//            ACPCore.log(ACPMobileLogLevel.verbose, tag: MessagingConstants.logTag, message: "Cannot process event that does not have a DCCS Endpoint - '\(event.eventUniqueIdentifier)'.")
//            return true
//        }
        
        // get ecid
        guard let ecid = identity[MessagingConstants.SharedState.Identity.ecid] as? String else {
            ACPCore.log(ACPMobileLogLevel.verbose, tag: MessagingConstants.logTag, message: "Cannot process event that does not have a valid ECID - '\(event.eventUniqueIdentifier)'.")
            return true
        }
        
        // get push token from event
        guard let token = event.eventData![MessagingConstants.EventDataKeys.Identity.pushIdentifier] as? String else {
            ACPCore.log(ACPMobileLogLevel.debug, tag: MessagingConstants.logTag, message: "Ignoring event with missing or invalid push identifier - '\(event.eventUniqueIdentifier)'.")
            return true
        }
        
        // generate the url
        guard let url = URL(string:MessagingConstants.Temp.dccsEndpoint) else {
            ACPCore.log(ACPMobileLogLevel.warning, tag: MessagingConstants.logTag, message: "DCCS endpoint is invalid. All requests to sync with profile will fail.")
            return true
        }
        
        // send the request
        let postBodyString = String.init(format: MessagingConstants.Temp.postBodyBase,
                                         MessagingConstants.Temp.schemaUrl, MessagingConstants.Temp.orgId,
                                         MessagingConstants.Temp.datasetId, MessagingConstants.Temp.schemaUrl,
                                         ecid, token, ecid)
        let headers = ["Content-Type":"application/json"]
        let request = NetworkRequest(url: url,
                                     httpMethod: .post,
                                     connectPayload: postBodyString,
                                     httpHeaders: headers,
                                     connectTimeout: 5.0,
                                     readTimeout: 5.0)
        
        ACPCore.log(ACPMobileLogLevel.verbose, tag: MessagingConstants.logTag, message: "Syncing push token to DCCS - url: \(url)  payload: \(postBodyString)")
        
        AEPServiceProvider.shared.networkService.connectAsync(networkRequest: request) { (connection: HttpConnection) in
            if connection.error != nil {
                ACPCore.log(ACPMobileLogLevel.warning, tag: MessagingConstants.logTag, message: "Error sending push token to profile - \(connection.error!.localizedDescription).")
                return
            } else {
                ACPCore.log(ACPMobileLogLevel.verbose, tag: MessagingConstants.logTag, message: "Push Token \(token) synced for ECID \(ecid)")
            }
        }
        
        // validate the response
        return true
    }
}
