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

#if canImport(SwiftUI)
    import SwiftUI
#endif
import AEPServices
import Foundation
import Combine

/// InboxUI displays content cards in a layout based on schema data.
@available(iOS 15.0, *)
public class InboxUI: Identifiable, ObservableObject {
    
    // MARK: - Published Properties
    
    /// The current list of content cards in the inbox
    @Published private(set) var contentCards: [ContentCardUI] = []
    
    /// Current state of the inbox
    @Published private(set) var state: InboxState = .loading
    
    // MARK: - Public Properties
    
    /// Unique identifier for the inbox
    public let id = UUID()
    
    /// The surface for fetching content cards
    public let surface: Surface
    
    /// Inbox schema data (from JSON schema)
    /// Will be nil until fetched from propositions
    @Published public private(set) var inboxSchemaData: InboxSchemaData?
    
    /// SwiftUI view that represents the Inbox
    public var view: some View {
        InboxView(inbox: self)
    }
    
    // MARK: - Private Properties
    
    /// Customizer for content cards
    private let customizer: ContentCardCustomizing?
    
    /// Listener for inbox events
    public var listener: InboxEventListening?
    
    /// Event listener for individual content card events
    private var cardEventListener: ContentCardUIEventListening?
    
    /// Custom loading view builder
    internal var customLoadingView: (() -> AnyView)?
    
    /// Custom error view builder
    internal var customErrorView: ((Error) -> AnyView)?
    
    /// Custom empty state view builder
    internal var customEmptyView: ((EmptyStateSettings?) -> AnyView)?
    
    // MARK: - Pull-to-Refresh Properties
    
    /// Enables or disables pull-to-refresh functionality.
    /// When enabled, users can pull down on the inbox to refresh content.
    /// Default is `false`.
    public var isPullToRefreshEnabled: Bool = false
    
    // MARK: - Customization Properties
    
    /// Background view for the inbox container.
    /// Default is `Color(.systemGroupedBackground)` which adapts to light/dark mode.
    internal var background: AnyView = AnyView(Color(.systemGroupedBackground))
    
    /// Spacing between content cards in the inbox.
    /// Default is `16` points.
    public var cardSpacing: CGFloat = 16
    
