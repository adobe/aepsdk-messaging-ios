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

import AEPAssurance
import AEPCore
import AEPEdge
import AEPEdgeConsent
import AEPEdgeIdentity
import AEPLifecycle
import AEPSignal
import AEPMessaging
import SwiftUI

final class AppDelegate: NSObject, UIApplicationDelegate {
    
    private let ENVIRONMENT_FILE_ID = "3149c49c3910/b6541e5e6301/launch-f7ac0a320fb3-development"
//    private let ENVIRONMENT_FILE_ID = "staging/1b50a869c4a2/bcd1a623883f/launch-e44d085fc760-development"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        MobileCore.setLogLevel(.trace)

        let extensions = [
            AEPEdgeIdentity.Identity.self, 
            Lifecycle.self,
            Signal.self,
            Edge.self,
            Messaging.self,
            Assurance.self
        ]
        
        MobileCore.registerExtensions(extensions) {
            MobileCore.configureWith(appId: self.ENVIRONMENT_FILE_ID)

            // set `messaging.useSandbox` to "true"  to test push notifications in debug environment (Apps signed with Development Certificate)
        #if DEBUG
//            let debugConfig = [
//                //"messaging.useSandbox": true,
//                "edge.environment": "int"
//            ]
//            MobileCore.updateConfigurationWith(configDict: debugConfig)
        #endif
        }
        
        self.registerForPushNotifications(application)
        return true
    }
    
    // MARK: - Push Notification registration methods
    func registerForPushNotifications(_ application : UIApplication) {
        let center = UNUserNotificationCenter.current()
        // Ask for user permission
        center.requestAuthorization(options: [.badge, .sound, .alert]) { [weak self] granted, _ in
            guard granted else { return }
            
            center.delegate = self as? UNUserNotificationCenterDelegate
            
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
        // Perform the task associated with the action.
        switch response.actionIdentifier {
        case "ACCEPT_ACTION":
            Messaging.handleNotificationResponse(response)

        case "DECLINE_ACTION":
            Messaging.handleNotificationResponse(response)

        // Handle other actions…
        default:
            Messaging.handleNotificationResponse(response)
        }

        // Always call the completion handler when done.
        completionHandler()
    }
}

@main
struct MessagingDemoAppSwiftUIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .onOpenURL{ url in
                    Assurance.startSession(url: url)
                }
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
                case .background:
                    print("Scene phase changed to background.")
                    MobileCore.lifecyclePause()
                case .active:
                    print("Scene phase changed to active.")
                    MobileCore.lifecycleStart(additionalContextData: nil)
                case .inactive:
                    print("Scene phase changed to inactive.")
                @unknown default:
                    print("Unknown scene phase.")
            }
        }
    }
}
