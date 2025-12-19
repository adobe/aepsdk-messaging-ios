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

struct CardsView: View, ContentCardUIEventListening, ContainerEventListening {
    
    @State private var containerUI: ContainerUI?
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Container view
            ZStack {
                if let container = containerUI {
                    container.view
                } else if isLoading {
                    ProgressView("Loading container...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text("No container loaded")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .navigationTitle("Container Demo")
        .onAppear {
            loadContainer()
        }
    }
    
    // MARK: - Core API Usage
    
    /// This is the main API call that developers will use in production
    private func loadContainer() {
        isLoading = true
        containerUI = nil
        
        // Create surface for the container
        let surface = Surface(path: "demo://container")
        
        // Call the Container API (using mock for demo purposes)
        Messaging.getContentCardContainerUIMock(
            for: surface,
            customizer: CardCustomizer(),
            listener: self
        ) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let container):
                    // Set custom loading view
                    container.setLoadingView {
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
                    container.setErrorView { error in
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
                                    container.refresh()
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
                    container.setEmptyView { emptyStateSettings in
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
                                    container.refresh()
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
                    
                    self.containerUI = container
                    
                case .failure(let error):
                    print("Container loading failed: \(error)")
                    self.containerUI = nil
                }
            }
        }
    }
    
    // MARK: - Event Listeners
    
    // Container Events
    func onLoading(_ container: ContainerUI) {
        print("Container is loading...")
    }
    
    func onLoaded(_ container: ContainerUI) {
        print("Container loaded successfully")
    }
    
    func onError(_ container: ContainerUI, _ error: Error) {
        print("Container error: \(error.localizedDescription)")
    }
    
    func onEmpty(_ container: ContainerUI) {
        print("Container is empty")
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
