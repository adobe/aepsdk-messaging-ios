#  API Usage

## Syncing the push token to profile in platform. 

To do this, add the following code to Application Delegate's `application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)` method:
```swift
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    MobileCore.setPushIdentifier(deviceToken: deviceToken)
}
```

## Sending feedback about push notification interactions. 

### Fields for push notification tracking.
| Key               | dataType   | Description                                                                                                                    |
|-------------------|------------|--------------------------------------------------------------------------------------------------------------------------------|
| eventType         | String     | Type of event when push notification  interaction happens Values: - pushTracking.applicationOpened - pushTracking.customAction |
| id                | String     | MessageId for the push notification                                                                                            |
| applicationOpened | boolean    | Whether application was opened or not                                                                                          |
| actionId          | String     | actionId of the element which performed  the custom action.                                                                    |
| adobe             | Dictionary | Adobe related information.                                                                                                     |

##### Sending feedback when application is opened without any custom action. To do this, add the following code where you have access to `UNNotificationResponse` response:
```swift
let xdm = response.notification.request.content.userInfo["_xdm"] as? [String: Any] ?? [:]
let messageId = response.notification.request.identifier
let messageInfo = ["eventType": "pushTracking.applicationOpened", "id": messageId, "applicationOpened": true, "adobe": xdm] as [String: Any]
MobileCore.collectMessageInfo(messageInfo: messageInfo)
```

##### Sending feedback when application is opened with custom action. To do this, add the following code where you have access to `UNNotificationResponse` response:
```swift
let xdm = response.notification.request.content.userInfo["_xdm"] as? [String: Any] ?? [:]
let messageId = response.notification.request.identifier
let messageInfo = ["eventType": "pushTracking.customAction", "id": messageId, "applicationOpened": true, "actionId" : "<Custom Action Id>", "adobe": xdm] as [String: Any]
MobileCore.collectMessageInfo(messageInfo: messageInfo)
```

##### Sending feedback when application is not opened but a custom action is performed by the user. To do this, add the following code where you have access to `UNNotificationResponse` response:
```swift
let xdm = response.notification.request.content.userInfo["_xdm"] as? [String: Any] ?? [:]
let messageId = response.notification.request.identifier
let messageInfo = ["eventType": "pushTracking.customAction", "id": messageId, "applicationOpened": false, "actionId" : "<Custom Action Id>", "adobe": xdm] as [String: Any]
MobileCore.collectMessageInfo(messageInfo: messageInfo)
```
