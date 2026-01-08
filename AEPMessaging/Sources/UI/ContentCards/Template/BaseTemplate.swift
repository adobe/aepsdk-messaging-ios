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

/// A base class for content card templates, providing common properties and initialization logic.
///
/// `BaseTemplate` serves as a foundational class for more specific content card templates.
/// It includes properties and methods that are shared across different template types, such as
/// the background color. This class is intended to be subclassed by specific template implementations
/// that define their own layout and content.
///
///
/// - Note: This class is not intended to be used directly. Instead, use one of its subclasses
///   that provide specific template implementations.
@available(iOS 15.0, *)
public class BaseTemplate: ObservableObject {
    /// The background color of the content card.
    /// Use this property to set the background color for the content card.
    @Published public var backgroundColor: Color?

    /// the dismiss button model
    @Published public var dismissButton: AEPDismissButton?

    /// The unread indicator icon model
    /// Contains settings for the unread icon including image and placement
    /// This property is optional and will only be set if unread icon settings are provided
    @Published public var unreadIcon: AEPUnreadIcon?
    
    /// The background view for the unread state obtained from the inbox settings
    /// This view overlays the card content when the card is in unread state
    @Published public var unreadBackground: AnyView?
    
    /// Boolean indicating if the card has been read
    /// Used to determine visibility of unread indicators
    @Published var isRead: Bool = false

    /// An optional handler that conforms to the `TemplateEventHandler` protocol.
    /// Use this property to assign a listener that will handle events related to the content card's interactions.
    weak var eventHandler: TemplateEventHandler?

    /// The URL that is intended to be opened when the content card is interacted with.
    var actionURL: URL?

    /// Boolean indicating if the template's view is displayed to the user
    /// Use this boolean to avoid sending multiple display events on a template
    var isDisplayed: Bool = false

    /// Initializes a `BaseTemplate` with the given schema data.
    /// This initializer is designed to be called by subclasses to perform common initialization tasks.
    /// - Parameters:
    ///   - schemaData: The schema data used for initialization.
    ///   - inboxSettings: Optional settings that apply specific configurations to content cards when displayed within an inbox
    init?(_ schemaData: ContentCardSchemaData, _ inboxSettings: InboxSettings? = nil) {
        actionURL = schemaData.actionUrl
        
        // Apply inbox settings if provided
        if let inboxSettings = inboxSettings {
            // Apply unread indicator settings if available
            if let unreadSettings = inboxSettings.unreadIndicator {
                // Set unread icon if available
                if let iconSettings = unreadSettings.unreadIcon {
                    self.unreadIcon = AEPUnreadIcon(settings: iconSettings)
                }
                
                // Set unread background if available
                if let bgSettings = unreadSettings.unreadBackground {
                    self.unreadBackground = AnyView(Color(aepColor: bgSettings.color))
                }
            }
            isRead = true
        }
    }
    
    /// Updates the visual state of the template based on read status
    /// - Parameter isRead: Boolean indicating if the card has been read
    func updateUnreadState(isRead: Bool) {
        self.isRead = isRead
    }

    /// Constructs a SwiftUI view with common properties and behaviors applied for all templates.
    ///
    /// - Parameter content: A closure that returns the content view to be displayed.
    /// - Returns: A SwiftUI view of the templated Content Card
    func buildCardView<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        TemplateWrapperView(template: self, content: content)
    }
}

/// A wrapper view that observes the template and updates when it changes
@available(iOS 15.0, *)
private struct TemplateWrapperView<Content: View>: View {
    @ObservedObject var template: BaseTemplate
    let content: () -> Content
    
    var body: some View {
        content()
            .background {
                if !template.isRead, let unreadBackground = template.unreadBackground {
                    unreadBackground
                } else {
                    template.backgroundColor
                }
            }
            .onTapGesture {
                template.eventHandler?.onInteract(interactionId: UIConstants.CardTemplate.InteractionID.cardTapped, actionURL: template.actionURL)
            }.onAppear(perform: {
                if !template.isDisplayed {
                    template.isDisplayed = true
                    template.eventHandler?.onDisplay()
                }
            })
            // Unread Icon Overlay
            .overlay(alignment: template.unreadIcon?.alignment ?? .topTrailing, content: {
                if !template.isRead, let icon = template.unreadIcon {
                    icon.view
                }
            })
            // Dismiss Button Overlay
            .overlay(alignment: template.dismissButton?.alignment ??
                UIConstants.CardTemplate.DefaultStyle.DismissButton.ALIGNMENT, content: {
                    if template.dismissButton != nil {
                        template.dismissButton?.view
                            .padding(UIConstants.CardTemplate.DefaultStyle.PADDING)
                    }
                })
    }
}
