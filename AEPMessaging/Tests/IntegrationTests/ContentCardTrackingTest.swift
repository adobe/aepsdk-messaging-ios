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
import Testing
import AEPTestUtils
@testable import AEPMessaging

@Suite("ContentCard Tracking", .serialized, .tags(.NetworkTest, .TrackingTest))
class ContentCardTrackingTest : IntegrationTestBase {
    
    override init() {
        super.init()
    }
    
    @Test("trigger tracked")
    func triggerEventTracked() async throws {
        // setup
        setContentCardResponse(fromFile: "SmallImageCard")
        let networkLatch = setupNetworkWaitLatch(count: 2)
        
        // test
        let cards = try await getContentCardUI(homeSurface)
        #expect(cards.count == 1)
        
        // wait for network calls to complete
        try awaitNetworkCalls(latch: networkLatch)
        
        // verify events
        #expect(mockNetwork.edgeRequests.count == 2)
        #expect(mockNetwork.getEdgeRequestsWith(eventType: "decisioning.propositionTrigger").count == 1)
    }
    
    @Test("display tracked")
     func displayEventTracked() async throws {
         // setup
         setContentCardResponse(fromFile: "SmallImageCard")
         let networkLatch = setupNetworkWaitLatch(count: 3)
         
         // download cards and simulate display
         let cards = try await getContentCardUI(homeSurface)
         let cardTemplate = try #require(cards.first?.template as? SmallImageTemplate)
         cardTemplate.eventHandler?.onDisplay()
         
         // wait for network calls to complete
         try awaitNetworkCalls(latch: networkLatch)
         
         // verify events
         #expect(mockNetwork.edgeRequests.count == 3)
         #expect(mockNetwork.getEdgeRequestsWith(eventType: "personalization.request").count == 1)
         #expect(mockNetwork.getEdgeRequestsWith(eventType: "decisioning.propositionTrigger").count == 1)
         #expect(mockNetwork.getEdgeRequestsWith(eventType: "decisioning.propositionDisplay").count == 1)
     }
    
    @Test("interaction tracked")
     func interactionEventTracked() async throws {
         // setup
         setContentCardResponse(fromFile: "SmallImageCard")
         let networkLatch = setupNetworkWaitLatch(count: 3)
         
         // download cards and simulate interaction
         let cards = try await getContentCardUI(homeSurface)
         let cardTemplate = try #require(cards.first?.template as? SmallImageTemplate)
         cardTemplate.eventHandler?.onInteract(interactionId: "ButtonClicked", actionURL: nil)
         
         // wait for network calls to complete
         try awaitNetworkCalls(latch: networkLatch)
         
         // verify events
         #expect(mockNetwork.edgeRequests.count == 3)
         #expect(mockNetwork.getEdgeRequestsWith(eventType: "personalization.request").count == 1)
         #expect(mockNetwork.getEdgeRequestsWith(eventType: "decisioning.propositionTrigger").count == 1)
         #expect(mockNetwork.getEdgeRequestsWith(eventType: "decisioning.propositionInteract").count == 1)
     }
    
    @Test("dismiss tracked")
     func dismissEventTracked() async throws {
         // setup
         setContentCardResponse(fromFile: "SmallImageCard")
         let networkLatch = setupNetworkWaitLatch(count: 3)
         
         // download cards and simulate interaction
         let cards = try await getContentCardUI(homeSurface)
         let cardTemplate = try #require(cards.first?.template as? SmallImageTemplate)
         cardTemplate.eventHandler?.onDismiss()
         
         // wait for network calls to complete
         try awaitNetworkCalls(latch: networkLatch)
         
         // verify events
         #expect(mockNetwork.edgeRequests.count == 3)
         #expect(mockNetwork.getEdgeRequestsWith(eventType: "personalization.request").count == 1)
         #expect(mockNetwork.getEdgeRequestsWith(eventType: "decisioning.propositionTrigger").count == 1)
         #expect(mockNetwork.getEdgeRequestsWith(eventType: "decisioning.propositionDismiss").count == 1)
     }
    
    @Test("large image display tracked")
     func largeImageDisplayEventTracked() async throws {
         // setup
         setContentCardResponse(fromFile: "LargeImageCard")
         let networkLatch = setupNetworkWaitLatch(count: 3)
         
         // download cards and simulate display
         let cards = try await getContentCardUI(homeSurface)
         let cardTemplate = try #require(cards.first?.template as? LargeImageTemplate)
         cardTemplate.eventHandler?.onDisplay()
         
         // wait for network calls to complete
         try awaitNetworkCalls(latch: networkLatch)
         
         // verify events
         #expect(mockNetwork.edgeRequests.count == 3)
         #expect(mockNetwork.getEdgeRequestsWith(eventType: "personalization.request").count == 1)
         #expect(mockNetwork.getEdgeRequestsWith(eventType: "decisioning.propositionTrigger").count == 1)
         #expect(mockNetwork.getEdgeRequestsWith(eventType: "decisioning.propositionDisplay").count == 1)
     }
    
    @Test("large image interaction tracked")
     func largeImageInteractionEventTracked() async throws {
         // setup
         setContentCardResponse(fromFile: "LargeImageCard")
         let networkLatch = setupNetworkWaitLatch(count: 3)
         
         // download cards and simulate interaction
         let cards = try await getContentCardUI(homeSurface)
         let cardTemplate = try #require(cards.first?.template as? LargeImageTemplate)
         cardTemplate.eventHandler?.onInteract(interactionId: "ButtonClicked", actionURL: nil)
         
         // wait for network calls to complete
         try awaitNetworkCalls(latch: networkLatch)
         
         // verify events
         #expect(mockNetwork.edgeRequests.count == 3)
         #expect(mockNetwork.getEdgeRequestsWith(eventType: "personalization.request").count == 1)
         #expect(mockNetwork.getEdgeRequestsWith(eventType: "decisioning.propositionTrigger").count == 1)
         #expect(mockNetwork.getEdgeRequestsWith(eventType: "decisioning.propositionInteract").count == 1)
     }
    
