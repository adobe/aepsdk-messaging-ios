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
@import WebKit;

@interface MessageHandler : NSObject <AEPMessagingDelegate>

@property (nonatomic) bool showMessages;
@property (nonatomic, strong) AEPMessage* currentMessage;

@end

@implementation MessageHandler

- (void) onDismiss:(id<AEPShowable> _Nonnull)message {
    AEPFullscreenMessage *fullscreenMessage = (AEPFullscreenMessage *)message;
    AEPMessage *aepMessage = fullscreenMessage.settings.parent;
    NSLog(@"message was dismissed: %@", aepMessage.id);
}

- (void) onShow:(id<AEPShowable> _Nonnull)message {
    AEPFullscreenMessage *fullscreenMessage = (AEPFullscreenMessage *)message;
    AEPMessage *aepMessage = fullscreenMessage.settings.parent;
    NSLog(@"message was shown: %@", aepMessage.id);
}

- (BOOL) shouldShowMessage:(id<AEPShowable> _Nonnull)message {
    // access to the whole message object from the parent
    AEPFullscreenMessage *fullscreenMessage = (AEPFullscreenMessage *)message;
    AEPMessage *aepMessage = fullscreenMessage.settings.parent;
    
    // in-line handling of javascript calls
    // see Assets/nativeMethodCallingSample.html for an example of how to call this method
    [aepMessage handleJavascriptMessage:@"buttonClicked" withHandler:^(NSString* content) {
        NSLog(@"handling content from JS! content is: %@", content ?: @"empty");
        if (aepMessage) {
            [aepMessage trackInteraction:content withEdgeEventType:AEPMessagingEdgeEventTypeInteract];
        }
    }];
    
    // access the WKWebView containing the message's UI
    WKWebView *webView = (WKWebView *)aepMessage.view;
    // execute JavaScript inside of the message's WKWebView
    [webView evaluateJavaScript:@"startTimer();" completionHandler:^(id result, NSError * _Nullable error) {
        if (error) {
            // handle error
        }
        if (result) {
            // do something with the result
        }
    }];
    
    // if we're not showing the message now, we can save it for later
    if (!_showMessages) {
        _currentMessage = aepMessage;
        [_currentMessage trackInteraction:@"message suppressed" withEdgeEventType:AEPMessagingEdgeEventTypeInteract];
    }
    
    return _showMessages;
}

- (void) urlLoaded:(NSURL *)url byMessage:(id<AEPShowable>)message {
    NSLog(@"message loaded url: %@", url);
    [AEPMobileMessaging updatePropositionsForSurfaces:@[]];
}

@end


@interface ViewController ()
@property (strong) MessageHandler *messageHandler;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _messageHandler = [[MessageHandler alloc] init];
    _messageHandler.showMessages = true;
    
    [AEPMobileCore setMessagingDelegate:_messageHandler];
}

- (IBAction) triggerFullscreen:(id)sender {
    [AEPMobileCore trackAction:@"keep-fullscreen" data:nil];
}

@end


