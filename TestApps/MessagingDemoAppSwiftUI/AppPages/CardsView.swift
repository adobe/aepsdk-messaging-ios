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

    // Surface — editable for testing different surfaces without a rebuild
    @State private var surfacePath: String = Constants.SurfaceName.CONTENT_CARD

    // XDM input
    @State private var xdmInput: String = ""
    @State private var xdmParseError: String = ""

    // Fetch state
    @State private var isLoading: Bool = false
    @State private var fetchStatus: String = ""
    @State private var savedCards: [ContentCardUI] = []
    @State private var didFetch: Bool = false
    @State private var viewLoaded: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // ── Page title ─────────────────────────────────────────────
                Text("Content Cards")
                    .font(.largeTitle).bold()
                    .foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // ── Surface ────────────────────────────────────────────────
                sectionHeader("Surface")
                TextField("Surface path (e.g. largeImageCards)", text: $surfacePath)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                Divider()

                // ── XDM Input ──────────────────────────────────────────────
                sectionHeader("XDM Data (JSON)")

                TextEditor(text: $xdmInput)
                    .frame(minHeight: 76, maxHeight: 130)
                    .font(.system(.footnote, design: .monospaced))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                    )

                if !xdmParseError.isEmpty {
                    Text(xdmParseError)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Divider()

                // ── Fetch Buttons ──────────────────────────────────────────
                HStack(spacing: 12) {
                    Button {
                        fetchCards(useXdm: true)
                    } label: {
                        Label("Fetch with XDM", systemImage: "arrow.down.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)

                    Button {
                        fetchCards(useXdm: false)
                    } label: {
                        Label("Fetch with nil", systemImage: "arrow.down.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isLoading)
                }

                // ── Status ─────────────────────────────────────────────────
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Fetching content cards…").font(.caption).foregroundColor(.secondary)
                    }
                } else if !fetchStatus.isEmpty {
                    Text(fetchStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }

                Divider()

                // ── Content Cards ──────────────────────────────────────────
                sectionHeader("Content Cards")

                if savedCards.isEmpty && didFetch && !isLoading {
                    Text("No content cards returned for this surface / XDM combination.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(savedCards) { card in
                            card.view
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            if !viewLoaded {
                viewLoaded = true
                // Auto-load from cache (no re-download) on first appear
                refreshFromCache()
            }
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.headline)
    }

    // MARK: - Fetch Logic

    /// Downloads propositions with the given XDM, then reloads cards from cache.
    private func fetchCards(useXdm: Bool) {
        xdmParseError = ""
        savedCards = []
        didFetch = false
        isLoading = true

        // Parse XDM JSON if requested
        var xdm: [String: Any]? = nil
        if useXdm {
            let trimmed = xdmInput.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty,
                  let data = trimmed.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                xdmParseError = "⚠️ Invalid or empty JSON — check XDM input"
                isLoading = false
                return
            }
            xdm = parsed
        }

        fetchStatus = useXdm
            ? "Last: WITH XDM → \(xdmInput.trimmingCharacters(in: .whitespacesAndNewlines))"
            : "Last: NO XDM (nil)"

        let surface = Surface(path: surfacePath)

        // Download propositions with optional XDM, then pull cards from cache
        Messaging.updatePropositionsForSurfaces([surface], withXdm: xdm, andData: nil) { _ in
            self.refreshFromCache()
        }
    }

    /// Reads content cards from the local propositions cache (no network call).
    private func refreshFromCache() {
        isLoading = true
        let surface = Surface(path: surfacePath)
        Messaging.getContentCardsUI(for: surface,
                                    customizer: CardCustomizer(),
                                    listener: self) { result in
            DispatchQueue.main.async {
                isLoading = false
                didFetch = true
                switch result {
                case .success(let cards):
                    savedCards = cards.sorted { $0.priority > $1.priority }
                case .failure(let error):
                    print("CardsView: getContentCardsUI error — \(error)")
                    savedCards = []
                }
            }
        }
    }

    // MARK: - ContentCardUIEventListening

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

// MARK: - CardCustomizer

class CardCustomizer: ContentCardCustomizing {
    func customize(template: AEPMessaging.LargeImageTemplate) {
        template.title.textColor = .primary
        template.title.font = .system(size: 16, weight: .bold)
        template.body?.textColor = .secondary
        template.body?.font = .caption

        template.buttons?.first?.text.font = .system(size: 13)
        template.buttons?.first?.text.textColor = .primary
        template.buttons?.first?.modifier = AEPViewModifier(ButtonModifier())

        template.image?.contentMode = .fill
        template.image?.modifier = AEPViewModifier(LargeImageModifier())

        template.rootVStack.spacing = 0
        template.textVStack.alignment = .leading
        template.textVStack.spacing = 4
        template.textVStack.modifier = AEPViewModifier(TextAreaModifier())
        template.buttonHStack.modifier = AEPViewModifier(LargeButtonHStackModifier())
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

        template.image?.modifier = AEPViewModifier(SmallImageModifier())

        template.rootHStack.spacing = 0
        template.textVStack.alignment = .leading
        template.textVStack.spacing = 4
        template.textVStack.modifier = AEPViewModifier(TextAreaModifier())
        template.buttonHStack.modifier = AEPViewModifier(SmallButtonHStackModifier())
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

    struct TextAreaModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 4)
        }
    }

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

#Preview {
    NavigationView {
        CardsView()
    }
}
