#  Getting started with AEPMessaging SDK

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

```ruby
# Podfile
use_frameworks!

# for app development, include all the following pods
target 'YOUR_TARGET_NAME' do
      pod 'AEPMessaging'
      pod 'AEPEdge'
      pod 'AEPEdgeIdentity'
      pod 'AEPCore'
      pod 'AEPServices'
      pod 'AEPRulesEngine'
end
```

Replace `YOUR_TARGET_NAME` and then, in the `Podfile` directory, type:

```ruby
$ pod install
```

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

To add the AEPMessaging Package to your application, from the Xcode menu select:

`File > Add Packages...`

> **Note**: the menu options may vary depending on the version of Xcode being used.

Enter the URL for the AEPMessaging package repository: `https://github.com/adobe/aepsdk-messaging-ios.git`.

For `Dependency Rule`, select `Up to Next Major Version`.

Alternatively, if your project has a `Package.swift` file, you can add AEPMessaging directly to your dependencies:

```
dependencies: [
    .package(url: "https://github.com/adobe/aepsdk-messaging-ios.git", .upToNextMajor(from: "4.0.0"))
],
targets: [
    .target(name: "YourTarget",
            dependencies: ["AEPMessaging"],
            path: "your/path")
]
```

### Binaries

To generate `AEPMessaging.xcframework`, run the following command from the root directory:

```
make archive
```

This will generate an XCFramework under the `build` folder. Drag and drop `AEPMessaging.xcframework` to your app target.

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
