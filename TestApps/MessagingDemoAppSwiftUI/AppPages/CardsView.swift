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
            if let inboxUI = inboxUI {
                inboxUI.view
            }
        }
        .navigationTitle("Inbox Demo")        
        .onAppear {
            // Only initialize once
            guard inboxUI == nil else { return }
            let surface = Surface(path: "inboxcard")
            
            // Get InboxUI immediately - it starts in loading state
            let inbox = Messaging.getInboxUI(
                for: surface,
                customizer: CardCustomizer(),
                listener: self
            )
            inboxUI = inbox
            
            // Configure inbox properties
            inbox.isPullToRefreshEnabled = true
            inbox.cardSpacing = 20
            inbox.contentPadding = EdgeInsets(top: 20, leading: 10, bottom: 20, trailing: 10)
            
            
            
            // Set custom heading view
           inbox.setHeadingView { heading in
               AnyView(
                   HStack {
                       Text(heading.text.content)
                           .font(.title)
                           .fontWeight(.bold)
                       Spacer()
                   }
                   .padding(.horizontal, 20)
                   .padding(.vertical, 16)
                   .background(
                       LinearGradient(
                           colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.05)],
                           startPoint: .leading,
                           endPoint: .trailing
                       )
                   )
               )
           }
            
            // Set custom loading view
            inbox.setLoadingView {
                AnyView(
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(2.0)
                            .tint(.blue)
                        Text("Loading your offers")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                )
            }
            
            // Set custom error view
            inbox.setErrorView { error in
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
                            inbox.refresh()
                        } label: {
                            Label("Try Again", systemImage: "arrow.clockwise")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                )
            }
            
            // Set custom empty view
            inbox.setEmptyView { emptyStateSettings in
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
                            Text("No Offers yet")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("Check back later for updates")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Button {
                            inbox.refresh()
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
    }
    
    // MARK: - Event Listeners
    
    // Inbox Events
    func onLoading(_ inbox: InboxUI) {
        print("Inbox is loading...")
    }
    
    func onSuccess(_ inbox: InboxUI) {
        print("Inbox loaded successfully")
    }
    
    func onError(_ inbox: InboxUI, _ error: Error) {
        print("Inbox error: \(error.localizedDescription)")
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
        // Smaller title font with better styling
        template.title.textColor = .primary
        template.title.font = .system(size: 16, weight: .semibold)
        
        // Smaller description font
        template.body?.textColor = .secondary
        template.body?.font = .system(size: 13, weight: .regular)
        
        // Set image to 100x100 with rounded corners
        template.image?.modifier = AEPViewModifier(ImageViewModifier())
        
        // Set background white with opacity
        template.backgroundColor = Color.white.opacity(0.95)
        
        // Improve spacing between elements
        template.rootHStack.spacing = 12
        template.textVStack.spacing = 6
        template.buttonHStack.spacing = 8
        
        // Add enhanced card styling with corner radius, border, and shadow
        template.rootHStack.modifier = AEPViewModifier(SmallImageCardBorderModifier())
        
        // Customize buttons with enhanced styling
        customizeButtons(template.buttons)
        
        // Customize dismiss button
        template.dismissButton?.image.iconColor = .gray
        template.dismissButton?.image.iconFont = .system(size: 14, weight: .semibold)
        template.unreadIcon?.image.iconColor = .yellow
        template.unreadIcon?.image.iconFont = .system(size: 40, weight: .semibold)
        template.unreadIcon?.alignment = .topTrailing
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
            // Set button text with better styling
            button.text.textColor = .white
            button.text.font = .system(size: 14, weight: .semibold)
            
            // Apply enhanced button styling using AEPViewModifier
            button.modifier = AEPViewModifier(EnhancedButtonStyleModifier())
        }
    }
}

// MARK: - Enhanced Button Style Modifier

struct EnhancedButtonStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 10)
            .padding(.horizontal, 24)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(20)
            .shadow(color: .blue.opacity(0.4), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Image View Modifier

struct ImageViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Small Image Card Border Modifier

struct SmallImageCardBorderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}
