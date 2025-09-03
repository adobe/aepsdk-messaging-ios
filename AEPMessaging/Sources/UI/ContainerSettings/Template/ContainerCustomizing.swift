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

/// A protocol that allows customization of container templates.
///
/// Implement this protocol to provide custom styling and behavior for different container template types.
/// The protocol provides default implementations, so you only need to implement the methods for the
/// template types you want to customize.
@available(iOS 15.0, *)
public protocol ContainerCustomizing {
    /// Customize an inbox container template.
    /// - Parameter template: The inbox container template to customize
    func customize(template: InboxContainerTemplate)
    
    /// Customize a carousel container template.
    /// - Parameter template: The carousel container template to customize
    func customize(template: CarouselContainerTemplate)
    
    /// Customize a custom container template.
    /// - Parameter template: The custom container template to customize
    func customize(template: CustomContainerTemplate)
    
    /// Customize any container template (called for all template types).
    /// - Parameter template: The container template to customize
    func customize(template: BaseContainerTemplate)
}

/// Default implementations for optional customization methods
@available(iOS 15.0, *)
public extension ContainerCustomizing {
    func customize(template: InboxContainerTemplate) {
        // Default implementation - no customization
    }
    
    func customize(template: CarouselContainerTemplate) {
        // Default implementation - no customization
    }
    
    func customize(template: CustomContainerTemplate) {
        // Default implementation - no customization
    }
    
    func customize(template: BaseContainerTemplate) {
        // Default implementation - no customization
    }
}
