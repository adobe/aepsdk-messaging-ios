/*
 Copyright 2025 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

// MARK: - Inbox Event Listening Protocol

/// Protocol for listening to inbox-level events
@available(iOS 15.0, *)
public protocol InboxEventListening {
    /// Called when the inbox starts loading content
    func onLoading(_ inbox: InboxUI)
    
    /// Called when the inbox successfully loads content (may be empty or have cards)
    func onSuccess(_ inbox: InboxUI)
    
    /// Called when the inbox encounters an error while loading
    func onError(_ inbox: InboxUI, _ error: Error)
    
    /// Called when a card is dismissed
    func onCardDismissed(_ card: ContentCardUI)
    
    /// Called when a card is displayed
    func onCardDisplayed(_ card: ContentCardUI)
    
    /// Called when a card is interacted with
    func onCardInteracted(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool
    
    /// Called when a card is created
    func onCardCreated(_ card: ContentCardUI)
}
