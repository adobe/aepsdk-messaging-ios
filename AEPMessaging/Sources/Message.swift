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

public class Message: FullscreenMessageDelegate {
    var fullscreenMessage: FullscreenMessage?
    var parent: Messaging
    public var trackOnShow: Bool = true
    
    init(parent: Messaging, html: String) {
        self.parent = parent
        self.fullscreenMessage = ServiceProvider.shared.uiService.createFullscreenMessage(payload: html,
                                                                                listener: self,
                                                                                isLocalImageUsed: false) as? FullscreenMessage
    }
    
    init(parent: Messaging, message: FullscreenMessage) {
        self.parent = parent
        self.fullscreenMessage = message
    }
    
    // ui management
    public func show() {
        if trackOnShow {
            track("viewed")
        }
        
        fullscreenMessage?.show()        
    }
        
    public func dismiss() {
        
    }
    
    // edge event generation
    public func track(_ interaction: String) {
        parent.sendEvent()
    }
    
    // =================================================================================================================
    // MARK: - FullscreenMessageDelegate protocol methods
    // =================================================================================================================
    public func onShow(message: FullscreenMessage) {
        Log.debug(label: MessagingConstants.LOG_TAG, #function)
        
        // send "viewed" Experience Event
        // TODO:
    }
    
    public func onDismiss(message: FullscreenMessage) {
        Log.debug(label: MessagingConstants.LOG_TAG, #function)
    }
    
    public func overrideUrlLoad(message: FullscreenMessage, url: String?) -> Bool {
        Log.debug(label: MessagingConstants.LOG_TAG, #function)
        
        guard let url = url else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Unable to load nil URL.")
            return true
        }
        
        if url.contains("adbinapp://cancel") {
            message.dismiss()
            return false
        }
        
        return true
    }
    
    public func onShowFailure() {
        Log.debug(label: MessagingConstants.LOG_TAG, #function)
    }
}
