# Adobe Experience Platform - Messaging extension for iOS

## ALPHA
AEPMessaging is currently in Alpha. Use of this code is by invitation only and not otherwise supported by Adobe. Please contact your Adobe Customer Success Manager to learn more.

By using the Alpha, you hereby acknowledge that the Alpha is provided "as is" without warranty of any kind. Adobe shall have no obligation to maintain, correct, update, change, modify or otherwise support the Alpha. You are advised to use caution and not to rely in any way on the correct functioning or performance of such Alpha and/or accompanying materials.

## About this project

Adobe Experience Platform Messaging extension allows you to send push notification token and push notification click through feedback to the Adobe Experience Platform.

The Adobe Experience Platform Messaging Mobile Extension is an extension for the [Adobe Experience Platform SDK](https://github.com/Adobe-Marketing-Cloud/acp-sdks).

To learn more about this extension, read [Adobe Experience Platform Messaging Mobile Extension](https://aep-sdks.gitbook.io/docs/Alpha/experience-platform-messaging-extension).

## Requirements
- Xcode 11.x
- Swift 5.x

## Current version
The Experience Platform Messaging extension for iOS is currently in Alpha development.

## Installation

### Binaries

To generate an `AEPMessaging.xcframework`, run the following command:

```
make archive
```

This will generate the xcframework under the `build` folder. Drag and drop all the .xcframeworks to your app target.

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

```ruby
# Podfile
use_frameworks!

target 'YOUR_TARGET_NAME' do
      pod 'AEPMessaging', :git => 'git@github.com:adobe/aepsdk-messaging-ios.git', :branch => 'main'
      pod 'AEPEdge', :git => 'git@github.com:adobe/aepsdk-edge-ios.git', :branch => 'main'
      pod 'AEPCore', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'main'
      pod 'AEPServices', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'main'
      pod 'AEPRulesEngine', :git => 'git@github.com:adobe/aepsdk-rulesengine-ios.git', :branch => 'main'
end
```

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

To add the AEPEdge Package to your application, from the Xcode menu select:

`File > Swift Packages > Add Package Dependency...`

Enter the URL for the AEPMessaging package repository: `https://github.com/adobe/aepsdk-messaging-ios.git`.

When prompted, make sure you change the branch to `main`. (Once the repo is public, we will reference specific tags/versions instead of a branch)

Alternatively, if your project has a `Package.swift` file, you can add AEPMessaging directly to your dependencies:

```
dependencies: [
    .package(url: "https://github.com/adobe/aepsdk-messaging-ios.git", .branch: "dev"),
targets: [
       .target(name: "YourTarget",
                    dependencies: ["AEPMessaging"],
              path: "your/path"),
    ]
]
```

## Documentation
### Prerequisites
### Adding capabilities for push notification
### Setup AEP Messaging SDK

#### Import messaging extension in the AppDelegate file:
```swift
import AEPMessaging
import AEPCore
import AEPEdge
import AEPIdentity
import AEPLifecycle
```

#### Registering the extension
Register the messaging extensions and configure the SDK with the assigned application identifier. To do this, add the following code to the Application Delegate's `application(_:didFinishLaunchingWithOptions:)` method:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

 // Enable debug logging
 MobileCore.setLogLevel(level: .trace)

 MobileCore.registerExtensions([Messaging.self, Lifecycle.self, Identity.self, Signal.self, Edge.self], {
 // Use the App id assigned to this application via Adobe Launch
 MobileCore.configureWith(appId: "appId")
  
 })  
 return true
}
```
#### Updating the configuration 
To update the configuration with the required DCCS url, add the following code to the Application Delegate's `application(_:didFinishLaunchingWithOptions:)` method:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

MobileCore.updateConfigurationWith(configDict: ["messaging.dccs": "DCCS_URL"])
  
 })  
 return true
}
```

#### Using apnsSandbox environment for push notification
Optionaly the apnsSandbox environment can be used for receiving the push notification.  To do this, add the following code to the Application Delegate's `application(_:didFinishLaunchingWithOptions:)` method:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

MobileCore.updateConfigurationWith(configDict: ["messaging.useSandbox": true])
  
 })  
 return true
}
```

### APIs

#### Syncing the push token to profile in platform. 

To do this, add the following code to Application Delegate's `application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)` method:
```swift
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    MobileCore.setPushIdentifier(deviceToken: deviceToken)
}
```

#### Sending feedback about push notification interactions. 

##### Fields for push notification tracking.
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

## Setup Demo Application
The AEP Messaging Demo application is a sample app which demonstrates how to send psuh notification token and notification click through feedback

## Contributing
Looking to contribute to this project? Please review our [Contributing guidelines](CONTRIBUTING.md) prior to opening a pull request.

We look forward to working with you!

## Licensing
This project is licensed under the Apache V2 License. See [LICENSE](LICENSE) for more information.
