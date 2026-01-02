/*
Copyright 2024 Adobe. All rights reserved.
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
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        MobileCore.setLogLevel(.trace)

        let extensions = [
            Identity.self,
            Lifecycle.self,
            Signal.self,
            Edge.self,
            Consent.self,
            Messaging.self,
            Assurance.self,
            TokenCollector.self
        ]
        
        MobileCore.registerExtensions(extensions) {
            MobileCore.configureWith(appId: Constants.APPID)
            
            if Constants.isStage {
                MobileCore.updateConfigurationWith(configDict: ["edge.environment": "int"])
            }
                
            #if DEBUG
                MobileCore.updateConfigurationWith(configDict: ["messaging.useSandbox": true])
            #endif
            
            if !Constants.assuranceURL.isEmpty {
                Assurance.startSession(url: URL(string: Constants.assuranceURL)!)
            }
            
            // Set consent to "yes" for data collection
            print("📋 [CONSENT] Setting consent to 'yes' for data collection")
            Consent.update(with: [
                "consents": [
                    "collect": [
                        "val": "y"
                    ]
                ]
            ])
            
            // Log current consent status after a brief delay to allow consent update to process
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Consent.getConsents { consents, error in
                    if let error = error {
                        print("❌ [CONSENT] Error getting consents: \(error.localizedDescription)")
                        return
                    }
                    
                    if let consents = consents {
                        print("""
                        ✅ [CONSENT] Current consent status retrieved:
                        ═══════════════════════════════════════════════════════════
                        \(consents.prettyPrintedJson ?? "\(consents)")
                        ═══════════════════════════════════════════════════════════
                        """)
                    } else {
                        print("⚠️ [CONSENT] No consent data available")
                    }
                }
            }
            
            self.registerForPushNotifications(application)
            let cardSurface = Surface(path: Constants.SurfaceName.CONTENT_CARD)
            let cbeSurface1 = Surface(path: Constants.SurfaceName.CBE_HTML)
            let cbeSurface2 = Surface(path: Constants.SurfaceName.CBE_JSON)
            Messaging.updatePropositionsForSurfaces([cardSurface,cbeSurface1, cbeSurface2])
        }
        
        if #available(iOS 16.1, *) {
            Messaging.registerLiveActivity(AirplaneTrackingAttributes.self)
            Messaging.registerLiveActivity(FoodDeliveryLiveActivityAttributes.self)
            Messaging.registerLiveActivity(GameScoreLiveActivityAttributes.self)
        }
        
        return true
    }
        
    // MARK: - Push Notification registration methods
    func registerForPushNotifications(_ application : UIApplication) {
        let center = UNUserNotificationCenter.current()
        
        // Set delegate BEFORE requesting authorization
        center.delegate = self
        print("✅ [SETUP] UNUserNotificationCenter delegate set to AppDelegate")
        
        // Ask for user permission
        center.requestAuthorization(options: [.badge, .sound, .alert]) { [weak self] granted, _ in
            guard granted else {
                print("❌ [SETUP] Notification permission denied")
                return
            }
            
            print("✅ [SETUP] Notification permission granted")
            
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
        print("""
            
            ══════════════════════════════════════════════════════════════════
            🔕 [DEMO APP] SILENT PUSH NOTIFICATION RECEIVED
            ══════════════════════════════════════════════════════════════════
            App State: \(application.applicationState == .background ? "Background" : application.applicationState == .inactive ? "Inactive" : "Active")
            
            📦 UserInfo Payload:
            \(userInfo)
            
            ══════════════════════════════════════════════════════════════════
            
            """)
        completionHandler(.noData)
    }
    

    // Delegate method to handle a notification that arrived while the app was running in the foreground.
    func userNotificationCenter(_: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let content = notification.request.content
        let timestamp = Date()
        
        print("""
            
            ══════════════════════════════════════════════════════════════════
            📲 [DEMO APP] PUSH NOTIFICATION RECEIVED (FOREGROUND)
            ══════════════════════════════════════════════════════════════════
            🕐 Timestamp: \(timestamp)
            Notification ID: '\(notification.request.identifier)'
            Thread ID: '\(content.threadIdentifier.isEmpty ? "(none)" : content.threadIdentifier)'
            
            📝 Content:
            ├─ Title: '\(content.title)'
            ├─ Subtitle: '\(content.subtitle)'
            ├─ Body: '\(content.body)'
            ├─ Badge: \(content.badge?.intValue ?? 0)
            ├─ Sound: \(content.sound != nil ? "Present" : "None")
            └─ Category: '\(content.categoryIdentifier)'
            
            📦 UserInfo Payload:
            \(content.userInfo)
            
            🎯 Will present with: [Alert, Sound, Badge]
            ══════════════════════════════════════════════════════════════════
            
            """)
        
        completionHandler([.alert, .sound, .badge])
    }

    // Delegate method is called when a notification is interacted with
    func userNotificationCenter(_: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let content = response.notification.request.content
        let timestamp = Date()
        let actionType: String
        
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            actionType = "Notification Tapped (Default Action)"
        case UNNotificationDismissActionIdentifier:
            actionType = "Notification Dismissed"
        case "ACCEPT_ACTION":
            actionType = "Custom Action: ACCEPT"
        case "DECLINE_ACTION":
            actionType = "Custom Action: DECLINE"
        default:
            actionType = "Custom Action: \(response.actionIdentifier)"
        }
        
        print("""
            
            ══════════════════════════════════════════════════════════════════
            👆 [DEMO APP] PUSH NOTIFICATION INTERACTION
            ══════════════════════════════════════════════════════════════════
            🕐 Timestamp: \(timestamp)
            Action Type: \(actionType)
            Action Identifier: '\(response.actionIdentifier)'
            Notification ID: '\(response.notification.request.identifier)'
            Thread ID: '\(content.threadIdentifier.isEmpty ? "(none)" : content.threadIdentifier)'
            
            📝 Notification Content:
            ├─ Title: '\(content.title)'
            ├─ Subtitle: '\(content.subtitle)'
            ├─ Body: '\(content.body)'
            ├─ Badge: \(content.badge?.intValue ?? 0)
            ├─ Category: '\(content.categoryIdentifier)'
            └─ Thread ID: '\(content.threadIdentifier)'
            
            📦 UserInfo Payload:
            \(content.userInfo)
            
            🔄 Calling Messaging.handleNotificationResponse()...
            ══════════════════════════════════════════════════════════════════
            
            """)
        
        // Perform the task associated with the action.
        switch response.actionIdentifier {
        case "ACCEPT_ACTION":
            Messaging.handleNotificationResponse(response) { status in
                print("✅ [DEMO APP] Messaging.handleNotificationResponse completed with status: \(status)")
            }

        case "DECLINE_ACTION":
            Messaging.handleNotificationResponse(response) { status in
                print("✅ [DEMO APP] Messaging.handleNotificationResponse completed with status: \(status)")
            }

        // Handle other actions…
        default:
            Messaging.handleNotificationResponse(response) { status in
                print("✅ [DEMO APP] Messaging.handleNotificationResponse completed with status: \(status)")
            }
        }

        // Always call the completion handler when done.
        completionHandler()
    }
    
    // MARK: - Local Notification Testing
    /// Creates and schedules a local notification with XDM tracking data for testing
    /// Call this from Xcode debugger: `expr (UIApplication.shared.delegate as! AppDelegate).scheduleTestNotificationWithXDM()`
    @objc func scheduleTestNotificationWithXDM(delay: TimeInterval = 3.0) {
        let center = UNUserNotificationCenter.current()
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "🧪 Test Notification with XDM"
        content.subtitle = "Local notification for testing"
        content.body = "This notification contains XDM tracking data to test the complete flow"
        content.badge = NSNumber(value: 1)
        content.sound = .default
        
        // ✅ Add XDM tracking data (this is the key part that enables tracking!)
        let timestamp = Int(Date().timeIntervalSince1970)
        let executionId = UUID().uuidString
        
        content.userInfo = [
            "_xdm": [
                "cjm": [
                    "_experience": [
                        "customerJourneyManagement": [
                            "messageExecution": [
                                "messageExecutionID": "local-test-execution-\(executionId)",
                                "messageID": "local-test-message-\(timestamp)",
                                "journeyVersionID": "local-test-journey-v1.0",
                                "journeyVersionInstanceId": "local-test-instance-\(timestamp)"
                            ],
                            "messageProfile": [
                                "channel": [
                                    "_id": "https://ns.adobe.com/xdm/channels/push"
                                ]
                            ],
                            "pushChannelContext": [
                                "platform": "apns"
                            ]
                        ]
                    ]
                ]
            ],
            "adb_m_id": "local-test-\(UUID().uuidString)",
            "adb_a_type": "WEBURL",
            "adb_uri": "https://www.adobe.com/test"
        ]
        
        // Convert userInfo to pretty printed JSON for logging
        let userInfoJson: String
        if let data = try? JSONSerialization.data(withJSONObject: content.userInfo, options: [.prettyPrinted]),
           let jsonString = String(data: data, encoding: .utf8) {
            userInfoJson = jsonString
        } else {
            userInfoJson = "\(content.userInfo)"
        }
        
        print("""
        
        ══════════════════════════════════════════════════════════════════
        🧪 [LOCAL TEST] Scheduling test notification with XDM tracking data
        ══════════════════════════════════════════════════════════════════
        📅 Will appear in: \(delay) seconds
        📝 Title: \(content.title)
        📝 Body: \(content.body)
        
        📦 UserInfo Payload (with XDM tracking):
        \(userInfoJson)
        
        ⚠️  IMPORTANT: Minimize the app to see the notification!
        ══════════════════════════════════════════════════════════════════
        
        """)
        
        // Create trigger (fires after specified delay)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        
        // Create request with unique identifier
        let request = UNNotificationRequest(
            identifier: "test-xdm-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        // Schedule the notification
        center.add(request) { error in
            if let error = error {
                print("❌ [LOCAL TEST] Error scheduling test notification: \(error.localizedDescription)")
            } else {
                print("✅ [LOCAL TEST] Test notification scheduled successfully! Minimize the app now.")
            }
        }
    }
    
    /// Schedules immediate test notification (2 seconds delay)
    @objc func scheduleImmediateTest() {
        scheduleTestNotificationWithXDM(delay: 2.0)
    }
}

// MARK: - Helper Extensions
extension Dictionary where Key == String, Value == Any {
    /// Converts the dictionary to a JSON string with pretty printing.
    var prettyPrintedJson: String? {
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted]) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
