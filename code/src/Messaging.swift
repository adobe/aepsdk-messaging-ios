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
import AEPCore
import AEPExperiencePlatform
import AEPServices

@objc(ACPMessaging)
public class Messaging : NSObject, Extension {
    public static var extensionVersion: String = MessagingConstants.version
    public var name = MessagingConstants.name
    public var friendlyName = MessagingConstants.friendlyName
    public var metadata: [String: String]?
    public var runtime: ExtensionRuntime
    
    // =================================================================================================================
    // MARK: - private constants
    // =================================================================================================================
    typealias EventHandlerMapping = (event: Event, handler: (Event) -> (Bool))
    private let requestEventQueue = OperationQueue<EventHandlerMapping>("Messaging Requests")
    
    // =================================================================================================================
    // MARK: - ACPExtension protocol methods
    // =================================================================================================================
    public required init?(runtime: ExtensionRuntime) {
        self.runtime = runtime
        super.init()
    }
    
    public func onRegistered() {
        requestEventQueue.setHandler({ return $0.handler($0.event) })

        // register listener for shared state events
        registerListener(type: MessagingConstants.EventTypes.hub,
                         source: MessagingConstants.EventSources.sharedState,
                         listener: handleMessagingEventRequest)
        
        // register listener for set push identifier events
        registerListener(type: MessagingConstants.EventTypes.genericIdentity,
                         source: MessagingConstants.EventSources.requestContent,
                         listener: handleMessagingEventRequest)
        
        // register listener for collect message info (collect data) events
        registerListener(type: MessagingConstants.EventTypes.genericData,
                         source: MessagingConstants.EventSources.os,
                         listener: handleMessagingEventRequest)
        
        requestEventQueue.start()
    }

    public func onUnregistered() {
        // if the shared states are not used in the next registration they can be cleared in this method
        // TODO try? api.clearSharedEventStates()
        print("Extension unregistered from MobileCore: \(MessagingConstants.friendlyName)")
    }
    
    public func readyForEvent(_ event: Event) -> Bool {
        guard let configurationSharedState = getSharedState(extensionName: MessagingConstants.SharedState.Configuration.name, event: event) else {
            Log.debug(label: MessagingConstants.logTag, "Event processing is paused, waiting for valid configuration - '\(event.id.uuidString)'.")
            return true
        }
        
        // hard dependency on identity module for ecid
        guard let identitySharedState = getSharedState(extensionName: MessagingConstants.SharedState.Identity.name, event: event) else {
            Log.debug(label: MessagingConstants.logTag, "Event processing is paused, waiting for valid shared state from identity - '\(event.id.uuidString)'.")
            return true
        }
        
        return configurationSharedState.status == .set && identitySharedState.status == .set
    }
    
    // =================================================================================================================
    // MARK: - Listener methods
    // =================================================================================================================
    func handleMessagingEventRequest(_ event: Event) {
        if event.data == nil {
            Log.trace(label: MessagingConstants.logTag, "Event with id \(event.id.uuidString) contained no data, ignoring.")
            return
        }
        
        Log.trace(label: MessagingConstants.logTag, "handleMessagingEventRequest - Processing event with id \(event.id.uuidString).")
        
        // Handle SharedState events
        if event.type == MessagingConstants.EventTypes.hub {
            guard let eventData = event.data else {
                Log.debug(label: MessagingConstants.logTag, "Ignoring event with no data (\(event.id.uuidString)).")
                return
            }
            
            let stateOwner = eventData[MessagingConstants.SharedState.stateOwner] as? String
            if stateOwner == MessagingConstants.SharedState.Configuration.name {
                // kick event queue processing
                kickRequestQueue()
            }
        } else if event.type == MessagingConstants.EventTypes.genericIdentity && event.source == MessagingConstants.EventSources.requestContent {
            // handle set push identifier calls
            addToRequestQueue(event)
        } else if event.type == MessagingConstants.EventTypes.genericData && event.source == MessagingConstants.EventSources.os {
            // handle collect message info calls
            addToRequestQueue(event)
        }
    }
    
    // =================================================================================================================
    // MARK: - protected methods
    // =================================================================================================================
    /// Called by event listeners to kick the processing of the event queue. Event passed to function is not added to queue for processing
    func kickRequestQueue() {
        requestEventQueue.start()
    }
    
