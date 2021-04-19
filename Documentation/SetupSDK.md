#  Setting up AEPMessaging SDK

#### Import messaging extension in the AppDelegate file:
```swift
import AEPMessaging
import AEPCore
import AEPEdge
import AEPEdgeIdentity
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

#### Using apnsSandbox environment for push notification
Optionaly the apnsSandbox environment can be used for receiving the push notification.  To do this, add the following code to the Application Delegate's `application(_:didFinishLaunchingWithOptions:)` method:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

MobileCore.updateConfigurationWith(configDict: ["messaging.useSandbox": true])
  
 })  
 return true
}
```
