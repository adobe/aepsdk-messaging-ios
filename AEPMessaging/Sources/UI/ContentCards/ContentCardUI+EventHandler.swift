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
import UIKit

@available(iOS 15.0, *)
extension ContentCardUI: TemplateEventHandler {
    /// Called when the templated content card is displayed to the user.
    func onDisplay() {
        proposition.items.first?.contentCardSchemaData?.track(withEdgeEventType: .display)
        listener?.onDisplay(self)
    }

    /// Called when the templated content card is dismissed by the user.
    func onDismiss() {
        proposition.items.first?.contentCardSchemaData?.track(withEdgeEventType: .dismiss)
        listener?.onDismiss(self)
    }

    /// Called when the templated content card is interacted by the user
    func onInteract(interactionId: String, actionURL url: URL?) {
        proposition.items.first?.contentCardSchemaData?.track(interactionId, withEdgeEventType: .interact)
        
        // Automatically mark as read if this content card is tracking read status
        if isRead != nil {
            markAsRead()
        }
        
        let urlHandled = listener?.onInteract(self, interactionId, actionURL: url) ?? false

        // Open the URL if available and not handled by the listener
        if let url = url, !urlHandled {
            UIApplication.shared.open(url)
        }
    }
}
