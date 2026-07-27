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

struct CardsView: View, ContentCardUIEventListening {

    let cardsSurface = Surface(path: Constants.SurfaceName.CONTENT_CARD)
    @State var savedCards: [ContentCardUI] = []
    @State private var viewLoaded: Bool = false
    @State private var showLoadingIndicator: Bool = false
    @State private var statusMessage: String = ""

    var body: some View {
        VStack(spacing: 0) {
            TabHeader(title: "Content Cards")

            actionPanel
                .padding(.horizontal, 16)
                .padding(.top, 8)

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }

            ZStack {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 20) {
                        ForEach(savedCards) { card in
                            card.view
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 12)
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
                fetchContentCards()
            }
        }
    }

    // MARK: - Action Panel

    private var actionPanel: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                actionButton(title: "Download", systemImage: "arrow.down.circle") {
                    downloadCards()
                }
                actionButton(title: "Fetch Content Cards", systemImage: "arrow.clockwise.circle") {
                    fetchContentCards()
                }
            }
            HStack(spacing: 10) {
                actionButton(title: "Fetch Offline Content Cards", systemImage: "icloud.slash") {
                    fetchOfflineContentCards()
                }
                actionButton(title: "Clear Cache", systemImage: "trash") {
                    clearPersistedPropositions()
                }
            }
        }
    }

    private func actionButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    /// Fires a network update for the content card surface (fire-and-forget, no callback).
    func downloadCards() {
        Messaging.updatePropositionsForSurfaces([cardsSurface])
        statusMessage = "Download requested for surface: \(cardsSurface.uri)"
    }

    /// Reads content cards from the SDK's in-memory cache only.
    func fetchContentCards() {
        showLoadingIndicator = true
        Messaging.getContentCardsUI(for: cardsSurface,
                                    customizer: CardCustomizer(),
                                    listener: self) { result in
            DispatchQueue.main.async {
                showLoadingIndicator = false
                handleResult(result, source: "Memory")
            }
        }
    }

    /// Explicitly reads content cards from the persisted disk cache.
    func fetchOfflineContentCards() {
        showLoadingIndicator = true
        Messaging.getContentCardsUI(for: cardsSurface,
                                    usePersistedContentCards: true,
                                    customizer: CardCustomizer(),
                                    listener: self) { result in
            DispatchQueue.main.async {
                showLoadingIndicator = false
                handleResult(result, source: "Persisted disk cache")
            }
        }
    }

    /// Clears the persisted content card and inbox disk cache.
    func clearPersistedPropositions() {
        Messaging.clearPersistedPropositions()
        statusMessage = "Persisted content card and inbox caches cleared."
    }

    private func handleResult(_ result: Result<[ContentCardUI], Error>, source: String) {
        switch result {
        case .failure(let error):
            statusMessage = "Fetch failed (\(source)): \(error.localizedDescription)"
            savedCards = []
        case .success(let cards):
            if cards.isEmpty {
                statusMessage = "No cards found (\(source))"
                savedCards = []
            } else {
                statusMessage = "Loaded \(cards.count) card(s) from \(source)"
                savedCards = cards.sorted { $0.priority > $1.priority }
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

class CardCustomizer: ContentCardCustomizing {
    func customize(template: AEPMessaging.LargeImageTemplate) {
        template.title.textColor = .primary
        template.title.font = .system(size: 16, weight: .bold)
        template.body?.textColor = .secondary
        template.body?.font = .caption

        template.buttons?.first?.text.font = .system(size: 13)
        template.buttons?.first?.text.textColor = .primary
        template.buttons?.first?.modifier = AEPViewModifier(ButtonModifier())

        // Image: full width, fixed height, flush to top/left/right edges
        template.image?.contentMode = .fill
        template.image?.modifier = AEPViewModifier(LargeImageModifier())

        // No spacing so image sits flush against card top
        template.rootVStack.spacing = 0
        template.textVStack.alignment = .leading
        template.textVStack.spacing = 4
        // Padding only on the text area
        template.textVStack.modifier = AEPViewModifier(TextAreaModifier())
        template.buttonHStack.modifier = AEPViewModifier(LargeButtonHStackModifier())
        // Card container — no inner padding so image reaches edges
        template.rootVStack.modifier = AEPViewModifier(CardContainerModifier())

        template.dismissButton?.image.iconColor = .white
        template.dismissButton?.image.iconFont = .system(size: 12, weight: .semibold)
    }

    func customize(template: SmallImageTemplate) {
        template.title.textColor = .primary
        template.title.font = .system(size: 15, weight: .bold)
        template.body?.textColor = .secondary
        template.body?.font = .caption

        template.buttons?.first?.text.font = .system(size: 13)
        template.buttons?.first?.text.textColor = .primary
        template.buttons?.first?.modifier = AEPViewModifier(ButtonModifier())

        // Image: fixed size, flush to left/top/bottom edges
        template.image?.modifier = AEPViewModifier(SmallImageModifier())

        template.rootHStack.spacing = 0
        template.textVStack.alignment = .leading
        template.textVStack.spacing = 4
        // Padding only on the text area
        template.textVStack.modifier = AEPViewModifier(TextAreaModifier())
        template.buttonHStack.modifier = AEPViewModifier(SmallButtonHStackModifier())
        // Card container — no inner padding so image reaches edges
        template.rootHStack.modifier = AEPViewModifier(CardContainerModifier())

        template.dismissButton?.image.iconColor = .primary
        template.dismissButton?.image.iconFont = .system(size: 10, weight: .semibold)
    }

    func customize(template: ImageOnlyTemplate) {
        template.dismissButton?.image.iconColor = .white
        template.dismissButton?.image.iconFont = .system(size: 10)
    }

    // MARK: - Large Image Modifiers

    struct LargeImageModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180)
                .clipped()
        }
    }

    // MARK: - Small Image Modifiers

    struct SmallImageModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .frame(width: 110)
                .frame(maxHeight: .infinity)
                .clipped()
        }
    }

    // MARK: - Shared Modifiers

    /// Padding applied to the text+body area only
    struct TextAreaModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 4)
        }
    }

    /// Card container: rounded corners + subtle shadow
    struct CardContainerModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
    }

    struct LargeButtonHStackModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
        }
    }

    struct SmallButtonHStackModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
        }
    }

    struct ButtonModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding(.vertical, 6)
                .padding(.horizontal, 14)
                .background(Color.primary.opacity(0.08))
                .cornerRadius(8)
        }
    }
}