    func addToRequestQueue(_ event: Event) {
        requestEventQueue.add((event, handleAddEvent(event:)))
    }
        
    func handleAddEvent(event: Event) -> Bool {
        if event.data == nil {
            Log.debug(label: MessagingConstants.logTag, "Ignoring event with no data - `\(event.id)`.")
            return true
        }
        
        return handleProcessEvent(event)
    }
    
    /// Processes the events in the event queue in the order they were received.
    ///
    /// A valid Configuration shared state is required for processing events. If one is not available, the event
    /// will remain in the queue to be processed at a later time.
    ///
    /// - Parameters:
    ///   - event: An ACPExtensionEvent to be processed
    /// - Returns: true if the event was successfully processed or cannot ever be processed,
    ///            which will remove it from the processing queue.
    func handleProcessEvent(_ event: Event) -> Bool {
        guard let configSharedState = getSharedState(extensionName: MessagingConstants.SharedState.Configuration.name, event: event)?.value else {
            Log.trace(label: MessagingConstants.logTag, "Event processing is paused, waiting for valid configuration - '\(event.id.uuidString)'.")
            return true
        }
                
        // hard dependency on identity module for ecid
        guard let identitySharedState = getSharedState(extensionName: MessagingConstants.SharedState.Identity.name, event: event)?.value else {
            Log.debug(label: MessagingConstants.logTag, "Event processing is paused, waiting for valid shared state from identity - '\(event.id.uuidString)'.")
            return true
        }
        
        if event.type == MessagingConstants.EventTypes.genericIdentity && event.source == MessagingConstants.EventSources.requestContent {
             // Temp : if we don't have valid config, we can't process the event
            if !configIsValid(configSharedState) {
                Log.trace(label: MessagingConstants.logTag, "Ignoring event that does not have valid configuration - '\(event.id.uuidString)'.")
                return true
            }
            
            // eventually we'll use platform extension for this, but until ExEdge supports profile updates, we are forced
            // to go directly to dccs
            return tempSendToDccs(configSharedState, identity: identitySharedState, event: event)
        }
        
        // Check if the event type is MessagingConstants.EventTypes.genericData and eventSource is MessagingConstants.EventSources.os handle processing of the tracking information
        if event.type == MessagingConstants.EventTypes.genericData && event.source == MessagingConstants.EventSources.os && configSharedState.keys.contains(MessagingConstants.SharedState.Configuration.experienceEventDatasetId) {
            return handleTrackingInfo(event: event, configSharedState)
        }
        
        return true
    }
    
    private func configIsValid(_ config: [AnyHashable : Any]) -> Bool {
        // Temp : implementation for dccs hack for collecting push tokens
        // If both the dccs url and profile dataset exists return true
        return config.keys.contains(MessagingConstants.SharedState.Configuration.dccsEndpoint) && config.keys.contains(MessagingConstants.SharedState.Configuration.profileDatasetId)
    }
    