    @Test("large image dismiss tracked")
     func largeImageDismissEventTracked() async throws {
         // setup
         setContentCardResponse(fromFile: "LargeImageCard")
         let networkLatch = setupNetworkWaitLatch(count: 3)
         
         // download cards and simulate interaction
         let cards = try await getContentCardUI(homeSurface)
         let cardTemplate = try #require(cards.first?.template as? LargeImageTemplate)
         cardTemplate.eventHandler?.onDismiss()
         
         // wait for network calls to complete
         try awaitNetworkCalls(latch: networkLatch)
         
         // verify events
         #expect(mockNetwork.edgeRequests.count == 3)
         #expect(mockNetwork.getEdgeRequestsWith(eventType: "personalization.request").count == 1)
         #expect(mockNetwork.getEdgeRequestsWith(eventType: "decisioning.propositionTrigger").count == 1)
         #expect(mockNetwork.getEdgeRequestsWith(eventType: "decisioning.propositionDismiss").count == 1)
     }
    
    @Test("image only display tracked")
    func imageOnlyDisplayEventTracked() async throws {
        // setup
        setContentCardResponse(fromFile: "ImageOnlyCard")
        let networkLatch = setupNetworkWaitLatch(count: 3)
        
        // download cards and simulate display
        let cards = try await getContentCardUI(homeSurface)
        let cardTemplate = try #require(cards.first?.template as? ImageOnlyTemplate)
        cardTemplate.eventHandler?.onDisplay()
        
        // wait for network calls to complete
        try awaitNetworkCalls(latch: networkLatch)
        
        // verify events
        #expect(mockNetwork.edgeRequests.count == 3)
        #expect(mockNetwork.getEdgeRequestsWith(eventType: "personalization.request").count == 1)
        #expect(mockNetwork.getEdgeRequestsWith(eventType: "decisioning.propositionTrigger").count == 1)
        #expect(mockNetwork.getEdgeRequestsWith(eventType: "decisioning.propositionDisplay").count == 1)
    }
   
   @Test("image only interaction tracked")
    func imageOnlyInteractionEventTracked() async throws {
        // setup
        setContentCardResponse(fromFile: "ImageOnlyCard")
        let networkLatch = setupNetworkWaitLatch(count: 3)
        
        // download cards and simulate interaction
        let cards = try await getContentCardUI(homeSurface)
        let cardTemplate = try #require(cards.first?.template as? ImageOnlyTemplate)
        cardTemplate.eventHandler?.onInteract(interactionId: "ImageClicked", actionURL: nil)
        
        // wait for network calls to complete
        try awaitNetworkCalls(latch: networkLatch)
        
        // verify events
        #expect(mockNetwork.edgeRequests.count == 3)
        #expect(mockNetwork.getEdgeRequestsWith(eventType: "personalization.request").count == 1)
        #expect(mockNetwork.getEdgeRequestsWith(eventType: "decisioning.propositionTrigger").count == 1)
        #expect(mockNetwork.getEdgeRequestsWith(eventType: "decisioning.propositionInteract").count == 1)
    }
   
   @Test("image only dismiss tracked")
    func imageOnlyDismissEventTracked() async throws {
        // setup
        setContentCardResponse(fromFile: "ImageOnlyCard")
        let networkLatch = setupNetworkWaitLatch(count: 3)
        
        // download cards and simulate dismiss
        let cards = try await getContentCardUI(homeSurface)
        let cardTemplate = try #require(cards.first?.template as? ImageOnlyTemplate)
        cardTemplate.eventHandler?.onDismiss()
        
        // wait for network calls to complete
        try awaitNetworkCalls(latch: networkLatch)
        
        // verify events
        #expect(mockNetwork.edgeRequests.count == 3)
        #expect(mockNetwork.getEdgeRequestsWith(eventType: "personalization.request").count == 1)
        #expect(mockNetwork.getEdgeRequestsWith(eventType: "decisioning.propositionTrigger").count == 1)
        #expect(mockNetwork.getEdgeRequestsWith(eventType: "decisioning.propositionDismiss").count == 1)
    }

    @Test("multiple getContentCardUI API call")
    func multipleGetContentUI() async throws {
        // setup
        setContentCardResponse(fromFile: "SmallImageCard")
        let networkLatch = setupNetworkWaitLatch(count: 3)
        
        // test
        let cardsOne = try await getContentCardUI(homeSurface)
        let cardsTwo = try await getContentCardUI(homeSurface)
        #expect(cardsOne.count == 1)
        #expect(cardsTwo.count == 1)
        
        // wait for network calls to complete
        try awaitNetworkCalls(latch: networkLatch)
        
        // verify events
        #expect(mockNetwork.edgeRequests.count == 3)
        #expect(mockNetwork.getEdgeRequestsWith(eventType: "personalization.request").count == 2)
        #expect(mockNetwork.getEdgeRequestsWith(eventType: "decisioning.propositionTrigger").count == 1)
    }
    
    private func setupNetworkWaitLatch(count: Int) -> CountDownLatch {
        let latch = CountDownLatch(Int32(count))
        mockNetwork.onEdgeNetworkRequest { request in
            latch.countDown()
        }
        return latch
    }

    private func awaitNetworkCalls(latch: CountDownLatch) throws {
        #expect(DispatchTimeoutResult.success == latch.await(timeout: TIMEOUT))
    }    
}
