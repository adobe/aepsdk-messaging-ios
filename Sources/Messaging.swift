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

import AEPCore
import AEPServices
import Foundation

@objc(AEPMobileMessaging)
public class Messaging: NSObject, Extension {
    public static var extensionVersion: String = MessagingConstants.EXTENSION_VERSION
    public var name = MessagingConstants.EXTENSION_NAME
    public var friendlyName = MessagingConstants.FRIENDLY_NAME
    public var metadata: [String: String]?
    public var runtime: ExtensionRuntime

    // =================================================================================================================
    // MARK: - ACPExtension protocol methods
    // =================================================================================================================
    public required init?(runtime: ExtensionRuntime) {
        self.runtime = runtime
        super.init()
    }

    public func onRegistered() {
        // register listener for configuration response event
        registerListener(type: MessagingConstants.EventTypes.configuration,
                         source: MessagingConstants.EventSources.responseContent,
                         listener: handleConfigurationResponse)

        // register listener for set push identifier event
        registerListener(type: MessagingConstants.EventTypes.genericIdentity,
                         source: MessagingConstants.EventSources.requestContent,
                         listener: handleProcessEvent)

        // register listener for Messaging request content event
        registerListener(type: MessagingConstants.EventTypes.MESSAGING,
                         source: MessagingConstants.EventSources.requestContent,
                         listener: handleProcessEvent)
    }

    public func onUnregistered() {
        print("Extension unregistered from MobileCore: \(MessagingConstants.FRIENDLY_NAME)")
    }

    public func readyForEvent(_ event: Event) -> Bool {
        guard let configurationSharedState = getSharedState(extensionName: MessagingConstants.SharedState.Configuration.name, event: event) else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Event processing is paused, waiting for valid configuration - '\(event.id.uuidString)'.")
            return false
        }

