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
@testable import AEPServices
@testable import AEPMessaging
import WebKit

class MockFullscreenMessage: FullscreenMessage {
    
    public init(parent: Message? = nil) {
        let messageSettings = MessageSettings(parent: parent)
        super.init(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: MessageMonitor(), settings: messageSettings)
        webView = WKWebView()
    }
    
    var handleJavascriptMessageCalled = false
    var paramJavascriptMessage: String?
    var paramJavascriptHandlerReturnValue: Any?
    override func handleJavascriptMessage(_ name: String, withHandler handler: @escaping (Any?) -> Void) {
        handleJavascriptMessageCalled = true
        paramJavascriptMessage = name
        handler(paramJavascriptHandlerReturnValue)
    }
}
