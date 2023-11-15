# Push Messaging APIs

This document details how to use the APIs provided by the AEPMessaging framework for tracking and displaying push notificaitons.

For more in-depth information about the Messaging extension, visit the [official SDK documentation for Adobe Journey Optimizer Messaging extension](https://developer.adobe.com/client-sdks/documentation/adobe-journey-optimizer/).


### Sync the device's push token to the Adobe Experience Platform profile

Add the following code to the `application(_: didRegisterForRemoteNotificationsWithDeviceToken:)` method in the `AppDelegate`:

```swift
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    MobileCore.setPushIdentifier(deviceToken)
}
```

### Track push notification interactions

The interface for handling notifications and their related actions is the `UNUserNotificationCenterDelegate` protocol. For help implementing this, refer to the [Apple documentation for UNUserNotificationCenterDelegate](https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate).

Once you have designated a delegate for the UNNotificationCenter, handle push notification responses in the [userNotificationCenter(_:didReceive:withCompletionHandler:)](https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate/1649501-usernotificationcenter) method in the `UNUserNotificationCenterDelegate`.

###### Swift

```swift
func userNotificationCenter(_: UNUserNotificationCenter,
                            didReceive response: UNNotificationResponse,
                            withCompletionHandler completionHandler: @escaping () -> Void) {                                
    Messaging.handleNotificationResponse(response)
    // always call the completion handler
    completionHandler()
}
```

<b>Note:</b> This API method will automatically handle click behaviour defined for the push notification.

##### Reading push tracking status

Implement the callback in `handleNotificationResponse` API to read [PushTrackingStatus](../enum-push-tracking-status.md) enum representing tracking status of the push notification.

```
Messaging.handleNotificationResponse(response) { trackingStatus in
    // handle the different values of trackingStatus
}
```