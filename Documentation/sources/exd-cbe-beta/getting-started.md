#  Getting started with AEPMessaging SDK

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

```ruby
# Podfile
use_frameworks!

# for app development, include all the following pods
target 'YOUR_TARGET_NAME' do
      pod 'AEPMessaging', :git => 'https://github.com/adobe/aepsdk-messaging-ios.git', :branch => 'exd-cbe-beta' 
      pod 'AEPEdge'
      pod 'AEPCore'
end
```

Replace `YOUR_TARGET_NAME` and then, in the `Podfile` directory, type:

```ruby
$ pod install
```

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

To add the AEPMessaging Package to your application, from the Xcode 15 menu select:

`File > Add Package Dependencies...`

> **Note**: the menu options may vary depending on the version of Xcode being used.

Enter the URL for the AEPMessaging package repository: `https://github.com/adobe/aepsdk-messaging-ios.git`.

For `Dependency Rule`, select `Branch`.

Alternatively, if your project has a `Package.swift` file, you can add AEPMessaging directly to your dependencies:

```
dependencies: [
    .package(url: "https://github.com/adobe/aepsdk-messaging-ios.git", .branch("exd-cbe-beta"))
],
targets: [
    .target(name: "YourTarget",
            dependencies: ["AEPMessaging"],
            path: "your/path")
]
```

### Binaries

Select `exd-cbe-beta` branch and clone the repository (or download ZIP). To generate `AEPMessaging.xcframework`, run the following command from the root directory:

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
            // use the Environment file ID assigned for this application from Adobe Data Collection (formerly Adobe Launch)
            MobileCore.configureWith(appId: "<YOUR_ENVIRONMENT_FILE_ID>")
        }

        return true
    }
}
```