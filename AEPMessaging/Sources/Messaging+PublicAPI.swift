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
    private static var isFeedResponseListenerRegistered: Bool = false
    private static var feedsResponseHandler: (([String: Feed]) -> Void)?

    /// Sends the push notification interactions as an experience event to Adobe Experience Edge.
    /// - Parameters:
    ///   - response: UNNotificationResponse object which contains the payload and xdm informations.
    ///   - applicationOpened: Boolean values denoting whether the application was opened when notification was clicked
    ///   - customActionId: String value of the custom action (e.g button id on the notification) which was clicked.
    @objc(handleNotificationResponse:applicationOpened:withCustomActionId:)
    static func handleNotificationResponse(_ response: UNNotificationResponse, applicationOpened: Bool, customActionId: String?) {
        let notificationRequest = response.notification.request

        // Checking if the message has the optional xdm key
        let xdm = notificationRequest.content.userInfo[MessagingConstants.XDM.AdobeKeys._XDM] as? [String: Any]
        if xdm == nil {
            Log.debug(label: MessagingConstants.LOG_TAG, "Optional XDM specific fields are missing from push notification interaction.")
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

    /// Initiates a network call to retrieve remote In-App Message definitions.
    static func refreshInAppMessages() {
        let eventData: [String: Any] = [MessagingConstants.Event.Data.Key.REFRESH_MESSAGES: true]
        let event = Event(name: MessagingConstants.Event.Name.REFRESH_MESSAGES,
                          type: MessagingConstants.Event.EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)

        MobileCore.dispatch(event: event)
    }

    // MARK: Message Feed

    /// Dispatches an event to fetch message feeds for the provided surface paths from the Adobe Journey Optimizer via the Experience Edge network.
    /// - Parameter surfacePaths: An array of surface path strings.
    static func updateFeedsForSurfacePaths(_ surfacePaths: [String]) {
        let validSurfacePaths = surfacePaths
            .filter { !$0.isEmpty }

        guard !validSurfacePaths.isEmpty else {
            Log.warning(label: MessagingConstants.LOG_TAG,
                        "Cannot update feeds as the provided surface paths array has no valid items.")
            return
        }

        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.UPDATE_FEEDS: true,
            MessagingConstants.Event.Data.Key.SURFACES: validSurfacePaths
        ]

        let event = Event(name: MessagingConstants.Event.Name.UPDATE_MESSAGE_FEEDS,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)

        MobileCore.dispatch(event: event)
    }

    /// Retrieves the previously fetched (and cached) feeds content from the SDK for the provided surface path strings.
    /// If the feeds content for one or more surface paths isn't previously cached in the SDK, it will not be retrieved from the Adobe Journey Optimizer via the Experience Edge network.
    /// - Parameters:
    ///   - surfacePaths: An array of surface path strings.
    ///   - completion: The completion handler to be invoked with a dictionary containing the surface paths and the corresponding Feed objects.
    static func getFeedsForSurfacePaths(_ surfacePaths: [String], _ completion: @escaping ([String: Feed]?, Error?) -> Void) {
        let validSurfacePaths = surfacePaths
            .filter { !$0.isEmpty }

        guard !validSurfacePaths.isEmpty else {
            Log.warning(label: MessagingConstants.LOG_TAG,
                        "Cannot get feeds as the provided surface paths array has no valid items.")
            completion(nil, AEPError.invalidRequest)
            return
        }

        let eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.GET_FEEDS: true,
            MessagingConstants.Event.Data.Key.SURFACES: validSurfacePaths
        ]

        let event = Event(name: MessagingConstants.Event.Name.GET_MESSAGE_FEEDS,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: eventData)

        MobileCore.dispatch(event: event) { responseEvent in
            guard let responseEvent = responseEvent else {
                completion(nil, AEPError.callbackTimeout)
                return
            }

            if let error = responseEvent.responseError {
                completion(nil, error)
                return
            }

            guard let feeds = responseEvent.feeds else {
                completion(nil, AEPError.unexpected)
                return
            }

            completion(feeds, .none)
        }
    }

    /// Registers a permanent event listener with the Mobile Core for listening to personalization decisions events received upon a personalization query to the Experience Edge network.
    /// - Parameter completion: The completion handler to be invoked with a dictionary containing the surface paths and the corresponding Feed objects.
    static func setFeedsHandler(_ completion: (([String: Feed]) -> Void)? = nil) {
        if !isFeedResponseListenerRegistered {
            isFeedResponseListenerRegistered = true
            MobileCore.registerEventListener(type: EventType.messaging, source: EventSource.notification, listener: feedsResponseListener(_:))
        }
        feedsResponseHandler = completion
    }

    private static func feedsResponseListener(_ event: Event) {
        guard let feedsResponseHandler = feedsResponseHandler else {
            return
        }

        guard
            let feeds = event.feeds,
            !feeds.isEmpty
        else {
            Log.warning(label: MessagingConstants.LOG_TAG, "No valid feeds found in the notification event.")
            return
        }

        feedsResponseHandler(feeds)
    }
}
