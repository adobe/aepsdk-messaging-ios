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

/// A protocol defining event handling methods for container templates.
///
/// Conforming objects can respond to various container-related events such as
/// display events and user interactions with the container itself.
@available(iOS 15.0, *)
protocol ContainerTemplateEventHandler: AnyObject {
    /// Called when the container template is displayed to the user.
    func onContainerDisplay()
    
    /// Called when the user interacts with the container (but not individual content cards).
    /// - Parameter interactionId: A unique identifier for the type of interaction
    func onContainerInteract(interactionId: String)
}
