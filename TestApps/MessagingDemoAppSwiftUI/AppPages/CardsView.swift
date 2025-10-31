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

struct CardsView: View, ContentCardUIEventListening, ContainerSettingsEventListening {
    
    @State private var selectedTemplate: ContainerTemplateType = .inbox
    @State private var containerUI: ContainerUI?
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Template selector
            templateSelector
            
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
            loadContainer(for: selectedTemplate)
        }
    }
    
    private var templateSelector: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Container Template:")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 0) {
                ForEach([ContainerTemplateType.inbox, .carousel, .custom], id: \.self) { template in
                    Button(action: {
                        selectedTemplate = template
                        loadContainer(for: template)
                    }) {
                        VStack(spacing: 4) {
                            Text(templateIcon(for: template))
                                .font(.title2)
                            Text(template.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedTemplate == template ? Color.blue.opacity(0.15) : Color.clear)
                        .foregroundColor(selectedTemplate == template ? .blue : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal)
    }
    
    private func templateIcon(for template: ContainerTemplateType) -> String {
        switch template {
        case .inbox: return "📥"
        case .carousel: return "🎠"
        case .custom: return "⚙️"
        case .unknown: return "❓"
        @unknown default: return "❓"
        }
    }
    
    // MARK: - Core API Usage
    
    /// This is the main API call that developers will use in production
    private func loadContainer(for template: ContainerTemplateType) {
        isLoading = true
        containerUI = nil
        
        // Create surface for the container
        let surfacePath = getSurfacePathForTemplate(template)
        let surface = Surface(path: surfacePath)
        
        // Call the Container API (using mock for demo purposes)
        Messaging.getContentCardContainerUIMock(
            for: surface,
            customizer: CardCustomizer(),
            containerCustomizer: ContainerCustomizer(), // Now using the customizer
            listener: self
        ) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let container):
                    self.containerUI = container
                    
                case .failure(let error):
                    print("Container loading failed: \(error)")
                    self.containerUI = nil
                }
            }
        }
    }
    
    private func getSurfacePathForTemplate(_ template: ContainerTemplateType) -> String {
        switch template {
        case .inbox:
            return "demo://inbox-container"
        case .carousel:
            return "demo://carousel-container"
        case .custom:
            return "demo://custom-container"
        case .unknown:
            return "demo://unknown-container"
        @unknown default:
            return "demo://unknown-container"
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

// MARK: - Container Template Customizer

class ContainerCustomizer: ContainerCustomizing {
    
    // Customize the base container template (applies to all container types)
    func customize(template: InboxContainerTemplate) {
        template.backgroundColor = Color(.red)
        // Set custom background color for containers
        // Note: Since backgroundColor might not be accessible from external modules yet,
        // we'll keep this simple for now and rely on the default implementation
        print("Customizing container template: \(type(of: template))")
    }
    
    // For now, let's keep the specific template customizations simple
    // until the backgroundColor property is fully accessible from the test app
}
