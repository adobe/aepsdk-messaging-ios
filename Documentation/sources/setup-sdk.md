#  Setup AEPMessaging SDK

## BETA instructions

While the in-app messaging feature is in beta, the developer will need to use the Messaging extension on the `staging` branch of this repo. The example below shows how to point to the `staging` branch in a Cocoapods `Podfile`:

```
pod 'AEPMessaging', :git => 'https://github.com/adobe/aepsdk-messaging-ios.git', :branch => 'staging'
```

### Import and register the Messaging extension

Import the AEPMessaging framework and its dependencies, then register the Messaging extension and dependencies in the `application(_: didFinishLaunchingWithOptions:)` method in the `AppDelegate`:

```swift
import AEPMessaging
import AEPCore
import AEPEdge
import AEPEdgeIdentity
import AEPOptimize

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // optionally enable debug logging
        MobileCore.setLogLevel(.trace)

        // create a list of extensions that will be registered
        let extensions = [
            Messaging.self,
            Identity.self,
            Edge.self,
            Optimize.self
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
