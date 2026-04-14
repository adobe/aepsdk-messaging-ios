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

/// The model class representing the image UI element of the ContentCard.
/// This class handles the initialization of the image from different sources such as URL or bundle.
@available(iOS 15.0, *)
public class AEPImage: ObservableObject, AEPViewModel, Codable {
    /// The URL of the image to be displayed.
    var url: URL?

    /// The URL of the dark mode image to be displayed.
    var darkUrl: URL?

    /// The alternate text for the image for accessibility purpose.
    var altText: String?

    /// The name of the image bundled resource.
    var bundle: String?

    /// The name of the dark mode image bundled resource.
    var darkBundle: String?

    /// The name of the SF Symbol icon used in the image
    @Published public var icon: String?

    /// The font of the SF Symbol icon used in the image
    /// Set the size and weight of SF Symbol using the font property
    @Published public var iconFont: Font?

    /// The color of the SF Symbol icon used in the image
    @Published public var iconColor = Color.primary

    /// custom view modifier that can be applied to the image view.
    @Published public var modifier: AEPViewModifier?

    /// The content mode of the image.
    @Published public var contentMode: ContentMode = .fit

    /// The source type of the image, either URL or bundle.
    let imageSourceType: ImageSourceType

    lazy var view: some View = AEPImageView(model: self)

    /// Initializes a new instance of `AEPImage`
    /// Failable initializer, returns nil if the required fields are not present in the data
    /// - Parameter data: The dictionary containing server side styling and content of the Image
    init?(_ data: [String: Any]) {
        altText = data[UIConstants.CardTemplate.UIElement.Image.ALTERNATE_TEXT] as? String

        // Attempt to initialize from URL
        if let urlString = data[UIConstants.CardTemplate.UIElement.Image.URL] as? String,
           let url = URL(string: urlString) {
            imageSourceType = .url
            self.url = url
            darkUrl = (data[UIConstants.CardTemplate.UIElement.Image.DARK_URL] as? String).flatMap { URL(string: $0) }
            return
        }

        // Attempt to initialize from bundle
        if let bundle = data[UIConstants.CardTemplate.UIElement.Image.BUNDLE] as? String {
            imageSourceType = .bundle
            self.bundle = bundle
            darkBundle = data[UIConstants.CardTemplate.UIElement.Image.DARK_BUNDLE] as? String
            return
        }

        // Attempt to initialize from icon
        if let icon = data[UIConstants.CardTemplate.UIElement.Image.ICON] as? String {
            imageSourceType = .icon
            self.icon = icon
            return
        }

        // If no valid data is provided, return nil
        return nil
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case url
        case darkUrl
        case alt
        case bundle
        case darkBundle
        case icon
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        altText = try container.decodeIfPresent(String.self, forKey: .alt)
        
        if let urlString = try container.decodeIfPresent(String.self, forKey: .url),
           let url = URL(string: urlString) {
            imageSourceType = .url
            self.url = url
            if let darkUrlString = try container.decodeIfPresent(String.self, forKey: .darkUrl) {
                darkUrl = URL(string: darkUrlString)
            }
            return
        }
        
        if let bundle = try container.decodeIfPresent(String.self, forKey: .bundle) {
            imageSourceType = .bundle
            self.bundle = bundle
            darkBundle = try container.decodeIfPresent(String.self, forKey: .darkBundle)
            return
        }
        
        if let icon = try container.decodeIfPresent(String.self, forKey: .icon) {
            imageSourceType = .icon
            self.icon = icon
            return
        }
        
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to decode AEPImage, no valid image source found."))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(altText, forKey: .alt)
        
        switch imageSourceType {
        case .url:
            try container.encodeIfPresent(url?.absoluteString, forKey: .url)
            try container.encodeIfPresent(darkUrl?.absoluteString, forKey: .darkUrl)
        case .bundle:
            try container.encodeIfPresent(bundle, forKey: .bundle)
            try container.encodeIfPresent(darkBundle, forKey: .darkBundle)
        case .icon:
            try container.encodeIfPresent(icon, forKey: .icon)
        }
    }
}
