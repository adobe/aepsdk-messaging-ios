/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import AEPCore
import AEPServices
import Foundation
import WebKit

public class Message {
    // MARK: - public properties
    public var id: String
    public var autoTrack: Bool = true
    public var view: UIView? {
        return fullscreenMessage?.webView
    }

    // MARK: internal properties
    weak var parent: Messaging?
    var fullscreenMessage: FullscreenMessage?
    var triggeringEvent: Event?
    let experienceInfo: [String: Any] /// holds xdm data necessary for tracking message interactions with AJO

    /// Creates a Message object which owns and controls UI and tracking behavior of the In-App Message
    ///
    /// - Parameters:
    ///   - parent: the `Messaging` object that owns the new `Message`
    ///   - event: the Rules Consequence `Event` that defines the message and contains reporting information
    ///
    init(parent: Messaging, event: Event) {
        self.parent = parent
        self.triggeringEvent = event
        self.id = event.messageId ?? ""
        self.experienceInfo = event.experienceInfo ?? [:]
        let messageSettings = event.getMessageSettings(withParent: self)
                        

        
        // TODO: remove test stuff prior to merge
//         test modal
//        let leftRightGestures = [
//            MessageGesture.fromString("swipeLeft")!: URL(string: "adbinapp://dismiss?interaction=negative")!,
//            MessageGesture.fromString("swipeRight")!: URL(string: "adbinapp://dismiss?interaction=positive")!
//        ]
//        let modalSettings = MessageSettings(parent: self).setDisplayAnimation(.left).setDismissAnimation(.fade).setHeight(20).setWidth(80).setGestures(leftRightGestures)
        
//        // test top banner
//        let upGesture = [ MessageGesture.fromString("swipeUp")!: URL(string: "adbinapp://dismiss")!]
//        let bannerTopSettings = MessageSettings(parent: self).setVerticalAlign(.top).setDisplayAnimation(.top).setDismissAnimation(.top).setHeight(15).setGestures(upGesture)
        
//        // test bottom banner
//        let downGesture = [ MessageGesture.fromString("swipeDown")!: URL(string: "adbinapp://dismiss")!]
//        let bannerBottomSettings = MessageSettings(parent: self).setVerticalAlign(.bottom).setDisplayAnimation(.bottom).setDismissAnimation(.bottom).setHeight(15).setGestures(downGesture)
//
        //        messageSettings.setBackdropColor("000000")
        //        messageSettings.setBackdropOpacity(0.5)
        
        
        self.fullscreenMessage = ServiceProvider.shared.uiService.createFullscreenMessage?(payload: event.html ?? "",
                                                                                           listener: self,
                                                                                           isLocalImageUsed: false,
                                                                                           settings: messageSettings) as? FullscreenMessage
    }

    // MARK: - UI management

    /// Signals to the UIServices that the message should be shown.
    /// If `autoTrack` is true, calling this method will result in a "trigger" Edge Event being dispatched.
    public func show() {
        if autoTrack {
            track(nil, withEdgeEventType: .inappDisplay)
        }

        fullscreenMessage?.show()
    }

    /// Signals to the UIServices that the message should be dismissed.
    /// If `autoTrack` is true, calling this method will result in a "dismiss" Edge Event being dispatched.
    public func dismiss(suppressAutoTrack: Bool? = false) {
        if autoTrack, let suppress = suppressAutoTrack, !suppress {
            track(nil, withEdgeEventType: .inappDismiss)
        }

        fullscreenMessage?.dismiss()
    }

    // MARK: - Edge Event creation

    /// Generates an Edge Event for the provided `interaction` and `eventType`.
    ///
    /// - Parameters:
    ///   - interaction: a custom `String` value to be recorded in the interaction
    ///   - eventType: the `MessagingEdgeEventType` to be used for the ensuing Edge Event
    public func track(_ interaction: String?, withEdgeEventType eventType: MessagingEdgeEventType) {
        parent?.sendExperienceEvent(withEventType: eventType, andInteraction: interaction, forMessage: self)
    }

    // MARK: - Webview javascript handling

    /// Adds a handler for Javascript messages sent from the message's webview.
    ///
    /// The parameter passed to `handler` will contain the body of the message passed from the webview's Javascript.
    ///
    /// - Parameters:
    ///   - name: the name of the message that should be handled by `handler`
    ///   - handler: the closure to be called with the body of the message passed by the Javascript message
    public func handleJavascriptMessage(_ name: String, withHandler handler: @escaping (Any?) -> Void) {
        fullscreenMessage?.handleJavascriptMessage(name, withHandler: handler)
    }

    // MARK: - Internal methods
    func trigger() {
        if autoTrack {
            track(nil, withEdgeEventType: .inappTrigger)
        }
    }
}