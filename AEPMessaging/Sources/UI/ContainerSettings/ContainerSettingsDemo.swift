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

/// Demo class to test the hybrid container settings implementation
@available(iOS 15.0, *)
class ContainerSettingsDemo {
    
    /// Creates a demo container with sample JSON schema data
    static func createDemoContainer(completion: @escaping (Result<ContainerSettingsUI, ContainerSettingsUIError>) -> Void) {
        let surface = Surface(path: "demo://container")
        
        print("🚀 Creating demo container...")
        
        // Use the new async API
        Messaging.getContentCardContainerUI(
            for: surface,
            customizer: nil,
            listener: DemoEventListener()
        ) { result in
            switch result {
            case .success(let container):
                print("✅ Demo container created successfully")
                completion(.success(container))
                
            case .failure(let error):
                print("❌ Demo container creation failed: \(error)")
                
                // For demo purposes, create a container with sample settings if API fails
                // This handles cases like containerSettingsNotFound or dataUnavailable
                let sampleJSON = """
                {
                    "heading": {
                        "content": "Monthly Deals"
                    },
                    "layout": {
                        "orientation": "vertical"
                    },
                    "capacity": 10,
                    "emptyStateSettings": {
                        "message": {
                            "content": "No deals today, come back soon!"
                        },
                        "image": {
                            "url": "https://example.com/empty.png",
                            "darkUrl": "https://example.com/empty-dark.png"
                        }
                    },
                    "unread_indicator": {
                        "unread_bg": {
                            "clr": {
                                "light": "0x10AAFFCC",
                                "dark": "0x11BBCCDD"
                            }
                        },
                        "unread_icon": {
                            "placement": "topleft",
                            "image": {
                                "url": "https://example.com/unread.png",
                                "darkUrl": "https://example.com/unread-dark.png"
                            }
                        }
                    },
                    "isUnreadEnabled": true
                }
                """
                
                // Parse the JSON into our schema data
                let containerSettings = try? JSONDecoder().decode(
                    ContainerSettingsSchemaData.self,
                    from: sampleJSON.data(using: .utf8) ?? Data()
                )
                
                // Create fallback container with the parsed settings
                guard let containerSettings = containerSettings else {
                    completion(.failure(.containerSettingsNotFound))
                    return
                }
                
                let fallbackContainer = ContainerSettingsUI(
                    surface: surface,
                    containerSettings: containerSettings,
                    customizer: nil,
                    listener: DemoEventListener()
                )
                
                print("🔄 Created fallback demo container with sample data")
                completion(.success(fallbackContainer))
            }
        }
    }
    
    /// Demo event listener
    class DemoEventListener: ContainerSettingsEventListening {
        func onLoading(_ container: ContainerSettingsUI) {
            print("🚀 Demo: Container loading...")
        }
        
        func onLoaded(_ container: ContainerSettingsUI) {
            print("✅ Demo: Container loaded with \(container.contentCards.count) cards")
            print("📱 Demo: Template type selected: \(container.templateType)")
            
            // Verify template selection logic
            if let settings = container.containerSettings {
                let expectedTemplate = getExpectedTemplate(settings)
                let actualTemplate = container.templateType
                
                if expectedTemplate == actualTemplate {
                    print("✅ Demo: Template selection correct!")
                } else {
                    print("❌ Demo: Template selection mismatch - expected: \(expectedTemplate), got: \(actualTemplate)")
                }
            }
        }
        
        func onError(_ container: ContainerSettingsUI, _ error: Error) {
            print("❌ Demo: Error - \(error)")
        }
        
        func onEmpty(_ container: ContainerSettingsUI) {
            print("📭 Demo: Container empty")
        }
        
        func onCardDismissed(_ card: ContentCardUI) {
            print("🗑️ Demo: Card dismissed")
        }
        
        func onCardDisplayed(_ card: ContentCardUI) {
            print("👁️ Demo: Card displayed")
        }
        
