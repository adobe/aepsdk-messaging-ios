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

/// Enum responsible for building container templates based on template types.
@available(iOS 15.0, *)
enum ContainerTemplateBuilder {
    /// Builds and returns a container template based on the provided schema data.
    ///
    /// - Parameters:
    ///   - containerSettings: The container settings schema data containing template information.
    ///   - contentCards: The content cards to be displayed in the container
    ///   - customizer: An object conforming to `ContainerCustomizing` protocol that allows for
    ///                 custom styling of the container template
    /// - Returns: An instance conforming to `ContainerTemplate` if a supported template type is found, otherwise `nil`.
    static func buildTemplate(from containerSettings: ContainerSchemaData,
                              contentCards: [ContentCardUI],
                              customizer: ContainerCustomizing?) -> (any ContainerTemplate)? {
        switch containerSettings.templateType {
        case .inbox:
            return InboxContainerTemplate(containerSettings, contentCards: contentCards, customizer: customizer)
        case .carousel:
            return CarouselContainerTemplate(containerSettings, contentCards: contentCards, customizer: customizer)
        case .custom:
            return CustomContainerTemplate(containerSettings, contentCards: contentCards, customizer: customizer)
        case .unknown:
            // Default to custom template for unknown types
            return CustomContainerTemplate(containerSettings, contentCards: contentCards, customizer: customizer)
        }
    }
}
