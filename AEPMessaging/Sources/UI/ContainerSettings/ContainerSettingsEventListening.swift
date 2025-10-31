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

// MARK: - Container Event Listening Protocol

/// Protocol for listening to container-level events
@available(iOS 15.0, *)
public protocol ContainerSettingsEventListening {
    func onLoading(_ container: ContainerUI)
    func onLoaded(_ container: ContainerUI)
    func onError(_ container: ContainerUI, _ error: Error)
    func onEmpty(_ container: ContainerUI)
    func onCardDismissed(_ card: ContentCardUI)
    func onCardDisplayed(_ card: ContentCardUI)
    func onCardInteracted(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool
    func onCardCreated(_ card: ContentCardUI)
}

// MARK: - Default Implementation

@available(iOS 15.0, *)
public extension ContainerSettingsEventListening {
    func onLoading(_ container: ContainerUI) {}
    func onLoaded(_ container: ContainerUI) {}
    func onError(_ container: ContainerUI, _ error: Error) {}
    func onEmpty(_ container: ContainerUI) {}
    func onCardDismissed(_ card: ContentCardUI) {}
    func onCardDisplayed(_ card: ContentCardUI) {}
    func onCardInteracted(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool { false }
    func onCardCreated(_ card: ContentCardUI) {}
}
