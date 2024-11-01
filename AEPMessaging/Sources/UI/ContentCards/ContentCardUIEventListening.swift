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
public protocol ContentCardUIEventListening {
    /// Called when the templated content card appears on the screen
    func onDisplay(_ card: ContentCardUI)

    /// Called when the dismiss button is tapped on templated content card
    func onDismiss(_ card: ContentCardUI)

    /// Called when the user interacts with the templated content card.
    /// The boolean return value determines how the interaction is handled:
    /// Return `true` if the client app has handled the actionURL associated with the interaction
    /// Return `false` if the SDK should handle the actionURL.
    ///
    /// - Parameters:
    ///   - card: The ContentCardUI instance that was interacted with.
    ///   - interactionId: A string identifier for the interaction event.
    ///   - actionURL: An optional URL associated with the interaction.
    /// - Returns: A boolean indicating whether the interaction was handled.
    func onInteract(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool
}

/// Public extension of `ContentCardUIEventListening` protocol provides default implementations,
/// making protocol methods optional for implementers.
@available(iOS 15.0, *)
public extension ContentCardUIEventListening {
    func onDisplay(_: ContentCardUI) {}
    func onDismiss(_: ContentCardUI) {}
    func onInteract(_: ContentCardUI, _: String, actionURL _: URL?) -> Bool { false }
}
