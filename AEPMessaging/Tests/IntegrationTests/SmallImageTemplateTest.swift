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
@testable import AEPServices
@testable import AEPCore
@testable import AEPMessaging

@Suite("SmallImageTemplate", .serialized, .tags(.SmallImageTemplate))
class SmallImageTemplateTest : IntegrationTestBase {
    
    override init() {
        super.init()
    }

    @Test("verify UI elements", .tags(.UITest))
    func smallImageTemplateCard() async throws {
        // setup
        setContentCardResponse(fromFile: "SmallImageCard")
        
        // test
        let cards = try await getContentCardUI(homeSurface)
        
        // verify
        #expect(cards.count == 1)
                
        // verify content card details
        let card = try #require (cards.first?.template as? SmallImageTemplate)
        #expect(card.templateType == .smallImage)
        
        // verify cards UI elements
        #expect(card.title.content == "This is small image title")
        #expect(card.body?.content == "This is small image body")
        #expect(card.actionURL?.absoluteString == "https://cardaction.com")
        #expect(card.dismissButton?.image.icon == "xmark")
        #expect(card.image?.url?.absoluteString == "https://imageurl.com/light")
        #expect(card.image?.darkUrl?.absoluteString == "https://imageurl.com/dark")
        
        // verify buttons
        #expect(card.buttons?.count == 1)
        let firstButton = try #require (card.buttons?.first)
        #expect(firstButton.text.content == "ButtonTextOne")
        #expect(firstButton.interactId == "buttonOneClicked")
        #expect(firstButton.actionUrl?.absoluteString == "https://buttonone.com/action")
        #expect(card.view != nil)
    }
        
    @Test("verify customization", .tags(.UITest))
    func smallImageTemplateCustomization() async throws {
        // setup
        setContentCardResponse(fromFile: "SmallImageCard")
        let homePageCardCustomizer = SmallImageCustomizer()
        
        // test
        let cards = try await getContentCardUI(homeSurface, customizer: homePageCardCustomizer)
        
        // verify
        #expect(cards.count == 1)
                
        // verify content card details
        let card = try #require (cards.first?.template as? SmallImageTemplate)
        #expect(card.templateType == .smallImage)
        
        // verify card title customization
        #expect(card.title.font == homePageCardCustomizer.TITLE_FONT)
        #expect(card.title.textColor == homePageCardCustomizer.TITLE_COLOR)
        
        // verify card body customization
        #expect(card.body?.font == homePageCardCustomizer.BODY_FONT)
        #expect(card.body?.textColor == homePageCardCustomizer.BODY_COLOR)
        
        // verify root stack customization
        #expect(card.rootHStack.spacing == homePageCardCustomizer.ROOT_STACK_SPACING)
        #expect(card.rootHStack.alignment == homePageCardCustomizer.ROOT_STACK_ALIGNMENT)
        
        // verify text stack customization
        #expect(card.textVStack.spacing == homePageCardCustomizer.TEXT_STACK_SPACING)
        #expect(card.textVStack.alignment == homePageCardCustomizer.TEXT_STACK_ALIGNMENT)
        
        // verify button stack customization
        #expect(card.buttonHStack.spacing == homePageCardCustomizer.BUTTON_STACK_SPACING)
        #expect(card.buttonHStack.alignment == homePageCardCustomizer.BUTTON_STACK_ALIGNMENT)
        
        // verify view modifiers
        #expect(card.rootHStack.modifier != nil)
        #expect(card.buttonHStack.modifier != nil)
        #expect(card.textVStack.modifier == nil)
        
        // verify button customization
        let firstButton = try #require (card.buttons?.first)
        #expect(firstButton.text.textColor == homePageCardCustomizer.BUTTON_TEXT_COLOR)
        #expect(firstButton.text.font == homePageCardCustomizer.BUTTON_FONT)
        
        // verify card properties
        #expect(card.backgroundColor == homePageCardCustomizer.CARD_BACKGROUND_COLOR)
        
        // verify dismiss button
        #expect(card.dismissButton?.image.iconFont == homePageCardCustomizer.DISMISS_ICON_FONT)
        #expect(card.dismissButton?.image.iconColor == homePageCardCustomizer.DISMISS_ICON_COLOR)
        #expect(card.dismissButton?.alignment == homePageCardCustomizer.DISMISS_ICON_ALIGNMENT)
        #expect(card.dismissButton?.modifier == nil)
    }
    
    @Test("missing ui element - no title", .tags(.UITest))
    func smallImageTemplateNoTitle() async throws {
        // setup
        setContentCardResponse(fromFile: "small image no title")
        
        // test
        let cards = try await getContentCardUI(homeSurface)
        
        // verify
        #expect(cards.isEmpty == true)
    }
    
    @Test("missing ui element - no body", .tags(.UITest))
    func smallImageTemplateNoBody() async throws {
        // setup
        setContentCardResponse(fromFile: "small image no body")
        
        // test
        let cards = try await getContentCardUI(homeSurface)
        
        // verify
        #expect(cards.isEmpty == false)
    }
    
    @Test("missing ui element - no image", .tags(.UITest))
    func smallImageTemplateNoImage() async throws {
        // setup
        setContentCardResponse(fromFile: "small image no image")
        
        // test
        let cards = try await getContentCardUI(homeSurface)
        
        // verify
        #expect(cards.isEmpty == false)
    }
    
    @Test("missing ui element - no buttons", .tags(.UITest))
    func smallImageTemplateNoButtons() async throws {
        // setup
        setContentCardResponse(fromFile: "small image no buttons")
        
        // test
        let cards = try await getContentCardUI(homeSurface)
        
        // verify
        #expect(cards.isEmpty == false)
    }
    
}
