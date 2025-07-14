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

import Testing
import SwiftUI
@testable import AEPMessaging

class ImageOnlyCustomizer : ContentCardCustomizing {
    
    public var DISMISS_ICON_FONT : Font = .system(size: 10)
    public var DISMISS_ICON_COLOR : Color = .gray
    public var DISMISS_ICON_ALIGNMENT : Alignment = .topLeading
    
    public var CARD_BACKGROUND_COLOR : Color = .yellow

    func customize(template: SmallImageTemplate) {
        // Do nothing for SmallImageTemplate
    }
    
    func customize(template: LargeImageTemplate) {
        // Do nothing for LargeImageTemplate
    }
    
    func customize(template: ImageOnlyTemplate) {
        // customize the dismiss buttons
        template.dismissButton?.image.iconColor = DISMISS_ICON_COLOR
        template.dismissButton?.image.iconFont = DISMISS_ICON_FONT
        template.dismissButton?.alignment = DISMISS_ICON_ALIGNMENT
        
        // change card background color
        template.backgroundColor = CARD_BACKGROUND_COLOR
    }
} 