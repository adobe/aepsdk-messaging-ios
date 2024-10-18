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
    import AEPServices
    import Combine
    import SwiftUI

    @available(iOS 15.0, *)
    public class AEPDismissButton: ObservableObject, AEPViewModel {
        /// custom view modifier that can be applied to the dismiss button view.
        @Published public var modifier: AEPViewModifier?

        /// The image for the dismiss button
        @Published public var image: AEPImage

        /// Alignment for the dismiss button rendered as an overlay on the card's template
        @Published public var alignment: Alignment = Constants.CardTemplate.DefaultStyle.DismissButton.ALIGNMENT

        /// The parent template that contains this button.
        weak var parentTemplate: (any ContentCardTemplate)?

        lazy var view: some View = AEPDismissButtonView(model: self)

        init?(_ data: [String: Any], _ template: any ContentCardTemplate) {
            // bail out, if we cannot create a dismiss button Image
            guard let dismissImage = AEPDismissButton.createDismissImage(data) else {
                return nil
            }

            parentTemplate = template
            image = dismissImage
        }

        private static func createDismissImage(_ data: [String: Any]) -> AEPImage? {
            guard let styleString = data[Constants.CardTemplate.DismissButton.STYLE] as? String,
                  let style = DismissButtonStyle(rawValue: styleString.lowercased()) else {
                Log.warning(label: Constants.LOG_TAG, "Dismiss button not created, invalid or missing style property.")
                return nil
            }

            guard let iconName = style.iconName else {
                Log.trace(label: Constants.LOG_TAG, "Dismiss button style set to 'none'. No button will be created.")
                return nil
            }

            return AEPImage([Constants.CardTemplate.UIElement.Image.ICON: iconName])
        }
    }
#endif
