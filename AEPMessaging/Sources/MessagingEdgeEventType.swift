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

import Foundation

/// Provides mapping to XDM EventType strings needed for Experience Event requests
@objc(AEPMessagingEdgeEventType)
public enum MessagingEdgeEventType: Int {
    @available(*, deprecated, message: "Use 'dismiss' instead.")
    case inappDismiss = 0
    @available(*, deprecated, message: "Use 'interact' instead.")
    case inappInteract = 1
    @available(*, deprecated, message: "Use 'trigger' instead.")
    case inappTrigger = 2
    @available(*, deprecated, message: "Use 'display' instead.")
    case inappDisplay = 3
    case pushApplicationOpened = 4
    case pushCustomAction = 5
    case dismiss = 6
    case interact = 7
    case trigger = 8
    case display = 9

    public func toString() -> String {
        switch self {
        case .inappDismiss, .dismiss:
            return MessagingConstants.XDM.Inbound.EventType.DISMISS
        case .inappTrigger, .trigger:
            return MessagingConstants.XDM.Inbound.EventType.TRIGGER
        case .inappInteract, .interact:
            return MessagingConstants.XDM.Inbound.EventType.INTERACT
        case .inappDisplay, .display:
            return MessagingConstants.XDM.Inbound.EventType.DISPLAY
        case .pushCustomAction:
            return MessagingConstants.XDM.Push.EventType.CUSTOM_ACTION
        case .pushApplicationOpened:
            return MessagingConstants.XDM.Push.EventType.APPLICATION_OPENED
        }
    }

    /// Initializes `MessagingEdgeEventType` with the provided type string.
    /// - Parameter type: Event type string
    init?(fromType type: String) {
        switch type {
        case MessagingConstants.XDM.Inbound.EventType.DISMISS:
            self = .dismiss
        case MessagingConstants.XDM.Inbound.EventType.TRIGGER:
            self = .trigger
        case MessagingConstants.XDM.Inbound.EventType.INTERACT:
            self = .interact
        case MessagingConstants.XDM.Inbound.EventType.DISPLAY:
            self = .display
        case MessagingConstants.XDM.Push.EventType.CUSTOM_ACTION:
            self = .pushCustomAction
        case MessagingConstants.XDM.Push.EventType.APPLICATION_OPENED:
            self = .pushApplicationOpened
        default:
            return nil
        }
    }
}

extension MessagingEdgeEventType {
    /// Used to generate `propositionEventType` payload in outgoing proposition interaction events
    var propositionEventType: String {
        switch self {
        case .inappDismiss, .dismiss:
            return MessagingConstants.XDM.Inbound.PropositionEventType.DISMISS
        case .inappInteract, .interact:
            return MessagingConstants.XDM.Inbound.PropositionEventType.INTERACT
        case .inappTrigger, .trigger:
            return MessagingConstants.XDM.Inbound.PropositionEventType.TRIGGER
        case .inappDisplay, .display:
            return MessagingConstants.XDM.Inbound.PropositionEventType.DISPLAY
        case .pushApplicationOpened, .pushCustomAction:
            return ""
        }
    }
}
