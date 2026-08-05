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
import AEPServices
import SwiftUI

// MARK: - Edge Network Simulator

/// Wraps the real `Networking` service installed in `ServiceProvider.shared.networkService` and
/// intercepts requests to `*.adobedc.net` (Edge Network only). All other traffic passes through
/// unchanged. This mirrors the exact mechanism used by aepsdk-edge-ios functional tests.
///
/// Recoverable HTTP codes (from Edge SDK): 408, 429, 502, 503, 504, 507 — SDK retries.
/// Recoverable URLError codes: timedOut, cannotConnectToHost, networkConnectionLost,
///   notConnectedToInternet, dataNotAllowed — SDK retries.
/// Everything else is non-recoverable — SDK drops the hit and dispatches an error event.
private final class EdgeNetworkSimulator: Networking {

    enum Simulation {
        case httpStatus(Int, body: String?)
        case urlError(URLError)

        var label: String {
            switch self {
            case .httpStatus(let code, _): return "HTTP \(code)"
            case .urlError(let e): return "URLError.\(e.code)"
            }
        }

        /// Derived from Edge SDK's recoverable code set + AEPServices URLError.isRecoverable.
        var isRecoverable: Bool {
            switch self {
            case .httpStatus(let code, _):
                return [408, 429, 502, 503, 504, 507].contains(code)
            case .urlError(let e):
                return [URLError.Code.timedOut, .cannotConnectToHost, .networkConnectionLost,
                        .notConnectedToInternet, .dataNotAllowed].contains(e.code)
            }
        }

        var behaviorNote: String {
            isRecoverable
                ? "Recoverable — SDK will retry automatically."
                : "Non-recoverable — SDK drops hit, dispatches error event."
        }
    }

    // Singleton: install once, configure/clear as needed.
    private static var _instance: EdgeNetworkSimulator?
    private let realService: Networking

    private(set) var current: Simulation?
    var onIntercepted: ((Simulation) -> Void)?

    static func install() -> EdgeNetworkSimulator {
        if let existing = _instance { return existing }
        let real = ServiceProvider.shared.networkService
        let sim = EdgeNetworkSimulator(real: real)
        ServiceProvider.shared.networkService = sim
        _instance = sim
        return sim
    }

    func configure(_ sim: Simulation) { current = sim }
    func clear() { current = nil }

    private init(real: Networking) { self.realService = real }

    func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)?) {
        guard let sim = current, networkRequest.url.host?.contains("adobedc.net") == true else {
            realService.connectAsync(networkRequest: networkRequest, completionHandler: completionHandler)
            return
        }
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.onIntercepted?(sim)
            switch sim {
            case .httpStatus(let code, let body):
                guard let httpResponse = HTTPURLResponse(url: networkRequest.url, statusCode: code,
                                                         httpVersion: nil, headerFields: nil) else { return }
                completionHandler?(HttpConnection(data: body?.data(using: .utf8),
                                                  response: httpResponse, error: nil))
            case .urlError(let error):
                completionHandler?(HttpConnection(data: nil, response: nil, error: error))
            }
        }
    }
}

// MARK: - CardsView

struct CardsView: View, ContentCardUIEventListening {

