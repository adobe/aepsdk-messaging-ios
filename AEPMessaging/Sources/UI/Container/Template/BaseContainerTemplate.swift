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
    /// The background color of the container.
    /// Use this property to set the background color for the container.
    @Published public var backgroundColor: Color? = Color(.systemGroupedBackground)
    
    /// The container settings schema data used to configure the template
    public let containerSettings: ContainerSchemaData
    
    /// The content cards to be displayed in the container
    @Published public var contentCards: [ContentCardUI]
    
    /// An optional handler that conforms to the `ContainerTemplateEventHandler` protocol.
    /// Use this property to assign a listener that will handle events related to the container's interactions.
    weak var eventHandler: ContainerTemplateEventHandler?
    
    /// Boolean indicating if the template's view is displayed to the user
    /// Use this boolean to avoid sending multiple display events on a template
    var isDisplayed: Bool = false
    
    /// Optional custom header view builder provided by the customer app
    /// If set, this will be used instead of the default header view
    private var customHeaderBuilder: ((String) -> AnyView)?
    
    
    /// Initializes a `BaseContainerTemplate` with the given schema data and content cards.
    /// This initializer is designed to be called by subclasses to perform common initialization tasks.
    /// - Parameters:
    ///   - containerSettings: The container settings schema data
    ///   - contentCards: The content cards to be displayed
    ///   - customizer: Optional customizer for the container template
    init?(_ containerSettings: ContainerSchemaData, 
          contentCards: [ContentCardUI], 
          customizer: ContainerCustomizing?) {
        self.containerSettings = containerSettings
        self.contentCards = contentCards
    }
    
    /// Constructs a SwiftUI view with common properties and behaviors applied for all container templates.
    ///
    /// - Parameter content: A closure that returns the content view to be displayed.
    /// - Returns: A SwiftUI view of the templated Container
    func buildContainerView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(backgroundColor) // Configurable background color
            .onAppear(perform: {
                if !self.isDisplayed {
                    self.isDisplayed = true
                    // Track container display event to Edge
                    self.containerSettings.track(withEdgeEventType: .display)
                    self.eventHandler?.onContainerDisplay()
                }
            })
    }
    
    /// Builds a header view for the container
    /// - Parameter heading: The heading text to display
    /// - Returns: A SwiftUI view representing the header (custom if provided, otherwise default)
    func buildHeaderView(_ heading: String) -> some View {
        Group {
            if let customBuilder = customHeaderBuilder {
                // Use custom header view provided by customer
                customBuilder(heading)
            } else {
                // Use default SDK header view
                AnyView(defaultHeaderView(heading))
            }
        }
    }
    
    /// Builds the default SDK header view for the container
    /// - Parameter heading: The heading text to display
    /// - Returns: A SwiftUI view representing the default header
    private func defaultHeaderView(_ heading: String) -> some View {
        HStack {
            Text(heading)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        )
    }
    
    /// Sets a custom header view builder for the container
    /// This is called by the customizer to provide a custom header view
    /// - Parameter builder: A closure that takes a heading string and returns a custom view
    public func setCustomHeaderView<Content: View>(_ builder: @escaping (String) -> Content) {
        self.customHeaderBuilder = { heading in
            AnyView(builder(heading))
        }
    }
    
    /// Builds an unread indicator view
    /// - Returns: A SwiftUI view representing the unread indicator
    func buildUnreadIndicatorView() -> some View {
        Circle()
            .fill(Color.red)
            .frame(width: 10, height: 10)
            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
    }
    
    /// Checks if a content card is unread based on its persistent read status
    /// - Parameter card: The content card to check
    /// - Returns: True if the card is unread, false otherwise
    func isCardUnread(_ card: ContentCardUI) -> Bool {
        guard containerSettings.isUnreadEnabled == true else {
            return false
        }
        
        // Check the persistent isRead property - if nil, this card doesn't support read/unread
        // If false or nil (new card), it's unread. If true, it's been read.
        return card.isRead != true
    }
}
