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

import AEPAssurance
import AEPCore
import AEPEdge
import AEPEdgeConsent
import AEPEdgeIdentity
import AEPLifecycle
import AEPMessaging
import AEPSignal
import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        MobileCore.setLogLevel(.trace)

        let extensions = [
            Consent.self,
            Lifecycle.self,
            Identity.self,
            Messaging.self,
            Edge.self,
            Signal.self,
            Assurance.self
        ]

        MobileCore.registerExtensions(extensions) {
            // only start lifecycle if the application is not in the background
            DispatchQueue.main.async {
                if application.applicationState != .background {
                    MobileCore.lifecycleStart(additionalContextData: nil)
                }
            }
            
            // configure
            MobileCore.configureWith(appId: "")
            // set `messaging.useSandbox` to "true"  to test push notifications in debug environment (Apps signed with Development Certificate)
            #if DEBUG
                let debugConfig = ["messaging.useSandbox": true]
                MobileCore.updateConfigurationWith(configDict: debugConfig)
            #endif
        }
        
        registerForPushNotifications(application)
        registerNotificationCategories()
        return true
    }

    // MARK: - Push Notification registration methods
    func applicationWillEnterForeground(_: UIApplication) {
        MobileCore.lifecycleStart(additionalContextData: nil)
    }

    func applicationDidEnterBackground(_: UIApplication) {
        MobileCore.lifecyclePause()
    }
    
    // MARK: - Push Notification registration methods
    func registerForPushNotifications(_ application : UIApplication) {
        let center = UNUserNotificationCenter.current()
        // Ask for user permission
        center.requestAuthorization(options: [.badge, .sound, .alert]) { [weak self] granted, _ in
            guard granted else { return }
            
            center.delegate = self
            
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }
    
    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device token is - \(token)")
        MobileCore.setPushIdentifier(deviceToken)
    }

    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError _: Error) {
        MobileCore.setPushIdentifier(nil)
    }
    
    // MARK: - Handle Push Notification Reception
    // Delegate method that tells the app that a remote notification arrived that indicates there is data to be fetched.
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle the silent notifications received from AJO in here
        print("silent notification received")
        completionHandler(.noData)
    }
    

    // Delegate method to handle a notification that arrived while the app was running in the foreground.
    func userNotificationCenter(_: UNUserNotificationCenter,
                                willPresent _: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound, .badge])
    }

    // Delegate method is called when a notification is interacted with
    func userNotificationCenter(_: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            // UNNotificationDefaultActionIdentifier is an action which indicates the user has opened the app by tapping on the body of the notification.
            // since application has been opened because of this action, set applicationOpened to true
            // since there is no custom action performed on the notification, set customActionId to nil
            Messaging.handleNotificationResponse(response, applicationOpened: true, customActionId: nil)
        } else if response.actionIdentifier == UNNotificationDismissActionIdentifier {
            // UNNotificationDismissActionIdentifier is an action which indicates the user explicitly dismissed the notification interface.
            // Note : The system delivers this action only if your app configured the notification’s category object with the customDismissAction option
            // Note :  To trigger this action, the user must explicitly dismiss the notification interface. For example, the user must tap the Dismiss button
            // Note : Ignoring a notification or flicking away a notification banner doesn’t trigger this action.
            // Documentation : https://developer.apple.com/documentation/usernotifications/unnotificationdismissactionidentifier
            // since notification has been dismissed because of this action, set applicationOpened to false
            // since there is no custom action performed on the notification, set customActionId to nil
            Messaging.handleNotificationResponse(response, applicationOpened: false, customActionId: nil)
        } else {
            handleCustomAction(response)
        }

        // Always call the completion handler when done.
        completionHandler()
    }
    
    
    private func registerNotificationCategories() {
        // Registering a category that demonstrates using links on actionButton click
        let webUrlAction = UNNotificationAction(identifier: "WEB_URL", title: "Web Url", options: [.foreground])
        let deepLinkAction = UNNotificationAction(identifier: "DEEPLINK", title: "Deeplink", options: [.foreground])
        let dismissAction = UNNotificationAction(identifier: "DISMISS", title: "Dismiss", options: [.destructive])
        
        // Define the category
        let linkExampleCategory =
              UNNotificationCategory(identifier: "link_example",
              actions: [webUrlAction, deepLinkAction, dismissAction],
              intentIdentifiers: [],
              hiddenPreviewsBodyPlaceholder: "",
                                     options: [.customDismissAction])

        // Registering a category that demonstrates a common example without deeplinks
        let snoozeAction = UNNotificationAction(identifier: "SNOOZE_ACTION", title: "Snooze", options: [.foreground])
    
        // Define the category
        let reminderCategory =
              UNNotificationCategory(identifier: "reminder",
              actions: [snoozeAction, dismissAction],
              intentIdentifiers: [],
              hiddenPreviewsBodyPlaceholder: "",
              options: .customDismissAction)
        
        // Define another category without any actions
        let adobeCategory =
              UNNotificationCategory(identifier: "adobe",
              actions: [],
              intentIdentifiers: [],
              hiddenPreviewsBodyPlaceholder: "",
              options: .customDismissAction)
        
        
        // Register the notification type.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([linkExampleCategory, reminderCategory, adobeCategory])
    }
    
    private func handleCustomAction(_ response: UNNotificationResponse) {
        
        if response.notification.request.content.categoryIdentifier == "link_example" {
            switch response.actionIdentifier {
                
            case "WEB_URL":
                //  This action is configured to get the app to the foreground
                Messaging.handleNotificationResponse(response, applicationOpened: true, customActionId: response.actionIdentifier)
                UIApplication.shared.open(URL(string: "https://adobe.com")!)

            case "DEEPLINK":
                //  This action is configured to get the app to the foreground
                Messaging.handleNotificationResponse(response, applicationOpened: true, customActionId: response.actionIdentifier)
                UIApplication.shared.open(URL(string: "messagingdemo://home")!)
                
            case "DISMISS":
                //  This action is configured dismiss the notification
                Messaging.handleNotificationResponse(response, applicationOpened: false, customActionId: response.actionIdentifier)
            default:
                Messaging.handleNotificationResponse(response, applicationOpened: true, customActionId: nil)
            }
        }
        
        else if response.notification.request.content.categoryIdentifier == "reminder" {
            switch response.actionIdentifier {
            case "SNOOZE_ACTION":
                //  This action is configured to get the app to the foreground
                Messaging.handleNotificationResponse(response, applicationOpened: true, customActionId: response.actionIdentifier)
            case "DISMISS":
                //  This action is configured dismiss the notification
                Messaging.handleNotificationResponse(response, applicationOpened: false, customActionId: response.actionIdentifier)
            default:
                Messaging.handleNotificationResponse(response, applicationOpened: true, customActionId: nil)
            }
        }
    }
}
