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

/// Enum responsible for building content card templates based on template types.
@available(iOS 15.0, *)
enum TemplateBuilder {
    /// Builds and returns a content card template based on the provided schema data.
    ///
    /// - Parameters:
    ///    - schemaData: The content card schema data containing template information.
    ///    - customizer: An object conforming to `ContentCardCustomizing` protocol that allows for
    ///                 custom styling of the content card
    /// - Returns: An instance conforming to `ContentCardTemplate` if a supported template type is found, otherwise `nil`.
    static func buildTemplate(from schemaData: ContentCardSchemaData,
                              customizer: ContentCardCustomizing?) -> (any ContentCardTemplate)? {
        switch schemaData.templateType {
        case .smallImage:
            return SmallImageTemplate(schemaData, customizer)
        case .unknown:
            // Currently unsupported template types
            return nil
        }
    }
}
