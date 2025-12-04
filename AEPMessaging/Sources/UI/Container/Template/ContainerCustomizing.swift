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
    import SwiftUI
#endif
import Foundation

/// A protocol that allows customization of container templates.
///
/// Implement this protocol to provide custom styling and behavior for different container template types.
/// The protocol provides default implementations, so you only need to implement the method for the
/// specific template type you're using.
///
/// **Note:** Each container API call (`getContentCardContainerUI`) returns only one template type.
/// You typically only need to implement the customize method for that specific type.
///
/// Example:
/// ```swift
/// class MyContainerCustomizer: ContainerCustomizing {
///     func customize(template: InboxContainerTemplate) {
///         // Set custom header view
///         template.setCustomHeaderView { heading in
///             HStack {
///                 Image(systemName: "envelope.fill")
///                 Text(heading).font(.headline)
///             }
///             .padding()
///         }
///         
///         // Set custom background
///         template.backgroundColor = .blue
///     }
/// }
/// ```
@available(iOS 15.0, *)
public protocol ContainerCustomizing {
    /// Customize an inbox container template.
    /// 
    /// Use this method to customize containers with inbox layout (vertical scrolling list with unread indicators).
    /// You can customize the header view using `template.setCustomHeaderView()`, background color, and other properties.
    ///
    /// - Parameter template: The inbox container template to customize
    func customize(template: InboxContainerTemplate)
    
    /// Customize a carousel container template.
    /// 
    /// Use this method to customize containers with carousel layout (horizontal scrolling).
    /// You can customize the header view using `template.setCustomHeaderView()`, background color, and other properties.
    ///
    /// - Parameter template: The carousel container template to customize
    func customize(template: CarouselContainerTemplate)
    
    /// Customize a custom container template.
    /// 
    /// Use this method to customize containers with custom layout (configurable orientation and spacing).
    /// You can customize the header view using `template.setCustomHeaderView()`, background color, and other properties.
    ///
    /// - Parameter template: The custom container template to customize
    func customize(template: CustomContainerTemplate)
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
}
