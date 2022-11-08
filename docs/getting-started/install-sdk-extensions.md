# Install the AEPMessaging extension

> [!INFO]
> Using the `AEPMessaging` extension requires that `AEPCore`, `AEPEdge`, and `AEPEdgeIdentity` extensions also be installed in your mobile application.

The following installation options are currently supported when integrating the Adobe Experience Platform Mobile SDK extensions: 

## CocoaPods

#### BETA instructions

While the in-app messaging feature is in beta, the developer will need to use the Messaging extension on the `staging` branch of its repo. The example below shows how to point to the `staging` branch in a Cocoapods `Podfile`:

```
pod 'AEPMessaging', :git => 'https://github.com/adobe/aepsdk-messaging-ios.git', :branch => 'staging'
```

#### Podfile Example

```ruby
# Define a global platform for your project
platform :ios, '10.0'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

workspace 'MessagingTutorialStarterApp'
project 'MessagingTutorialStarterApp.xcodeproj'

target 'MessagingTutorialStarterApp' do
  # Pods for MessagingTutorialStarterApp
  pod 'AEPCore'  
  pod 'AEPEdge'
  pod 'AEPEdgeIdentity'
  pod 'AEPMessaging', :git => 'https://github.com/adobe/aepsdk-messaging-ios.git', :branch => 'staging'
  pod 'AEPAssurance'
end
```

Save the `Podfile` and run `pod install` to install the dependencies. This generates the `Podfile.lock` file, which tracks (and locks) the installed versions of the various pods.

```text
$ pod install
```

> [!TIP]
> **`pod install`** vs **`pod update`** -
> - `pod install` - when a `Podfile.lock` file is present, this command downloads the dependency versions it specifies. When no `Podfile.lock` file is present, it behaves like a `pod update`.
> - `pod update` - always updates the cocoapods to the latest version possible within `Podfile` restrictions.

<details>
<summary>
<b>Podfile.lock Example</b>
</summary>
<pre>
PODS:
  - AEPAssurance (3.0.1):
    - AEPCore (>= 3.1.0)
    - AEPServices (>= 3.1.0)
  - AEPCore (3.7.2):
    - AEPRulesEngine (>= 1.1.0)
    - AEPServices (>= 3.7.2)
  - AEPEdge (1.5.0):
    - AEPCore (>= 3.5.0)
    - AEPEdgeIdentity
  - AEPEdgeIdentity (1.1.0):
    - AEPCore (>= 3.6.0)
  - AEPMessaging (1.1.0-beta2):
    - AEPCore (>= 3.4.2)
    - AEPEdge (>= 1.1.0)
    - AEPEdgeIdentity (>= 1.0.0)
    - AEPServices (>= 3.4.2)
  - AEPRulesEngine (1.2.0)
  - AEPServices (3.7.2)

DEPENDENCIES:
  - AEPAssurance
  - AEPMessaging (from `https://github.com/adobe/aepsdk-messaging-ios.git`, branch `staging`)

SPEC REPOS:
  trunk:
    - AEPAssurance
    - AEPCore
    - AEPEdge
    - AEPEdgeIdentity
    - AEPRulesEngine
    - AEPServices

EXTERNAL SOURCES:
  AEPMessaging:
    :branch: staging
    :git: https://github.com/adobe/aepsdk-messaging-ios.git

CHECKOUT OPTIONS:
  AEPMessaging:
    :commit: 7cfc4a2403b5c824f2902ed5b6395cecc446d583
    :git: https://github.com/adobe/aepsdk-messaging-ios.git

SPEC CHECKSUMS:
  AEPAssurance: b25880cd4b14f22c61a1dce19807bd0ca0fe9b17
  AEPCore: b606a373e01673d3d9ee244d95010cd75f26d50d
  AEPEdge: 924cd8ace3db40b9c42bc2bc5e8fb1fcad3a9b77
  AEPEdgeIdentity: 47f0c6ecbec5857b2a8cb9b7bf717c2424c6bae0
  AEPMessaging: 31635f7570be215f1bd2781f0e67a7a3a49952aa
  AEPRulesEngine: 71228dfdac24c9ded09be13e3257a7eb22468ccc
  AEPServices: 243909789b9961d07ebe92ec8350e2d5954d5be7

PODFILE CHECKSUM: 10a7daabd701cd42a35c522c3cc85ebefc95fda1

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

## Swift Package Manager (SPM)

SPM installations are not currently supported during the beta.

## Manual Installation

Manual installations are not currently supported during the beta.