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

/// A protocol defining the requirements for container templates.
@available(iOS 15.0, *)
public protocol ContainerTemplate: BaseContainerTemplate {
    associatedtype Content: View

    /// The type of the container template.
    var templateType: ContainerTemplateType { get }

    /// The SwiftUI view representing the content of the template.
    var view: Self.Content { get }
}
