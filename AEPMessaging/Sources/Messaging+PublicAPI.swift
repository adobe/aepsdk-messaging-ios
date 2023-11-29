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
import UserNotifications

@objc public extension Messaging {
    /// Sends the push notification interactions as an experience event to Adobe Experience Edge.
    /// - Parameters:
    ///   - response: UNNotificationResponse object which contains the payload and xdm informations.
    ///   - applicationOpened: Boolean values denoting whether the application was opened when notification was clicked
    ///   - customActionId: String value of the custom action (e.g button id on the notification) which was clicked.
    @available(*, deprecated, message: "This method is deprecated. Use Messaging.handleNotificationResponse(:) instead to automatically track application open and handle notification actions.")
    @objc(handleNotificationResponse:applicationOpened:withCustomActionId:)
    static func handleNotificationResponse(_ response: UNNotificationResponse, applicationOpened: Bool, customActionId: String?) {
        let notificationRequest = response.notification.request

        // Checking if the message has the _xdm key that contains tracking information
        guard let xdm = notificationRequest.content.userInfo[MessagingConstants.XDM.AdobeKeys._XDM] as? [String: Any], !xdm.isEmpty else {
            Log.debug(label: MessagingConstants.LOG_TAG, "XDM specific fields are missing from push notification response. Ignoring to track push notification.")
            return
        }

        // Creating event data with tracking informations
        var eventData: [String: Any] = [MessagingConstants.Event.Data.Key.ID: notificationRequest.identifier,
                                        MessagingConstants.Event.Data.Key.APPLICATION_OPENED: applicationOpened,
                                        MessagingConstants.XDM.Key.ADOBE_XDM: xdm]
        if customActionId == nil {
            eventData[MessagingConstants.Event.Data.Key.EVENT_TYPE] = MessagingConstants.XDM.Push.EventType.APPLICATION_OPENED
        } else {
            eventData[MessagingConstants.Event.Data.Key.EVENT_TYPE] = MessagingConstants.XDM.Push.EventType.CUSTOM_ACTION
            eventData[MessagingConstants.Event.Data.Key.ACTION_ID] = customActionId
        }

        let event = Event(name: MessagingConstants.Event.Name.PUSH_NOTIFICATION_INTERACTION,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)
        MobileCore.dispatch(event: event)
    }

    /// Sends the push notification interactions as an experience event to Adobe Experience Edge.
    /// This API method will also automatically handle click behavior defined for the push notification.
    /// - Parameters:
    ///   - response: UNNotificationResponse object which contains the payload and xdm informations.
    ///   - closure : An optional callback with `PushTrackingStatus` representing the tracking status of the interacted notification
    @objc(handleNotificationResponse:closure:)
    static func handleNotificationResponse(_ response: UNNotificationResponse, closure: ((PushTrackingStatus) -> Void)? = nil) {
        let notificationRequest = response.notification.request

        // Checking if the message has the _xdm key that contains tracking information
        guard let xdm = notificationRequest.content.userInfo[MessagingConstants.XDM.AdobeKeys._XDM] as? [String: Any], !xdm.isEmpty else {
            Log.debug(label: MessagingConstants.LOG_TAG, "XDM specific fields are missing from push notification response. Ignoring to track push notification.")
            closure?(.noTrackingData)
            return
        }

        // Get off the main thread to process notification response
        DispatchQueue.global().async {
            hasApplicationOpenedForResponse(response, completion: { isAppOpened in

                let eventData: [String: Any] = [MessagingConstants.Event.Data.Key.ID: notificationRequest.identifier,
                                                MessagingConstants.Event.Data.Key.APPLICATION_OPENED: isAppOpened,
                                                MessagingConstants.Event.Data.Key.ADOBE_XDM: xdm]

                let modifiedEventData = addNotificationActionToEventData(eventData, response)

                let event = Event(name: MessagingConstants.Event.Name.PUSH_NOTIFICATION_INTERACTION,
                                  type: EventType.messaging,
                                  source: EventSource.requestContent,
                                  data: modifiedEventData)

                MobileCore.dispatch(event: event) { responseEvent in
                    guard let status = responseEvent?.pushTrackingStatus else {
                        closure?(.unknownError)
                        return
                    }
                    closure?(status)
                }
            })
        }
    }

    /// Initiates a network call to retrieve remote In-App Message definitions.
    static func refreshInAppMessages() {
        let eventData: [String: Any] = [MessagingConstants.Event.Data.Key.REFRESH_MESSAGES: true]
        let event = Event(name: MessagingConstants.Event.Name.REFRESH_MESSAGES,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)

        MobileCore.dispatch(event: event)
    }

    // MARK: Personalization via Surfaces

    /// Dispatches an event to fetch propositions for the provided surfaces from remote.
    /// - Parameter surfaces: An array of surface objects.
    static func updatePropositionsForSurfaces(_ surfaces: [Surface]) {
        let validSurfaces = surfaces
            .filter { $0.isValid }

        guard !validSurfaces.isEmpty else {
            Log.warning(label: MessagingConstants.LOG_TAG,
                        "Cannot update propositions as the provided surfaces array has no valid items.")
            return
        }

        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.UPDATE_PROPOSITIONS: true,
            MessagingConstants.Event.Data.Key.SURFACES: validSurfaces.compactMap { $0.asDictionary() }
        ]

