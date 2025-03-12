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

#if os(iOS)
    import Foundation
    import WebKit

    // MARK: - WKScriptMessageHandler
    @available(iOSApplicationExtension, unavailable)
    extension FullscreenMessage: WKScriptMessageHandler {
      
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
                let safeAreaHeight = safeAreaHeight
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
      
        
        public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if let handler = scriptHandlers[message.name] {
                Log.debug(label: LOG_PREFIX, "Calling javascript handler for \(message.name) with content \(message.body).")
//                DispatchQueue.main.async {
//                    guard let webViewHeightInPixels = self.stringToCGFloat(message.body) else {
//                        print("Invalid or nil content. Could not convert to CGFloat")
//                        return
//                    }
//
//                    let heightConversion = self.convertWebViewPixelToIOS(webViewHeightInPixels, for: "height")
//
//                    self.settings?.setHeight(Int(heightConversion.percentage));
//                    
//                    self.webView?.frame = self.frameWhenVisible
//                   // self.reframeMessage()
//                }
                guard let webViewHeightInPixels = self.stringToCGFloat(message.body) else {
                                      print("Invalid or nil content. Could not convert to CGFloat")
                                      return
                                  }
                let heightConversion = self.convertWebViewPixelToIOS(webViewHeightInPixels, for: "height")

                self.settings?.setHeight(Int(heightConversion.percentage));
                
                self.webView?.frame = self.frameWhenVisible
                handler(message.body)
            }
        }
    }
#endif
