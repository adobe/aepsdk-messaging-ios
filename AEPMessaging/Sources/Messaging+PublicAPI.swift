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
    ///
    @available(*, deprecated, message: "This method is deprecated. Use Messaging.handleNotificationResponse(response) instead to automatically track application open and handle notification actions.")
    @objc(handleNotificationResponse:applicationOpened:withCustomActionId:)
    static func handleNotificationResponse(_ response: UNNotificationResponse, applicationOpened: Bool, customActionId: String?) {
        let notificationRequest = response.notification.request

        // Checking if the message has the optional xdm key
        let xdm = notificationRequest.content.userInfo[MessagingConstants.XDM.AdobeKeys._XDM] as? [String: Any]
        if xdm == nil {
            Log.debug(label: MessagingConstants.LOG_TAG, "XDM specific fields are missing from push notification response.")
        }

        let messageId = notificationRequest.identifier
        if messageId.isEmpty {
            Log.warning(label: MessagingConstants.LOG_TAG, "Failed to track push notification interaction, MessageId is empty in the response.")
            return
        }

        // Creating event data with tracking informations
        var eventData: [String: Any] = [MessagingConstants.Event.Data.Key.MESSAGE_ID: messageId,
                                        MessagingConstants.Event.Data.Key.APPLICATION_OPENED: applicationOpened,
                                        MessagingConstants.XDM.Key.ADOBE_XDM: xdm ?? [:]] // If xdm data is nil we use empty dictionary
        if customActionId == nil {
            eventData[MessagingConstants.Event.Data.Key.EVENT_TYPE] = MessagingConstants.XDM.Push.EventType.APPLICATION_OPENED
        } else {
            eventData[MessagingConstants.Event.Data.Key.EVENT_TYPE] = MessagingConstants.XDM.Push.EventType.CUSTOM_ACTION
            eventData[MessagingConstants.Event.Data.Key.ACTION_ID] = customActionId
        }

        let event = Event(name: MessagingConstants.Event.Name.PUSH_NOTIFICATION_INTERACTION,
                          type: MessagingConstants.Event.EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)
        MobileCore.dispatch(event: event)
    }

    /// Sends the push notification interactions as an experience event to Adobe Experience Edge.
    /// - Parameters:
    ///   - response: UNNotificationResponse object which contains the payload and xdm informations.
    static func handleNotificationResponse(_ response: UNNotificationResponse) {
        hasApplicationOpenedForResponse(response, completion: { isAppOpened in

            let notificationRequest = response.notification.request

            // Checking if the message has the optional xdm key
            let xdm = notificationRequest.content.userInfo[MessagingConstants.XDM.AdobeKeys._XDM] as? [String: Any]
            if xdm == nil {
                Log.debug(label: MessagingConstants.LOG_TAG, "Optional XDM specific fields are missing from push notification interaction.")
            }

            let eventData: [String: Any] = [MessagingConstants.Event.Data.Key.MESSAGE_ID: notificationRequest.identifier,
                                            MessagingConstants.Event.Data.Key.APPLICATION_OPENED: isAppOpened,
                                            MessagingConstants.Event.Data.Key.ADOBE_XDM: xdm ?? [:]] // If xdm data is nil we use

            let modifiedEventData = addNotificationActionToEventData(eventData, response)

            let event = Event(name: MessagingConstants.Event.Name.PUSH_NOTIFICATION_INTERACTION,
                              type: MessagingConstants.Event.EventType.messaging,
                              source: EventSource.requestContent,
                              data: modifiedEventData)
            MobileCore.dispatch(event: event)
        })
    }

    /// Initiates a network call to retrieve remote In-App Message definitions.
    static func refreshInAppMessages() {
        let eventData: [String: Any] = [MessagingConstants.Event.Data.Key.REFRESH_MESSAGES: true]
        let event = Event(name: MessagingConstants.Event.Name.REFRESH_MESSAGES,
                          type: MessagingConstants.Event.EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)

        MobileCore.dispatch(event: event)
    }

    // MARK: - Private Helper Methods

    /// Determines whether the user's response to a notification has caused the application to open
    ///
    /// This method analyzes the registered categories and notification action buttons of the application
    /// and determines if the application was opened based on the action performed by the user. The result is provided through the `completion` closure.
    ///
    /// - Parameters:
    ///   - response: The user's response to a notification, represented by a `UNNotificationResponse` object.
    ///   - completion: A closure that takes a `Bool` parameter indicating whether the application was opened or not. This closure is invoked asynchronously once the determination is made.
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
            // customActionId `UNNotificationDefaultActionIdentifier` indicates user tapped the notification body.
            // This results in opening of the application.
            modifiedEventData[MessagingConstants.Event.Data.Key.EVENT_TYPE] = MessagingConstants.XDM.Push.EventType.APPLICATION_OPENED

        // Coming in next PR,
        // TODO: add any notificaiton action url to the event data to be processed.
        case UNNotificationDismissActionIdentifier:
            // customActionId `UNNotificationDefaultActionIdentifier` indicates user has dismissed the notification by tapping "Clear" action button
            modifiedEventData[MessagingConstants.Event.Data.Key.EVENT_TYPE] = MessagingConstants.XDM.Push.EventType.CUSTOM_ACTION
            modifiedEventData[MessagingConstants.Event.Data.Key.ACTION_ID] = "Dismiss"
        default:
            // If customActionId is none of the default values. This means
            // This results in opening of the application.
            modifiedEventData[MessagingConstants.Event.Data.Key.EVENT_TYPE] = MessagingConstants.XDM.Push.EventType.CUSTOM_ACTION
            modifiedEventData[MessagingConstants.Event.Data.Key.ACTION_ID] = response.actionIdentifier
        }

        return modifiedEventData
    }
}
