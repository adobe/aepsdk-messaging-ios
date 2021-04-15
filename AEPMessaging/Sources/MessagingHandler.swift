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

import Foundation
import AEPServices

class MessagingHandler: FullscreenMessageDelegate {
    
    // =================================================================================================================
    // MARK: - MessagingDelegate protocol methods
    // =================================================================================================================
//    func onShow(message: Showable) {
//        // TODO: send event to Edge
//        Log.debug(label: MessagingConstants.LOG_TAG, #function)
//    }
//    
//    func onDismiss(message: Showable) {
//        // TODO: send event to Edge
//        Log.debug(label: MessagingConstants.LOG_TAG, #function)
//    }
//    
//    func shouldShowMessage(message: Showable) -> Bool {
//        Log.debug(label: MessagingConstants.LOG_TAG, #function)
//        return true
//    }
    
    // =================================================================================================================
    // MARK: - FullscreenMessageDelegate protocol methods
    // =================================================================================================================
    func onShow(message: FullscreenMessage) {
        Log.debug(label: MessagingConstants.LOG_TAG, #function)
    }
    
    func onDismiss(message: FullscreenMessage) {
        Log.debug(label: MessagingConstants.LOG_TAG, #function)
    }
    
    func overrideUrlLoad(message: FullscreenMessage, url: String?) -> Bool {
        Log.debug(label: MessagingConstants.LOG_TAG, #function)
        
        if (url!.contains("adbinapp://cancel")) {
            message.dismiss()
            return false
        }
        return true
    }
    
    func onShowFailure() {
        Log.debug(label: MessagingConstants.LOG_TAG, #function)
    }
}
