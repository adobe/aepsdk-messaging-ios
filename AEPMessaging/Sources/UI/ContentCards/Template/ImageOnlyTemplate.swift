/*
 Copyright 2025 Adobe. All rights reserved.
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
import AEPServices

/// A class representing a content card template with an image-only layout.
///
/// `ImageOnlyTemplate` is a subclass of `BaseTemplate` and conforms to the `ContentCardTemplate` protocol.
/// It provides a structured layout for content cards that include only an image that can be tapped like a button.
/// This class is initialized with `ContentCardSchemaData`, which is used to populate the template's properties.
/// If the required `image` is missing from the schema data, the initialization fails.
///
/// - Note: The `view` property is lazily initialized and represents the entire layout of the content card.
@available(iOS 15.0, *)
public class ImageOnlyTemplate: BaseTemplate, ContentCardTemplate {
    public var templateType: ContentCardTemplateType = .imageOnly

    /// The image associated with the content card.
    public var image: AEPImage

    /// The SwiftUI view representing the content card.
    public lazy var view: some View = buildCardView {
        image.view
    }

    /// Initializes an `ImageOnlyTemplate` with the given schema data.
    ///
    /// This initializer extracts the image from the provided `ContentCardSchemaData`.
    /// The image is configured to be tappable and behave like a button.
    ///
    /// - Parameters:
    ///    - schemaData: The schema data used to populate the template's properties.
    ///    - customizer: An object conforming to ContentCardCustomizing protocol that allows for
    ///                 custom styling of the content card
    /// - Returns: An initialized `ImageOnlyTemplate` or `nil` if the required image is missing.
    init?(_ schemaData: ContentCardSchemaData, _ customizer: ContentCardCustomizing?) {
        guard let image = schemaData.image else {
            return nil
        }

        self.image = image
        super.init(schemaData)

        dismissButton = schemaData.getDismissButton(forTemplate: self)

        customizer?.customize(template: self)
    }
}
