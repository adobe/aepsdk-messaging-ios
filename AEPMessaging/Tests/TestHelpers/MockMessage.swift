/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

@testable import AEPMessaging
@testable import AEPServices
import Foundation

class MockMessage: Message {
    static func getInAppMessage(parent: Messaging, triggeringEvent: Event) -> MockMessage {
        let mockPropositionItemData = JSONFileLoader.getRulesJsonFromFile("mockPropositionItem")
        let mockPropositionItem = PropositionItem(itemId: "itemId", schema: .inapp, itemData: mockPropositionItemData)
        let message = Message.fromPropositionItem(mockPropositionItem, with: parent, triggeringEvent: triggeringEvent)
        return message as! MockMessage
    }
    
    var onDismissCalled = false
    var paramOnDismissMessage: FullscreenMessage?
    override func onDismiss(message: FullscreenMessage) {
        onDismissCalled = true
        paramOnDismissMessage = message
    }

    var dismissCalled = false
    var paramDismissSuppressAutoTrack = false
    override func dismiss(suppressAutoTrack: Bool = false) {
        dismissCalled = true
        paramDismissSuppressAutoTrack = suppressAutoTrack
    }

    var trackCalled = false
    var paramTrackInteraction: String?
    var paramTrackEventType: MessagingEdgeEventType?
    override func track(_ interaction: String?, withEdgeEventType eventType: MessagingEdgeEventType) {
        trackCalled = true
        paramTrackInteraction = interaction
        paramTrackEventType = eventType
    }

    var overrideUrlLoadReturnValue = false
    override func overrideUrlLoad(message _: FullscreenMessage, url _: String?) -> Bool {
        overrideUrlLoadReturnValue
    }
    
    var onShowCalled = false
    var paramOnShow: FullscreenMessage?
    override func onShow(message: FullscreenMessage) {
        onShowCalled = true
        paramOnShow = message
    }
}
