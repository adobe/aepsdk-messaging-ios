# Initialize the Adobe Experience Platform Mobile SDKs

Initialize the Experience Platform Mobile SDKs by adding the below code in your `AppDelegate` file.

> [!TIP]
> You can find your Environment File ID and SDK initialization code in your _Tag_ property in the _Experience Platform Data Collection_ UI. <br /><br />Navigate to **Environments** > select your environment (**Production**, **Staging**, or **Development**) > click **INSTALL**.

**AppDelegate Example**
<!-- tabs:start -->

#### **Swift**

```swift
// AppDelegate.swift

import AEPAssurance
import AEPCore
import AEPEdge
import AEPEdgeIdentity
import AEPMessaging

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        MobileCore.setLogLevel(.trace)

        let extensions = [
            Edge.self,                
            AEPEdgeIdentity.Identity.self,
            Assurance.self,
            Messaging.self 
        ]

        MobileCore.registerExtensions(extensions) {            
            MobileCore.configureWith(appId: "yourEnvironmentFileID")
        }
        return true
    }
}
```

#### **Objective-C**

```objc
// AppDelegate.h
@import AEPAssurance;
@import AEPCore;
@import AEPEdge;
@import AEPEdgeIdentity;
@import AEPMessaging;
```

```objc
// AppDelegate.m
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [AEPMobileCore setLogLevel:AEPLogLevelTrace];
    
    NSArray *extensions = @[
        AEPMobileEdge.class        
        AEPMobileEdgeIdentity.class,
        AEPMobileAssurance.class,
        AEPMobileMessaging.class
    ];

    [AEPMobileCore registerExtensions:extensions completion:^{
        [AEPMobileCore configureWithAppId: @"yourEnvironmentFileID"];
    }];
        
    return YES;
}
```
<!-- tabs:end -->
