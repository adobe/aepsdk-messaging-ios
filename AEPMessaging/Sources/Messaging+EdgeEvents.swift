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

extension Messaging {
    
    func sendEvent() {
        // get current shared state
        guard let sharedState = getSharedState(extensionName: MessagingConstants.SharedState.Configuration.NAME, event: nil)?.value else {
            return
        }
        
        
    }
    
    // MARK: - internal methods

    /// Get platform based on the `messaging.useSandbox` config value
    ///
    /// - Parameters:
    ///     - config: `[String: Any]` with platform informations
    /// - Returns: a `String` indicating the APNS platform in use
    func getPlatform(config: [String: Any]) -> String {
        return config[MessagingConstants.SharedState.Configuration.USE_SANDBOX] as? Bool ?? false
            ? MessagingConstants.PushNotificationDetails.JsonValues.APNS_SANDBOX
            : MessagingConstants.PushNotificationDetails.JsonValues.APNS
    }
    
    /// Sends an experience event to the platform SDK for tracking the notification click-throughs
    ///
    /// - Parameters:
    ///   - event: The triggering event with the click through data
    ///   - config: configuration data
    func handleTrackingInfo(event: Event, _ config: [String: Any]) {
        guard let expEventDatasetId = config[MessagingConstants.SharedState.Configuration.EXPERIENCE_EVENT_DATASET] as? String, !expEventDatasetId.isEmpty else {
            Log.warning(label: MessagingConstants.LOG_TAG,
                        "Failed to handle tracking information for push notification: " +
                            "Experience event dataset ID from the config is invalid or not available. '\(event.id.uuidString)'")
            return
        }

        // Get the xdm data with push tracking details
        guard var xdmMap = getXdmData(event: event, config: config) else {
            Log.warning(label: MessagingConstants.LOG_TAG,
                        "Failed to handle tracking information for push notification: " +
                            "Error while creating xdmMap with the push tracking details from the event and config. '\(event.id.uuidString)'")
            return
        }

        // Add application specific tracking data
        let applicationOpened = event.applicationOpened
        xdmMap = addApplicationData(applicationOpened: applicationOpened, xdmData: xdmMap)

        // Add Adobe specific tracking data
        xdmMap = addAdobeData(event: event, xdmDict: xdmMap)

        // Creating xdm edge event data
        let xdmEventData: [String: Any] = [
            MessagingConstants.XDM.DataKeys.XDM: xdmMap,
            MessagingConstants.XDM.DataKeys.META: [
                MessagingConstants.XDM.DataKeys.COLLECT: [
                    MessagingConstants.XDM.DataKeys.DATASET_ID: expEventDatasetId
                ]
            ]
        ]

        // Creating xdm edge event with request content source type
        let event = Event(name: MessagingConstants.EventName.PUSH_TRACKING_EDGE,
                          type: EventType.edge,
                          source: EventSource.requestContent,
                          data: xdmEventData)
        dispatch(event: event)
    }

    /// Send an edge event to sync the push notification details with push token
    ///
    /// - Parameters:
    ///   - ecid: Experience cloud id
    ///   - token: Push token for the device
    ///   - platform: `String` denoting the platform `apns` or `apnsSandbox`
    func sendPushToken(ecid: String, token: String, platform: String) {
        // send the request
        guard let appId: String = Bundle.main.bundleIdentifier else {
            Log.warning(label: MessagingConstants.LOG_TAG, "Failed to sync the push token, App bundle identifier is invalid.")
            return
        }

        // Create the profile experience event to send the push notification details with push token to profile
        let profileEventData: [String: Any] = [
            MessagingConstants.PushNotificationDetails.PUSH_NOTIFICATION_DETAILS: [
                [MessagingConstants.PushNotificationDetails.APP_ID: appId,
                 MessagingConstants.PushNotificationDetails.TOKEN: token,
                 MessagingConstants.PushNotificationDetails.PLATFORM: platform,
                 MessagingConstants.PushNotificationDetails.DENYLISTED: false,
                 MessagingConstants.PushNotificationDetails.IDENTITY: [
                    MessagingConstants.PushNotificationDetails.NAMESPACE: [
                        MessagingConstants.PushNotificationDetails.CODE: MessagingConstants.PushNotificationDetails.JsonValues.ECID
                    ],
                    MessagingConstants.PushNotificationDetails.ID: ecid
                 ]]
            ]
        ]

        // Creating xdm edge event data
        let xdmEventData: [String: Any] = [MessagingConstants.XDM.DataKeys.DATA: profileEventData]
        // Creating xdm edge event with request content source type
        let event = Event(name: MessagingConstants.EventName.PUSH_PROFILE_EDGE,
                          type: EventType.edge,
                          source: EventSource.requestContent,
                          data: xdmEventData)
        dispatch(event: event)
    }

    // MARK: - private methods

