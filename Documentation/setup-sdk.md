#  Setting up AEPMessaging SDK

#### Import messaging extension in the AppDelegate file:
```swift
import AEPMessaging
import AEPCore
import AEPEdge
import AEPEdgeIdentity
```

#### Registering the extension
Register the messaging extensions and configure the SDK with the assigned application identifier. To do this, add the following code to the Application Delegate's `application(_:didFinishLaunchingWithOptions:)` method:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    // Enable debug logging
    MobileCore.setLogLevel(level: .trace)

    // Declare what Extensions you want to register with the SDK
    let extensions = [
        Messaging.self,
        Identity.self,
        Edge.self
    ]

    MobileCore.registerExtensions(extensions, {
        // Use the App ID assigned to this application in Adobe Launch
        MobileCore.configureWith(appId: "appId")  
    })

    return true
}
```

#### Using apnsSandbox environment for push notification
Optionally the `apnsSandbox` environment can be used for receiving the push notification. To do this, add the following code to the Application Delegate's `application(_:didFinishLaunchingWithOptions:)` method:

```swift
MobileCore.updateConfigurationWith(configDict: ["messaging.useSandbox": true])
```
