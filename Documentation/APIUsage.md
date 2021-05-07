#  API Usage

## Syncing the push token to profile in platform. 

To do this, add the following code to Application Delegate's `application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)` method:
```swift
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    MobileCore.setPushIdentifier(deviceToken: deviceToken)
}
```

## Sending push notification interactions feedback to platform. 

### Information needed for push notification interactions.
| Key               | dataType   | Description                                                                                                                    |
|-------------------|------------|--------------------------------------------------------------------------------------------------------------------------------|
| response           | UNNotificationResponse     | Notification response which contains all necessary information.                                                                                 |
| applicationOpened | boolean    | Whether application was opened or not                                                                                          |
| customActionId          | String     | customActionId of the element which performed  the custom action.                                                                    |                                                                                                |

##### Sending feedback when application is opened without any custom action. To do this, add the following code where you have access to `UNNotificationResponse` response:
```swift
Messaging.handleNotificationResponse(response, applicationOpened: true, customActionId: nil)
```

##### Sending feedback when application is opened with custom action. To do this, add the following code where you have access to `UNNotificationResponse` response:
```swift
Messaging.handleNotificationResponse(response, applicationOpened: true, customActionId: <customActionId>)
```

##### Sending feedback when application is not opened but a custom action is performed by the user. To do this, add the following code where you have access to `UNNotificationResponse` response:
```swift
Messaging.handleNotificationResponse(response, applicationOpened: false, customActionId: <customActionId>)
```
