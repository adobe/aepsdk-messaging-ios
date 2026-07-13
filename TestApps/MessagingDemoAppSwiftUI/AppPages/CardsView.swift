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
    @State private var lastLoadSource: String = ""
    @State private var propositionLog: String = ""

    var body: some View {
        VStack {
            TabHeader(title: "Content Cards", refreshAction: {
                refreshCards()
            }, redownloadAction: {
                downloadCards()
                refreshCards()
            }, offlineFallbackAction: {
                updatePropositionsWithOfflineFallback()
            }, logPropositionsAction: {
                updateAndLogPropositions()
            })

            if !lastLoadSource.isEmpty {
                Text("Loaded from: \(lastLoadSource)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
            }

            if !propositionLog.isEmpty {
                ScrollView {
                    Text(propositionLog)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 120)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .padding(.horizontal, 16)
            }

            ZStack {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 20) {
                        ForEach(savedCards) { card in
                            card.view
                                .padding(.horizontal, 16)
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
        fetchPropositionsAndLoadUI(usePersistedContentCards: false, sourceLabel: "Memory")
    }

    /// Demo: update from network; on success get from memory, on failure get from persisted storage.
    func updatePropositionsWithOfflineFallback() {
        showLoadingIndicator = true
        Messaging.updatePropositionsForSurfacesWithCompletionHandler([cardsSurface]) { success in
            DispatchQueue.main.async {
                if success {
                    self.fetchPropositionsAndLoadUI(usePersistedContentCards: false,
                                                    sourceLabel: "Network (memory)",
                                                    notePersistSuccess: true)
                } else {
                    self.fetchPropositionsAndLoadUI(usePersistedContentCards: true,
                                                    sourceLabel: "Phone cache (offline fallback)")
                }
            }
        }
    }

    /// Demo: update from network, then log raw propositions — memory on success, persisted storage on failure.
    func updateAndLogPropositions() {
        showLoadingIndicator = true
        Messaging.updatePropositionsForSurfacesWithCompletionHandler([cardsSurface]) { success in
            DispatchQueue.main.async {
                if success {
                    self.fetchAndLogPropositions(usePersistedContentCards: false,
                                                 sourceLabel: "Memory",
                                                 notePersistSuccess: true)
                } else {
                    self.fetchAndLogPropositions(usePersistedContentCards: true,
                                                sourceLabel: "Phone cache (usePersistedContentCards: true)")
                }
            }
        }
    }

    private static let persistSuccessMessage = """
    updatePropositions: SUCCESS
    Content cards saved to persisted disk successfully (contentCardPropositions cache).
    """

    private func fetchAndLogPropositions(usePersistedContentCards: Bool, sourceLabel: String, notePersistSuccess: Bool = false) {
        Messaging.getPropositionsForSurfaces([cardsSurface], usePersistedContentCards: usePersistedContentCards) { propositionsDict, error in
            DispatchQueue.main.async {
                showLoadingIndicator = false
                if let error = error {
                    propositionLog = "getPropositions failed (\(sourceLabel))\n\(error)\n\(error.localizedDescription)"
                    print("TestAppLog Propositions: \(propositionLog)")
                    return
                }
                let prepend = notePersistSuccess && !(propositionsDict?[cardsSurface]?.isEmpty ?? true)
                    ? Self.persistSuccessMessage
                    : ""
                propositionLog = formatPropositionsLog(propositionsDict?[cardsSurface], source: sourceLabel,
                                                       usePersisted: usePersistedContentCards,
                                                       prepend: prepend)
                if !prepend.isEmpty {
                    lastLoadSource = "Persisted to disk"
                    print("TestAppLog Persist: \(Self.persistSuccessMessage)")
                }
                print("TestAppLog Propositions:\n\(propositionLog)")
            }
        }
    }

    private func formatPropositionsLog(_ propositions: [Proposition]?, source: String, usePersisted: Bool, prepend: String = "") -> String {
        var lines = [String]()
        if !prepend.isEmpty {
            lines.append(prepend.trimmingCharacters(in: .whitespacesAndNewlines))
            lines.append("")
        }
        lines.append(contentsOf: [
            "getPropositionsForSurfaces",
            "usePersistedContentCards: \(usePersisted)",
            "Source: \(source)"
        ])
        guard let propositions = propositions, !propositions.isEmpty else {
            lines.append("Result: no propositions")
            return lines.joined(separator: "\n")
        }
        lines.append("Count: \(propositions.count)")
        for (index, proposition) in propositions.enumerated() {
            let schema = proposition.items.first?.schema.toString() ?? "unknown"
            lines.append("[\(index)] id=\(proposition.uniqueId) scope=\(proposition.scope) schema=\(schema) items=\(proposition.items.count)")
        }
        return lines.joined(separator: "\n")
    }

    private func fetchPropositionsAndLoadUI(usePersistedContentCards: Bool, sourceLabel: String, notePersistSuccess: Bool = false) {
        Messaging.getContentCardsUI(for: cardsSurface,
                                    usePersistedContentCards: usePersistedContentCards,
                                    customizer: CardCustomizer(),
                                    listener: self) { result in
            DispatchQueue.main.async {
                showLoadingIndicator = false
                switch result {
                case .failure(let error):
                    print("TestAppLog getContentCardsUI (\(sourceLabel)): \(error)")
                    lastLoadSource = "Failed — \(sourceLabel)"
                    savedCards = []
                case .success(let cards):
                    if cards.isEmpty {
                        print("TestAppLog getContentCardsUI (\(sourceLabel)): no cards")
                        lastLoadSource = "Empty — \(sourceLabel)"
                        savedCards = []
                    } else {
                        if notePersistSuccess {
                            propositionLog = Self.persistSuccessMessage
                            lastLoadSource = "Persisted to disk"
                            print("TestAppLog Persist: \(Self.persistSuccessMessage)")
                        }
                        savedCards = cards.sorted { $0.priority > $1.priority }
                        lastLoadSource = sourceLabel
                        print("TestAppLog getContentCardsUI (\(sourceLabel)): \(cards.count) card(s), usePersistedContentCards=\(usePersistedContentCards)")
                    }
                }
            }
        }
    }

    func downloadCards() {
        Messaging.updatePropositionsForSurfaces([cardsSurface])
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
