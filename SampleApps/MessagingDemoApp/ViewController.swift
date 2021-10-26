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
import UIKit
import UserNotifications
import WebKit

class ViewController: UIViewController {
    @IBOutlet var switchShowMessages: UISwitch?

    private let messageHandler = MessageHandler()

    weak var appDelegate = UIApplication.shared.delegate as? AppDelegate

    override func viewDidLoad() {
        super.viewDidLoad()
        MobileCore.messagingDelegate = messageHandler
    }

    @IBAction func triggerFullscreen(_ sender: Any) {
        MobileCore.dispatch(event: Event(name: "test", type: "iamtest", source: "iamtest", data: ["seahawks": "sad"]))
        
        
//        MobileCore.track(state: "triggerFullscreen", data: ["testFullscreen": "true"])

        // southwest
        //{"xdm:activityId":"xcore:offer-activity:14090235e6b6757a","xdm:placementId":"xcore:offer-placement:142426be131dce37"}
        
        //{"xdm:activityId":"xcore:offer-activity:14090235e6b6757a","xdm:placementId":"xcore:offer-placement:14254cbbee5de2b8"}
    }
    
    @IBAction func triggerModal(_ sender: Any) {
        MobileCore.track(state: "triggerModal", data: ["testSteveModal": "true"])
//        MobileCore.track(state: "triggerModal", data: ["testModal": "true"])
    }
    
    @IBAction func triggerBannerTop(_ sender: Any) {
        MobileCore.track(state: "triggerBannerTop", data: ["testBannerTop": "true"])
        
    }
    
    @IBAction func triggerBannerBottom(_ sender: Any) {
        MobileCore.track(state: "triggerInapp", data: ["testBannerBottom": "true"])
        
    }

    /// Messaging delegate
    private class MessageHandler: MessagingDelegate {
        var showMessages = true
        var currentMessage: Message?

        func onShow(message: Showable) {

            let fullscreenMessage = message as? FullscreenMessage
            let message = fullscreenMessage?.parent
            print("message was shown \(message?.id ?? "undefined")")
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
            message?.handleJavascriptMessage("magic") { content in
                print("magical handling of our content from js! content is: \(content ?? "empty")")
                message?.track(content as? String, withEdgeEventType: .inappInteract)
            }

            // get the uiview - add it
            let messageWebView = message?.view as! WKWebView
            print("message web view: \(messageWebView)")
            
            // if we're not showing the message now, we can save it for later
            if !showMessages {
                currentMessage = message
                currentMessage?.track("message suppressed", withEdgeEventType: .inappTrigger)
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

    @IBAction func scheduleNotification(_ sender: Any) {
        self.appDelegate?.scheduleNotification()
    }

    @IBAction func scheduleNotificationWithCustomAction(_ sender: Any) {
        self.appDelegate?.scheduleNotificationWithCustomAction()
    }

    @IBAction func refreshMessages(_ sender: Any) {
        Messaging.refreshInAppMessages()
    }

    @IBAction func showStoredMessage(_ sender: Any) {
        messageHandler.currentMessage?.show()
    }
    
    
    
    
    
    @IBAction func checkSequence(_ sender: Any) {
        let checkSequenceEvent = Event(name: "Check Sequence", type: "iam.tester", source: "inbound", data: ["checkSequence": "true"])
        MobileCore.dispatch(event: checkSequenceEvent)
    }
    
    @IBAction func triggerEvent1(_ sender: Any) {
        let event = Event(name: "Event1", type: "iam.tester", source: "inbound", data: ["firstEvent": "true"], mask: ["firstEvent"])
        MobileCore.dispatch(event: event)
    }
    
    @IBAction func triggerEvent2(_ sender: Any) {
        let event = Event(name: "Event2", type: "iam.tester", source: "inbound", data: ["secondEvent": "true"], mask: ["secondEvent"])
        MobileCore.dispatch(event: event)
    }
    
    @IBAction func triggerEvent3(_ sender: Any) {
        let event = Event(name: "Event3", type: "iam.tester", source: "inbound", data: ["thirdEvent": "true"], mask: ["thirdEvent"])
        MobileCore.dispatch(event: event)
    }
}
