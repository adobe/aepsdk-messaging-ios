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
    func onLoading(_ inbox: InboxUI)
    func onLoaded(_ inbox: InboxUI)
    func onError(_ inbox: InboxUI, _ error: Error)
    func onEmpty(_ inbox: InboxUI)
    func onCardDismissed(_ card: ContentCardUI)
    func onCardDisplayed(_ card: ContentCardUI)
    func onCardInteracted(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool
    func onCardCreated(_ card: ContentCardUI)
}
