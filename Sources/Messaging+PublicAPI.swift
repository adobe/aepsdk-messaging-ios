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
import UserNotifications

public extension Messaging {

    /// Sends the push notification interactions as an experience event to Adobe Experience Edge.
    /// - Parameters:
    ///   - response: UNNotificationResponse object which contains the payload and xdm informations.
    ///   - applicationOpened: Boolean values denoting whether the application was opened when notification was clicked
    ///   - customActionId: String value of the custom action (e.g button id on the notification) which was clicked.
    static func handleNotificationResponse(_ response: UNNotificationResponse, applicationOpened: Bool, customActionId: String?) {
        let notificationRequest = response.notification.request
        guard let xdm = notificationRequest.content.userInfo[MessagingConstants.AdobeTrackingKeys.XDM] as? [String: Any] else {
            Log.warning(label: MessagingConstants.LOG_TAG, "Failed to track push notification interaction. XDM specific fields are missing.")
            return
        }
        let messageId = notificationRequest.identifier
        if messageId.isEmpty {
            Log.warning(label: MessagingConstants.LOG_TAG, "Failed to track push notification interaction, Message Id is invalid in the response. ")
            return
        }
        var eventType: String
        if customActionId == nil {
            eventType = MessagingConstants.EventDataKeys.EVENT_TYPE_PUSH_TRACKING_APPLICATION_OPENED
        } else {
            eventType = MessagingConstants.EventDataKeys.EVENT_TYPE_PUSH_TRACKING_CUSTOM_ACTION
        }
        let eventData: [String: Any] = ["eventType": eventType, "id": messageId, "applicationOpened": applicationOpened, "adobe": xdm]
        let event = Event(name: "Messaging Request Event",
                          type: MessagingConstants.EventTypes.MESSAGING,
                          source: MessagingConstants.EventSources.requestContent,
                          data: eventData)
        MobileCore.dispatch(event: event)
    }
}
