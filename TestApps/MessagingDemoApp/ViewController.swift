//
// Copyright 2021 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import AEPCore
import AEPMessaging
import AEPServices
import AEPAssurance
import UIKit
import UserNotifications
import WebKit
import UserNotifications

class ViewController: UIViewController {
    @IBOutlet var switchShowMessages: UISwitch?

    private let messageHandler = MessageHandler()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MobileCore.messagingDelegate = messageHandler
    }

    @IBAction func triggerFullscreen(_: Any) {
        MobileCore.track(action: "fullscreen", data: ["testFullscreen": "true"])
    }

    @IBAction func triggerModal(_: Any) {
        MobileCore.track(action: "triggerModal", data: ["testModal": "true"])
    }

    @IBAction func triggerBannerTop(_: Any) {
        MobileCore.track(action: "triggerBannerTop", data: ["testBannerTop": "true"])
    }

    @IBAction func triggerBannerBottom(_: Any) {
        MobileCore.track(action: "modalTakeoverGestures", data: nil)
    }

    /// Messaging delegate
    private class MessageHandler: MessagingDelegate {
        var showMessages = true
        var currentMessage: Message?
        let autoDismiss = false

        func onShow(message: Showable) {
            let fullscreenMessage = message as? FullscreenMessage
            print("message was shown \(fullscreenMessage?.debugDescription ?? "undefined")")
        }

        func onDismiss(message: Showable) {
            let fullscreenMessage = message as? FullscreenMessage
            print("message was dismissed \(fullscreenMessage?.debugDescription ?? "undefined")")
        }

        func shouldShowMessage(message: Showable) -> Bool {
            
            // access to the whole message from the parent
            let fullscreenMessage = message as? FullscreenMessage
            let message = fullscreenMessage?.parent

            // in-line handling of javascript calls
            // see Assets/nativeMethodCallingSample.html for an example of how to call this method
            message?.handleJavascriptMessage("buttonClicked") { content in
                print("magical handling of our content from js! content is: \(content ?? "empty")")
                message?.track(content as? String, withEdgeEventType: .inappInteract)
            }

            // if using the webview for something, make sure to dispatch back to the main thread
            DispatchQueue.main.async {
                // access the WKWebView containing the message's UI
                let messageWebView = message?.view as? WKWebView
                // execute JavaScript inside of the message's WKWebView
                messageWebView?.evaluateJavaScript("startTimer();") { result, error in
                    if error != nil {
                        // handle error
                    }
                    if result != nil {
                        // do something with the result
                    }
                }
            }
            
            // if we're not showing the message now, we can save it for later
            if !showMessages {
                currentMessage = message
                currentMessage?.track("message suppressed", withEdgeEventType: .inappTrigger)
            } else if autoDismiss {
                currentMessage = message
                let _ = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { timer in
                    timer.invalidate()
                    self.currentMessage?.track("test for reporting", withEdgeEventType: .inappInteract)
                    self.currentMessage?.dismiss()
                }
            }

            return showMessages
        }

        func urlLoaded(_ url: URL) {
            print("fullscreen message loaded url: \(url)")
        }
    }

    @IBAction func toggleShowMessages(_ sender: Any) {
        if sender as? UISwitch == switchShowMessages {
            messageHandler.showMessages.toggle()
            print("messageHandler.showMessages: \(messageHandler.showMessages)")
        }
    }

    @IBAction func scheduleNotification(_: Any) {
        scheduleNotification()
    }

    @IBAction func scheduleNotificationWithCustomAction(_: Any) {
        scheduleNotificationWithCustomAction()
    }

    @IBAction func refreshMessages(_: Any) {
        Messaging.refreshInAppMessages()
    }

    @IBAction func showStoredMessage(_: Any) {
        messageHandler.currentMessage?.show()
    }

    @IBAction func checkSequence(_: Any) {
        let checkSequenceEvent = Event(name: "Check Sequence", type: "iam.tester", source: "inbound", data: ["checkSequence": "true"])
        MobileCore.dispatch(event: checkSequenceEvent)
    }

    @IBAction func triggerEvent1(_: Any) {
        let event = Event(name: "Event1", type: "iam.tester", source: "inbound", data: ["firstEvent": "true"], mask: ["firstEvent"])
        MobileCore.dispatch(event: event)
    }

    @IBAction func triggerEvent2(_: Any) {
        let event = Event(name: "Event2", type: "iam.tester", source: "inbound", data: ["secondEvent": "true"], mask: ["secondEvent"])
        MobileCore.dispatch(event: event)
    }

    @IBAction func triggerEvent3(_: Any) {
        let event = Event(name: "Event3", type: "iam.tester", source: "inbound", data: ["thirdEvent": "true"], mask: ["thirdEvent"])
        MobileCore.dispatch(event: event)
    }

    @IBAction func sendTrackAction(_: Any) {
        let data = ["key": "value"]
        MobileCore.track(action: "buttonClicked", data: data)
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
}