    private func tempSendToDccs(_ config: [AnyHashable : Any], identity: [AnyHashable : Any], event: Event) -> Bool {
        // Get the dccs endpoint
        // TEMP: if we want to let this be configurable, uncomment below
        guard let dccsUrl = URL(string:config[MessagingConstants.SharedState.Configuration.dccsEndpoint] as? String ?? "") else {
            Log.warning(label: MessagingConstants.logTag, "DCCS endpoint is invalid. All requests to sync with profile will fail.")
            return true
        }
        
        // TEMP: Send profile DatasetId
        guard let experienceCloudOrgId = config[MessagingConstants.SharedState.Configuration.experienceCloudOrgId] as? String else {
            Log.warning(label: MessagingConstants.logTag, "Experience Cloud id is invalid. All requests to sync with profile will fail.")
            return true
        }
        
        // TEMP: Send profile DatasetId
        guard let profileDatasetId = config[MessagingConstants.SharedState.Configuration.profileDatasetId] as? String else {
            Log.warning(label: MessagingConstants.logTag, "DCCS endpoint is invalid. All requests to sync with profile will fail.")
            return true
        }
        
        // get ecid
        guard let ecid = identity[MessagingConstants.SharedState.Identity.ecid] as? String else {
            Log.warning(label: MessagingConstants.logTag, "Cannot process event that does not have a valid ECID - '\(event.id.uuidString)'.")
            return true
        }
        
        // get push token from event
        guard let token = event.data![MessagingConstants.EventDataKeys.Identity.pushIdentifier] as? String else {
            Log.debug(label: MessagingConstants.logTag, "Ignoring event with missing or invalid push identifier - '\(event.id.uuidString)'.")
            return true
        }
        
        // send the request
        let postBodyString = String.init(format: MessagingConstants.Temp.postBodyBase, experienceCloudOrgId, profileDatasetId, ecid, token, ecid)
        let headers = ["Content-Type":"application/json"]
        let request = NetworkRequest(url: dccsUrl,
                                     httpMethod: .post,
                                     connectPayload: postBodyString,
                                     httpHeaders: headers,
                                     connectTimeout: 5.0,
                                     readTimeout: 5.0)
        
        Log.trace(label: MessagingConstants.logTag, "Syncing push token to DCCS - url: \(dccsUrl)  payload: \(postBodyString)")
                
        ServiceProvider.shared.networkService.connectAsync(networkRequest: request) { (connection: HttpConnection) in
            if connection.error != nil {
                Log.warning(label: MessagingConstants.logTag, "Error sending push token to profile - \(connection.error!.localizedDescription).")
                return
            } else {
                Log.trace(label: MessagingConstants.logTag, "Push Token \(token) synced for ECID \(ecid)")
            }
        }
        
        // validate the response
        return true
    }
    
    /// Sends an experience event to the platform sdk for tracking the notification click-throughs
    /// - Parameters:
    ///   - event: The triggering event with the click through data
    /// - Returns: A boolean explaining whether the handling of tracking info was successful or not
    private func handleTrackingInfo(event: Event, _ config: [AnyHashable : Any]) -> Bool {
        guard let eventData = event.data else {
            Log.trace(label: MessagingConstants.logTag, "Unable to track information. EventData received is null.")
            return true
        }
        
        // TEMP: Send experience event DatasetId
        guard let expEventDatasetId = config[MessagingConstants.SharedState.Configuration.experienceEventDatasetId] as? String else {
            Log.warning(label: MessagingConstants.logTag, "DCCS endpoint is invalid. All requests to sync with profile will fail.")
            return true
        }
        
        let schema = getXdmSchema(eventData: eventData)
        if schema == nil {
            Log.trace(label: MessagingConstants.logTag, "Unable to track information. Schema generation from eventData failed.")
            return true
        }
        
        let jsonXdm = try? JSONEncoder().encode(schema)
        guard let xdmMap = try? JSONSerialization.jsonObject(with: jsonXdm!, options: []) as? [String: Any] else {
            return true
        }
        
        // Creating experience event
        let expEvent = ExperiencePlatformEvent.init(xdm: xdmMap, data: nil, datasetIdentifier: expEventDatasetId)
        // Send experience event to aep sdk.
        ExperiencePlatform.sendEvent(experiencePlatformEvent: expEvent)
        
        return true
    }
    
    /// Creates the xdm schema from event data
    /// - Parameters:
    ///   - eventData: Dictionary with push notification tracking information
    /// - Returns: MobilePushTrackingSchema xdm schema object which conatins the push click-through tracking informations
    private func getXdmSchema(eventData: Dictionary<AnyHashable, Any>) -> MobilePushTrackingSchema? {
        let eventType = eventData["eventType"] as? String
        let id = eventData["id"] as? String
        let applicationOpened = eventData["applicationOpened"] as? Bool
        let actionId = eventData["actionId"] as? String
        
        if eventType == nil || eventType?.isEmpty == true || id == nil || id?.isEmpty == true {
            Log.trace(label: MessagingConstants.logTag, "Unable to track information. EventType or MessageId received is null.")
            return nil
        }
        
        var schema = MobilePushTrackingSchema()
        var acorprod3 = Acopprod3()
        var track = Track()
        var customAction = CustomAction()
        
        if (applicationOpened == true) {
            track.applicationOpened = true
        } else {
            customAction.actionId = actionId
            track.customAction = customAction
        }
        
        schema.eventType = eventType
        track.id = id
        acorprod3.track = track
        schema.Acopprod3 = acorprod3
        
        return schema
    }
}
