# Install Optimize SDK extension in your mobile application

> [!WARNING]
> The Optimize extension depends on the `Mobile Core` and `Edge network` extensions and requires these extensions to be installed in your mobile application.

The following installation options are currently supported when integrating the Adobe Experience Platform Mobile SDK extensions: 

## CocoaPods

If you are using CocoaPods to manage your Adobe Experience Platform Mobile SDK dependencies, include the following pods in the `Podfile`.

**Podfile Example**
```ruby
# Define a global platform for your project
platform :ios, '10.0'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

workspace 'OptimizeTutorialStarterApp'
project 'OptimizeTutorialStarterApp.xcodeproj'

target 'OptimizeTutorialStarterApp' do
  # Pods for OptimizeTutorialStarterApp
  pod 'AEPCore'
  pod 'AEPLifecycle'
  pod 'AEPEdge'
  pod 'AEPEdgeConsent'
  pod 'AEPEdgeIdentity'
  pod 'AEPOptimize'
  pod 'AEPAssurance'
end
```
Save the `Podfile` and run `pod install` to install the dependencies. This generates the `Podfile.lock` file, which tracks (and locks) the installed versions of the various pods.

```text
$ pod install
```

> [!TIP]
> `pod install` vs `pod update`: pod install, as opposed to pod update, doesn't check whether newer versions are available for the pods listed in the `Podfile.lock`. For newer pods not listed in the `Podfile.lock`, it resolves dependencies and installs the versions that conform to the Podfile. pod update will always update the pods to the latest version possible as long as any Podfile version restrictions are still met.

<details>
<summary>
<b>Podfile.lock Example</b>
</summary>
<pre>
PODS:
  - AEPAssurance (3.0.1):
    - AEPCore (>= 3.1.0)
    - AEPServices (>= 3.1.0)
  - AEPCore (3.7.1):
    - AEPRulesEngine (>= 1.1.0)
    - AEPServices (>= 3.7.1)
  - AEPEdge (1.5.0):
    - AEPCore (>= 3.5.0)
    - AEPEdgeIdentity
  - AEPEdgeConsent (1.0.1):
    - AEPCore (>= 3.5.0)
    - AEPEdge (>= 1.4.0)
  - AEPEdgeIdentity (1.1.0):
    - AEPCore (>= 3.6.0)
  - AEPLifecycle (3.7.1):
    - AEPCore (>= 3.7.1)
  - AEPOptimize (1.0.0):
    - AEPCore (>= 3.2.0)
    - AEPEdge (>= 1.2.0)
  - AEPRulesEngine (1.2.0)
  - AEPServices (3.7.1)

DEPENDENCIES:
  - AEPAssurance
  - AEPCore
  - AEPEdge
  - AEPEdgeConsent
  - AEPEdgeIdentity
  - AEPLifecycle
  - AEPOptimize

SPEC REPOS:
  trunk:
    - AEPAssurance
    - AEPCore
    - AEPEdge
    - AEPEdgeConsent
    - AEPEdgeIdentity
    - AEPLifecycle
    - AEPOptimize
    - AEPRulesEngine
    - AEPServices

SPEC CHECKSUMS:
  AEPAssurance: b25880cd4b14f22c61a1dce19807bd0ca0fe9b17
  AEPCore: 412fe933382892ab6c6af958d2f69ebcbca11216
  AEPEdge: 924cd8ace3db40b9c42bc2bc5e8fb1fcad3a9b77
  AEPEdgeConsent: a23b35ab331d2aa2013fcef49c9d6b80085d5597
  AEPEdgeIdentity: 47f0c6ecbec5857b2a8cb9b7bf717c2424c6bae0
  AEPLifecycle: 94c36a54f7e5466c5274bc822c53eaa410b74888
  AEPOptimize: 413690f88cb8ae574153a94081331788ca740a91
  AEPRulesEngine: 71228dfdac24c9ded09be13e3257a7eb22468ccc
  AEPServices: 7284c30359c789cd16bf366b4ea81094a66d21ab

