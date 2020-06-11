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
    private let responseEventQueue = OperationQueue<EventHandlerMapping>("Messaging Responses")
//    private var experiencePlatformNetworkService: ExperiencePlatformNetworkService = ExperiencePlatformNetworkService()
//    private var networkResponseHandler: NetworkResponseHandler = NetworkResponseHandler()
    
    
    // =================================================================================================================
    // MARK: - initialization
    // =================================================================================================================
    override init() {
        super.init()
        requestEventQueue.setHandler({ return $0.handler($0.event) })
        responseEventQueue.setHandler({ return $0.handler($0.event) })
        
        // register listener for shared state events
        do {
            try api.registerListener(MessagingRequestListener.self,
                                     eventType: MessagingConstants.EventType.hub,
                                     eventSource: MessagingConstants.EventSource.sharedState)
        } catch {
            ACPCore.log(ACPMobileLogLevel.warning, tag: MessagingConstants.logTag, message: "There was an error registering the listener for shared state events:  \(error.localizedDescription)")
        }
        
        // register listener for set push identifier events
        do {
            try api.registerListener(MessagingRequestListener.self,
                                     eventType: MessagingConstants.EventType.genericIdentity,
                                     eventSource: MessagingConstants.EventSource.requestContent)
        } catch {
            ACPCore.log(ACPMobileLogLevel.warning, tag: MessagingConstants.logTag, message: "There was an error registering the listener for the set push identifier event: \(error.localizedDescription)")
        }
        
        // register listener for collect message info (collect data) events
        do {
            try api.registerListener(MessagingRequestListener.self,
                                     eventType: MessagingConstants.EventType.genericData,
                                     eventSource: MessagingConstants.EventSource.os)
        } catch {
            ACPCore.log(ACPMobileLogLevel.error, tag: MessagingConstants.logTag, message: "There was an error registering the listener for collect message info events: \(error.localizedDescription)")
        }
        
        requestEventQueue.start()
        responseEventQueue.start()
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
    // MARK: - public methods
    // =================================================================================================================
    /// Called by event listeners to kick the processing of the event queue. Event passed to function is not added to queue for processing
    /// - Parameter event: the event which triggered processing of the event queue
    func processEventQueue(_ event: ACPExtensionEvent) {
        // Trigger processing of queue
        requestEventQueue.start()
        ACPCore.log(ACPMobileLogLevel.verbose, tag: MessagingConstants.logTag, message: "Event with id \(event.eventUniqueIdentifier) requested event queue kick.")
    }
    
    func handleSetPushIdentifier(_ event: ACPExtensionEvent) {
        
    }
    
    func handleCollectMessageInfo(_ event: ACPExtensionEvent) {
        
    }
}
