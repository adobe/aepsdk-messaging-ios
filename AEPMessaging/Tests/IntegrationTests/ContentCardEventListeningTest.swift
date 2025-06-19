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
@testable import AEPMessaging

@Suite("Content card event listening", .serialized)
class ContentCardEventListeningTest : IntegrationTestBase, ContentCardUIEventListening {

    var displayEventReceived : Bool
    var dismissEventReceived : Bool
    var interactEventReceived : Bool
    
    override init() {
        displayEventReceived = false
        dismissEventReceived = false
        interactEventReceived = false
        super.init()
    }

    @Test("display event")
    func displayEvent() async throws {
        // setup
        setContentCardResponse(fromFile: "SmallImageCard")
        let cards = try await getContentCardUI(homeSurface, listener: self)
        let card = try #require (cards.first?.template as? SmallImageTemplate)
        
        // test
        card.eventHandler?.onDisplay()
        
        // verify
        #expect(displayEventReceived == true)
    }
    
    @Test("dismiss event")
    func dismissEvent() async throws {
        // setup
        setContentCardResponse(fromFile: "SmallImageCard")
        let cards = try await getContentCardUI(homeSurface, listener: self)
        let card = try #require (cards.first?.template as? SmallImageTemplate)
        
        // test
        card.eventHandler?.onDismiss()
        
        // verify
        #expect(dismissEventReceived == true)
    }
    
    @Test("interact event")
    func interactEvent() async throws {
        // setup
        setContentCardResponse(fromFile: "SmallImageCard")
        let cards = try await getContentCardUI(homeSurface, listener: self)
        let card = try #require (cards.first?.template as? SmallImageTemplate)
        
        // test
        card.eventHandler?.onInteract(interactionId: "Button Clicked", actionURL: nil)
        
        // verify
        #expect(interactEventReceived == true)
    }
    
    @Test("large image display event")
    func largeImageDisplayEvent() async throws {
        // setup
        setContentCardResponse(fromFile: "LargeImageCard")
        let cards = try await getContentCardUI(homeSurface, listener: self)
        let card = try #require (cards.first?.template as? LargeImageTemplate)
        
        // test
        card.eventHandler?.onDisplay()
        
        // verify
        #expect(displayEventReceived == true)
    }
    
    @Test("large image dismiss event")
    func largeImageDismissEvent() async throws {
        // setup
        setContentCardResponse(fromFile: "LargeImageCard")
        let cards = try await getContentCardUI(homeSurface, listener: self)
        let card = try #require (cards.first?.template as? LargeImageTemplate)
        
        // test
        card.eventHandler?.onDismiss()
        
        // verify
        #expect(dismissEventReceived == true)
    }
    
    @Test("large image interact event")
    func largeImageInteractEvent() async throws {
        // setup
        setContentCardResponse(fromFile: "LargeImageCard")
        let cards = try await getContentCardUI(homeSurface, listener: self)
        let card = try #require (cards.first?.template as? LargeImageTemplate)
        
        // test
        card.eventHandler?.onInteract(interactionId: "Button Clicked", actionURL: nil)
        
        // verify
        #expect(interactEventReceived == true)
    }


    ///**************************************************************
    /// ContentCardUIEventListening protocol implementation
    ///**************************************************************
    
    func onDismiss(_ card: ContentCardUI) {
        dismissEventReceived = true
    }
    
    func onInteract(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool {
        interactEventReceived = true
        return false
    }
    
    func onDisplay(_ card: ContentCardUI) {
        displayEventReceived = true
    }
}
