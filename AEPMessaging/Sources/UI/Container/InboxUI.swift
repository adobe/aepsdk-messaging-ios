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
                             "Error retrieving content cards for Inbox surface: \(self.surface.uri). Error: \(error)")
                    self.state = .error(error)
                    self.listener?.onError(self, error)
                    return
                }
                
                // Extract propositions for the surface
                guard let propositions = propositionDict?[self.surface] else {
                    let error = InboxError.dataUnavailable
                    self.state = .error(error)
                    self.listener?.onError(self, error)
                    return
                }
                
                // Look for inboxSchemaData in propositions - REQUIRED
                guard let fetchedSettings = propositions
                    .flatMap({ $0.items })
                    .compactMap({ $0.inboxSchemaData })
                    .first else {
                    // No inboxSchemaData found - this is an error state
                    let error = InboxError.inboxSchemaDataNotFound
                    Log.error(label: UIConstants.LOG_TAG,
                             "No InboxSchemaData found in propositions for surface: \(self.surface.uri)")
                    self.state = .error(error)
                    self.listener?.onError(self, error)
                    return
                }
                
                // Update inboxSchemaData from server response
                self.inboxSchemaData = fetchedSettings
                
                // Extract content cards from propositions
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
                
                // Apply capacity limit if specified in inboxSchemaData
                if fetchedSettings.capacity > 0 {
                    cards = Array(cards.prefix(fetchedSettings.capacity))
                }
                
                // If unread functionality is enabled, initialize NEW cards as unread
                if fetchedSettings.isUnreadEnabled {
                    for card in cards {
                        // Only set as unread if this card doesn't have a stored read status yet
                        if card.isRead == nil {
                            card.isRead = false
                        }
                    }
                }
                
                self.contentCards = cards
                
                if cards.isEmpty {
                    self.state = .empty
                    self.listener?.onEmpty(self)
                } else {
                    self.state = .loaded
                    self.listener?.onLoaded(self)
                }
            }
        }
    }
    
    /// Refreshes the Inbox by re-downloading content cards
    public func refresh() {
        downloadCards()
    }
    
    // MARK: - Custom State Views
    
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
