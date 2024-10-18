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

import Foundation
#if canImport(SwiftUI)
    import SwiftUI
#endif

@available(iOS 15.0, *)
enum Constants {
    static let LOG_TAG = "AEPSwiftUI"
    static let EXTENSION_VERSION = "5.1.0"

    enum CardTemplate {
        static let SmallImage = "SmallImage"
        static let LargeImage = "LargeImage"
        static let ImageOnly = "ImageOnly"

        enum DefaultStyle {
            static let PADDING = 8.0
            enum Text {
                static let TITLE_FONT = Font.system(size: 15, weight: .medium)
                static let TITLE_COLOR = Color.primary

                static let BODY_FONT = Font.system(size: 13, weight: .regular)
                static let BODY_COLOR = Color.secondary

                static let BUTTON_FONT = Font.system(size: 13, weight: .regular)
                static let BUTTON_COLOR = Color.blue
            }

            enum Stack {
                static let SPACING = 8.0
                static let HORIZONTAL_ALIGNMENT = HorizontalAlignment.center
                static let VERTICAL_ALIGNMENT = VerticalAlignment.center
            }

            enum Image {
                static let ICON_COLOR = Color.primary
                static let ICON_SIZE = 13
            }

            enum DismissButton {
                static let ALIGNMENT = Alignment.topTrailing
                static let SIZE = 13
            }
        }

        enum InteractionID {
            static let cardTapped = "Card clicked"
        }

        enum SchemaData {
            enum Meta {
                static let ADOBE_DATA = "adobe"
                static let TEMPLATE = "template"
            }

            static let TITLE = "title"
            static let BODY = "body"
            static let IMAGE = "image"
            static let ACTION_URL = "actionUrl"
            static let BUTTONS = "buttons"
            static let DISMISS_BTN = "dismissBtn"
        }

        enum DismissButton {
            static let STYLE = "style"

            enum Icon {
                static let SIMPLE = "xmark"
                static let CIRCLE = "xmark.circle.fill"
            }
        }

        enum UIElement {
            enum Text {
                static let CONTENT = "content"
            }

            enum Button {
                static let INTERACTION_ID = "interactId"
                static let TEXT = "text"
                static let ACTION_URL = "actionUrl"
            }

            enum Image {
                static let URL = "url"
                static let DARK_URL = "darkUrl"
                static let BUNDLE = "bundle"
                static let DARK_BUNDLE = "darkBundle"
                static let ICON = "icon"
                static let ALTERNATE_TEXT = "alt"
            }
        }
    }
}