    let cardsSurface = Surface(path: Constants.SurfaceName.CONTENT_CARD)
    @State var savedCards: [ContentCardUI] = []
    @State private var viewLoaded: Bool = false
    @State private var showLoadingIndicator: Bool = false
    @State private var statusMessage: String = ""
    @State private var showErrorPanel: Bool = false
    @State private var activeSimLabel: String? = nil

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
        .onAppear {
            if !viewLoaded {
                viewLoaded = true
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

            // Error simulation toggle row
            Button(action: { showErrorPanel.toggle() }) {
                HStack(spacing: 6) {
                    Image(systemName: showErrorPanel ? "bolt.circle.fill" : "bolt.circle")
                    Text("Error Simulation")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    if activeSimLabel != nil {
                        Text("ACTIVE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    }
                    Image(systemName: showErrorPanel ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .foregroundColor(activeSimLabel != nil ? .red : .primary)

            if showErrorPanel {
                errorSimulationPanel
            }
        }
    }

    // MARK: - Error Simulation Panel

    private var errorSimulationPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Active simulation banner
            if let label = activeSimLabel {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Active: \(label)")
                            .font(.system(size: 12, weight: .medium))
                        Text("All Edge Network requests are intercepted.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Restore") {
                        restoreRealNetwork()
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.blue)
                }
                .padding(10)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(8)
            }

            // Info banner
            Text("Intercepts *.adobedc.net requests only (same mechanism as Edge SDK tests). Other SDK traffic is unaffected. Tap a button then watch logs/Assurance.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal, 2)

            // HTTP error buttons
            Text("HTTP Errors")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.top, 2)

            HStack(spacing: 8) {
                simButton(
                    title: "400 Bad Request",
                    subtitle: "Non-recoverable · hit dropped",
                    color: .red
                ) {
                    // Proper 400 body matching the EdgeResponse schema so NetworkResponseHandler
                    // can decode and dispatch an errorResponseContent event with full detail.
                    let body = """
                    {"requestId":"sim-400","errors":[{"status":400,"title":"Bad Request (Demo)",\
                    "detail":"Simulated by demo app.","type":"https://ns.adobe.com/aep/errors/EXEG-0103-400"}]}
                    """
                    activateSim(.httpStatus(400, body: body), label: "HTTP 400 (non-recoverable)")
                }
                simButton(
                    title: "502 Bad Gateway",
                    subtitle: "Recoverable · SDK retries",
                    color: .orange
                ) {
                    activateSim(.httpStatus(502, body: nil), label: "HTTP 502 (recoverable, SDK retries)")
                }
            }

            // URLError buttons
            Text("URLError (transport-level)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.top, 2)

            HStack(spacing: 8) {
                simButton(
                    title: "Network Down",
                    subtitle: "notConnectedToInternet · recoverable",
                    color: .orange
                ) {
                    activateSim(
                        .urlError(URLError(.notConnectedToInternet)),
                        label: "URLError.notConnectedToInternet (recoverable)"
                    )
                }
                simButton(
                    title: "DNS Failure",
                    subtitle: "cannotFindHost · non-recoverable",
                    color: .red
                ) {
                    activateSim(
                        .urlError(URLError(.cannotFindHost)),
                        label: "URLError.cannotFindHost (non-recoverable)"
                    )
                }
            }

            // Restore button (always visible in expanded panel as a fallback)
            Button(action: restoreRealNetwork) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle")
                    Text("Restore Real Network")
                        .font(.system(size: 13, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(activeSimLabel != nil ? Color.green.opacity(0.15) : Color(.secondarySystemBackground))
                .cornerRadius(10)
                .foregroundColor(activeSimLabel != nil ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(activeSimLabel == nil)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .cornerRadius(12)
    }

    // MARK: - Helpers

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

    private func simButton(title: String, subtitle: String, color: Color,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .background(color.opacity(0.08))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Simulation Actions

    private func activateSim(_ sim: EdgeNetworkSimulator.Simulation, label: String) {
        let simulator = EdgeNetworkSimulator.install()
        simulator.configure(sim)
        activeSimLabel = label
        statusMessage = "Armed: \(label). Now tap Download — that request will be intercepted."
        simulator.onIntercepted = { intercepted in
            DispatchQueue.main.async {
                statusMessage = "⚡ Intercepted! Returned \(intercepted.label). \(intercepted.behaviorNote)"
            }
        }
    }

    private func restoreRealNetwork() {
        EdgeNetworkSimulator.install().clear()
        activeSimLabel = nil
        statusMessage = "Real network restored. Next download goes to the live Edge Network."
    }

    // MARK: - SDK Actions

    func downloadCards() {
        Messaging.updatePropositionsForSurfaces([cardsSurface])
        if activeSimLabel == nil {
            statusMessage = "Download requested for surface: \(cardsSurface.uri)"
        }
    }

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

    func clearPersistedPropositions() {
        Messaging.clearPersistedPropositions()
        statusMessage = "Persisted content card cache cleared."
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

// MARK: - Card Customizer

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