    /// Adding Adobe/AJO specific data to tracking information map.
    ///
    /// - Parameters:
    ///  - event: `Event` with Adobe AJO tracking information
    ///  - xdmDict: `[String: Any]` which is updated with the AJO tracking information.
    /// - Returns: a dictionary combining Adobe related data with the provided `xdmDict`
    private func addAdobeData(event: Event, xdmDict: [String: Any]) -> [String: Any] {
        // make sure this event has adobe xdm data
        guard event.adobeXdm != nil else {
            Log.warning(label: MessagingConstants.LOG_TAG,
                        "Failed to update xdmMap with Adobe/AJO related informations : Adobe/AJO information are invalid or not available in the event '\(event.id.uuidString)'.")
            return xdmDict
        }

        // required keys are found using the following priority
        // 1. check the event's "mixins" key
        // 2. check the event's "cjm" key
        var mixins: [String: Any]
        if event.mixins != nil {
            mixins = event.mixins!
        } else {
            guard let cjm = event.cjm else {
                Log.warning(label: MessagingConstants.LOG_TAG,
                            "Failed to update xdmMap with Adobe/AJO information : Adobe/AJO data is not available in the event '\(event.id.uuidString)'.")
                return xdmDict
            }

            mixins = cjm
        }

        var xdmDictResult = xdmDict

        // Add all the key and value pair to xdmDictResult
        xdmDictResult.mergeXdm(rhs: mixins)

        // Check if the xdm data provided by the customer is using cjm for tracking
        // Check if both `MessagingConstant.AdobeTrackingKeys.EXPERIENCE` and `MessagingConstant.AdobeTrackingKeys.CUSTOMER_JOURNEY_MANAGEMENT` exists
        if var experienceDict = xdmDictResult[MessagingConstants.AdobeTrackingKeys.EXPERIENCE] as? [String: Any] {
            if var cjmDict = experienceDict[MessagingConstants.AdobeTrackingKeys.CUSTOMER_JOURNEY_MANAGEMENT] as? [String: Any] {
                // Adding Message profile and push channel context to CUSTOMER_JOURNEY_MANAGEMENT
                guard let messageProfile = MessagingConstants.AdobeTrackingKeys.MESSAGE_PROFILE_JSON.toJsonDictionary() else {
                    Log.warning(label: MessagingConstants.LOG_TAG,
                                "Failed to update xdmMap with adobe/cjm informations:" +
                                    "converting message profile string to dictionary failed in the event '\(event.id.uuidString)'.")
                    return xdmDictResult
                }
                // Merging the dictionary
                cjmDict.mergeXdm(rhs: messageProfile)
                experienceDict[MessagingConstants.AdobeTrackingKeys.CUSTOMER_JOURNEY_MANAGEMENT] = cjmDict
                xdmDictResult[MessagingConstants.AdobeTrackingKeys.EXPERIENCE] = experienceDict
            }
        } else {
            Log.warning(label: MessagingConstants.LOG_TAG,
                        "Failed to send adobe/cjm information data with the tracking," +
                            "\(MessagingConstants.AdobeTrackingKeys.EXPERIENCE) is missing in the event '\(event.id.uuidString)'.")
        }
        return xdmDictResult
    }

    /// Adding application data based on the application opened or not
    /// - Parameters:
    ///   - applicationOpened: `Bool` stating whether the application is opened or not
    ///   - xdmData: `[AnyHashable: Any]` xdm data in which application data needs to be added
    /// - Returns: `[String: Any]` which contains the application data
    private func addApplicationData(applicationOpened: Bool, xdmData: [String: Any]) -> [String: Any] {
        var xdmDataResult = xdmData
        xdmDataResult[MessagingConstants.AdobeTrackingKeys.APPLICATION] =
            [MessagingConstants.AdobeTrackingKeys.LAUNCHES:
                [MessagingConstants.AdobeTrackingKeys.LAUNCHES_VALUE: applicationOpened ? 1 : 0]]
        return xdmDataResult
    }

    /// Creates the xdm schema from event data
    /// - Parameters:
    ///   - event: `Event` with push notification tracking information
    ///   - config: `[String: Any]` with configuration informations
    /// - Returns: `[String: Any]?` which contains the xdm data
    private func getXdmData(event: Event, config: [String: Any]) -> [String: Any]? {
        guard let eventType = event.eventType else {
            Log.warning(label: MessagingConstants.LOG_TAG, "Updating xdm data for tracking failed, eventType is invalid or nil in the event '\(event.id.uuidString)'.")
            return nil
        }
        let messageId = event.messagingId
        let actionId = event.actionId

        if eventType.isEmpty == true || messageId == nil || messageId?.isEmpty == true {
            Log.trace(label: MessagingConstants.LOG_TAG, "Updating xdm data for tracking failed, EventType or MessageId received in the event '\(event.id.uuidString)' is nil.")
            return nil
        }

        var xdmDict: [String: Any] = [MessagingConstants.XDM.DataKeys.EVENT_TYPE: eventType]
        var pushNotificationTrackingDict: [String: Any] = [:]
        var customActionDict: [String: Any] = [:]
        if actionId != nil {
            customActionDict[MessagingConstants.XDM.DataKeys.ACTION_ID] = actionId
            pushNotificationTrackingDict[MessagingConstants.XDM.DataKeys.CUSTOM_ACTION] = customActionDict
        }
        pushNotificationTrackingDict[MessagingConstants.XDM.DataKeys.PUSH_PROVIDER_MESSAGE_ID] = messageId
        pushNotificationTrackingDict[MessagingConstants.XDM.DataKeys.PUSH_PROVIDER] = getPlatform(config: config)
        xdmDict[MessagingConstants.XDM.DataKeys.PUSH_NOTIFICATION_TRACKING] = pushNotificationTrackingDict

        return xdmDict
    }
}
