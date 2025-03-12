/*
 Copyright 2022 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

#import "AppDelegate.h"
@import AEPCore;
@import AEPAssurance;
@import AEPEdge;
@import AEPEdgeConsent;
@import AEPEdgeIdentity;
@import AEPMessaging;
@import AEPServices;
@import AEPSignal;
@import AEPLifecycle;

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [AEPMobileCore setLogLevel:AEPLogLevelTrace];
    
    NSArray *extensions = @[
        AEPMobileEdgeConsent.class,
        AEPMobileEdgeIdentity.class,
        AEPMobileMessaging.class,
        AEPMobileEdge.class,
        AEPMobileAssurance.class,
        AEPMobileLifecycle.class,
        AEPMobileSignal.class
    ];
    
    [AEPMobileCore registerExtensions:extensions completion:^{
        [AEPMobileAssurance startSessionWithUrl:[NSURL URLWithString:@"edgetutorialapp://?adb_validation_sessionid=6d2f49c1-630b-4ae3-9966-82b02c6961f3&env=stage"]];
    }];
    
    [AEPMobileCore configureWithAppId:@"staging/1b50a869c4a2/9590f35e2dc9/launch-752d0a90822f-development"];
    
    return YES;
}

#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {

}


- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    [AEPMobileMessaging handleNotificationResponse:response urlHandler:nil closure:^(AEPPushTrackingStatus status){
        if (status == AEPPushTrackingStatusTrackingInitiated) {
            NSLog(@"Successfully started push notification tracking");
        }
    }];
}

@end
