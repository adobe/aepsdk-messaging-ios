# Usage

This document details how to use the APIs provided by the AEPMessaging framework.

For more in-depth information about the Messaging extension, visit the [official SDK documentation for Adobe Journey Optimizer Messaging extension](https://aep-sdks.gitbook.io/docs/using-mobile-extensions/adobe-journey-optimizer).

## Push Messaging APIs

### Sync the device's push token to the Adobe Experience Platform profile

Add the following code to the `application(_: didRegisterForRemoteNotificationsWithDeviceToken:)` method in the `AppDelegate`:

```swift
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    MobileCore.setPushIdentifier(deviceToken: deviceToken)
}
```

### Collect push notification interaction information

The interface for handling notifications and their related actions is the `UNUserNotificationCenterDelegate` protocol. For help implementing this, refer to the [Apple documentation for UNUserNotificationCenterDelegate](https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate).

Once you have designated a delegate for the UNNotificationCenter, handle push notification responses in the [userNotificationCenter(_:didReceive:withCompletionHandler:)](https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate/1649501-usernotificationcenter) method in the `UNUserNotificationCenterDelegate`.

###### Swift

```swift
func userNotificationCenter(_: UNUserNotificationCenter,
                            didReceive response: UNNotificationResponse,
                            withCompletionHandler completionHandler: @escaping () -> Void) {                                
    // if necessary, determine the task associated with the action
    switch response.actionIdentifier {
    case "ACCEPT_ACTION":
        Messaging.handleNotificationResponse(response, applicationOpened: true, customActionId: "ACCEPT_ACTION")
    case "DECLINE_ACTION":
        Messaging.handleNotificationResponse(response, applicationOpened: false, customActionId: "DECLINE_ACTION")        
    default:
        Messaging.handleNotificationResponse(response, applicationOpened: true, customActionId: nil)
    }

    // always call the completion handler
    completionHandler()
}
```

There are three scenarios which are most common for handling a push notification response:

- The application was opened without any custom action performed:
```swift
Messaging.handleNotificationResponse(response, applicationOpened: true, customActionId: nil)
```
- The application was opened when the user performed a custom action:
```swift
Messaging.handleNotificationResponse(response, applicationOpened: true, customActionId: <customActionId>)
```
- The application was not opened, but the user performed a custom action:
```swift
Messaging.handleNotificationResponse(response, applicationOpened: false, customActionId: <customActionId>)
```

#### Information needed in push notification interactions

The table below describes the parameters for `handleNotificationResponse(_:applicationOpened:customActionId)` - the API used to collect push notification interactions:

| Key               | Data Type              | Description                                                                                 |
|-------------------|------------------------|---------------------------------------------------------------------------------------------|
| response          | UNNotificationResponse | Notification response produced by iOS containing information that will be parsed by the SDK |
| applicationOpened | Bool                   | Indicates whether the application was opened during this interaction                        |
| customActionId    | String?                | Unique identifier for the custom action on which the interaction occurred                   |

## In-App Messaging APIs

#### Programmatically refresh in-app message definitions from the remote

By default, the SDK will automatically fetch in-app message definitions from the remote at the time the Messaging extension is registered. This generally happens once per app lifecycle, in the `application(_: didFinishLaunchingWithOptions:)` method of the `AppDelegate`.

Some use cases may require the client to request an update from the remote more frequently. Calling the following API will force the Messaging extension to get an updated definition of messages from the remote:

```swift
Messaging.refreshInAppMessages()
```