        func onCardInteracted(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool {
            print("🔄 Demo: Card interaction - \(interactionId)")
            return false
        }
        
        func onCardCreated(_ card: ContentCardUI) {
            print("🆕 Demo: Card created")
        }
        
        private func getExpectedTemplate(_ settings: ContainerSettingsSchemaData) -> ContainerTemplateType {
            switch (settings.layout.orientation, settings.isUnreadEnabled) {
            case (.vertical, true):
                return .inbox
            case (.horizontal, false):
                return .carousel
            default:
                return .custom
            }
        }
    }
    
    /// Test different template configurations
    static func testTemplateSelection() {
        print("\n🧪 Testing Template Selection Logic...")
        
        // Test Inbox template (vertical + unread)
        testTemplate(
            orientation: .vertical,
            unreadEnabled: true,
            expectedTemplate: .inbox,
            description: "Inbox (vertical + unread)"
        )
        
        // Test Carousel template (horizontal + no unread)
        testTemplate(
            orientation: .horizontal,
            unreadEnabled: false,
            expectedTemplate: .carousel,
            description: "Carousel (horizontal + no unread)"
        )
        
        // Test Custom template (vertical + no unread)
        testTemplate(
            orientation: .vertical,
            unreadEnabled: false,
            expectedTemplate: .custom,
            description: "Custom (vertical + no unread)"
        )
        
        // Test Custom template (horizontal + unread)
        testTemplate(
            orientation: .horizontal,
            unreadEnabled: true,
            expectedTemplate: .custom,
            description: "Custom (horizontal + unread)"
        )
        
        print("✅ Template selection tests complete!\n")
    }
    
    private static func testTemplate(
        orientation: ContainerOrientation,
        unreadEnabled: Bool,
        expectedTemplate: ContainerTemplateType,
        description: String
    ) {
        let jsonString = """
        {
            "heading": { "content": "Test" },
            "layout": { "orientation": "\(orientation.rawValue)" },
            "capacity": 5,
            "isUnreadEnabled": \(unreadEnabled)
        }
        """
        
        guard let data = jsonString.data(using: .utf8),
              let settings = try? JSONDecoder().decode(ContainerSettingsSchemaData.self, from: data) else {
            print("❌ Failed to parse JSON for \(description)")
            return
        }
        
        let actualTemplate = settings.templateType
        
        if actualTemplate == expectedTemplate {
            print("✅ \(description): \(actualTemplate)")
        } else {
            print("❌ \(description): Expected \(expectedTemplate), got \(actualTemplate)")
        }
    }
}

// MARK: - SwiftUI Demo View

@available(iOS 15.0, *)
struct ContainerSettingsDemoView: View {
    @State private var demoContainer: ContainerSettingsUI?
    @State private var isLoading = true
    @State private var error: ContainerSettingsUIError?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Creating demo container...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        Text("Demo Error")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            loadDemoContainer()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let container = demoContainer {
                    // Template info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Template Information")
                            .font(.headline)
                        
                        HStack {
                            Text("Selected Template:")
                            Spacer()
                            Text(container.templateType.rawValue)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        
                        if let settings = container.containerSettings {
                            HStack {
                                Text("Orientation:")
                                Spacer()
                                Text(settings.layout.orientation.rawValue)
                            }
                            
                            HStack {
                                Text("Unread Enabled:")
                                Spacer()
                                Text(settings.isUnreadEnabled ? "Yes" : "No")
                            }
                            
                            HStack {
                                Text("Capacity:")
                                Spacer()
                                Text("\(settings.capacity)")
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    // Container view
                    container.view
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text("No container available")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding()
            .navigationTitle("Container Demo")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        demoContainer?.refresh()
                    }
                    .disabled(demoContainer == nil)
                }
            }
        }
        .onAppear {
            loadDemoContainer()
            // Run template selection tests
            ContainerSettingsDemo.testTemplateSelection()
        }
    }
    
    private func loadDemoContainer() {
        isLoading = true
        error = nil
        
        ContainerSettingsDemo.createDemoContainer { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let container):
                    self.demoContainer = container
                    self.error = nil
                case .failure(let error):
                    self.error = error
                    self.demoContainer = nil
                }
            }
        }
    }
}