        let event = Event(name: MessagingConstants.Event.Name.UPDATE_PROPOSITIONS,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)

        MobileCore.dispatch(event: event)
    }

    /// Retrieves the previously fetched (and cached) feeds content from the SDK for the provided surfaces.
    /// If the feeds content for one or more surfaces isn't previously cached in the SDK, it will not be retrieved from Adobe Journey Optimizer via the Experience Edge network.
    /// - Parameters:
    ///   - surfacePaths: An array of surface objects.
    ///   - completion: The completion handler to be invoked with a dictionary containing the surface objects and the corresponding array of Proposition objects.
    static func getPropositionsForSurfaces(_ surfacePaths: [Surface], _ completion: @escaping ([Surface: [MessagingProposition]]?, Error?) -> Void) {
        let validSurfaces = surfacePaths
            .filter { $0.isValid }

        guard !validSurfaces.isEmpty else {
            Log.warning(label: MessagingConstants.LOG_TAG,
                        "Cannot get propositions as the provided surfaces array has no valid items.")
            completion(nil, AEPError.invalidRequest)
            return
        }

        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.GET_PROPOSITIONS: true,
            MessagingConstants.Event.Data.Key.SURFACES: validSurfaces.compactMap { $0.asDictionary() }
        ]

        let event = Event(name: MessagingConstants.Event.Name.GET_PROPOSITIONS,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)

        MobileCore.dispatch(event: event, timeout: 1) { responseEvent in
            guard let responseEvent = responseEvent else {
                completion(nil, AEPError.callbackTimeout)
                return
            }

            if let error = responseEvent.responseError {
                completion(nil, error)
                return
            }

            guard let propositions = responseEvent.propositions else {
                completion(nil, AEPError.unexpected)
                return
            }

            completion(propositions.toDictionary { Surface(uri: $0.scope) }, .none)
        }
    }

    // MARK: - Private Helper Methods

    /// Determines whether the user's response to a notification has caused the application to open
    ///
    /// This method analyzes the registered categories and notification action buttons of the application
    /// and determines if the application was opened based on the action performed by the user. The result is provided through the `completion` closure.
    ///
    /// - Parameters:
    ///   - response: The user's response to a notification, represented by a `UNNotificationResponse` object.
    ///   - completion: The completion block to be executed with a boolean value determining if application was opened because of user's interaction with the notification.
    ///
    /// - Note: The completion handler is invoked asynchronously, so any code relying on the result should be placed within the completion handler or called from there.
    private static func hasApplicationOpenedForResponse(_ response: UNNotificationResponse, completion: @escaping (Bool) -> Void) {
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            completion(true)
        case UNNotificationDismissActionIdentifier:
            completion(false)
        default:
            // If customAction has been performed by the user,
            // then examine the registered custom action option to check if the action has brought the app to foreground.
            UNUserNotificationCenter.current().getNotificationCategories { categories in
                for category in categories where category.identifier == response.notification.request.content.categoryIdentifier {
                    for action in category.actions where action.identifier == response.actionIdentifier {
                        if action.options.contains(.foreground) {
                            completion(true)
                            return
                        } else {
                            completion(false)
                            return
                        }
                    }
                }
                // Unlikely Case: If the custom actionID is not found in the registered categories, then return false
                completion(false)
            }
        }
    }

    /// Modifies the provided event data based on the user's response to a notification.
    ///
    /// - Parameters:
    ///   - eventData: The original event data dictionary.
    ///   - response: The user's response to a notification, represented by a `UNNotificationResponse` object.
    /// - Returns: The modified event data dictionary.
    private static func addNotificationActionToEventData(_ eventData: [String: Any], _ response: UNNotificationResponse) -> [String: Any] {
        var modifiedEventData = eventData
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // actionIdentifier `UNNotificationDefaultActionIdentifier` indicates user tapped the notification body.
            // This results in opening of the application.
            modifiedEventData[MessagingConstants.Event.Data.Key.EVENT_TYPE] = MessagingConstants.XDM.Push.EventType.APPLICATION_OPENED

            // Add actionable URL to eventData if available
            if let clickThroughURL = response.notification.request.content.userInfo[MessagingConstants.PushNotification.UserInfoKey.ACTION_URL] {
                modifiedEventData[MessagingConstants.Event.Data.Key.PUSH_CLICK_THROUGH_URL] = clickThroughURL
            }
        case UNNotificationDismissActionIdentifier:
            // actionIdentifier `UNNotificationDismissActionIdentifier` indicates user has dismissed the
            // notification by tapping "Clear" action button.
            modifiedEventData[MessagingConstants.Event.Data.Key.EVENT_TYPE] = MessagingConstants.XDM.Push.EventType.CUSTOM_ACTION
            modifiedEventData[MessagingConstants.Event.Data.Key.ACTION_ID] = "Dismiss"
        default:
            // If actionIdentifier is none of the default values.
            // This indicates that a custom action on a notification is taken by the user. (i.e. The user has clicked on one of the notification action buttons.)
            modifiedEventData[MessagingConstants.Event.Data.Key.EVENT_TYPE] = MessagingConstants.XDM.Push.EventType.CUSTOM_ACTION
            modifiedEventData[MessagingConstants.Event.Data.Key.ACTION_ID] = response.actionIdentifier
        }

        return modifiedEventData
    }
}
