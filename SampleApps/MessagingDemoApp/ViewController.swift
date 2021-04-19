//
// Copyright 2020 Adobe. All rights reserved.
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
import AEPOfferDecisioning

class ViewController: UIViewController {
    @IBOutlet var switchShowMessages: UISwitch?
    
    var htmlDecisionScope: DecisionScope?
    private let messageHandler = MessageHandler()

    weak var appDelegate = UIApplication.shared.delegate as? AppDelegate

    override func viewDidLoad() {
        super.viewDidLoad()
        MobileCore.messagingDelegate = messageHandler
    }
    
    @IBAction func triggerInapp(_ sender: Any) {
//        MobileCore.track(state: "triggerInapp", data: ["testShowMessage":"true"])
        MobileCore.track(state: "triggerInapp", data: ["testShowMessage3":"true"])
    }
    
    /// Messaging delegate
    private class MessageHandler: MessagingDelegate {
        var showMessages = true
        
        func onShow(message: Showable) {
            
            let fullscreenMessage = message as? FullscreenMessage
            print("message was shown \(fullscreenMessage?.debugDescription ?? "undefined")")
        }
        
        func onDismiss(message: Showable) {
            let fullscreenMessage = message as? FullscreenMessage
            print("message was dismissed \(fullscreenMessage?.debugDescription ?? "undefined")")
        }
        
        func shouldShowMessage(message: Showable) -> Bool {
            
            // do whatever logic to decide if the message should show
            
            return showMessages
        }
    }
    
    @IBAction func toggleShowMessages(_ sender: Any) {
        if sender as? UISwitch == switchShowMessages {
            messageHandler.showMessages = !messageHandler.showMessages
            print("messageHandler.showMessages: \(messageHandler.showMessages)")
        }
    }
    
    @IBAction func scheduleNotification(_ sender: Any) {
        self.appDelegate?.scheduleNotification()
    }
    
    @IBAction func scheduleNotificationWithCustomAction(_ sender: Any) {
        self.appDelegate?.scheduleNotificationWithCustomAction()

    @IBAction func scheduleNotification(_: Any) {
        appDelegate?.scheduleNotification()
    }

    @IBAction func scheduleNotificationWithCustomAction(_: Any) {
        appDelegate?.scheduleNotificationWithCustomAction()
    }
    
    @IBAction func refreshMessages(_ sender: Any) {
        Messaging.refreshInAppMessages()
    }
}
