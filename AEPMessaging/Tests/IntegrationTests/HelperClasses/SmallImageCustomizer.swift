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

import Testing
import SwiftUI
@testable import AEPMessaging

class SmallImageCustomizer : ContentCardCustomizing {
    public var TITLE_COLOR : Color = .blue
    public var BODY_COLOR : Color = .green
    
    public var TITLE_FONT : Font = .title
    public var BODY_FONT : Font = .body
    
    public var BUTTON_BG_COLOR : Color = .red
    public var BUTTON_TEXT_COLOR : Color = .white
    public var BUTTON_FONT : Font = .caption
    
    public var ROOT_STACK_SPACING : CGFloat = 10
    public var TEXT_STACK_SPACING : CGFloat = 20
    public var BUTTON_STACK_SPACING : CGFloat = 30
    
    public var ROOT_STACK_ALIGNMENT : VerticalAlignment = .bottom
    public var TEXT_STACK_ALIGNMENT : HorizontalAlignment = .leading
    public var BUTTON_STACK_ALIGNMENT : VerticalAlignment = .top
    
    public var DISMISS_ICON_FONT : Font = .system(size: 10)
    public var DISMISS_ICON_COLOR : Color = .gray
    public var DISMISS_ICON_ALIGNMENT : Alignment = .topLeading
    
    public var CARD_BACKGROUND_COLOR : Color = .yellow

    
    func customize(template: SmallImageTemplate) {
        // customize UI elements
        template.title.textColor = TITLE_COLOR
        template.title.font = TITLE_FONT
        template.body?.textColor = BODY_COLOR
        template.body?.font = BODY_FONT
        
        // customize buttons
        template.buttons?.first?.text.font = BUTTON_FONT
        template.buttons?.first?.text.textColor = BUTTON_TEXT_COLOR        
        
        // customize root stack
        template.rootHStack.spacing = ROOT_STACK_SPACING
        template.rootHStack.alignment = ROOT_STACK_ALIGNMENT
        
        // customize text stack
        template.textVStack.spacing = TEXT_STACK_SPACING
        template.textVStack.alignment = TEXT_STACK_ALIGNMENT
        
        // customize button stack
        template.buttonHStack.spacing = BUTTON_STACK_SPACING
        template.buttonHStack.alignment = BUTTON_STACK_ALIGNMENT
        
        // add custom modifiers
        template.buttonHStack.modifier = AEPViewModifier(ButtonHStackModifier())
        template.rootHStack.modifier = AEPViewModifier(RootHStackModifier())
                
        // customize the dismiss buttons
        template.dismissButton?.image.iconColor = DISMISS_ICON_COLOR
        template.dismissButton?.image.iconFont = DISMISS_ICON_FONT
        template.dismissButton?.alignment = DISMISS_ICON_ALIGNMENT
        
        // change card background color
        template.backgroundColor = CARD_BACKGROUND_COLOR
    }
    
    struct RootHStackModifier : ViewModifier {
        func body(content: Content) -> some View {
             content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing)
         }
    }
    
    struct ButtonHStackModifier : ViewModifier {
        func body(content: Content) -> some View {
             content
                .frame(maxWidth: .infinity, alignment: .trailing)
         }
    }
}
