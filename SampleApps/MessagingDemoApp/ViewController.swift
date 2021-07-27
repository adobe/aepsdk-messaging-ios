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
    
    

    @IBAction func triggerInapp(_ sender: Any) {
        
        MobileCore.track(state: "triggerInapp", data: ["testShowMessage": "true"])
        
    }

    
    
    /// Messaging delegate
    private class MessageHandler: MessagingDelegate {
        var showMessages = true
        var currentMessage: Message?

        func onShow(message: Showable) {
            
            let fullscreenMessage = message as? FullscreenMessage
            let message = fullscreenMessage?.parent as? Message
            print("message was shown \(message?.id ?? "undefined")")
        }

        func onDismiss(message: Showable) {
            
            
            
            let fullscreenMessage = message as? FullscreenMessage
            print("message was dismissed \(fullscreenMessage?.debugDescription ?? "undefined")")
        }

        func shouldShowMessage(message: Showable) -> Bool {
            
            // access to the whole message from the parent
            let fullscreenMessage = message as? FullscreenMessage
            let message = fullscreenMessage?.parent as? Message
            
            // in-line handling of javascript calls
            message?.handleJavascriptMessage("magic") { content in
                print("magical handling of our content from js! content is: \(content ?? "empty")")
                message?.track(content as! String)
            }
                        
            // get the uiview - add it
            // let messageWebView = message?.view as! WKWebView
            
            // if we're not showing the message now, we can save it for later
            if !showMessages {
                currentMessage = message
                currentMessage?.track("message suppressed")
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
}