        // hard dependency on identity module for ecid
        guard let identitySharedState = getSharedState(extensionName: MessagingConstants.SharedState.Identity.name, event: event) else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Event processing is paused, waiting for valid shared state from identity - '\(event.id.uuidString)'.")
            return false
        }

        return configurationSharedState.status == .set && identitySharedState.status == .set
    }

    /// Based on the configuration response check for privacy status stop events if opted out
    func handleConfigurationResponse(_ event: Event) {
        guard let eventData = event.data as [String: Any]? else {
            Log.trace(label: MessagingConstants.LOG_TAG, "Unable to handle configuration response. Event data is null.")
            return
        }

        guard let privacyStatusValue = eventData[MessagingConstants.SharedState.Configuration.privacyStatus] as? String else {
            Log.warning(label: MessagingConstants.LOG_TAG, "Privacy status does not exists. All requests to sync with profile will fail.")
            return
        }

        let privacyStatus = PrivacyStatus.init(rawValue: privacyStatusValue)
        if privacyStatus != PrivacyStatus.optedIn {
            Log.debug(label: MessagingConstants.LOG_TAG, "Privacy is not optedIn, stopping the events processing.")
            stopEvents()
        }

        if privacyStatus == PrivacyStatus.optedIn {
            Log.debug(label: MessagingConstants.LOG_TAG, "Privacy is optedIn, starting the events processing.")
            startEvents()
        }
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
    func handleProcessEvent(_ event: Event) {
        if event.data == nil {
            Log.debug(label: MessagingConstants.LOG_TAG, "Ignoring event with no data - `\(event.id)`.")
            return
        }

        guard let configSharedState = getSharedState(extensionName: MessagingConstants.SharedState.Configuration.name, event: event)?.value else {
            Log.trace(label: MessagingConstants.LOG_TAG, "Event processing is paused, waiting for valid configuration - '\(event.id.uuidString)'.")
            return
        }

        // hard dependency on identity module for ecid
        guard let identitySharedState = getSharedState(extensionName: MessagingConstants.SharedState.Identity.name, event: event)?.value else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Event processing is paused, waiting for valid shared state from identity - '\(event.id.uuidString)'.")
            return
        }

        if event.type == MessagingConstants.EventTypes.genericIdentity && event.source == MessagingConstants.EventSources.requestContent {
            // Temp : if we don't have valid config, we can't process the event
            if !configIsValid(configSharedState) {
                Log.trace(label: MessagingConstants.LOG_TAG, "Ignoring event that does not have valid configuration - '\(event.id.uuidString)'.")
                return
            }

            guard let privacyStatus = PrivacyStatus.init(rawValue: configSharedState[MessagingConstants.SharedState.Configuration.privacyStatus] as? String ?? "") else {
                Log.warning(label: MessagingConstants.LOG_TAG, "ConfigSharedState has invalid privacy status, Ignoring to process event : '\(event.id.uuidString)'.")
                return
            }

            // eventually we'll use platform extension for this, but until ExEdge supports profile updates, we are forced
            // to go directly to dccs
            if privacyStatus == PrivacyStatus.optedIn {
                tempSyncPushToken(configSharedState, identity: identitySharedState, event: event)
            }
        }

        // Check if the event type is MessagingConstants.EventTypes.genericData and eventSource is MessagingConstants.EventSources.os handle processing of the tracking information
        if event.type == MessagingConstants.EventTypes.MESSAGING
            && event.source == MessagingConstants.EventSources.requestContent && configSharedState.keys.contains(
                MessagingConstants.SharedState.Configuration.experienceEventDatasetId) {
            handleTrackingInfo(event: event, configSharedState)
        }

        return
    }

    private func configIsValid(_ config: [AnyHashable: Any]) -> Bool {
        // Temp : implementation for dccs hack for collecting push tokens
        // If both the dccs url and profile dataset exists return true
        return config.keys.contains(MessagingConstants.SharedState.Configuration.dccsEndpoint) && config.keys.contains(MessagingConstants.SharedState.Configuration.profileDatasetId)
    }

    private func tempSyncPushToken(_ config: [AnyHashable: Any], identity: [AnyHashable: Any], event: Event) {
        // Get the dccs endpoint
        // TEMP: if we want to let this be configurable, uncomment below
        guard let dccsUrl = URL(string: config[MessagingConstants.SharedState.Configuration.dccsEndpoint] as? String ?? "") else {
            Log.warning(label: MessagingConstants.LOG_TAG, "DCCS endpoint is invalid. All requests to sync with profile will fail.")
            return
        }

        // TEMP: Send experience Cloud Org ID
        guard let experienceCloudOrgId = config[MessagingConstants.SharedState.Configuration.experienceCloudOrgId] as? String else {
            Log.warning(label: MessagingConstants.LOG_TAG, "Experience Cloud id is invalid. All requests to sync with profile will fail.")
            return
        }

        // get platform
        var platform = MessagingConstants.JsonValues.apns
        let useSandbox = config[MessagingConstants.SharedState.Configuration.useSandbox] as? Bool
        if useSandbox != nil && useSandbox == true {
            platform = MessagingConstants.JsonValues.apnsSandbox
        }

        // get profile DatasetId
        guard let profileDatasetId = config[MessagingConstants.SharedState.Configuration.profileDatasetId] as? String else {
            Log.warning(label: MessagingConstants.LOG_TAG, "DCCS endpoint is invalid. All requests to sync with profile will fail.")
            return
        }

        // get ecid
        guard let ecid = identity[MessagingConstants.SharedState.Identity.ecid] as? String else {
            Log.warning(label: MessagingConstants.LOG_TAG, "Cannot process event that does not have a valid ECID - '\(event.id.uuidString)'.")
            return
        }

        // get push token from event
        guard let eventData = event.data as [String: Any]? else {
            Log.trace(label: MessagingConstants.LOG_TAG, "Ignoring event with missing event data.")
            return
        }
        guard let token = eventData[MessagingConstants.EventDataKeys.PUSH_IDENTIFIER] as? String else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Ignoring event with missing or invalid push identifier - '\(event.id.uuidString)'.")
            return
        }

        // Check if push token is empty
        if token.isEmpty {
            Log.debug(label: MessagingConstants.LOG_TAG, "Ignoring event with missing or invalid push identifier - '\(event.id.uuidString)'.")
            return
        }

        sendPushToken(experienceCloudOrgId: experienceCloudOrgId, profileDatasetId: profileDatasetId, ecid: ecid, token: token, dccsUrl: dccsUrl, platform: platform)
    }

    /// Sends push  token using the dccsUrl and the predefined post body.
    ///
    /// - Parameters:
    ///   - experienceCloudOrgId: The cloud org id
    ///   - profileDatasetId: Profile dataset id where the data needs to be sent
    ///   - ecid: Experience cloud id
    ///   - token: Push token for the device
    ///   - dccsUrl: Endpoint used to send push token to the dataset
    private func sendPushToken(experienceCloudOrgId: String, profileDatasetId: String, ecid: String, token: String, dccsUrl: URL, platform: String) {
        // send the request
        guard let appId: String = Bundle.main.bundleIdentifier else {
            Log.warning(label: MessagingConstants.LOG_TAG, "Failed to sync the push token, App bundle identifier is invalid.")
            return
        }

        let postBodyString = String.init(format: MessagingConstants.Temp.postBodyBase, experienceCloudOrgId, profileDatasetId, ecid, appId, platform, token, ecid)
        let headers = ["Content-Type": "application/json"]
        let request = NetworkRequest(url: dccsUrl,
                                     httpMethod: .post,
                                     connectPayload: postBodyString,
                                     httpHeaders: headers,
                                     connectTimeout: 5.0,
                                     readTimeout: 5.0)

        Log.trace(label: MessagingConstants.LOG_TAG, "Syncing push token to DCCS - url: \(dccsUrl)  payload: \(postBodyString)")

        ServiceProvider.shared.networkService.connectAsync(networkRequest: request) { (connection: HttpConnection) in
            if connection.error != nil {
                Log.warning(label: MessagingConstants.LOG_TAG, "Error sending push token to profile - \(String(describing: connection.error?.localizedDescription)).")
            } else {
                Log.trace(label: MessagingConstants.LOG_TAG, "Push Token \(token) synced for ECID \(ecid)")
            }
        }
    }

    /// Sends an experience event to the platform sdk for tracking the notification click-throughs
    /// - Parameters:
    ///   - event: The triggering event with the click through data
    /// - Returns: A boolean explaining whether the handling of tracking info was successful or not
    private func handleTrackingInfo(event: Event, _ config: [AnyHashable: Any]) {
        guard let eventData = event.data else {
            Log.trace(label: MessagingConstants.LOG_TAG, "Unable to track information. EventData received is null.")
            return
        }

        // TEMP: Send experience event DatasetId
        guard let expEventDatasetId = config[MessagingConstants.SharedState.Configuration.experienceEventDatasetId] as? String else {
            Log.warning(label: MessagingConstants.LOG_TAG, "DCCS endpoint is invalid. All requests to sync with profile will fail.")
            return
        }

        // Get the schema and convert to xdm dictionary
        guard var xdmMap = getXdmData(eventData: eventData) else {
            Log.warning(label: MessagingConstants.LOG_TAG, "Unable to track information. Schema generation from eventData failed.")
            return
        }

        // Add application specific tracking data
        let applicationOpened = eventData[MessagingConstants.EventDataKeys.APPLICATION_OPENED] as? Bool ?? false
        xdmMap = addApplicationData(applicationOpened: applicationOpened, xdmData: xdmMap)

        // Add Adobe specific tracking data
        xdmMap = addAdobeData(eventData: eventData, xdmDict: xdmMap)

        // Creating xdm edge event data
        let xdmEventData: [String: Any] = [MessagingConstants.XDMDataKeys.XDM: xdmMap, MessagingConstants.XDMDataKeys.META: [
                                            MessagingConstants.XDMDataKeys.COLLECT: [
                                                MessagingConstants.XDMDataKeys.DATASET_ID: expEventDatasetId]]]
        // Creating xdm edge event with request content source type
        let event = Event(name: "Messaging Push Tracking Event",
                          type: MessagingConstants.EventTypes.EDGE,
                          source: MessagingConstants.EventSources.requestContent,
                          data: xdmEventData)
        MobileCore.dispatch(event: event)
    }

    /// Adding CJM specific data to tracking information schema map.
    /// - Parameters:
    ///  - eventData: Dictionary with Adobe cjm tracking information
    ///  - schemaXml: Dictionary which is updated with the cjm tracking information.
    private func addAdobeData(eventData: [AnyHashable: Any], xdmDict: [String: Any]) -> [String: Any] {
        var xdmDictResult = xdmDict
        guard let adobeTrackingDict = eventData[MessagingConstants.EventDataKeys.ADOBE_XDM] as? [String: Any] else {
            Log.warning(label: MessagingConstants.LOG_TAG, "Failed to update Adobe tracking information. Adobe data is invalid.")
            return xdmDictResult
        }

        // Check if the json has the required keys
        var mixins: [String: Any]? = adobeTrackingDict[MessagingConstants.AdobeTrackingKeys.MIXINS] as? [String: Any]
        // If key `mixins` is not present check for cjm
        if mixins == nil {
            // check if CJM key is not present return the orginal xdmDict
            guard let cjm: [String: Any] = adobeTrackingDict[MessagingConstants.AdobeTrackingKeys.CJM] as? [String: Any] else {
                Log.warning(label: MessagingConstants.LOG_TAG,
                            "Failed to send Adobe data with the tracking data, Adobe data is malformed")
                return xdmDictResult
            }
            mixins = cjm
        }

        // Add all the key and value pair to xdmDictResult
        xdmDictResult += mixins ?? [:]

        // Check if the xdm data provided by the customer is using cjm for tracking
        // Check if both {@link MessagingConstant#EXPERIENCE} and {@link MessagingConstant#CUSTOMER_JOURNEY_MANAGEMENT} exists
        if var experienceDict = xdmDictResult[MessagingConstants.AdobeTrackingKeys.EXPERIENCE] as? [String: Any] {
            if var cjmDict = experienceDict[MessagingConstants.AdobeTrackingKeys.CUSTOMER_JOURNEY_MANAGEMENT] as? [String: Any] {
                // Adding Message profile and push channel context to CUSTOMER_JOURNEY_MANAGEMENT
                guard let messageProfile = convertStringToDictionary(text: MessagingConstants.AdobeTrackingKeys.MESSAGE_PROFILE_JSON) else {
                    Log.warning(label: MessagingConstants.LOG_TAG,
                                "Failed to update Adobe tracking information. Messaging profile data is malformed.")
                    return xdmDictResult
                }
                // Merging the dictionary
                cjmDict += messageProfile
                experienceDict[MessagingConstants.AdobeTrackingKeys.CUSTOMER_JOURNEY_MANAGEMENT] = cjmDict
                xdmDictResult[MessagingConstants.AdobeTrackingKeys.EXPERIENCE] = experienceDict
            }
        } else {
            Log.warning(label: MessagingConstants.LOG_TAG, "Failed to send cjm xdm data with the tracking, required keys are missing.")
        }
        return xdmDictResult
    }

    /// Adding application data based on the application opened or not
    private func addApplicationData(applicationOpened: Bool, xdmData: [String: Any]) -> [String: Any] {
        var xdmDataResult = xdmData
        xdmDataResult[MessagingConstants.AdobeTrackingKeys.APPLICATION] =
            [MessagingConstants.AdobeTrackingKeys.LAUNCHES:
                [MessagingConstants.AdobeTrackingKeys.LAUNCHES_VALUE: applicationOpened ? 1 : 0]]
        return xdmDataResult
    }

    /// Creates the xdm schema from event data
    /// - Parameters:
    ///   - eventData: Dictionary with push notification tracking information
    /// - Returns: MobilePushTrackingSchema xdm schema object which conatins the push click-through tracking informations
    private func getXdmData(eventData: [AnyHashable: Any]) -> [String: Any]? {
        let eventType = eventData[MessagingConstants.EventDataKeys.EVENT_TYPE] as? String
        let messageId = eventData[MessagingConstants.EventDataKeys.MESSAGE_ID] as? String
        let actionId = eventData[MessagingConstants.EventDataKeys.ACTION_ID] as? String

        if eventType == nil || eventType?.isEmpty == true || messageId == nil || messageId?.isEmpty == true {
            Log.trace(label: MessagingConstants.LOG_TAG, "Unable to track information. EventType or MessageId received is null.")
            return nil
        }

        var xdmDict: [String: Any] = [MessagingConstants.XDMDataKeys.EVENT_TYPE: eventType]
        var pushNotificationTrackingDict: [String: Any] = [:]
        var customActionDict: [String: Any] = [:]
        if actionId != nil {
            customActionDict[MessagingConstants.XDMDataKeys.ACTION_ID] = actionId
            pushNotificationTrackingDict[MessagingConstants.XDMDataKeys.CUSTOM_ACTION] = customActionDict
        }
        pushNotificationTrackingDict[MessagingConstants.XDMDataKeys.PUSH_PROVIDER_MESSAGE_ID] = messageId
        pushNotificationTrackingDict[MessagingConstants.XDMDataKeys.PUSH_PROVIDER] = MessagingConstants.JsonValues.apns
        xdmDict[MessagingConstants.XDMDataKeys.PUSH_NOTIFICATION_TRACKING] = pushNotificationTrackingDict

        return xdmDict
    }

    /// Helper methods

    /// Converts a dictionary string to dictionary object
    /// - Parameters:
    ///   - text: String dictionary which needs to be converted
    /// - Returns: Dictionary
    private func convertStringToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]
                return json
            } catch {
                print("Unexpected error: \(error).")
                return nil
            }
        }
        return nil
    }
}

/// Use to merge 2 dictionaries together
func += <K, V> (left: inout [K: V], right: [K: V]) {
    left.merge(right) { _, new in new }
}
