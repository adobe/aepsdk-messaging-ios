/*
Copyright 2023 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/

import SwiftUI

struct PushView: View {
    var body: some View {
        VStack {
            VStack {
                Text("Push")
                    .font(Font.title2.weight(.bold))
                    .frame(height: 100)
                    .padding(.top, 30)
                Divider()
            }
            Grid(alignment: .leading, horizontalSpacing: 70, verticalSpacing: 30) {
                GridRow {
                    Button("ScheduleNotification") {
                        scheduleNotification()
                    }
                }
                GridRow {
                    Button("ScheduleNotificationWithCustomAction") {
                        scheduleNotificationWithCustomAction()
                    }
                }
            }
            Spacer()
        }
    }
}

func scheduleNotification() {
    let content = UNMutableNotificationContent()

    content.title = "Notification Title"
    content.body = "This is example how to create "

    // userInfo is mimicking data that would be provided in the push payload by Adobe Journey Optimizer
    content.userInfo = ["_xdm": ["cjm": ["_experience": ["customerJourneyManagement":
                                                            ["messageExecution": ["messageExecutionID": "16-Sept-postman", "messageID": "567",
                                                                                  "journeyVersionID": "some-journeyVersionId", "journeyVersionInstanceId": "someJourneyVersionInstanceId"]]]]]]

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
    let identifier = "Local Notification"
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Error \(error.localizedDescription)")
        }
    }
}

func scheduleNotificationWithCustomAction() {
    let content = UNMutableNotificationContent()

    content.title = "Notification Title"
    content.body = "This is example how to create "
    content.categoryIdentifier = "MEETING_INVITATION"
    // userInfo is mimicking data that would be provided in the push payload by Adobe Journey Optimizer
    content.userInfo = ["_xdm": ["cjm": ["_experience": ["customerJourneyManagement":
                                                            ["messageExecution": ["messageExecutionID": "16-Sept-postman", "messageID": "567",
                                                                                  "journeyVersionID": "some-journeyVersionId", "journeyVersionInstanceId": "someJourneyVersionInstanceId"]]]]]]

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
    let identifier = "Local Notification"
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

    // Define the custom actions.
    let acceptAction = UNNotificationAction(identifier: "ACCEPT_ACTION",
                                            title: "Accept",
                                            options: .foreground)
    let declineAction = UNNotificationAction(identifier: "DECLINE_ACTION",
                                             title: "Decline",
                                             options: .destructive)
    // Define the notification type
    let meetingInviteCategory =
        UNNotificationCategory(identifier: "MEETING_INVITATION",
                               actions: [acceptAction, declineAction],
                               intentIdentifiers: [],
                               hiddenPreviewsBodyPlaceholder: "",
                               options: .customDismissAction)
    // Register the notification type.
    let notificationCenter = UNUserNotificationCenter.current()
    notificationCenter.setNotificationCategories([meetingInviteCategory])

    notificationCenter.add(request) { error in
        if let error = error {
            print("Error \(error.localizedDescription)")
        }
    }
}

struct PushView_Previews: PreviewProvider {
    static var previews: some View {
        PushView()
    }
}