    /// Padding around the content area of the inbox.
    /// Default is `EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)`.
    public var contentPadding: EdgeInsets = EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)    
    
    /// Size of the unread indicator icon.
    /// Default is `20` points (width and height).
    public var unreadIconSize: CGFloat = 16
    
    // MARK: - Initialization
    
    /// Initializes a new InboxUI that will fetch InboxSchemaData dynamically
    /// - Parameters:
    ///   - surface: The surface for which to retrieve the content cards
    ///   - customizer: Optional customizer for content cards
    ///   - listener: Optional listener for inbox events
    public init(surface: Surface,
                customizer: ContentCardCustomizing? = nil,
                listener: InboxEventListening? = nil) {
        self.surface = surface
        self.inboxSchemaData = nil // Will be fetched from propositions
        self.customizer = customizer
        self.listener = listener
        self.cardEventListener = self
        
        // Start downloading content cards and inboxSchemaData immediately
        refresh()
    }
    
    // MARK: - Public Methods
    
    /// Refreshes the inbox by fetching the latest propositions.
    ///
    /// First updates propositions from the server, then fetches the updated propositions.
    /// The state transitions to `.loading` during the fetch, then to `.loaded`, `.empty`, or `.error`
    /// based on the results. The listener is notified at each state change.
    public func refresh() {
        performRefresh(completion: {})
    }
    
    /// Asynchronously refreshes the inbox by fetching the latest propositions.
    ///
    /// This method is designed for use with SwiftUI's `.refreshable` modifier.
    /// First updates propositions from the server, then fetches the updated propositions.
    /// It suspends until the refresh operation completes (success or failure).
    @MainActor
    internal func refreshAsync() async {
        await withCheckedContinuation { continuation in
            performRefresh {
                continuation.resume()
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Performs the refresh operation by updating propositions from the server and fetching them.
    ///
    /// This is the core refresh logic used by both `refresh()` and `refreshAsync()`.
    /// - Parameter completion: Called when the refresh operation completes (success or failure)
    private func performRefresh(completion: @escaping () -> Void) {
        state = .loading
        listener?.onLoading(self)
        
        // First update propositions from the server
        Messaging.updatePropositionsForSurfaces([surface]) { [weak self] _ in
            guard let self = self else {
                completion()
                return
            }
            
            // Then get the updated propositions
            Messaging.getPropositionsForSurfaces([self.surface]) { propositionDict, error in
                DispatchQueue.main.async {
                    self.processInboxPropositions(propositionDict, error: error)
                    completion()
                }
            }
        }
    }
    
    /// Processes the received propositions for the inbox surface.
    ///
    /// - Parameters:
    ///   - propositionDict: Dictionary mapping surfaces to their propositions
    ///   - error: Optional error from the proposition fetch
    private func processInboxPropositions(_ propositionDict: [Surface: [Proposition]]?, error: Error?) {
        // Handle fetch errors
        if let error = error {
            handleError(error, message: "Error retrieving propositions for Inbox")
            return
        }
        
        // Extract propositions for given inbox surface
        guard let propositions = propositionDict?[surface], !propositions.isEmpty else {
            handleError(InboxError.dataUnavailable, message: "No propositions found for surface")
            return
        }
        
        // Separate inbox configuration from content card propositions
        let (inboxProposition, contentCardPropositions) = separatePropositions(propositions)
        
        // Extract and validate inboxSchemaData
        guard let inboxSchemaData = extractInboxSchemaData(from: inboxProposition) else {
            return // Error already handled in extractInboxSchemaData
        }
        
        // Store inboxSchemaData
        self.inboxSchemaData = inboxSchemaData
        
        // Create content card UI instances
        let cards = createContentCards(from: contentCardPropositions)
        
        // Apply inbox configuration (capacity, unread status) to contentCards
        let configuredCards = applyInboxConfiguration(to: cards, with: inboxSchemaData)
        
        // Cleanup stale read status entries using ReadStatusManager
        // This removes read statuses for campaigns no longer active on this surface
        ReadStatusManager.shared.cleanupStaleReadStatus(
            currentCards: configuredCards,
            surfaceUri: surface.uri
        )
        
        // Update content cards and state based on results
        contentCards = configuredCards
        
        if configuredCards.isEmpty {
            state = .empty
            listener?.onEmpty(self)
        } else {
            state = .loaded
            listener?.onLoaded(self)
        }
        
        Log.debug(label: UIConstants.LOG_TAG,
                 "Inbox loaded successfully with \(configuredCards.count) card(s) for surface: \(surface.uri)")
    }
    
    /// Separates inbox proposition (container-item) from content card propositions.
    ///
    /// - Parameter propositions: All propositions for the surface
    /// - Returns: Tuple containing the inbox proposition and array of content card propositions
    private func separatePropositions(_ propositions: [Proposition]) -> (inbox: Proposition?, contentCards: [Proposition]) {
        var inboxProposition: Proposition?
        var contentCardPropositions: [Proposition] = []
        
        for proposition in propositions {
            if proposition.items.first?.schema == .containerItem {
                inboxProposition = proposition
                Log.debug(label: UIConstants.LOG_TAG,
                         "Found inbox configuration (container-item) with ID: \(proposition.uniqueId)")
            } else {
                contentCardPropositions.append(proposition)
            }
        }
        
        Log.debug(label: UIConstants.LOG_TAG,
                 "Separated \(contentCardPropositions.count) content card proposition(s) from inbox configuration")
        
        return (inboxProposition, contentCardPropositions)
    }
    
    /// Extracts inbox schema data from the inbox proposition.
    ///
    /// - Parameter proposition: The inbox (container-item) proposition
    /// - Returns: InboxSchemaData if extraction is successful, nil otherwise
    private func extractInboxSchemaData(from proposition: Proposition?) -> InboxSchemaData? {
        guard let proposition = proposition else {
            handleError(InboxError.inboxSchemaDataNotFound,
                       message: "No inbox proposition (container-item) found")
            return nil
        }
        
        guard let firstItem = proposition.items.first,
              let inboxSchemaData = firstItem.inboxSchemaData else {
            handleError(InboxError.inboxSchemaDataNotFound,
                       message: "No InboxSchemaData found in container-item")
            return nil
        }
        
        return inboxSchemaData
    }
    
    /// Creates ContentCardUI instances from content card propositions.
    ///
    /// - Parameter propositions: Array of content card propositions
    /// - Returns: Array of successfully created ContentCardUI instances
    private func createContentCards(from propositions: [Proposition]) -> [ContentCardUI] {
        return propositions.compactMap { proposition in
            guard let contentCard = ContentCardUI.createInstance(
                with: proposition,
                customizer: customizer,
                listener: cardEventListener
            ) else {
                Log.warning(label: UIConstants.LOG_TAG,
                           "Failed to create ContentCardUI for proposition: \(proposition.uniqueId)")
                return nil
            }
            return contentCard
        }
    }
    
    /// Applies inbox-specific configuration to content cards.
    ///
    /// This includes:
    /// - Limiting cards based on capacity setting
    /// - Initializing unread status for new cards
    ///
    /// - Parameters:
    ///   - cards: Array of content card UI instances
    ///   - settings: Inbox configuration settings
    /// - Returns: Configured array of content cards
    private func applyInboxConfiguration(to cards: [ContentCardUI], with settings: InboxSchemaData) -> [ContentCardUI] {
        var configuredCards = cards
        
        // Apply capacity limit if specified
        if settings.content.capacity > 0 {
            configuredCards = Array(configuredCards.prefix(settings.content.capacity))
            if cards.count > configuredCards.count {
                Log.debug(label: UIConstants.LOG_TAG,
                         "Applied capacity limit: showing \(configuredCards.count) of \(cards.count) cards")
            }
        }
        
        // Initialize unread status for all new cards
        // Cards with no existing read status will default to false (unread)
        configuredCards.forEach { card in
            // Just accessing isRead will trigger the getter which defaults to false
            // This ensures the card is registered in ReadStatusManager
            _ = card.isRead
        }
        
        return configuredCards
    }
    
    /// Handles errors by updating state and notifying the listener.
    ///
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - message: Descriptive message for logging
    private func handleError(_ error: Error, message: String) {
        Log.error(label: UIConstants.LOG_TAG,
                 "\(message) for surface: \(surface.uri). Error: \(error)")
        state = .error(error)
        listener?.onError(self, error)
    }
    
    
    // MARK: - Custom State Views
    
    /// Sets a custom background for the inbox container.
    /// Can be a color, image, gradient, or any SwiftUI view.
    /// 
    /// ## Examples:
    /// ```swift
    /// // Solid color
    /// inbox.setBackground(Color.white)
    /// 
    /// // Gradient
    /// inbox.setBackground(
    ///     LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
    /// )
    /// 
    /// // Image
    /// inbox.setBackground(
    ///     Image("background").resizable().aspectRatio(contentMode: .fill)
    /// )
    /// ```
    /// - Parameter view: Any SwiftUI view to use as the background
    @available(iOS 15.0, *)
    public func setBackground<V: View>(_ view: V) {
        self.background = AnyView(view)
    }
    
    /// Sets a custom loading view to be displayed while content is being fetched
    /// - Parameter builder: A closure that returns a SwiftUI view wrapped in AnyView
    public func setLoadingView(_ builder: @escaping () -> AnyView) {
        self.customLoadingView = builder
    }
    
    /// Sets a custom error view to be displayed when content fetch fails
    /// - Parameter builder: A closure that takes an Error and returns a SwiftUI view wrapped in AnyView
    public func setErrorView(_ builder: @escaping (Error) -> AnyView) {
        self.customErrorView = builder
    }
    
    /// Sets a custom empty view to be displayed when no content cards are available
    /// - Parameter builder: A closure that takes optional EmptyStateSettings and returns a SwiftUI view wrapped in AnyView
    public func setEmptyView(_ builder: @escaping (EmptyStateSettings?) -> AnyView) {
        self.customEmptyView = builder
    }
}


// MARK: - ContentCardUIEventListening Implementation

@available(iOS 15.0, *)
extension InboxUI: ContentCardUIEventListening {
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
        let handled = listener?.onCardInteracted(card, interactionId, actionURL: actionURL) ?? false
        return handled
    }
}
