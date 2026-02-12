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
    /// This API method will also automatically handle click behavior defined for the push notification.
    /// Use the optional urlHandler callback to handle the actionable URL from the push notification.
    /// The urlHandler does not get called for push notification that is not originated from Adobe Journey Optimizer.
    /// If the urlHandler closure returns `true`, the SDK will not handle the URL and the application is responsible for handling the URL.
    /// If the urlHandler closure returns `false`, the SDK will handle the opening of the URL.
    ///
    /// - Parameters:
    ///   - response: UNNotificationResponse object which contains the payload and xdm informations.
    ///   - urlHandler: An optional closure to handle the actionable URL from the push notification.
    ///   - closure : An optional callback with `PushTrackingStatus` representing the tracking status of the interacted notification
    @objc(handleNotificationResponse:urlHandler:closure:)
    static func handleNotificationResponse(_ response: UNNotificationResponse,
                                           urlHandler: ((URL) -> Bool)? = nil,
                                           closure: ((PushTrackingStatus) -> Void)? = nil) {
        let notificationRequest = response.notification.request

        // Checking if the message has the _xdm key that contains tracking information
        guard let xdm = notificationRequest.content.userInfo[MessagingConstants.XDM.AdobeKeys._XDM] as? [String: Any], !xdm.isEmpty else {
            Log.trace(label: MessagingConstants.LOG_TAG, "XDM fields containing tracking data are not present in the received push notification response. No push interaction tracking will be done for the notification.")
            closure?(.noTrackingData)
            return
        }

        // check for a deeplink to an in-app message
        let pushToInappIdentifier = notificationRequest.content.userInfo[MessagingConstants.PushNotification.UserInfoKey.PUSH_TO_INAPP] as? String
        if let pushToInappIdentifier = pushToInappIdentifier {
            // we found an in-app to trigger, make a call to refresh IAMs from the remote to make sure we have this message
            Log.trace(label: MessagingConstants.LOG_TAG, "Found an in-app message to show based on user interaction with a push notification. Downloading updated message definitions to ensure availability of the desired in-app message.")
            RefreshInAppHandler.shared.refresh { success in
                if !success {
                    Log.debug(label: MessagingConstants.LOG_TAG, "Failed to download updated in-app message definitions. Attempting to show the in-app message anyway.")
                }

                // send the event to trigger the in-app notification
                let event = Event(name: MessagingConstants.Event.Name.PUSH_TO_IN_APP,
                                  type: EventType.rulesEngine,
                                  source: EventSource.requestContent,
                                  data: [
                                      MessagingConstants.PushNotification.UserInfoKey.PUSH_TO_INAPP: pushToInappIdentifier
                                  ])
                MobileCore.dispatch(event: event)
            }
        }

        // Get off the main thread to process notification response
        DispatchQueue.global().async {
            hasApplicationOpenedForResponse(response, completion: { isAppOpened in
                let eventData: [String: Any] = [MessagingConstants.Event.Data.Key.ID: notificationRequest.identifier,
                                                MessagingConstants.Event.Data.Key.APPLICATION_OPENED: isAppOpened,
                                                MessagingConstants.Event.Data.Key.ADOBE_XDM: xdm]

                let modifiedEventData = addNotificationActionToEventData(eventData, response, urlHandler)

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
    /// Uses RefreshInAppHandler for deduplication of concurrent refresh requests.
    static func refreshInAppMessages() {
        RefreshInAppHandler.shared.refresh()
    }

    // MARK: Personalization via Surfaces

    /// Dispatches an event to fetch propositions for the provided surfaces from remote.
    /// - Parameters:
    ///   - surfaces: An array of `Surface` objects.
    static func updatePropositionsForSurfaces(_ surfaces: [Surface]) {
        updatePropositionsForSurfaces(surfaces, nil)
    }

    /// Dispatches an event to fetch propositions for the provided surfaces from remote.
    /// If provided, `completion` will be called on the Messaging extension's background thread once the response has been fully processed.
    /// `true` will be passed to the `completion` method if a network response was returned and successfully processed.
    /// - Parameters:
    ///   - surfaces: An array of `Surface` objects.
    ///   - completion: An optional completion handler to be called once the proposition response has been processed by the Messaging extension
    @objc(updatePropositionsForSurfaces:completion:)
    static func updatePropositionsForSurfaces(_ surfaces: [Surface], _ completion: ((Bool) -> Void)? = nil) {
        let validSurfaces = surfaces
            .filter { $0.isValid }

        guard !validSurfaces.isEmpty else {
            Log.warning(label: MessagingConstants.LOG_TAG,
                        "Cannot update propositions as the provided surfaces array has no valid items.")
            completion?(false)
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

        // create a CompletionHandler if a callback was provided
        if let completion = completion {
            completionHandlers.append(CompletionHandler(originatingEvent: event, handler: completion))
        }

        MobileCore.dispatch(event: event)
    }

    /// Retrieves the previously fetched (and cached) feeds content from the SDK for the provided surfaces.
    /// If the feeds content for one or more surfaces isn't previously cached in the SDK, it will not be retrieved from Adobe Journey Optimizer via the Experience Edge network.
    /// - Parameters:
    ///   - surfaces: An array of `Surface` objects.
    ///   - completion: The completion handler to be invoked with a dictionary containing the surface objects and the corresponding array of Proposition objects.
    static func getPropositionsForSurfaces(_ surfaces: [Surface], _ completion: @escaping ([Surface: [Proposition]]?, Error?) -> Void) {
        let validSurfaces = surfaces
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

        MobileCore.dispatch(event: event, timeout: 5) { responseEvent in
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
    private static func hasApplicationOpenedForResponse(_ response: UNNotificationResponse,
                                                        completion: @escaping (Bool) -> Void) {
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
    ///   - urlHandler: An optional closure defined in the consumer app to  handle the actionable URL from the push notification.
    /// - Returns: The modified event data dictionary.
    private static func addNotificationActionToEventData(_ eventData: [String: Any],
                                                         _ response: UNNotificationResponse,
                                                         _ urlHandler: ((URL) -> Bool)?) -> [String: Any] {
        var modifiedEventData = eventData
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // actionIdentifier `UNNotificationDefaultActionIdentifier` indicates user tapped the notification body.
            // This results in opening of the application.
            modifiedEventData[MessagingConstants.Event.Data.Key.EVENT_TYPE] = MessagingConstants.XDM.Push.EventType.APPLICATION_OPENED

            let userInfo = response.notification.request.content.userInfo
            // If the notification does not contain a valid click through URL, log a warning and break
            guard let clickThroughURLString = userInfo[MessagingConstants.PushNotification.UserInfoKey.ACTION_URL] as? String,
                  let clickThroughURL = URL(string: clickThroughURLString)
            else {
                Log.warning(label: MessagingConstants.LOG_TAG, "Invalid or missing click through URL on notification.")
                break
            }

            // If the urlHandler is not defined by the consumer app, then add the click through URL to the event data.
            guard let urlHandler = urlHandler else {
                modifiedEventData[MessagingConstants.Event.Data.Key.PUSH_CLICK_THROUGH_URL] = clickThroughURLString
                break
            }

            // If the urlHandler returns false, then add the click through URL to the event data.
            if !urlHandler(clickThroughURL) {
                modifiedEventData[MessagingConstants.Event.Data.Key.PUSH_CLICK_THROUGH_URL] = clickThroughURLString
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
