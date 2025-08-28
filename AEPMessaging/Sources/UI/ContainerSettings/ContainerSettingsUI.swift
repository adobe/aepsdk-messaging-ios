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

#if canImport(SwiftUI)
    import SwiftUI
#endif
import AEPServices
import Foundation

/// ContainerSettingsUI is a hybrid class that combines PravinPK's proven UI patterns 
/// with schema-driven template architecture for displaying content cards in containers.
@available(iOS 15.0, *)
public class ContainerSettingsUI: Identifiable, ObservableObject {
    
    // MARK: - Published Properties
    
    /// The current list of content cards in the container
    @Published private(set) var contentCards: [ContentCardUI] = []
    
    /// Current state of the container
    @Published private(set) var state: ContainerState = .loading
    
    // MARK: - Public Properties
    
    /// Unique identifier for the container
    public let id = UUID()
    
    /// The surface for fetching content cards
    public let surface: Surface
    
    /// Container settings schema data (from JSON schema)
    public let containerSettings: ContainerSettingsSchemaData
    
    /// Template type determined by container settings
    public var templateType: ContainerTemplateType {
        containerSettings.templateType
    }
    
    /// SwiftUI view that represents the container
    public var view: some View {
        ContainerView(container: self)
    }
    
    // MARK: - Private Properties
    
    /// Customizer for content cards
    private let customizer: ContentCardCustomizing?
    
    /// Listener for container events
    private var listener: ContainerSettingsEventListening?
    
    /// Event listener for individual content card events
    private var cardEventListener: ContentCardUIEventListening?
    
    // MARK: - Initialization
    
    /// Initializes a new container settings UI
    /// - Parameters:
    ///   - surface: The surface for which to retrieve the content cards
    ///   - containerSettings: Required container settings from JSON schema
    ///   - customizer: Optional customizer for content cards
    ///   - listener: Optional listener for container events
    public init(surface: Surface,
                containerSettings: ContainerSettingsSchemaData,
                customizer: ContentCardCustomizing? = nil,
                listener: ContainerSettingsEventListening? = nil) {
        self.surface = surface
        self.containerSettings = containerSettings
        self.customizer = customizer
        self.listener = listener
        self.cardEventListener = self
        
        // Start downloading content cards immediately
        downloadCards()
    }
    
    // MARK: - Public Methods
    
    /// Downloads the content cards for the surface
    public func downloadCards() {
        state = .loading
        listener?.onLoading(self)
        
        Messaging.getPropositionsForSurfaces([surface]) { [weak self] propositionDict, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    Log.error(label: UIConstants.LOG_TAG,
                             "Error retrieving content cards for container surface: \(self.surface.uri). Error: \(error)")
                    self.state = .error(error)
                    self.listener?.onError(self, error)
                    return
                }
                
                // Extract content cards from propositions
                guard let propositions = propositionDict?[self.surface] else {
                    self.state = .empty
                    self.contentCards = []
                    self.listener?.onEmpty(self)
                    return
                }
                
                var cards: [ContentCardUI] = []
                for proposition in propositions {
                    guard let contentCard = ContentCardUI.createInstance(
                        with: proposition,
                        customizer: self.customizer,
                        listener: self.cardEventListener
                    ) else {
                        Log.warning(label: UIConstants.LOG_TAG,
                                   "Failed to create ContentCardUI for proposition with ID: \(proposition.uniqueId)")
                        continue
                    }
                    cards.append(contentCard)
                }
                
                // Apply capacity limit if specified in container settings
                if self.containerSettings.capacity > 0 {
                    cards = Array(cards.prefix(self.containerSettings.capacity))
                }
                
                self.contentCards = cards
                self.state = .loaded
                self.listener?.onLoaded(self)
            }
        }
    }
    
    /// Refreshes the container by re-downloading content cards
    public func refresh() {
        downloadCards()
    }
}

// MARK: - Container State

/// Represents the different states of the container
public enum ContainerState {
    case loading
    case loaded
    case empty
    case error(Error)
}

// MARK: - ContentCardUIEventListening Implementation

@available(iOS 15.0, *)
extension ContainerSettingsUI: ContentCardUIEventListening {
    public func onCreate(_ card: ContentCardUI) {
        listener?.onCardCreated(card)
    }
    
    public func onDisplay(_ card: ContentCardUI) {
        listener?.onCardDisplayed(card)
    }
    
    public func onDismiss(_ card: ContentCardUI) {
        // Remove card from the list
        contentCards.removeAll { $0.id == card.id }
        
        // Update state if no cards remain
        if contentCards.isEmpty {
            state = .empty
            listener?.onEmpty(self)
        }
        
        listener?.onCardDismissed(card)
    }
    
