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
    import Combine
    import SwiftUI
#endif

/// A base class for container templates, providing common properties and initialization logic.
///
/// `BaseContainerTemplate` serves as a foundational class for more specific container templates.
/// It includes properties and methods that are shared across different template types, such as
/// header rendering, event handling, and common styling. This class is intended to be subclassed
/// by specific template implementations that define their own layout and content.
///
/// - Note: This class is not intended to be used directly. Instead, use one of its subclasses
///   that provide specific template implementations.
@available(iOS 15.0, *)
public class BaseContainerTemplate: ObservableObject {
    /// The container settings schema data used to configure the template
    public let containerSettings: ContainerSettingsSchemaData
    
    /// The content cards to be displayed in the container
    @Published public var contentCards: [ContentCardUI]
    
    /// An optional handler that conforms to the `ContainerTemplateEventHandler` protocol.
    /// Use this property to assign a listener that will handle events related to the container's interactions.
    weak var eventHandler: ContainerTemplateEventHandler?
    
    /// Boolean indicating if the template's view is displayed to the user
    /// Use this boolean to avoid sending multiple display events on a template
    var isDisplayed: Bool = false
    
    /// Initializes a `BaseContainerTemplate` with the given schema data and content cards.
    /// This initializer is designed to be called by subclasses to perform common initialization tasks.
    /// - Parameters:
    ///   - containerSettings: The container settings schema data
    ///   - contentCards: The content cards to be displayed
    ///   - customizer: Optional customizer for the container template
    init?(_ containerSettings: ContainerSettingsSchemaData, 
          contentCards: [ContentCardUI], 
          customizer: ContainerCustomizing?) {
        self.containerSettings = containerSettings
        self.contentCards = contentCards
        
        // Apply customization if provided
        customizer?.customize(template: self)
    }
    
    /// Constructs a SwiftUI view with common properties and behaviors applied for all container templates.
    ///
    /// - Parameter content: A closure that returns the content view to be displayed.
    /// - Returns: A SwiftUI view of the templated Container
    func buildContainerView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .onAppear(perform: {
                if !self.isDisplayed {
                    self.isDisplayed = true
                    // Track container display event to Edge
                    self.containerSettings.track(withEdgeEventType: .display)
                    self.eventHandler?.onContainerDisplay()
                }
            })
    }
    
    /// Builds a standardized header view for the container
    /// - Parameter heading: The heading text to display
    /// - Returns: A SwiftUI view representing the header
    func buildHeaderView(_ heading: String) -> some View {
        HStack {
            Text(heading)
                .font(.title2)
                .fontWeight(.semibold)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    /// Builds an unread indicator view
    /// - Returns: A SwiftUI view representing the unread indicator
    func buildUnreadIndicatorView() -> some View {
        Circle()
            .fill(Color.red)
            .frame(width: 8, height: 8)
    }
    
    /// Checks if a content card is unread based on its metadata
    /// - Parameter card: The content card to check
    /// - Returns: True if the card is unread, false otherwise
    func isCardUnread(_ card: ContentCardUI) -> Bool {
        guard containerSettings.isUnreadEnabled == true,
              let unreadValue = card.meta?["unread"] as? Bool else {
            return false
        }
        return unreadValue
    }
}
