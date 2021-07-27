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

public class Message: FullscreenMessageDelegate {
    // MARK: - public properties
    public var id: String
    public var autoTrack: Bool = true
    public var view: UIView? {        
        return fullscreenMessage?.webView
    }
    
    public func handleJavascriptMessage(_ name: String, withHandler handler: @escaping (Any?) -> Void) {
        fullscreenMessage?.handleJavascriptMessage(name, withHandler: handler)
    }
    
    
    // MARK: internal properties
    weak var parent: Messaging?
    var fullscreenMessage: FullscreenMessage?
    var triggeringEvent: Event?
    let experienceInfo: [String: Any] /// holds xdm data necessary for tracking message interactions with AJO
    
    init(parent: Messaging, event: Event) {
        self.parent = parent
        self.triggeringEvent = event
        self.id = event.messageId ?? ""
        self.experienceInfo = event.experienceInfo ?? [:]
        self.fullscreenMessage = ServiceProvider.shared.uiService.createFullscreenMessage?(payload: event.html ?? "",
                                                                                          listener: self,
                                                                                          isLocalImageUsed: false,
                                                                                          parent: self) as? FullscreenMessage
    }
    
    // ui management
    public func show() {
        if autoTrack {
            track("triggered")
        }
        
        fullscreenMessage?.show()        
    }
        
    public func dismiss() {
        if autoTrack {
            track("dismissed")
        }
        
        fullscreenMessage?.dismiss()
    }
    
    // edge event generation
    public func track(_ interaction: String) {
        parent?.recordInteractionForMessage(interaction, message:self)
    }
    
    // =================================================================================================================
    // MARK: - FullscreenMessageDelegate protocol methods
    // =================================================================================================================
    public func onShow(message: FullscreenMessage) {
        Log.debug(label: MessagingConstants.LOG_TAG, #function)
    }
    
    public func onDismiss(message: FullscreenMessage) {
        Log.debug(label: MessagingConstants.LOG_TAG, #function)
                
        guard let message = message.parent as? Message else {
            return
        }
        
        message.dismiss()    
    }
    
    public func overrideUrlLoad(message: FullscreenMessage, url: String?) -> Bool {
        Log.debug(label: MessagingConstants.LOG_TAG, #function)
        
        guard let urlString = url, let url = URL(string: urlString) else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Unable to load nil URL.")
            return true
        }
        
        let message = message.parent as? Message
        
        if url.scheme == "adbinapp" {
            
            // handle request parameters
            let queryParams = url.query?.components(separatedBy: "&").map({
                $0.components(separatedBy: "=")
            }).reduce(into: [String: String]()) { dict, pair in
                if pair.count == 2 {
                    dict[pair[0]] = pair[1]
                }
            }
            
            // handle optional tracking
            if let interaction = queryParams?["interaction"] {
                message?.track(interaction)
            }
            
            // dismiss if requested
            if url.host == "dismiss" {
                message?.dismiss()
            }
            
            // handle optional deep link
            if let deeplinkUrl = URL(string: queryParams?["link"] ?? "") {
                UIApplication.shared.open(deeplinkUrl)
            }
            
            return false
        }
        
        return true
    }
    
    public func onShowFailure() {
        Log.debug(label: MessagingConstants.LOG_TAG, #function)
    }
}
