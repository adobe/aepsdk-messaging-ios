/*
 Copyright 2022 Adobe
 All Rights Reserved.
 
 NOTICE: Adobe permits you to use, modify, and distribute this file in
 accordance with the terms of the Adobe license agreement accompanying
 it.
 */

import UIKit
import AEPAssurance
import AEPCore
import AEPEdge
import AEPEdgeIdentity
import AEPMessaging

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    let notificationCenter = UNUserNotificationCenter.current()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let extensions = [
            Assurance.self,
            Edge.self,
            AEPEdgeIdentity.Identity.self,
            Messaging.self
        ]
        MobileCore.setLogLevel(.trace)
        MobileCore.registerExtensions(extensions, {
            MobileCore.configureWith(appId: "staging/1b50a869c4a2/be179250b601/launch-f4cf45c6399f-development")
            
        })
        
        /* START NOTIFICATION CENTER CODE */
        notificationCenter.delegate = self
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        notificationCenter.requestAuthorization(options: options) {
            didAllow, _ in
            if !didAllow {
                print("User has declined notifications")
            }
            
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }        
        /* END NOTIFICATION CENTER CODE */
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Token is - ")
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print(token)
        MobileCore.setPushIdentifier(deviceToken)
    }

    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError _: Error) {
        MobileCore.setPushIdentifier(nil)
    }
    
    func userNotificationCenter(_: UNUserNotificationCenter,
                                willPresent _: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }

    func userNotificationCenter(_: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // Perform the task associated with the action.
        switch response.actionIdentifier {
        case "ACCEPT_ACTION":
            Messaging.handleNotificationResponse(response, applicationOpened: true, customActionId: "ACCEPT_ACTION")

        case "DECLINE_ACTION":
            Messaging.handleNotificationResponse(response, applicationOpened: false, customActionId: "DECLINE_ACTION")

        // Handle other actions…
        default:
            Messaging.handleNotificationResponse(response, applicationOpened: true, customActionId: nil)
        }

        // Always call the completion handler when done.
        completionHandler()
    }
}

