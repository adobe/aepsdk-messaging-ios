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
import Foundation

// MARK: - Usage Example for Hybrid Container Settings

/// Example showing how to use the hybrid ContainerSettingsUI that combines
/// PravinPK's proven UI patterns with schema-driven template architecture
@available(iOS 15.0, *)
struct ContainerSettingsUsageExample {
    
    /// Example SwiftUI view that uses ContainerSettingsUI
    struct ContentCardsContainerView: View, ContainerSettingsEventListening {
        @State private var containerUI: ContainerSettingsUI?
        @State private var isLoading = true
        @State private var error: ContainerSettingsUIError?
        
        let surface: Surface
        
        init(surface: Surface) {
            self.surface = surface
        }
        
        var body: some View {
            NavigationView {
                Group {
                    if isLoading {
                        ProgressView("Loading container...")
                    } else if let error = error {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(.red)
                            Text("Error loading container")
                                .font(.headline)
                            Text(error.localizedDescription)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Try Again") {
                                loadContainer()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    } else if let containerUI = containerUI {
                        containerUI.view
                    } else {
                        Text("No container available")
                    }
                }
                .navigationTitle("Content Cards")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Refresh") {
                            containerUI?.refresh()
                        }
                        .disabled(containerUI == nil)
                    }
                }
            }
            .onAppear {
                loadContainer()
            }
        }
        
        private func loadContainer() {
            isLoading = true
            error = nil
            
            Messaging.getContentCardContainerUI(
                for: surface,
                customizer: ExampleCardCustomizer(),
                listener: self
            ) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let container):
                        self.containerUI = container
                        self.error = nil
                    case .failure(let error):
                        self.error = error as? ContainerSettingsUIError ?? .dataUnavailable
                        self.containerUI = nil
                    }
                }
            }
        }
        
        // MARK: - ContainerSettingsEventListening
        
        func onLoading(_ container: ContainerSettingsUI) {
            print("📱 Container is loading content cards...")
            print("📱 Template type will be: \(container.templateType)")
        }
        
        func onLoaded(_ container: ContainerSettingsUI) {
            print("✅ Container loaded \(container.contentCards.count) cards")
            print("📱 Using template: \(container.templateType)")
            
            // Log container settings if available
            let settings = container.containerSettings
            print("📋 Container Settings:")
            print("   - Orientation: \(settings.layout.orientation)")
            print("   - Capacity: \(settings.capacity)")
            print("   - Unread enabled: \(settings.isUnreadEnabled)")
            print("   - Heading: \(settings.heading?.content ?? "None")")
        }
        
        func onError(_ container: ContainerSettingsUI, _ error: Error) {
            print("❌ Container error: \(error.localizedDescription)")
            
            // Handle specific error types
            if let containerError = error as? ContainerSettingsUIError {
                switch containerError {
                case .dataUnavailable:
                    print("📭 No propositions available for this surface")
                case .containerSettingsNotFound:
                    print("⚙️ No container settings found in propositions")
                case .invalidContainerSettings:
                    print("🔧 Invalid container settings schema")
                case .containerCreationFailed:
                    print("💥 Container creation failed")
                @unknown default:
                    print("❓ Unknown ContainerSettingsUIError")
                }
            }
        }
        
        func onEmpty(_ container: ContainerSettingsUI) {
            print("📭 Container is empty")
        }
        
        func onCardDismissed(_ card: ContentCardUI) {
            print("🗑️ Card dismissed: \(card.id)")
        }
        
        func onCardDisplayed(_ card: ContentCardUI) {
            print("👁️ Card displayed: \(card.id)")
        }
        
        func onCardInteracted(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool {
            print("🔄 Card interaction: \(interactionId)")
            print("🔗 Action URL: \(actionURL?.absoluteString ?? "none")")
            
            // Return false to let SDK handle the URL
            return false
        }
        
        func onCardCreated(_ card: ContentCardUI) {
            print("🆕 Card created: \(card.id)")
            
            // Example: Add custom content based on PravinPK's pattern
            if let smallImageCard = card.template as? SmallImageTemplate {
                if let sentDate = card.meta?["sentDate"] as? String {
                    smallImageCard.textVStack.addView(
                        Text(sentDate)
                            .foregroundColor(.secondary)
                            .font(.system(size: 11, weight: .light))
                    )
                }
            }
        }
    }
    
    /// Example customizer following PravinPK's pattern
    class ExampleCardCustomizer: ContentCardCustomizing {
        func customize(template: SmallImageTemplate) {
            // Customize small image cards
            template.backgroundColor = Color(.systemBackground)
            template.rootHStack.spacing = 12
            template.textVStack.alignment = .leading
            
            // Customize button if present
            // Note: AEPButton styling should be done through ContentCardCustomizing
            // template.buttons?.first?.backgroundColor = .blue
            template.buttons?.first?.text.textColor = .white
        }
        
        func customize(template: LargeImageTemplate) {
            // Customize large image cards
            template.backgroundColor = Color(.systemBackground)
            template.textVStack.alignment = .leading
        }
        
        func customize(template: ImageOnlyTemplate) {
            // Customize image-only cards
            template.backgroundColor = Color(.systemBackground)
        }
    }
    
    /// Example of programmatic usage
    class ContainerManager {
        private var containerUI: ContainerSettingsUI?
        private var isLoading = false
        
        func setupContainer(for surface: Surface, completion: @escaping (Result<ContainerSettingsUI, ContainerSettingsUIError>) -> Void) {
            guard !isLoading else {
                print("⚠️ Container setup already in progress")
                return
            }
            
            isLoading = true
            print("🚀 Starting container setup...")
            
            // Create container with automatic template selection
            Messaging.getContentCardContainerUI(
                for: surface,
                customizer: ExampleCardCustomizer(),
                listener: ContainerEventListener()
            ) { [weak self] result in
                self?.isLoading = false
                
                switch result {
                case .success(let container):
                    self?.containerUI = container
                    print("✅ Container setup complete")
                    print("📱 Template type: \(container.templateType)")
                    completion(.success(container))
                    
                case .failure(let error):
                    print("❌ Container setup failed: \(error)")
                    completion(.failure(error as? ContainerSettingsUIError ?? .dataUnavailable))
                }
            }
        }
        
        func refreshContainer() {
            containerUI?.refresh()
            print("🔄 Container refresh initiated")
        }
        
        func getContainerView() -> some View {
            if let containerUI = containerUI {
                return AnyView(containerUI.view)
            } else {
                return AnyView(Text("Container not initialized"))
            }
        }
    }
    
    /// Example event listener
    class ContainerEventListener: ContainerSettingsEventListening {
        func onLoading(_ container: ContainerSettingsUI) {
            print("📡 Loading cards for surface: \(container.surface.uri)")
        }
        
        func onLoaded(_ container: ContainerSettingsUI) {
            print("✅ Loaded \(container.contentCards.count) cards")
            
            // Example: Log template selection logic
            let settings = container.containerSettings
            let templateReason = getTemplateSelectionReason(settings)
            print("🎯 Template selection: \(container.templateType) - \(templateReason)")
        }
        
        func onError(_ container: ContainerSettingsUI, _ error: Error) {
            print("❌ Error: \(error)")
        }
        
        func onEmpty(_ container: ContainerSettingsUI) {
            print("📭 No content cards available")
        }
        
        func onCardDismissed(_ card: ContentCardUI) {
            print("🗑️ Card dismissed")
        }
        
        func onCardDisplayed(_ card: ContentCardUI) {
            print("👁️ Card displayed")
        }
        
        func onCardInteracted(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool {
            print("🔄 Card interaction: \(interactionId)")
            return false
        }
        
        func onCardCreated(_ card: ContentCardUI) {
            print("🆕 Card created")
        }
        
        private func getTemplateSelectionReason(_ settings: ContainerSettingsSchemaData) -> String {
            switch (settings.layout.orientation, settings.isUnreadEnabled) {
            case (.vertical, true):
                return "Vertical orientation + unread enabled = Inbox"
            case (.horizontal, false):
                return "Horizontal orientation + unread disabled = Carousel"
            default:
                return "Other configuration = Custom"
            }
        }
    }
}

