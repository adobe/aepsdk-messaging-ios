# Initialize the Adobe Experience Platform Mobile SDKs

Initialize the Experience Platform Mobile SDKs by adding the below code in your `AppDelegate` file.

> [!TIP]
> You can find your Environment File ID and also the mobile SDK initialization code in your tag property on Experience Platform Data Collection UI. Navigate to Environments (select your environment - Production, Staging, or Development), click <small>INSTALL<small>.

| ![SDK Initialization Code](../assets/sdk-init-code.png?raw=true) |
| :---: |
| **SDK Initialization Code** |

**AppDelegate Example**
<!-- tabs:start -->

#### **Swift**
```swift
// AppDelegate.swift

import AEPCore
import AEPLifecycle
import AEPAssurance
import AEPEdge
import AEPEdgeConsent
import AEPEdgeIdentity
import AEPOptimize
import SwiftUI

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        MobileCore.setLogLevel(.trace)

        MobileCore.registerExtensions([
                Lifecycle.self,
                Edge.self,
                Consent.self,
                AEPEdgeIdentity.Identity.self,
                Assurance.self,
                Optimize.self ]) {
            
            MobileCore.configureWith(appId: "yourEnvironmentFileID")
        }
        return true
    }
}
```

#### **Objective-C**

```objc
// AppDelegate.h
@import AEPCore;
@import AEPServices;
@import AEPLifecycle;
@import AEPAssurance;
@import AEPEdge;
@import AEPEdgeConsent;
@import AEPEdgeIdentity;
@import AEPOptimize;
```

```objc
// AppDelegate.m
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [AEPMobileCore setLogLevel:AEPLogLevelTrace];
    
    [AEPMobileCore registerExtensions:@[
        AEPMobileLifecycle.class,
        AEPMobileEdge.class,
        AEPMobileEdgeConsent.class,
        AEPMobileEdgeIdentity.class,
        AEPMobileAssurance.class,
        AEPMobileOptimize.class
    ] completion:^{
        [AEPMobileCore lifecycleStart:@{}];
    }];
    [AEPMobileCore configureWithAppId: @"yourEnvironmentFileID"];
    
    return YES;
}
```
<!-- tabs:end -->
