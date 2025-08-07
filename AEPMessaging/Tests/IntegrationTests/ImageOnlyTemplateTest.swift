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

@Suite("ImageOnlyTemplate", .serialized, .tags(.ImageOnlyTemplate))
class ImageOnlyTemplateTest : IntegrationTestBase {
    
    override init() {
        super.init()
    }

    @Test("verify UI elements", .tags(.UITest))
    func imageOnlyTemplateCard() async throws {
        // setup
        setContentCardResponse(fromFile: "ImageOnlyCard")
        
        // test
        let cards = try await getContentCardUI(homeSurface)
        
        // verify
        #expect(cards.count == 1)
                
        // verify content card details
        let card = try #require (cards.first?.template as? ImageOnlyTemplate)
        #expect(card.templateType == .imageOnly)
        
        // verify cards UI elements
        #expect(card.actionURL?.absoluteString == "https://cardaction.com")
        #expect(card.dismissButton?.image.icon == "xmark")
        #expect(card.image.url?.absoluteString == "https://imageurl.com/light")
        #expect(card.image.darkUrl?.absoluteString == "https://imageurl.com/dark")
        #expect(card.image.altText == "flight offer")
        #expect(card.view != nil)
    }
        
    @Test("verify customization", .tags(.UITest))
    func imageOnlyTemplateCustomization() async throws {
        // setup
        setContentCardResponse(fromFile: "ImageOnlyCard")
        let homePageCardCustomizer = ImageOnlyCustomizer()
        
        // test
        let cards = try await getContentCardUI(homeSurface, customizer: homePageCardCustomizer)
        
        // verify
        #expect(cards.count == 1)
                
        // verify content card details
        let card = try #require (cards.first?.template as? ImageOnlyTemplate)
        #expect(card.templateType == .imageOnly)
        
        // verify card properties
        #expect(card.backgroundColor == homePageCardCustomizer.CARD_BACKGROUND_COLOR)
        
        // verify dismiss button
        #expect(card.dismissButton?.image.iconFont == homePageCardCustomizer.DISMISS_ICON_FONT)
        #expect(card.dismissButton?.image.iconColor == homePageCardCustomizer.DISMISS_ICON_COLOR)
        #expect(card.dismissButton?.alignment == homePageCardCustomizer.DISMISS_ICON_ALIGNMENT)
    }
} 
