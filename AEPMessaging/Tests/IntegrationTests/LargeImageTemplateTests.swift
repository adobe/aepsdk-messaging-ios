//
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
@testable import AEPServices
@testable import AEPCore
@testable import AEPMessaging

@Suite("LargeImageTemplate", .serialized, .tags(.LargeImageTemplate))
class LargeImageTemplateTest : IntegrationTestBase {
    
    override init() {
        super.init()
    }

    @Test("verify UI elements", .tags(.UITest))
    func largeImageTemplateCard() async throws {
        // setup
        setContentCardResponse(fromFile: "LargeImageCard")
        
        // test
        let cards = try await getContentCardUI(homeSurface)
        
        // verify
        #expect(cards.count == 1)
                
        // verify content card details
        let card = try #require (cards.first?.template as? LargeImageTemplate)
        #expect(card.templateType == .largeImage)
        
        // verify cards UI elements
        #expect(card.title.content == "Card Title")
        #expect(card.body?.content == "body")
        #expect(card.actionURL?.absoluteString == "https://luma.com/sale")
        #expect(card.dismissButton?.image.icon == "xmark")
        #expect(card.image?.url?.absoluteString == "https://imagetoDownload.com/cardimage")
        #expect(card.image?.darkUrl?.absoluteString == "https://imagetoDownload.com/darkimage")
        
        // verify buttons
        #expect(card.buttons?.count == 2)
        let firstButton = try #require (card.buttons?.first)
        #expect(firstButton.text.content == "Purchase Now")
        #expect(firstButton.interactId == "purchaseID")
        #expect(firstButton.actionUrl?.absoluteString == "https://adobe.com/offer")
        #expect(card.view != nil)
    }
        
    @Test("verify customization", .tags(.UITest))
    func largeImageTemplateCustomization() async throws {
        // setup
        setContentCardResponse(fromFile: "LargeImageCard")
        let homePageCardCustomizer = LargeImageCustomizer()
        
        // test
        let cards = try await getContentCardUI(homeSurface, customizer: homePageCardCustomizer)
        
        // verify
        #expect(cards.count == 1)
                
        // verify content card details
        let card = try #require (cards.first?.template as? LargeImageTemplate)
        #expect(card.templateType == .largeImage)
        
        // verify card title customization
        #expect(card.title.font == homePageCardCustomizer.TITLE_FONT)
        #expect(card.title.textColor == homePageCardCustomizer.TITLE_COLOR)
        
        // verify card body customization
        #expect(card.body?.font == homePageCardCustomizer.BODY_FONT)
        #expect(card.body?.textColor == homePageCardCustomizer.BODY_COLOR)
        
        // verify root stack customization
        #expect(card.rootVStack.spacing == homePageCardCustomizer.ROOT_STACK_SPACING)
        #expect(card.rootVStack.alignment == homePageCardCustomizer.ROOT_STACK_ALIGNMENT)
        
        // verify text stack customization
        #expect(card.textVStack.spacing == homePageCardCustomizer.TEXT_STACK_SPACING)
        #expect(card.textVStack.alignment == homePageCardCustomizer.TEXT_STACK_ALIGNMENT)
        
        // verify button stack customization
        #expect(card.buttonHStack.spacing == homePageCardCustomizer.BUTTON_STACK_SPACING)
        #expect(card.buttonHStack.alignment == homePageCardCustomizer.BUTTON_STACK_ALIGNMENT)
        
        // verify view modifiers
        #expect(card.rootVStack.modifier != nil)
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
    func largeImageTemplateNoTitle() async throws {
        // setup
        setContentCardResponse(fromFile: "large image no title")
        
        // test
        let cards = try await getContentCardUI(homeSurface)
        
        // verify
        #expect(cards.isEmpty == true)
    }
    
    @Test("missing ui element - no body", .tags(.UITest))
    func largeImageTemplateNoBody() async throws {
        // setup
        setContentCardResponse(fromFile: "large image no body")
        
        // test
        let cards = try await getContentCardUI(homeSurface)
        
        // verify
        #expect(cards.isEmpty == false)
    }
    
    @Test("missing ui element - no image", .tags(.UITest))
    func largeImageTemplateNoImage() async throws {
        // setup
        setContentCardResponse(fromFile: "large image no image")
        
        // test
        let cards = try await getContentCardUI(homeSurface)
        
        // verify
        #expect(cards.isEmpty == false)
    }
    
    @Test("missing ui element - no buttons", .tags(.UITest))
    func largeImageTemplateNoButtons() async throws {
        // setup
        setContentCardResponse(fromFile: "large image no buttons")
        
        // test
        let cards = try await getContentCardUI(homeSurface)
        
        // verify
        #expect(cards.isEmpty == false)
    }
}