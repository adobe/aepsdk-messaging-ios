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
import AEPEdge
import AEPMessaging
import AEPServices
import SwiftUI
import WebKit

struct InAppView: View {
    @State private var viewDidLoad = false
    @State private var messageHandler = MessageHandler()
    @State private var shouldShowMessages = true
    @State private var customAction = ""
    var body: some View {
        VStack {
            VStack {
                Text("In-app")
                    .font(Font.title2.weight(.bold))
                    .frame(height: 70)
                    .padding(.top, 10)
                    .padding(.bottom, -15)
                Divider().padding(.bottom, 5).padding(.top, 0)
            }
            Grid(alignment: .leading, horizontalSpacing: 70, verticalSpacing: 20) {
                GridRow {
                    Button("fullscreen") {
                        MobileCore.track(action: "fullscreen_ss", data: ["testFullscreen": "true"])
                    }
                    
                    Button("modal") {
                        MobileCore.track(action: "untilClicked", data: ["testModal": "true"])
                    }
                }
                GridRow {
                    Button("top banner") {
                        MobileCore.track(action: "triggerBannerTop", data: ["testBannerTop": "true"])
                    }
                    
                    Button("bottom banner") {
                        MobileCore.track(action: "surfaceTesting", data: nil)
                    }
                }
            }
            VStack {
                Text("Content card qualification")
                    .font(Font.title2.weight(.bold))
                    .frame(height: 70)
                    .padding(.top, 10)
                    .padding(.bottom, -15)
                Divider().padding(.bottom, 5).padding(.top, 0)
            }
            Grid(alignment: .leading, horizontalSpacing: 70, verticalSpacing: 20) {
                GridRow {
                    Button("qualify 1") {
                        MobileCore.track(action: "timestampz", data: nil)
                    }
                    Button("qualify 2") {
                        let experienceEvent = ExperienceEvent(xdm: ["player": "julio"])
                        Edge.sendEvent(experienceEvent: experienceEvent)
                    }
                }
                GridRow {
                    Button("qualify 3") {
                        MobileCore.track(action: "sticky", data: nil)
                    }
                    Button("request cards") {
                        let msContentCardsSurface = Surface(path: "cards/ms")
                        Messaging.updatePropositionsForSurfaces([msContentCardsSurface])
                    }
                }
                
            }
            VStack {
                Text("Messaging delegate")
                    .font(Font.title2.weight(.bold))
                    .frame(height: 70)
                    .padding(.top, 10)
                    .padding(.bottom, -15)
                Divider().padding(.bottom, 5).padding(.top, 0)
            }
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
            VStack {
                Text("Custom action testing")
                    .font(Font.title2.weight(.bold))
                    .frame(height: 70)
                    .padding(.top, 10)
                    .padding(.bottom, -15)
                Divider().padding(.bottom, 5).padding(.top, 0)
            }
            Grid(alignment: .leading, horizontalSpacing: 70, verticalSpacing: 30) {
                GridRow {
                    TextField("Enter custom action...", text: $customAction).padding(.leading, 25)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                GridRow {
                    Button("track") {
                        guard !customAction.isEmpty else {
                            return
                        }
                        MobileCore.track(action: customAction, data: nil)
                    }.padding(.leading, 25)
                }
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
    
        // Safely unwrap the FullscreenMessage and its parent
        guard let fullscreenMessage = message as? FullscreenMessage,
              let parentMessage = fullscreenMessage.parent else {
            print("Unable to cast message to FullscreenMessage or parent not found")
            return
        }
    }



    func onDismiss(message: Showable) {
        let fullscreenMessage = message as? FullscreenMessage
        print("message was dismissed \(fullscreenMessage?.debugDescription ?? "undefined")")
    }
    
    func getSafeAreaHeight() -> CGFloat {
        if #available(iOS 16.0, *) {
            if let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.keyWindow,
               let fullscreen = window.windowScene?.isFullScreen, fullscreen {
                return 0
            }
        }
        
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.keyWindow?
                .windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            return UIApplication.shared.statusBarFrame.height
        }
    }

    
    func convertWebViewPixelToIOS(_ webViewPixelValue: CGFloat, for dimension: String) -> (logicalPixels: CGFloat, percentage: CGFloat) {
        // Get the device pixel ratio (DPR) from JavaScript or assume default for iOS WebView
        let devicePixelRatio: CGFloat = UIScreen.main.scale // Matches the DPR in WebView

        // Convert WebView pixels to iOS logical pixels
//        let iosLogicalPixels = webViewPixelValue / devicePixelRatio
               let iosLogicalPixels = webViewPixelValue

        // Calculate the percentage relative to the screen dimension
        let screenSize = UIScreen.main.bounds
        
        var screenDimension: CGFloat
           
        if dimension == "width" {
            screenDimension = screenSize.width
        } else if dimension == "height" {
            let safeAreaHeight = getSafeAreaHeight()
            screenDimension = screenSize.height - safeAreaHeight
        } else {
            fatalError("Invalid dimension parameter. Use 'width' or 'height'.")
        }

        
        
        let percentage = (iosLogicalPixels / screenDimension) * 100

        print("Conversion Details for \(dimension):")
        print("WebView Pixel Value: \(webViewPixelValue)")
        print("iOS Logical Pixels: \(iosLogicalPixels)")
        print("Percentage of Screen \(dimension.capitalized): \(percentage)%")

        return (logicalPixels: iosLogicalPixels, percentage: percentage)
    }

    func stringToCGFloat(_ stringValue: Any?) -> CGFloat? {
        // Safely unwrap the value and check if it's a string
        if let stringValue = stringValue as? String, let doubleValue = Double(stringValue) {
            return CGFloat(doubleValue)
        }
        return nil
    }
  

    func shouldShowMessage(message: Showable) -> Bool {
        print("I am in this show message function always")

        // Access the FullscreenMessage instance
        guard let fullscreenMessage = message as? FullscreenMessage,
              let parentMessage = fullscreenMessage.parent else {
            print("Unable to cast message to FullscreenMessage or parent not found")
            return false
        }
        
        
        // if i am setting height here then its working fine...
        //fullscreenMessage.setHeightA(newHeight: 10);
       

        // Inline handling of JavaScript calls
//        parentMessage.handleJavascriptMessage("myCallback") { [weak self] content in
//            guard let self = self else { return }
//
//            print("Magical handling of our content from JS! Content is: \(content ?? "empty")")
//
//            // Extract the content and convert it to CGFloat for height
//            let webViewWidthInPixels: CGFloat = 900 // Example width value from JavaScript
//            guard let webViewHeightInPixels = self.stringToCGFloat(content) else {
//                print("Invalid or nil content. Could not convert to CGFloat")
//                return
//            }
//
//            // Perform width and height conversion
//            let widthConversion = self.convertWebViewPixelToIOS(webViewWidthInPixels, for: "width")
//            let heightConversion = self.convertWebViewPixelToIOS(webViewHeightInPixels, for: "height")
//        
//            // Log the conversion results
//            print("Width: \(widthConversion.logicalPixels) logical pixels, \(widthConversion.percentage)% of screen width")
//            print("Height: \(heightConversion.logicalPixels) logical pixels, \(heightConversion.percentage)% of screen height")
//    
//
//            // Track the interaction with the extracted content
//            parentMessage.track(content as? String, withEdgeEventType: .interact)
//        }

        // Handle scenarios where the message should not be shown immediately
        if !showMessages {
            currentMessage = parentMessage
            print("Message suppressed and stored for later use.")
        } else if autoDismiss {
            currentMessage = parentMessage
            let _ = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { timer in
                timer.invalidate()
                self.currentMessage?.track("Auto-dismiss triggered", withEdgeEventType: .interact)
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
