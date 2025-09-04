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

/// A class representing a container template with a custom configurable layout.
///
/// `CustomContainerTemplate` is a subclass of `BaseContainerTemplate` and conforms to the `ContainerTemplate` protocol.
/// It provides a structured layout for containers that include configurable scrolling orientation and unread indicators.
/// This class is initialized with `ContainerSettingsSchemaData` and content cards.
///
/// - Note: The `view` property is lazily initialized and represents the entire layout of the container.
@available(iOS 15.0, *)
public class CustomContainerTemplate: BaseContainerTemplate, ContainerTemplate {
    public let templateType: ContainerTemplateType = .custom

    /// The SwiftUI view representing the custom container.
    public lazy var view: some View = buildContainerView {
        VStack(alignment: .leading, spacing: 0) {
            // Header if available
            if let heading = containerSettings.heading?.content {
                buildHeaderView(heading)
            }
            
            // Custom layout based on orientation
            if containerSettings.layout.orientation == .horizontal {
                horizontalLayout
            } else {
                verticalLayout
            }
        }
    }
    
    /// Initializes a `CustomContainerTemplate` with the given schema data and content cards.
    ///
    /// - Parameters:
    ///   - containerSettings: The container settings schema data
    ///   - contentCards: The content cards to be displayed
    ///   - customizer: An object conforming to ContainerCustomizing protocol that allows for
    ///                 custom styling of the container template
    /// - Returns: An initialized `CustomContainerTemplate` or `nil` if initialization fails.
    override init?(_ containerSettings: ContainerSettingsSchemaData, 
                   contentCards: [ContentCardUI], 
                   customizer: ContainerCustomizing?) {
        super.init(containerSettings, contentCards: contentCards, customizer: customizer)
        
        // Apply specific customization for custom template
        customizer?.customize(template: self)
    }
    
    private var verticalLayout: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 16) {
                ForEach(contentCards, id: \.id) { card in
                    self.customCardView(card)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    private var horizontalLayout: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 20) {
                ForEach(contentCards, id: \.id) { card in
                    self.customCardView(card)
                        .frame(width: 280)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    private func customCardView(_ card: ContentCardUI) -> some View {
        card.view
            .padding(.all, 12) // Internal padding for content
            .padding(.top, containerSettings.layout.orientation == .horizontal ? 20 : 0) // Extra top padding for horizontal layout
            .overlay(alignment: .topLeading) {
                // Show unread indicator if enabled and card is unread
                if isCardUnread(card) {
                    buildUnreadIndicatorView()
                        .offset(x: 4, y: 4) // Small offset from top-left corner
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
