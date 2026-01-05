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

struct CardsView: View, ContentCardUIEventListening, InboxEventListening {
    
    @State private var inboxUI: InboxUI?
    
    var body: some View {
        VStack(spacing: 0) {
            // Container view - observes state changes automatically
            if let inboxUI = inboxUI {
                inboxUI.view
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Inbox Demo")        
        .onAppear {
            let cardSurface = Surface(path: Constants.SurfaceName.CONTENT_CARD)
            Messaging.updatePropositionsForSurfaces([cardSurface])
            // Only initialize once
            guard inboxUI == nil else { return }
            
            let surface = Surface(path: "inboxcard")
            
            // Get ContainerUI immediately - it starts in loading state
            let inbox = Messaging.getInboxUI(
                for: surface,
                customizer: CardCustomizer(),
                listener: self
            )
            
            // Enable pull-to-refresh
            inbox.isPullToRefreshEnabled = true
            
            inboxUI = inbox
            
            // Configure custom views
            configureCustomViews()
        }
    }
    
    // MARK: - Configuration
    
    /// Configures custom views for the container
    private func configureCustomViews() {
        guard let containerUI = inboxUI else { return }
        
        // Set custom loading view
        containerUI.setLoadingView {
            AnyView(
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(2.0)
                        .tint(.blue)
                    Text("Fetching your messages...")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            )
        }
        
        // Set custom error view
        containerUI.setErrorView { error in
            AnyView(
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text("Oops! Something went wrong")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Error: \(error.localizedDescription)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button {
                        containerUI.refresh()
                    } label: {
                        Label("Try Again", systemImage: "arrow.clockwise")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            )
        }
        
        // Set custom empty view
        containerUI.setEmptyView { emptyStateSettings in
            AnyView(
                VStack(spacing: 20) {
                    Image(systemName: "tray.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    // Use server-provided message if available
                    if let message = emptyStateSettings?.message?.content {
                        Text(message)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("No messages yet")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Check back later for updates")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Button {
                        containerUI.refresh()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            )
        }
    }
    
    // MARK: - Event Listeners
    
    // Inbox Events
    func onLoading(_ inbox: InboxUI) {
        print("Inbox is loading...")
    }
    
    func onLoaded(_ inbox: InboxUI) {
        print("Inbox loaded successfully")
    }
    
    func onError(_ inbox: InboxUI, _ error: Error) {
        print("Inbox error: \(error.localizedDescription)")
    }
    
    func onEmpty(_ inbox: InboxUI) {
        print("Inbox is empty")
    }
    
    // Content Card Events
    func onCardDismissed(_ card: ContentCardUI) {
        print("Card dismissed: \(card.id)")
    }
    
    func onCardDisplayed(_ card: ContentCardUI) {
        print("Card displayed: \(card.id)")
    }
    
    func onCardInteracted(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool {
        print("Card interacted: \(interactionId)")
        return false // Return false to allow default URL handling
    }
    
    func onCardCreated(_ card: ContentCardUI) {
        print("Card created: \(card.id)")
    }
}

// MARK: - Content Card Customizer

class CardCustomizer: ContentCardCustomizing {
    
    func customize(template: LargeImageTemplate) {
        // Basic styling for large image cards
        template.title.textColor = .primary
        template.title.font = .headline
        template.body?.textColor = .secondary
        template.body?.font = .body
        
        // Customize buttons with blue styling
        customizeButtons(template.buttons)
        
        // Customize dismiss button
        template.dismissButton?.image.iconColor = .primary
    }
    
    func customize(template: SmallImageTemplate) {
        // Basic styling for small image cards
        template.title.textColor = .primary
        template.title.font = .headline
        template.body?.textColor = .secondary
        template.body?.font = .body
        
        // Customize buttons with blue styling
        customizeButtons(template.buttons)
        
        // Customize dismiss button
        template.dismissButton?.image.iconColor = .primary
    }
    
    func customize(template: ImageOnlyTemplate) {
        // Basic styling for image-only cards
        // Note: ImageOnlyTemplate doesn't have buttons, just image and dismiss button
        
        // Customize dismiss button
        template.dismissButton?.image.iconColor = .primary
    }
    
    // MARK: - Button Styling Helper
    
    private func customizeButtons(_ buttons: [AEPButton]?) {
        guard let buttons = buttons else { return }
        
        for button in buttons {
            // Set button text color to white
            button.text.textColor = .white
            button.text.font = .system(size: 16, weight: .medium)
            
            // Apply blue button styling using AEPViewModifier
            button.modifier = AEPViewModifier(ButtonStyleModifier())
        }
    }
}

// MARK: - Custom Button Style Modifier

struct ButtonStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .frame(minWidth: 100)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue)
            )
            .shadow(color: .blue.opacity(0.3), radius: 2, x: 0, y: 1)
    }
}
