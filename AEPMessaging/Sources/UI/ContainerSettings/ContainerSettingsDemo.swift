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
    
    /// Creates a demo container using mock data to simulate real server flow
    static func createDemoContainer(completion: @escaping (Result<ContainerSettingsUI, ContainerSettingsUIError>) -> Void) {
        createDemoContainerWithMocks(templateType: .inbox, completion: completion)
    }
    
    /// Creates a demo container with specific template type using mocks
    static func createDemoContainerWithMocks(templateType: ContainerTemplateType, 
                                           completion: @escaping (Result<ContainerSettingsUI, ContainerSettingsUIError>) -> Void) {
        let surfacePath = getSurfacePathForTemplate(templateType)
        let surface = Surface(path: surfacePath)
        
        print("🚀 Creating demo container with mocks for template: \(templateType)")
        print("🧪 Using surface: \(surfacePath)")
        
        // Use the mock API to simulate real server flow
        Messaging.getContentCardContainerUIMock(
            for: surface,
            customizer: DemoCardCustomizer(),
            listener: DemoEventListener()
        ) { result in
            switch result {
            case .success(let container):
                print("✅ Mock demo container created successfully")
                print("📱 Template type: \(container.templateType)")
                print("📊 Container settings capacity: \(container.containerSettings.capacity)")
                completion(.success(container))
                
            case .failure(let error):
                print("❌ Mock demo container creation failed: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    /// Gets surface path that will trigger specific template type in mocks
    private static func getSurfacePathForTemplate(_ templateType: ContainerTemplateType) -> String {
        switch templateType {
        case .inbox:
            return "demo://inbox-container"
        case .carousel:
            return "demo://carousel-container"
        case .custom:
            return "demo://custom-container"
        case .unknown:
            return "demo://unknown-container"
        }
    }
    
    /// Creates demo containers for all template types
    static func createAllDemoContainers(completion: @escaping ([ContainerTemplateType: ContainerSettingsUI]) -> Void) {
        let templateTypes: [ContainerTemplateType] = [.inbox, .carousel, .custom]
        var containers: [ContainerTemplateType: ContainerSettingsUI] = [:]
        let group = DispatchGroup()
        
        for templateType in templateTypes {
            group.enter()
            createDemoContainerWithMocks(templateType: templateType) { result in
                defer { group.leave() }
                
                switch result {
                case .success(let container):
                    containers[templateType] = container
                    print("✅ Created \(templateType) container")
                case .failure(let error):
                    print("❌ Failed to create \(templateType) container: \(error)")
                }
            }
        }
        
        group.notify(queue: .main) {
            print("🎯 Created \(containers.count) demo containers")
            completion(containers)
        }
    }
    
    /// Demo card customizer for styling mock content cards
    class DemoCardCustomizer: ContentCardCustomizing {
        func customize(template: SmallImageTemplate) {
            // Customize small image cards with rounded corners and shadows
            template.backgroundColor = Color(.systemBackground)
            template.rootHStack.spacing = 12
            template.textVStack.alignment = .leading
            template.textVStack.spacing = 8
            
            // Note: Template styling should be done through ContentCardCustomizing
            // Direct template modification of modifiers and button colors is not supported
            
            // Customize button text if present
            if let button = template.buttons?.first {
                button.text.textColor = .white
                // Note: Button styling should be done through ContentCardCustomizing
            }
        }
        
        func customize(template: LargeImageTemplate) {
            // Customize large image cards with prominent styling
            template.backgroundColor = Color(.systemBackground)
            template.textVStack.alignment = .leading
            template.textVStack.spacing = 12
            
            // Note: Template styling should be done through ContentCardCustomizing
            
            // Style button text
            if let button = template.buttons?.first {
                button.text.textColor = .white
                // Note: Button styling should be done through ContentCardCustomizing
            }
        }
        
        func customize(template: ImageOnlyTemplate) {
            // Customize image-only cards
            template.backgroundColor = Color(.systemBackground)
            // Note: Template styling should be done through ContentCardCustomizing
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
            let settings = container.containerSettings
            let expectedTemplate = getExpectedTemplate(settings)
            let actualTemplate = container.templateType
            
            if expectedTemplate == actualTemplate {
                print("✅ Demo: Template selection correct!")
            } else {
                print("❌ Demo: Template selection mismatch - expected: \(expectedTemplate), got: \(actualTemplate)")
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

// MARK: - Demo View Modifiers

@available(iOS 13.0, *)
struct ShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

@available(iOS 13.0, *)
struct ButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
    }
}

// MARK: - SwiftUI Demo View

@available(iOS 15.0, *)
struct ContainerSettingsDemoView: View {
    @State private var selectedTemplate: ContainerTemplateType = .inbox
    @State private var demoContainers: [ContainerTemplateType: ContainerSettingsUI] = [:]
    @State private var isLoading = true
    @State private var error: ContainerSettingsUIError?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Template selector
                templateSelector
                
                if isLoading {
                    loadingView
                } else if let error = error {
                    errorView(error)
                } else if let container = demoContainers[selectedTemplate] {
                    containerView(container)
                } else {
                    emptyView
                }
            }
            .navigationTitle("Mock Container Demo")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Run Tests") {
                        ContainerSettingsDemo.testTemplateSelection()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        demoContainers[selectedTemplate]?.refresh()
                    }
                    .disabled(demoContainers[selectedTemplate] == nil)
                }
            }
        }
        .onAppear {
            loadAllDemoContainers()
        }
    }
    
    private var templateSelector: some View {
        HStack(spacing: 0) {
            ForEach([ContainerTemplateType.inbox, .carousel, .custom], id: \.self) { template in
                Button(action: {
                    selectedTemplate = template
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
                    .background(selectedTemplate == template ? Color.blue.opacity(0.1) : Color.clear)
                    .foregroundColor(selectedTemplate == template ? .blue : .primary)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private func templateIcon(for template: ContainerTemplateType) -> String {
        switch template {
        case .inbox: return "📥"
        case .carousel: return "🎠"
        case .custom: return "⚙️"
        case .unknown: return "❓"
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading demo containers...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ error: ContainerSettingsUIError) -> some View {
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
                loadAllDemoContainers()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func containerView(_ container: ContainerSettingsUI) -> some View {
        VStack(spacing: 0) {
            // Container info
            containerInfoCard(container)
            
            // Container view
            container.view
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func containerInfoCard(_ container: ContainerSettingsUI) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("📊 Container Details")
                    .font(.headline)
                Spacer()
                Text(container.templateType.rawValue)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Orientation: \(container.containerSettings.layout.orientation.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Capacity: \(container.containerSettings.capacity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Unread: \(container.containerSettings.isUnreadEnabled ? "Yes" : "No")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Cards: \(container.contentCards.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let heading = container.containerSettings.heading?.content {
                Text("Heading: \(heading)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No container available")
                .font(.headline)
                .foregroundColor(.secondary)
            Button("Reload") {
                loadAllDemoContainers()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadAllDemoContainers() {
        isLoading = true
        error = nil
        demoContainers = [:]
        
        ContainerSettingsDemo.createAllDemoContainers { containers in
            DispatchQueue.main.async {
                self.isLoading = false
                self.demoContainers = containers
                
                if containers.isEmpty {
                    self.error = .containerCreationFailed
                }
            }
        }
    }
}
