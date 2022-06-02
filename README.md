# Adobe Experience Platform - Messaging extension for iOS

[![Cocoapods](https://img.shields.io/cocoapods/v/AEPMessaging.svg?color=orange&label=AEPMessaging&logo=apple&logoColor=white)](https://cocoapods.org/pods/AEPMessaging)
[![SPM](https://img.shields.io/badge/SPM-Supported-orange.svg?logo=apple&logoColor=white)](https://swift.org/package-manager/)
[![CircleCI](https://img.shields.io/circleci/project/github/adobe/aepsdk-messaging-ios/main.svg?logo=circleci)](https://circleci.com/gh/adobe/workflows/aepsdk-messaging-ios)
[![Code Coverage](https://img.shields.io/codecov/c/github/adobe/aepsdk-messaging-ios/main.svg?logo=codecov)](https://codecov.io/gh/adobe/aepsdk-messaging-ios/branch/main)

## About this project

Adobe Experience Platform (AEP) Messaging Extension is an extension for the [Adobe Experience Platform Swift SDK](https://github.com/adobe/aepsdk-core-ios).

The AEPMessaging extension enables the following workflows:

- Sending push notification tokens and push notification click-through feedback to AEP
- Displaying in-app messages which were created and configured for this app in Adobe Journey Optimizer (AJO)

For further information about this extension, reference [this documentation](https://aep-sdks.gitbook.io/docs/using-mobile-extensions/adobe-journey-optimizer).

## Requirements
- Xcode 11.0 (or newer)
- Swift 5.1 (or newer)

## Installation

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
      pod 'AEPOptimize'
end
```

Replace `YOUR_TARGET_NAME` and then, in the `Podfile` directory, type:

```ruby
$ pod install
```

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

To add the AEPMessaging Package to your application, from the Xcode menu select:

`File > Swift Packages > Add Package Dependency...`

Enter the URL for the AEPMessaging package repository: `https://github.com/adobe/aepsdk-messaging-ios.git`.

When prompted, make sure you change the branch to `main`.

Alternatively, if your project has a `Package.swift` file, you can add AEPMessaging directly to your dependencies:

```
dependencies: [
    .package(url: "https://github.com/adobe/aepsdk-messaging-ios.git", .upToNextMajor(from: "1.1.0"))
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

## Documentation

Additional documentation for SDK usage and configuration can be found in the [Documentation](Documentation/README.md) directory.

## Setup Demo Application

The AEP Messaging Demo application is a sample app which demonstrates how to send the push notification token to AEP and how to collect feedback from notification click-throughs. It can also be used to demonstrate showing an in-app message created in AJO.

## Related Projects

| Project                                                      | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [AEPCore Extensions](https://github.com/adobe/aepsdk-core-ios) | The AEPCore and AEPServices represent the foundation of the Adobe Experience Platform SDK. |
| [AEPEdge Extension](https://github.com/adobe/aepsdk-edge-ios) | The AEPEdge extension allows you to send data to the Adobe Experience Platform (AEP) from a mobile application. |
| [AEPEdgeIdentity Extension](https://github.com/adobe/aepsdk-edgeidentity-ios) | The AEPEdgeIdentity enables handling of user identity data from a mobile app when using the AEPEdge extension. |
| [AEP SDK Sample App for iOS](https://github.com/adobe/aepsdk-sample-app-ios) | Contains iOS sample apps for the AEP SDK. Apps are provided for both Objective-C and Swift implementations. |
| [AEP SDK Sample App for Android](https://github.com/adobe/aepsdk-sample-app-android) | Contains Android sample app for the AEP SDK.                 |

## Contributing
Looking to contribute to this project? Please review our [Contributing guidelines](.github/CONTRIBUTING.md) prior to opening a pull request.

We look forward to working with you!

#### Development

The first time you clone or download the project, you should run the following from the root directory to setup the environment:

~~~
make pod-install
~~~

Subsequently, you can make sure your environment is updated by running the following:

~~~
make pod-update
~~~

##### Open the Xcode workspace
Open the workspace in Xcode by running the following command from the root directory of the repository:

~~~
make open
~~~

##### Command line integration

You can run all the test suites from command line:

~~~
make test
~~~

## Licensing
This project is licensed under the Apache V2 License. See [LICENSE](LICENSE) for more information.
