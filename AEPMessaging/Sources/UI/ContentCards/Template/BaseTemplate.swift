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

    /// When true, applies a Liquid Glass material to the card background on iOS 26+.
    /// On older OS versions this property has no effect and the card renders with its normal background.
    /// Defaults to false to preserve existing visual behaviour.
    @Published public var isGlassEffectEnabled: Bool = false

    /// Corner radius used for the Liquid Glass shape when `isGlassEffectEnabled` is true.
    /// Set this to match the corner radius of your card's clip shape.
    /// Defaults to 5.
    @Published public var glassCornerRadius: CGFloat = 5


    /// the dismiss button model
    @Published public var dismissButton: AEPDismissButton?

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
    /// - Parameter schemaData: The schema data used for initialization.
    init?(_ schemaData: ContentCardSchemaData) {
        actionURL = schemaData.actionUrl
    }

    /// Constructs a SwiftUI view with common properties and behaviors applied for all templates.
    ///
    /// - Parameter content: A closure that returns the content view to be displayed.
    /// - Returns: A SwiftUI view of the templated Content Card
    func buildCardView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background {
                if isGlassEffectEnabled, #available(iOS 26.0, *) {
                    Color.clear.glassEffect(.regular, in: RoundedRectangle(cornerRadius: glassCornerRadius))
                } else {
                    backgroundColor
                }
            }
            .onTapGesture {
                self.eventHandler?.onInteract(interactionId: UIConstants.CardTemplate.InteractionID.cardTapped, actionURL: self.actionURL)
            }.onAppear(perform: {
                if !self.isDisplayed {
                    self.isDisplayed = true
                    self.eventHandler?.onDisplay()
                }
            }).overlay(alignment: dismissButton?.alignment ??
                UIConstants.CardTemplate.DefaultStyle.DismissButton.ALIGNMENT, content: {
                    if dismissButton != nil {
                        dismissButton?.view
                            .padding(UIConstants.CardTemplate.DefaultStyle.PADDING)
                    }
                })
    }
}
