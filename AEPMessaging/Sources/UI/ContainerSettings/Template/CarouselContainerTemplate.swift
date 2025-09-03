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

/// A class representing a container template with a carousel-style layout.
///
/// `CarouselContainerTemplate` is a subclass of `BaseContainerTemplate` and conforms to the `ContainerTemplate` protocol.
/// It provides a structured layout for containers that include horizontal scrolling without unread indicators.
/// This class is initialized with `ContainerSettingsSchemaData` and content cards.
///
/// - Note: The `view` property is lazily initialized and represents the entire layout of the container.
@available(iOS 15.0, *)
public class CarouselContainerTemplate: BaseContainerTemplate, ContainerTemplate {
    public let templateType: ContainerTemplateType = .carousel

    /// The SwiftUI view representing the carousel container.
    public lazy var view: some View = buildContainerView {
        VStack(alignment: .leading, spacing: 0) {
            // Header if available
            if let heading = containerSettings.heading?.content {
                buildHeaderView(heading)
            }
            
            // Horizontal scrolling carousel
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(contentCards, id: \.id) { card in
                        card.view
                            .frame(width: 280) // Fixed width for carousel
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
    
    /// Initializes a `CarouselContainerTemplate` with the given schema data and content cards.
    ///
    /// - Parameters:
    ///   - containerSettings: The container settings schema data
    ///   - contentCards: The content cards to be displayed
    ///   - customizer: An object conforming to ContainerCustomizing protocol that allows for
    ///                 custom styling of the container template
    /// - Returns: An initialized `CarouselContainerTemplate` or `nil` if initialization fails.
    override init?(_ containerSettings: ContainerSettingsSchemaData, 
                   contentCards: [ContentCardUI], 
                   customizer: ContainerCustomizing?) {
        super.init(containerSettings, contentCards: contentCards, customizer: customizer)
        
        // Apply specific customization for carousel template
        customizer?.customize(template: self)
    }
}
