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
    
    let cardsSurface = Surface(path: Constants.SurfaceName.CONTENT_CARD)
    @State var savedCards : [ContentCardUI] = []
    @State private var containerUI: ContainerSettingsUI?
    @State private var viewLoaded: Bool = false
    @State private var showLoadingIndicator: Bool = false
    @State private var selectedView: CardViewType = .container
    @State private var selectedTemplate: ContainerTemplateType = .inbox
    @State private var loadedContainers: [ContainerTemplateType: ContainerSettingsUI] = [:]
    
    enum CardViewType: String, CaseIterable {
        case container = "Container View"
        case individual = "Individual Cards"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TabHeader(title: "Content Cards", refreshAction: {
                refreshCards()
            }, redownloadAction: {
                downloadCards()
                refreshCards()
            })
            
            // View type selector
            viewTypeSelector
            
            // Template selector (only show when container view is selected)
            if selectedView == .container {
                templateSelector
            }
            
            ZStack {
                Group {
                    switch selectedView {
                    case .container:
                        containerView
                    case .individual:
                        individualCardsView
                    }
                }
                
                if showLoadingIndicator {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
        }
        .onAppear() {
            if !viewLoaded {
                viewLoaded = true
                refreshCards()
                loadAllContainers()
            }
        }
    }
    
    private var viewTypeSelector: some View {
        Picker("View Type", selection: $selectedView) {
            ForEach(CardViewType.allCases, id: \.self) { viewType in
                Text(viewType.rawValue).tag(viewType)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var templateSelector: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Container Template:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            HStack(spacing: 0) {
                ForEach([ContainerTemplateType.inbox, .carousel, .custom], id: \.self) { template in
                    Button(action: {
                        selectedTemplate = template
                        updateCurrentContainer()
                    }) {
                        VStack(spacing: 4) {
                            Text(templateIcon(for: template))
                                .font(.title2)
                            Text(template.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
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
        .padding(.bottom, 8)
    }
    
    private func templateIcon(for template: ContainerTemplateType) -> String {
        switch template {
        case .inbox: return "📥"
        case .carousel: return "🎠"
        case .custom: return "⚙️"
        case .unknown: return "❓"
        }
    }
    
    private var containerView: some View {
        Group {
            if let currentContainer = loadedContainers[selectedTemplate] {
                VStack(spacing: 0) {
                    // Container info header
                    containerInfoHeader(currentContainer)
                    
                    // Container view
                    currentContainer.view
                }
            } else if showLoadingIndicator {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading \(selectedTemplate.rawValue) container...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 16) {
                    Text(templateIcon(for: selectedTemplate))
                        .font(.system(size: 48))
                    Text("No \(selectedTemplate.rawValue) container available")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("This template demonstrates \(templateDescription(for: selectedTemplate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Load \(selectedTemplate.rawValue) Container") {
                        loadContainer(for: selectedTemplate)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func templateDescription(for template: ContainerTemplateType) -> String {
        switch template {
        case .inbox:
            return "vertical scrolling with unread indicators"
        case .carousel:
            return "horizontal scrolling without unread indicators"
        case .custom:
            return "configurable scrolling and unread settings"
        case .unknown:
            return "unknown template configuration"
        }
    }
    
    private func containerInfoHeader(_ container: ContainerSettingsUI) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("🏷️ Container Settings")
                    .font(.headline)
                Spacer()
                Text(container.templateType.rawValue)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Orientation: \(container.containerSettings.layout.orientation.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Capacity: \(container.containerSettings.capacity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Unread: \(container.containerSettings.isUnreadEnabled ? "✓" : "✗")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var individualCardsView: some View {
        ScrollView (.vertical, showsIndicators: false){
            LazyVStack(spacing: 20) {
                ForEach(savedCards) { card in
                    card.view
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color(.systemGray3), lineWidth: 1)
                        )
                        .padding()
                }
            }
        }
    }
    
    func refreshCards() {
        showLoadingIndicator = true
        let cardsPageSurface = Surface(path: Constants.SurfaceName.CONTENT_CARD)
        Messaging.getContentCardsUI(for: cardsPageSurface,
                                     customizer: CardCustomizer(),
                                     listener: self) { result in
            showLoadingIndicator = false
            switch result {
            case .success(let cards):
                // sort the cards by priority order and save them to our state property
                savedCards = cards.sorted { $0.priority > $1.priority }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func downloadCards() {
        showLoadingIndicator = true
        Messaging.updatePropositionsForSurfaces([cardsSurface])
    }
    
    func loadAllContainers() {
        showLoadingIndicator = true
        
        let templates: [ContainerTemplateType] = [.inbox, .carousel, .custom]
        let group = DispatchGroup()
        
        for template in templates {
            group.enter()
            loadContainer(for: template, showLoading: false) {
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.showLoadingIndicator = false
            self.updateCurrentContainer()
            print("TestAppLog: All containers loaded - \(self.loadedContainers.count) available")
        }
    }
    
    func loadContainer(for template: ContainerTemplateType, showLoading: Bool = true, completion: (() -> Void)? = nil) {
        if showLoading {
            showLoadingIndicator = true
        }
        
        let surfacePath = getSurfacePathForTemplate(template)
        let mockSurface = Surface(path: surfacePath)
        
        Messaging.getContentCardContainerUIMock(
            for: mockSurface,
            customizer: CardCustomizer(),
            listener: self
        ) { result in
            DispatchQueue.main.async {
                if showLoading {
                    self.showLoadingIndicator = false
                }
                
                switch result {
                case .success(let container):
                    self.loadedContainers[template] = container
                    print("TestAppLog: \(template.rawValue) container loaded successfully")
                    
                    if showLoading {
                        self.updateCurrentContainer()
                    }
                    
                case .failure(let error):
                    print("TestAppLog: \(template.rawValue) container loading failed - \(error)")
                    self.loadedContainers[template] = nil
                }
                
                completion?()
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
    
    private func updateCurrentContainer() {
        containerUI = loadedContainers[selectedTemplate]
    }
    
    // MARK: - ContainerSettingsEventListening
    
    func onLoading(_ container: ContainerSettingsUI) {
        print("TestAppLog: Container is loading...")
    }
    
    func onLoaded(_ container: ContainerSettingsUI) {
        print("TestAppLog: Container loaded successfully")
    }
    
    func onError(_ container: ContainerSettingsUI, _ error: Error) {
        print("TestAppLog: Container error - \(error.localizedDescription)")
    }
    
    func onEmpty(_ container: ContainerSettingsUI) {
        print("TestAppLog: Container is empty")
    }
    
    func onCardDismissed(_ card: ContentCardUI) {
        print("TestAppLog: Container - Card dismissed")
        // Update individual cards list too for consistency
        savedCards.removeAll(where: { $0.id == card.id })
    }
    
    func onCardDisplayed(_ card: ContentCardUI) {
        print("TestAppLog: Container - Card displayed")
    }
    
    func onCardInteracted(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool {
        print("TestAppLog: Container - Card interacted: \(interactionId)")
        return false
    }
    
    func onCardCreated(_ card: ContentCardUI) {
        print("TestAppLog: Container - Card created")
        
        // Note: Card customizations should be handled through ContentCardCustomizing
        // The CardCustomizer used when creating the container will handle template styling
        // Direct access to template methods like addView() is not available from external modules
    }
}

class CardCustomizer : ContentCardCustomizing {
    func customize(template: AEPMessaging.LargeImageTemplate) {
        // customize UI elements
        template.title.textColor = .primary
        template.title.font = .subheadline
        template.body?.textColor = .secondary
        template.body?.font = .caption
        
        template.buttons?.first?.text.font = .system(size: 13)
        template.buttons?.first?.text.textColor = .primary
        template.buttons?.first?.modifier = AEPViewModifier(ButtonModifier())
        
        
        // customize stack structure
        template.rootVStack.spacing = 10
        template.textVStack.alignment = .leading
        template.textVStack.spacing = 10
        
        // add custom modifiers
        template.buttonHStack.modifier = AEPViewModifier(ButtonHStackModifier())
        template.rootVStack.modifier = AEPViewModifier(RootVStackModifier())
        
        // customize the dismiss buttons
        template.dismissButton?.image.iconColor = .primary
        template.dismissButton?.image.iconFont = .system(size: 10)
    }
    
    
    func customize(template: SmallImageTemplate) {
        // customize UI elements
        template.title.textColor = .primary
        template.title.font = .subheadline
        template.body?.textColor = .secondary
        template.body?.font = .caption
        
        template.buttons?.first?.text.font = .system(size: 13)
        template.buttons?.first?.text.textColor = .primary
        template.buttons?.first?.modifier = AEPViewModifier(ButtonModifier())
        
        
        // customize stack structure
        template.rootHStack.spacing = 10
        template.textVStack.alignment = .leading
        template.textVStack.spacing = 10
        
        // add custom modifiers
        template.buttonHStack.modifier = AEPViewModifier(ButtonHStackModifier())
        template.rootHStack.modifier = AEPViewModifier(RootHStackModifier())
        
        // customize the dismiss buttons
        template.dismissButton?.image.iconColor = .primary
        template.dismissButton?.image.iconFont = .system(size: 10)
    }
    
    func customize(template: ImageOnlyTemplate) {
        // customize UI elements
        // customize the dismiss buttons
        template.dismissButton?.image.iconColor = .primary
        template.dismissButton?.image.iconFont = .system(size: 10)

    }
    
    struct RootVStackModifier : ViewModifier {
        func body(content: Content) -> some View {
            content
                .frame(maxHeight: .infinity, alignment: .leading)
                .padding()
        }
    }
    
    struct RootHStackModifier : ViewModifier {
        func body(content: Content) -> some View {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }
    
    struct ButtonHStackModifier : ViewModifier {
        func body(content: Content) -> some View {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    struct ImageModifier : ViewModifier {
        func body(content: Content) -> some View {
            content
                .frame(width: 100, height: 100)
        }
    }
    
    struct ButtonModifier : ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding()
                .background(Color.primary.opacity(0.1))
                .cornerRadius(10)
        }
    }
}