// MARK: - Documentation Example

/*
 
 ## Hybrid Container Settings Architecture
 
 This implementation combines:
 
 ### 1. PravinPK's Proven Patterns:
 - ✅ ObservableObject for reactive UI updates
 - ✅ Immediate container creation (synchronous API)
 - ✅ Event-driven architecture with listeners
 - ✅ Card customization through onCreate callback
 - ✅ State management (loading, loaded, empty, error)
 
 ### 2. Schema-Driven Template Selection:
 - ✅ Automatic template type detection from JSON schema
 - ✅ Inbox: vertical + unread = vertical scrolling with indicators
 - ✅ Carousel: horizontal + no unread = horizontal scrolling
 - ✅ Custom: any other configuration = flexible layout
 
 ### 3. JSON Schema Compliance:
 ```json
 {
   "content": {
     "heading": { "content": "Monthly Deals" },
     "layout": { "orientation": "vertical|horizontal" },
     "capacity": 10,
     "emptyStateSettings": {
       "message": { "content": "No deals today" },
       "image": { "url": "...", "darkUrl": "..." }
     },
     "unread_indicator": {
       "unread_bg": { "clr": { "light": "0x...", "dark": "0x..." } },
       "unread_icon": { "placement": "topleft", "image": {...} }
     },
     "isUnreadEnabled": true
   }
 }
 ```
 
 ### Usage:
 ```swift
 // Async usage with completion handler - matches existing ContentCard API
 Messaging.getContentCardContainerUI(
     for: surface,
     customizer: MyCustomizer(),
     listener: MyListener()
 ) { result in
     switch result {
     case .success(let container):
         // Use container.view in SwiftUI
         print("Template: \(container.templateType)")
     case .failure(let error):
         // Handle specific errors
         if let containerError = error as? ContainerSettingsUIError {
             switch containerError {
             case .dataUnavailable:
                 print("No propositions available")
             case .containerSettingsNotFound:
                 print("No container settings in propositions")
             case .invalidContainerSettings:
                 print("Invalid container settings schema")
             case .containerCreationFailed:
                 print("Container creation failed")
             }
         }
     }
 }
 ```
 
 ### Benefits:
 1. **Backward Compatible**: Works with existing ContentCard system
 2. **Automatic**: No manual template selection needed
 3. **Flexible**: Falls back to custom template for any configuration
 4. **Event-Driven**: Rich event system for tracking and customization
 5. **Schema-Compliant**: Matches exact JSON specification
 
 */
