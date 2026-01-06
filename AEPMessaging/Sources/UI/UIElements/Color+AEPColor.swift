/*
 Copyright 2025 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

#if canImport(SwiftUI)
    import SwiftUI
#endif
import Foundation

@available(iOS 15.0, *)
extension Color {
    /// Creates a Color from AEPColor with light and dark mode support
    /// - Parameter aepColor: The AEPColor containing hex values for light and dark modes
    init(aepColor: AEPColor) {
        self.init(
            light: Color(hex: aepColor.light),
            dark: Color(hex: aepColor.dark)
        )
    }
    
    /// Creates a Color from AEPColor with light and dark mode support
    /// - Parameters:
    ///   - light: Color for light mode
    ///   - dark: Color for dark mode
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #else
        self = light
        #endif
    }
    
    /// Creates a Color from a hex string
    /// Supports formats: "0xRRGGBB", "0xRRGGBBAA", "#RRGGBB", "#RRGGBBAA", "RRGGBB", "RRGGBBAA"
    /// - Parameter hex: The hex string
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "0x", with: "")
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let length = hexSanitized.count
        let r, g, b, a: Double
        
        if length == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double((rgb & 0x000000FF)) / 255.0
        } else {
            r = 0
            g = 0
            b = 0
            a = 1
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

