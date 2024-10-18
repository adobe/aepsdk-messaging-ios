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

import Foundation

/// An extension of `ContentCardSchemaData` that provides methods and computed variables for extracting
/// specific data elements from the content card schema.
@available(iOS 15.0, *)
extension ContentCardSchemaData {
    /// The template type of the content card.
    /// This property extracts the template type from the Adobe-specific metadata and converts it to
    /// a `ContentCardTemplateType` value. If the template type cannot be determined, it defaults to `.unknown`.
    var templateType: ContentCardTemplateType {
        guard let templateString = metaAdobeData?[UIConstants.CardTemplate.SchemaData.Meta.TEMPLATE] as? String else {
            return .unknown
        }
        return ContentCardTemplateType(from: templateString)
    }

    /// This property extracts the title data from the content dictionary and attempts to
    /// initialize an `AEPText` object with it. Returns `nil` if the title data is not available.
    var title: AEPText? {
        guard let titleData = contentDict?[UIConstants.CardTemplate.SchemaData.TITLE] as? [String: Any] else {
            return nil
        }

        return AEPText(titleData, type: .title)
    }

    /// This property extracts the body data from the content dictionary and attempts to
    /// initialize an `AEPText` object with it. Returns `nil` if the body data is not available.
    var body: AEPText? {
        guard let bodyData = contentDict?[UIConstants.CardTemplate.SchemaData.BODY] as? [String: Any] else {
            return nil
        }
        return AEPText(bodyData, type: .body)
    }

    /// This property extracts the image data from the content dictionary and attempts to
    /// initialize an `AEPText` object with it. Returns `nil` if the image data is not available.
    var image: AEPImage? {
        guard let imageData = contentDict?[UIConstants.CardTemplate.SchemaData.IMAGE] as? [String: Any] else {
            return nil
        }
        return AEPImage(imageData)
    }

    /// Extracts the array of buttons from the content dictionary and initializes `AEPButton` objects with it.
    /// - Parameter template: The `ContentCardTemplate` instance for which the buttons are initialized.
    /// - Returns: An array of `AEPButton` objects, or `nil` if the buttons data is not available.
    func getButtons(forTemplate template: any ContentCardTemplate) -> [AEPButton]? {
        guard let buttonsData = contentDict?[UIConstants.CardTemplate.SchemaData.BUTTONS] as? [[String: Any]] else {
            return nil
        }

        return buttonsData.compactMap { AEPButton($0, template) }
    }

    /// Retrieves the dismiss button configuration for a given content card template.
    /// This method extracts the dismiss button data from the content dictionary and creates an instance of `AEPDismissButton` if the data is present. If the dismiss button data is not found, it returns `nil`.
    /// - Parameters:
    ///  - template: The `ContentCardTemplate` instance for which the dismiss button is initialized.
    /// - Returns: An AEPDismissButton instance, or nil if the data is not available.
    func getDismissButton(forTemplate template: any ContentCardTemplate) -> AEPDismissButton? {
        guard let dismissButtonData = contentDict?[UIConstants.CardTemplate.SchemaData.DISMISS_BTN] as? [String: Any] else {
            return nil
        }

        return AEPDismissButton(dismissButtonData, template)
    }

    /// This property extracts the action URL from the content dictionary and returns it as a URL object.
    /// Returns `nil` if the action URL is not available or if it is not a valid URL.
    var actionUrl: URL? {
        guard let actionUrl = contentDict?[UIConstants.CardTemplate.SchemaData.ACTION_URL] as? String else {
            return nil
        }
        return URL(string: actionUrl)
    }

    /// A dictionary representing the content of the content card.
    private var contentDict: [String: Any]? {
        content as? [String: Any]
    }

    /// A dictionary representing the Adobe-specific metadata of the content card.
    private var metaAdobeData: [String: Any]? {
        meta?[UIConstants.CardTemplate.SchemaData.Meta.ADOBE_DATA] as? [String: Any]
    }
}
