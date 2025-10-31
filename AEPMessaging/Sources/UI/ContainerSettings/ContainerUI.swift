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

/// ContainerSettingsUI is a hybrid class that combines PravinPK's proven UI patterns 
/// with schema-driven template architecture for displaying content cards in containers.
@available(iOS 15.0, *)
public class ContainerUI: Identifiable, ObservableObject {
    
    // MARK: - Published Properties
    
    /// The current list of content cards in the container
    @Published private(set) var contentCards: [ContentCardUI] = []
    
    /// Current state of the container
    @Published private(set) var state: ContainerState = .loading
    
    /// The container template instance
    @Published private(set) var containerTemplate: (any ContainerTemplate)?
    
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
    
    /// Customizer for container templates
    private let containerCustomizer: ContainerCustomizing?
    
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
    ///   - containerCustomizer: Optional customizer for container templates
    ///   - listener: Optional listener for container events
    public init(surface: Surface,
                containerSettings: ContainerSettingsSchemaData,
                customizer: ContentCardCustomizing? = nil,
                containerCustomizer: ContainerCustomizing? = nil,
                listener: ContainerSettingsEventListening? = nil) {
        self.surface = surface
        self.containerSettings = containerSettings
        self.customizer = customizer
        self.containerCustomizer = containerCustomizer
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
        
        Messaging.getPropositionsForSurfacesMock([surface]) { [weak self] propositionDict, error in
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
                    self.containerTemplate = ContainerTemplateBuilder.buildTemplate(
                        from: self.containerSettings,
                        contentCards: [],
                        customizer: self.containerCustomizer
                    )
                    
                    // Set event handler for container template tracking
                    self.containerTemplate?.eventHandler = self
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
                
                // If unread functionality is enabled, initialize NEW cards as unread
                if self.containerSettings.isUnreadEnabled {
                    for card in cards {
                        // Only set as unread if this card doesn't have a stored read status yet
                        if card.isRead == nil {
                            card.isRead = false
                        }
                    }
                }
                
                self.contentCards = cards
                
                // Create container template with the loaded content cards
                self.containerTemplate = ContainerTemplateBuilder.buildTemplate(
                    from: self.containerSettings,
                    contentCards: cards,
                    customizer: self.containerCustomizer
                )
                
                // Set event handler for container template tracking
                self.containerTemplate?.eventHandler = self
                
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
    
    /// Refreshes the container by re-downloading content cards
    public func refresh() {
        downloadCards()
    }
    
    /// Refreshes the container template with current card states (for UI updates)
    private func refreshContainerTemplate() {
        guard !contentCards.isEmpty else { return }
        
        // Rebuild container template with current cards to trigger UI update
        containerTemplate = ContainerTemplateBuilder.buildTemplate(
            from: containerSettings,
            contentCards: contentCards,
            customizer: containerCustomizer
        )
        
        // Set event handler for container template tracking
        containerTemplate?.eventHandler = self
    }
}



// MARK: - ContentCardUIEventListening Implementation

@available(iOS 15.0, *)
extension ContainerUI: ContentCardUIEventListening {
    public func onCreate(_ card: ContentCardUI) {
        listener?.onCardCreated(card)
    }
    
    public func onDisplay(_ card: ContentCardUI) {
        listener?.onCardDisplayed(card)
    }
    
    public func onDismiss(_ card: ContentCardUI) {
        // Remove card from the list
        contentCards.removeAll { $0.id == card.id }
        
        // Rebuild container template with updated content cards
        containerTemplate = ContainerTemplateBuilder.buildTemplate(
            from: containerSettings,
            contentCards: contentCards,
            customizer: containerCustomizer
        )
        
        // Set event handler for container template tracking
        containerTemplate?.eventHandler = self
        
        // Update state if no cards remain
        if contentCards.isEmpty {
            state = .empty
            listener?.onEmpty(self)
        }
        
        listener?.onCardDismissed(card)
    }
    
    public func onInteract(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool {
        let handled = listener?.onCardInteracted(card, interactionId, actionURL: actionURL) ?? false
        
        // Add a small delay to ensure the card's isRead status has been updated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Refresh container template after interaction to update unread indicators
            if self.containerSettings.isUnreadEnabled {
                self.refreshContainerTemplate()
            }
        }
        
        return handled
    }
}

// MARK: - ContainerTemplateEventHandler Implementation

@available(iOS 15.0, *)
extension ContainerUI: ContainerTemplateEventHandler {
    func onContainerDisplay() {
        // Container display tracking is handled in BaseContainerTemplate
        // This provides additional app-level notification
        listener?.onLoaded(self)
    }
    
    func onContainerInteract(interactionId: String) {
        // Track container-level interactions
        containerSettings.track(interactionId, withEdgeEventType: .interact)
        // Note: Could add container interaction method to listener protocol if needed
    }
}
