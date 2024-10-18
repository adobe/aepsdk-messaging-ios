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

// The model class representing the button UI element of the ContentCard.
@available(iOS 15.0, *)
public class AEPButton: ObservableObject, AEPViewModel {
    /// the text model for the button's label.
    @Published public var text: AEPText

    /// custom view modifier that can be applied to the button view.
    @Published public var modifier: AEPViewModifier?

    /// unique identifier for tracking button interactions.
    var interactId: String

    /// the URL to be opened when the button is tapped.
    var actionUrl: URL?

    /// The parent template that contains this button.
    weak var parentTemplate: (any ContentCardTemplate)?

    public lazy var view: some View = AEPButtonView(model: self)

    /// Initializes a new instance of `AEPButton`
    /// Failable initializer, returns nil if the required fields are not present in the data
    /// - Parameters:
    ///   - schemaData: A dictionary containing server-side styling and content information for the button.
    ///   - template: An instance conforming to the `ContentCardTemplate` protocol, representing the parent template of the button.
    /// - Returns: An optional `AEPButton` instance, or `nil` if required fields are missing or invalid.
    init?(_ schemaData: [String: Any], _ template: any ContentCardTemplate) {
        // Extract the button text
        // Bail out if the button text is not present
        guard let buttonTextData = schemaData[Constants.CardTemplate.UIElement.Button.TEXT] as? [String: Any],
              let buttonText = AEPText(buttonTextData, type: .button) else {
            return nil
        }

        // Extract the interactId
        // Bail out if the interact Id is not present
        guard let interactId = schemaData[Constants.CardTemplate.UIElement.Button.INTERACTION_ID] as? String else {
            return nil
        }

        self.text = buttonText
        self.interactId = interactId
        if let urlString = schemaData[Constants.CardTemplate.UIElement.Button.ACTION_URL] as? String,
           let url = URL(string: urlString) {
            self.actionUrl = url
        }
        self.parentTemplate = template
    }
}
#endif
