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

@available(iOS 15.0, *)
protocol TemplateEventHandler: AnyObject {
    /// Called when the templated content card appears on the screen
    func onDisplay()

    /// Called when the dismiss button is tapped on templated content card
    func onDismiss()

    /// Called when the user interacts with the templated content card.
    /// - Parameters:
    ///   - interactionId: A string identifier for the specific interaction event.
    ///   - actionURL: An optional URL associated with the interaction.
    func onInteract(interactionId: String, actionURL: URL?)
}