PODFILE CHECKSUM: 139193ae2dcd459e347b8cf76b4a3c7e33160820

COCOAPODS: 1.11.3
</pre>
</details>
<br/>

<details>
<summary>
<b>Troubleshooting</b>
</summary>

<b>When using macbook running M1 processor, issues are seen with pod install and pod update commands. How can I resolve these issues?</b>

There are a couple of solutions to the pod install and update issues seen when using M1 Mac:

<b>Option 1</b>: Install gem `ffi` and run pod commands with prefix `arch -x86_64`.
```text
$ sudo arch -x86_64 gem install ffi
$ arch -x86_64 pod install
```
<b>Option 2</b>: Uninstall cocoapods gems and install cocoapods using homebrew.
```text
$ gem list —-local | grep cocoapods
$ sudo gem uninstall <substitute with each cocoapods related gem in the above list>
$ brew install cocoapods
```
If homebrew is not installed, use the below command on the terminal to install it.
```text
$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
For more details, see [CocoaPods - issue 10518](https://github.com/CocoaPods/CocoaPods/issues/10518)
</details>

## Swift Package Manager

> [!WARNING]
> The steps mentioned below for integrating AEPOptimize extension via SPM are applicable only to Xcode >= 13, and they might differ slightly for Xcode < 13.

To add the AEPOptimize Package to your application, from the Xcode menu select:

```text
File > Add Packages...
```

1. Enter the URL for the AEPOptimize package repository: https://github.com/adobe/aepsdk-optimize-ios.git.

| ![Specify AEPOptimize package repo URL](../assets/spm-search-package.png?raw=true) |
| :---: |
| **Specify AEPOptimize package repository URL** |

2. Specify the **Dependency Rule**, by selecting an exact version, a range of versions or a version rule.

| ![Specify Dependency Rule](../assets/spm-select-dependency-rule.png?raw=true) |
| :---: |
| **Specify dependency version rule** |

3. Click on **Add Package**.

| ![Add Package](../assets/spm-add-package.png?raw=true) |
| :---: |
| **Add Package** |

Alternatively, if your project has a `Package.swift` file, you can add AEPOptimize directly to your dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/adobe/aepsdk-optimize-ios.git", .upToNextMajor(from: "1.0.0"))
],
targets: [
    .target(name: "YourTarget",
            dependencies: [
                "AEPOptimize"
            ],
            path: "your/path"),
]
```

## Manual Install

From the [Optimize project root directory](https://github.com/adobe/aepsdk-optimize-ios), run the following `Makefile` target to generate `AEPOptimize.xcframework`

```text
$ make archive
```

You should see the following terminal output if the command execution is successful.
<pre>
** ARCHIVE SUCCEEDED **

xcodebuild -create-xcframework -framework /Users/johndoe/Workspace/SDKs/aepsdk-optimize-ios/build/ios_simulator.xcarchive/Products/Library/Frameworks/AEPOptimize.framework -debug-symbols /Users/johndoe/Workspace/SDKs/aepsdk-optimize-ios/build/ios_simulator.xcarchive/dSYMs/AEPOptimize.framework.dSYM -framework /Users/johndoe/Workspace/SDKs/aepsdk-optimize-ios/build/ios.xcarchive/Products/Library/Frameworks/AEPOptimize.framework -debug-symbols /Users/johndoe/Workspace/SDKs/aepsdk-optimize-ios/build/ios.xcarchive/dSYMs/AEPOptimize.framework.dSYM -output ./build/AEPOptimize.xcframework

xcframework successfully written out to: /Users/johndoe/Workspace/SDKs/aepsdk-optimize-ios/build/AEPOptimize.xcframework
</pre>

The above command generates the xcframework under the `build` folder in the root directory. Repeat the above steps for all the required dependencies e.g. `AEPCore` and `AEPEdge`. Drag and drop all the `.xcframework`s to your application target in Xcode.