    public func onInteract(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool {
        return listener?.onCardInteracted(card, interactionId, actionURL: actionURL) ?? false
    }
}

// MARK: - Container Event Listening Protocol

/// Protocol for listening to container-level events
@available(iOS 15.0, *)
public protocol ContainerSettingsEventListening {
    func onLoading(_ container: ContainerSettingsUI)
    func onLoaded(_ container: ContainerSettingsUI)
    func onError(_ container: ContainerSettingsUI, _ error: Error)
    func onEmpty(_ container: ContainerSettingsUI)
    func onCardDismissed(_ card: ContentCardUI)
    func onCardDisplayed(_ card: ContentCardUI)
    func onCardInteracted(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool
    func onCardCreated(_ card: ContentCardUI)
}

// MARK: - Default Implementation

@available(iOS 15.0, *)
public extension ContainerSettingsEventListening {
    func onLoading(_ container: ContainerSettingsUI) {}
    func onLoaded(_ container: ContainerSettingsUI) {}
    func onError(_ container: ContainerSettingsUI, _ error: Error) {}
    func onEmpty(_ container: ContainerSettingsUI) {}
    func onCardDismissed(_ card: ContentCardUI) {}
    func onCardDisplayed(_ card: ContentCardUI) {}
    func onCardInteracted(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool { false }
    func onCardCreated(_ card: ContentCardUI) {}
}

// MARK: - SwiftUI Container View

/// SwiftUI view that renders the container based on template type
@available(iOS 15.0, *)
struct ContainerView: View {
    @ObservedObject var container: ContainerSettingsUI
    
    var body: some View {
        Group {
            switch container.state {
            case .loading:
                loadingView
            case .loaded:
                contentView
            case .empty:
                emptyStateView
            case .error(let error):
                errorView(error)
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading content cards...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var contentView: some View {
        Group {
            switch container.templateType {
            case .inbox:
                InboxContainerView(container: container)
            case .carousel:
                CarouselContainerView(container: container)
            case .custom:
                CustomContainerView(container: container)
            case .unknown:
                CustomContainerView(container: container)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            // Use empty state settings from container if available
            if let emptyStateSettings = container.containerSettings.emptyStateSettings {
                if let imageUrl = emptyStateSettings.image?.url {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: 120, maxHeight: 120)
                } else {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                }
                
                if let message = emptyStateSettings.message?.content {
                    Text(message)
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                // Default empty state
                Image(systemName: "tray")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                
                Text("No content cards available")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Button("Refresh") {
                container.refresh()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Error loading content cards")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                container.refresh()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Template-Specific Views (Placeholders for now)

@available(iOS 15.0, *)
struct InboxContainerView: View {
    @ObservedObject var container: ContainerSettingsUI
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header if available
            if let heading = container.containerSettings.heading?.content {
                headerView(heading)
            }
            
            // Vertical scrolling list with unread indicators
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 12) {
                    ForEach(container.contentCards, id: \.id) { card in
                        cardRowWithUnread(card)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
    
    private func headerView(_ heading: String) -> some View {
        HStack {
            Text(heading)
                .font(.title2)
                .fontWeight(.semibold)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private func cardRowWithUnread(_ card: ContentCardUI) -> some View {
        HStack(alignment: .top, spacing: 12) {
            card.view
            
            // Show unread indicator if enabled and card is unread
            if container.containerSettings.isUnreadEnabled == true,
               let unreadValue = card.meta?["unread"] as? Bool,
               unreadValue {
                unreadIndicatorView
            }
        }
        .padding(.vertical, 4)
    }
    
    private var unreadIndicatorView: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 8, height: 8)
    }
}

@available(iOS 15.0, *)
struct CarouselContainerView: View {
    @ObservedObject var container: ContainerSettingsUI
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header if available
            if let heading = container.containerSettings.heading?.content {
                headerView(heading)
            }
            
            // Horizontal scrolling carousel
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(container.contentCards, id: \.id) { card in
                        card.view
                            .frame(width: 280) // Fixed width for carousel
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
    
    private func headerView(_ heading: String) -> some View {
        HStack {
            Text(heading)
                .font(.title2)
                .fontWeight(.semibold)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

@available(iOS 15.0, *)
struct CustomContainerView: View {
    @ObservedObject var container: ContainerSettingsUI
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header if available
            if let heading = container.containerSettings.heading?.content {
                headerView(heading)
            }
            
            // Custom layout based on orientation
            if container.containerSettings.layout.orientation == .horizontal {
                horizontalLayout
            } else {
                verticalLayout
            }
        }
    }
    
    private func headerView(_ heading: String) -> some View {
        HStack {
            Text(heading)
                .font(.title2)
                .fontWeight(.semibold)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private var verticalLayout: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 12) {
                ForEach(container.contentCards, id: \.id) { card in
                    customCardView(card)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    private var horizontalLayout: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(container.contentCards, id: \.id) { card in
                    customCardView(card)
                        .frame(width: 280)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    private func customCardView(_ card: ContentCardUI) -> some View {
        HStack(alignment: .top, spacing: 8) {
            card.view
            
            // Show unread indicator if enabled and card is unread
            if container.containerSettings.isUnreadEnabled == true,
               let unreadValue = card.meta?["unread"] as? Bool,
               unreadValue {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
            }
        }
    }
}
