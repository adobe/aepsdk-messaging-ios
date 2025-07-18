/*
Copyright 2023 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/

import AEPMessaging
import SwiftUI
import AEPCore

struct CardsView: View, ContentCardUIEventListening {
    
    let cardsSurface = Surface(path: Constants.SurfaceName.CONTENT_CARD)
    // Surface that points to idsTest content cards
    let idsTestSurface = Surface(path: Constants.SurfaceName.IDS_TEST)
    @State var savedCards : [ContentCardUI] = []
    @State var idsCards: [ContentCardUI] = []
    @State private var viewLoaded: Bool = false
    @State private var showLoadingIndicator: Bool = false
    
    var body: some View {
        VStack {
            TabHeader(title: "Content Cards", refreshAction: {
                refreshCards()
            }, redownloadAction: {
                downloadCards()
                refreshCards()
            })

            // Buttons for idsTest cards
            HStack {
                Button("QUALIFY") {
                    MobileCore.track(action: "qualify", data: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        refreshCards()
                    }
                }
                .buttonStyle(.bordered)

                Button("UNQUALIFY/DISMISS") {
                    // Placeholder for future custom action
                    MobileCore.track(action: "unqualify", data: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        refreshCards()
                    }
                }
                .buttonStyle(.bordered)

                Button("DISQUALIFY") {
                    let eventData: [String: Any] = [
                        "xdm": [
                            "eventType": "decisioning.propositionDismiss",
                            "_experience": [
                                "decisioning": [
                                    "propositions": [
                                        [
                                            "scopeDetails": [
                                                "activity": [
                                                    "id": "cbd2e600-72c5-44c3-819f-431e5ecef03c#38cd6cf9-d9c7-456e-ada6-733b01fd31db"
                                                ]
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]

                    let dismissEvent = Event(
                        name: "Demo – manual propositionDismiss",
                        type: EventType.edge,
                        source: EventSource.requestContent,
                        data: eventData
                    )

                    MobileCore.dispatch(event: dismissEvent)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        refreshCards()
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            
            ZStack {
                ScrollView (.vertical, showsIndicators: false){
                    LazyVStack(spacing: 20) {
                        ForEach(savedCards) { card in
                            card.view
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color(.systemGray3), lineWidth: 1)
                                )
                                .padding()
                        }
                        // Show idsTest cards as well
                        ForEach(idsCards) { card in
                            card.view
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.blue, lineWidth: 1)
                                )
                                .padding()
                        }
                    }
                }
                
                if showLoadingIndicator {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
        }
        .onAppear() {
            if !viewLoaded {
                viewLoaded = true
                refreshCards()
            }
        }
        
    }
    
    func refreshCards() {
        showLoadingIndicator = true
        let cardsPageSurface = Surface(path: Constants.SurfaceName.CONTENT_CARD)
        Messaging.getContentCardsUI(for: cardsPageSurface,
                                     customizer: CardCustomizer(),
                                     listener: self) { result in
            showLoadingIndicator = false
            switch result {
            case .success(let cards):
                // sort the cards by priority order and save them to our state property
                savedCards = cards.sorted { $0.priority > $1.priority }
            case .failure(let error):
                print(error)
            }
        }
        loadIdsCards()
    }
    
    func downloadCards() {
        showLoadingIndicator = true
        Messaging.updatePropositionsForSurfaces([cardsSurface, idsTestSurface])
    }

    // MARK: - IDS Test helpers
    func loadIdsCards() {
        showLoadingIndicator = true
        Messaging.getContentCardsUI(for: idsTestSurface,
                                     customizer: CardCustomizer(),
                                     listener: self) { result in
            showLoadingIndicator = false
            switch result {
            case .success(let cards):
                idsCards = cards.sorted { $0.priority > $1.priority }
            case .failure(let error):
                if case ContentCardUIError.dataUnavailable = error {
                    idsCards = []
                }
                print(error)
            }
        }
    }
    
    func onDisplay(_ card: ContentCardUI) {
        print("TestAppLog : ContentCard Displayed")
    }
    
    func onDismiss(_ card: ContentCardUI) {
        print("TestAppLog : ContentCard Dismissed")
        savedCards.removeAll(where: { $0.id == card.id })
    }
    
    func onInteract(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool {
        print("TestAppLog : ContentCard Interacted : Interaction - \(interactionId)")
        return false
    }
}

class CardCustomizer : ContentCardCustomizing {
    
    func customize(template: SmallImageTemplate) {
        // customize UI elements
        template.title.textColor = .primary
        template.title.font = .subheadline
        template.body?.textColor = .secondary
        template.body?.font = .caption
        
        template.image?.modifier = AEPViewModifier(ImageModifier())
        
        template.buttons?.first?.text.font = .system(size: 13)
        template.buttons?.first?.text.textColor = .primary
        template.buttons?.first?.modifier = AEPViewModifier(ButtonModifier())
        
        
        // customize stack structure
        template.rootHStack.spacing = 10
        template.textVStack.alignment = .leading
        template.textVStack.spacing = 10
        
        // add custom modifiers
        template.buttonHStack.modifier = AEPViewModifier(ButtonHStackModifier())
        template.rootHStack.modifier = AEPViewModifier(RootHStackModifier())
        
        // customize the dismiss buttons
        template.dismissButton?.image.iconColor = .primary
        template.dismissButton?.image.iconFont = .system(size: 10)
    }
    
    struct RootHStackModifier : ViewModifier {
        func body(content: Content) -> some View {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }
    
    struct ButtonHStackModifier : ViewModifier {
        func body(content: Content) -> some View {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    struct ImageModifier : ViewModifier {
        func body(content: Content) -> some View {
            content
                .frame(width: 100, height: 100)
        }
    }
    
    struct ButtonModifier : ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding()
                .background(Color.primary.opacity(0.1))
                .cornerRadius(10)
        }
    }
}
