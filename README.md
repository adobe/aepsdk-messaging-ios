# Adobe Experience Platform - Messaging extension for iOS

## ALPHA
AEPMessaging is currently in Alpha. Use of this code is by invitation only and not otherwise supported by Adobe. Please contact your Adobe Customer Success Manager to learn more.

By using the Alpha, you hereby acknowledge that the Alpha is provided "as is" without warranty of any kind. Adobe shall have no obligation to maintain, correct, update, change, modify or otherwise support the Alpha. You are advised to use caution and not to rely in any way on the correct functioning or performance of such Alpha and/or accompanying materials.

## About this project

Adobe Experience Platform Messaging extension allows you to send push notification token and push notification click through feedback to the Adobe Experience Platform.

The Adobe Experience Platform Messaging Mobile Extension is an extension for the [Adobe Experience Platform SDK](https://github.com/Adobe-Marketing-Cloud/acp-sdks).

To learn more about this extension, read [Adobe Experience Platform Messaging Mobile Extension](https://aep-sdks.gitbook.io/docs/Alpha/experience-platform-messaging-extension).

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
    pod 'AEPEdge', :git => 'git@github.com:adobe/aepsdk-edge-ios.git', :branch => 'main'
      pod 'AEPCore', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'main'
      pod 'AEPServices', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'main'
      pod 'AEPRulesEngine', :git => 'git@github.com:adobe/aepsdk-rulesengine-ios.git', :branch => 'main'
end
```

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

To add the AEPEdge Package to your application, from the Xcode menu select:

`File > Swift Packages > Add Package Dependency...`

Enter the URL for the AEPEdge package repository: `https://github.com/adobe/aepsdk-edge-ios.git`.

When prompted, make sure you change the branch to `main`. (Once the repo is public, we will reference specific tags/versions instead of a branch)

Alternatively, if your project has a `Package.swift` file, you can add AEPEdge directly to your dependencies:

```
dependencies: [
    .package(url: "https://github.com/adobe/aepsdk-edge-ios.git", .branch: "dev"),
targets: [
       .target(name: "YourTarget",
                    dependencies: ["AEPEdge"],
              path: "your/path"),
    ]
]
```

## Setup Demo Application
The AEP Messaging Demo application is a sample app which demonstrates how to send psuh notification token and notification click through  feedback


## Contributing
Looking to contribute to this project? Please review our [Contributing guidelines](CONTRIBUTING.md) prior to opening a pull request.

We look forward to working with you!

## Licensing
This project is licensed under the Apache V2 License. See [LICENSE](LICENSE) for more information.
