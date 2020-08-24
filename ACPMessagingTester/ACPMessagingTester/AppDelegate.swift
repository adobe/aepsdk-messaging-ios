//
//  AppDelegate.swift
//  ACPMessagingTester
//
//  Created by steve benedick on 6/22/20.
//  Copyright © 2020 adobe. All rights reserved.
//

import UIKit
import ACPMessaging
import ACPCore
import AEPExperiencePlatform

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        ACPCore.setLogLevel(ACPMobileLogLevel.verbose)
        
        // Necessary property id for "MessagingSDKTest" which has the edge configuration id needed by aep sdk
        ACPCore.configure(withAppId: "3805cb8645dd/b8dec0fe156d/launch-7dfbe727ca00-development")
                
        ACPLifecycle.registerExtension()
        ACPIdentity.registerExtension()
        Messaging.registerExtension()
        ExperiencePlatform.registerExtension()
        
        ACPCore.start {
            
        }
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            
            if let error = error {
                print("error requesting authorization: \(error)")
            }
            
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }            
        }
        
        return true
    }

    // MARK: - UISceneSession Lifecycle

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

    // MARK: - Push Notification handling
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Token is - ")
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print(token)
        ACPCore.setPushIdentifier(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        ACPCore.setPushIdentifier(nil)
    }
}

