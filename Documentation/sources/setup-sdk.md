#  Setup AEPMessaging SDK

### Import and register the Messaging extension

Import the AEPMessaging framework and its dependencies, then register the Messaging extension and dependencies in the `application(_: didFinishLaunchingWithOptions:)` method in the `AppDelegate`:

```swift
import AEPMessaging
import AEPCore
import AEPEdge
import AEPEdgeIdentity

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // optionally enable debug logging
        MobileCore.setLogLevel(.trace)

        // create a list of extensions that will be registered
        let extensions = [
            Messaging.self,
            Identity.self,
            Edge.self
        ]

        MobileCore.registerExtensions(extensions) {            
            // use the App ID assigned for this application from Adobe Data Collection (formerly Adobe Launch)
            MobileCore.configureWith(appId: "MY_APP_ID")
        }

        return true
    }
}
```

### Using an APNS sandbox push environment

If testing in an APNS sandbox environment, add the `messaging.useSandbox` property to the SDK configuration.

Immediately after SDK configuration, update the configuration by doing the following:

```swift
MobileCore.updateConfigurationWith(configDict: ["messaging.useSandbox": true])
```
