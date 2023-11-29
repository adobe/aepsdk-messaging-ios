# Adobe Experience Platform test utilities

<!-- ## BETA

AEPTestUtils is currently in beta. Use of this code is by invitation only and not otherwise supported by Adobe. Please contact your Adobe Customer Success Manager to learn more.

By using the Beta, you hereby acknowledge that the Beta is provided "as is" without warranty of any kind. Adobe shall have no obligation to maintain, correct, update, change, modify or otherwise support the Beta. You are advised to use caution and not to rely in any way on the correct functioning or performance of such Beta and/or accompanying materials. -->

## About this project

The Experience Platform test utilities enables easily setting up test cases for Mobile SDKs by providing common functionality like event capture and assertions, mock network request/response, and resetting state.

## Requirements
- Xcode 11.0 (or newer)
- Swift 5.1 (or newer)

## Add test utilities to an application

### Install utilities
These are currently the supported installation options:

#### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

```ruby
# Podfile
use_frameworks!

# for app development, include the following pod
target 'YOUR_TARGET_NAME' do
  pod 'AEPCore'
	pod 'AEPTestUtils'
end
```

Replace `YOUR_TARGET_NAME` and then, in the `Podfile` directory, type:

```ruby
$ pod install
```

#### [Swift Package Manager](https://github.com/apple/swift-package-manager)

To add the AEPTestUtils Package to your application, from the Xcode menu select:

`File > Swift Packages > Add Package Dependency...`

Enter the URL for the AEPTestUtils package repository: `https://github.com/adobe/aepsdk-test-utils-ios.git`.

When prompted, input a specific version or a range of version for Version rule.

Alternatively, if your project has a `Package.swift` file, you can add AEPTestUtils directly to your dependencies:

```
dependencies: [
	.package(url: "https://github.com/adobe/aepsdk-core-ios.git", .upToNextMajor(from: "4.0.0")),
	.package(url: "https://github.com/adobe/aepsdk-test-utils-ios.git", .upToNextMajor(from: "1.0.0")),
],
targets: [
   	.target(name: "YourTarget",
    		dependencies: ["AEPCore",
                       "AEPTestUtils"],
          	path: "your/path")
]
```

#### Binaries

To generate an `AEPTestUtils.xcframework`, run the following command:

```ruby
$ make archive
```

This generates the xcframework under the `build` folder. Drag and drop all the `.xcframeworks` to your app target in Xcode.

Repeat these steps for each of the required depdendencies:
- [AEPCore](https://github.com/adobe/aepsdk-core-ios#binaries)

### Import and usage

<!-- TODO -->

## Development

The first time you clone or download the project, you should run the following from the root directory to setup the environment:

~~~
make pod-install
~~~

Subsequently, you can make sure your environment is updated by running the following:

~~~
make pod-update
~~~

#### Open the Xcode workspace
Open the workspace in Xcode by running the following command from the root directory of the repository:

~~~
make open
~~~

<!-- #### Command line integration

You can run all the test suites from command line:

~~~
make test
~~~ -->

## Documentation
Find further documentation in the [Documentation](./Documentation/) folder.

## Related Projects

| Project                                                      | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [AEPCore Extensions](https://github.com/adobe/aepsdk-core-ios) | The AEPCore and AEPServices represent the foundation of the Adobe Experience Platform SDK. |
| [AEPEdge Extension](https://github.com/adobe/aepsdk-edge-ios) | The AEPEdge extension allows you to send data to the Adobe Experience Platform (AEP) from a mobile application. |
| [AEP SDK Sample App for iOS](https://github.com/adobe/aepsdk-sample-app-ios) | Contains iOS sample apps for the AEP SDK. Apps are provided for both Objective-C and Swift implementations. |
| [AEP SDK Sample App for Android](https://github.com/adobe/aepsdk-sample-app-android) | Contains Android sample app for the AEP SDK.                 |
## Contributing

Contributions are welcomed! Read the [Contributing Guide](./.github/CONTRIBUTING.md) for more information.

## Licensing

This project is licensed under the Apache V2 License. See [LICENSE](LICENSE) for more information.
