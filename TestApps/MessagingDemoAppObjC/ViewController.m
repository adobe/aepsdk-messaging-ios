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

#import "ViewController.h"
@import AEPCore;
@import AEPServices;
@import AEPMessaging;


@interface MessageHandler : NSObject <AEPMessagingDelegate>

@end

@implementation MessageHandler

- (void) onDismiss:(id<AEPShowable> _Nonnull)message {
    
}


- (void) onShow:(id<AEPShowable> _Nonnull)message {
    
}

- (BOOL) shouldShowMessage:(id<AEPShowable> _Nonnull)message {
    AEPFullscreenMessage *fullscreenMessage = (AEPFullscreenMessage *)message;
    AEPMessage *aepMessage = fullscreenMessage.settings.parent;
    WKWebView *webView = (WKWebView *)aepMessage.view;
    NSLog(@"aepMessage.id: %@", aepMessage.id);
    NSLog(@"webView: %@", webView);
    
    return YES;
}

- (void) urlLoaded:(NSURL *)url byMessage:(id<AEPShowable>)message {
    
}

@end


@interface ViewController ()
@property (strong) MessageHandler *messageHandler;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _messageHandler = [[MessageHandler alloc] init];
    
    [AEPMobileCore setMessagingDelegate:_messageHandler];
}

- (IBAction) triggerFullscreen:(id)sender {
    [AEPMobileCore trackAction:@"keep-fullscreen" data:nil];
}

@end


