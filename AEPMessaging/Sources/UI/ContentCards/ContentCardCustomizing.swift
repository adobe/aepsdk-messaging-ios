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

/// Protocol for customizing Content Card templates
@available(iOS 15.0, *)
public protocol ContentCardCustomizing {
    /// Implement this function to customize content cards with SmallImageTemplate
    func customize(template: SmallImageTemplate)

    /// Implement this function to customize content cards with LargeImageTemplate
    func customize(template: LargeImageTemplate)

    /// Implement this function to customize content cards with ImageOnlyTemplate
    func customize(template: ImageOnlyTemplate)
}

/// Provide default empty implementations for the ContentCardCustomizing protocol methods so conformers can choose to implement only the ones they need.
@available(iOS 15.0, *)
public extension ContentCardCustomizing {
    func customize(template: SmallImageTemplate) {}
    func customize(template: LargeImageTemplate) {}
    func customize(template: ImageOnlyTemplate) {}
}
