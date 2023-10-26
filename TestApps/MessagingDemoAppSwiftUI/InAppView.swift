/*
Copyright 2023 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/

import AEPCore
import AEPMessaging
import AEPServices
import SwiftUI
import WebKit

struct InAppView: View {
    @State private var viewDidLoad = false
    @State private var messageHandler = MessageHandler()
    @State private var shouldShowMessages = true
    var body: some View {
        VStack {
            VStack {
                Text("In-app")
                    .font(Font.title2.weight(.bold))
                    .frame(height: 70)
                    .padding(.top, 30)
                Divider()
            }
            Grid(alignment: .leading, horizontalSpacing: 70, verticalSpacing: 30) {
                GridRow {
                    Button("fullscreen") {
                        MobileCore.track(action: "fullscreen_ss", data: ["testFullscreen": "true"])
                    }
                    
                    Button("modal") {
                        MobileCore.track(action: "triggerModal", data: ["testModal": "true"])
                    }
                }
                GridRow {
                    Button("top banner") {
                        MobileCore.track(action: "triggerBannerTop", data: ["testBannerTop": "true"])
                    }
                    
                    Button("bottom banner") {
                        MobileCore.track(action: "modalTakeoverGestures", data: nil)
                    }
                }
            }
            VStack {
                Text("Event Sequencing")
                    .font(Font.title2.weight(.bold))
                    .frame(height: 70)
                    .padding(.top, 30)
                Divider()
            }
            Grid(alignment: .leading, horizontalSpacing: 70, verticalSpacing: 30) {
                GridRow {
                    Button("event 1") {
                        let event = Event(name: "Event1", type: "iam.tester", source: "inbound", data: ["firstEvent": "true"], mask: ["firstEvent"])
                        MobileCore.dispatch(event: event)
                    }
                }
                GridRow {
                    Button("event 2") {
                        let event = Event(name: "Event2", type: "iam.tester", source: "inbound", data: ["secondEvent": "true"], mask: ["secondEvent"])
                        MobileCore.dispatch(event: event)
                    }
                    Button("1 > 2 > 3?") {
                        let checkSequenceEvent = Event(name: "Check Sequence", type: "iam.tester", source: "inbound", data: ["checkSequence": "true"])
                        MobileCore.dispatch(event: checkSequenceEvent)
                    }
                }
                GridRow {
                    Button("event 3") {
                        let event = Event(name: "Event3", type: "iam.tester", source: "inbound", data: ["thirdEvent": "true"], mask: ["thirdEvent"])
                        MobileCore.dispatch(event: event)
                    }
                }
            }
            Spacer()
                .frame(height: 80)
            Grid(alignment: .center, horizontalSpacing: 30, verticalSpacing: 30) {
                GridRow {
                    Button("refresh messages") {
                        Messaging.refreshInAppMessages()
                    }
                    Button("show stored messages") {
                        messageHandler.currentMessage?.show()
                    }
                }
                GridRow {
                    Toggle("Show message when triggered", isOn: $shouldShowMessages)
                        .onChange(of: shouldShowMessages) { _ in
                            messageHandler.showMessages.toggle()
                        }
                }
                .gridCellColumns(2)
                .gridCellUnsizedAxes([.horizontal])
            }
            Spacer()
        }
        .onAppear {
            if viewDidLoad == false {
                viewDidLoad = true
                MobileCore.messagingDelegate = messageHandler
            }
        }
    }
}

/// Messaging delegate
private class MessageHandler: MessagingDelegate {
    var showMessages = true
    var currentMessage: Message?
    let autoDismiss = false

    func onShow(message: Showable) {
        let fullscreenMessage = message as? FullscreenMessage
        print("message was shown \(fullscreenMessage?.debugDescription ?? "undefined")")
    }

    func onDismiss(message: Showable) {
        let fullscreenMessage = message as? FullscreenMessage
        print("message was dismissed \(fullscreenMessage?.debugDescription ?? "undefined")")
    }

    func shouldShowMessage(message: Showable) -> Bool {
        
        // access to the whole message from the parent
        let fullscreenMessage = message as? FullscreenMessage
        let message = fullscreenMessage?.parent

        // in-line handling of javascript calls
        // see Assets/nativeMethodCallingSample.html for an example of how to call this method
        message?.handleJavascriptMessage("buttonClicked") { content in
            print("magical handling of our content from js! content is: \(content ?? "empty")")
            message?.track(content as? String, withEdgeEventType: .inappInteract)
        }

        // if using the webview for something, make sure to dispatch back to the main thread
        DispatchQueue.main.async {
            // access the WKWebView containing the message's UI
            let messageWebView = message?.view as? WKWebView
            // execute JavaScript inside of the message's WKWebView
            messageWebView?.evaluateJavaScript("startTimer();") { result, error in
                if error != nil {
                    // handle error
                }
                if result != nil {
                    // do something with the result
                }
            }
        }
        
        // if we're not showing the message now, we can save it for later
        if !showMessages {
            currentMessage = message
            currentMessage?.track("message suppressed", withEdgeEventType: .inappTrigger)
        } else if autoDismiss {
            currentMessage = message
            let _ = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { timer in
                timer.invalidate()
                self.currentMessage?.track("test for reporting", withEdgeEventType: .inappInteract)
                self.currentMessage?.dismiss()
            }
        }

        return showMessages
    }

    func urlLoaded(_ url: URL) {
        print("fullscreen message loaded url: \(url)")
    }
}

struct InAppView_Previews: PreviewProvider {
    static var previews: some View {
        InAppView()
    }
}
