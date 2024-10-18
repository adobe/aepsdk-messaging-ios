/*
 Copyright 2024 Adobe. All rights reserved.
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

/// Defines the type of text and its default styling properties
@available(iOS 15.0, *)
enum AEPTextType {
    case title
    case body
    case button

    /// The default font for the text type
    var defaultFont: Font? {
        switch self {
        case .title:
            return Constants.CardTemplate.DefaultStyle.Text.TITLE_FONT
        case .body:
            return Constants.CardTemplate.DefaultStyle.Text.BODY_FONT
        case .button:
            return Constants.CardTemplate.DefaultStyle.Text.BUTTON_FONT
        }
    }

    /// The default color for the text type
    var defaultColor: Color? {
        switch self {
        case .title:
            return Constants.CardTemplate.DefaultStyle.Text.TITLE_COLOR
        case .body:
            return Constants.CardTemplate.DefaultStyle.Text.BODY_COLOR
        case .button:
            return Constants.CardTemplate.DefaultStyle.Text.BUTTON_COLOR
        }
    }
}
