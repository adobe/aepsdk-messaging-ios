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
    case pushApplicationOpened = 4
    case pushCustomAction = 5
    case dismiss = 6
    case interact = 7
    case trigger = 8
    case display = 9
    case disqualify = 10

    public func toString() -> String {
        switch self {
        case .dismiss:
            return MessagingConstants.XDM.Inbound.EventType.DISMISS
        case .trigger:
            return MessagingConstants.XDM.Inbound.EventType.TRIGGER
        case .interact:
            return MessagingConstants.XDM.Inbound.EventType.INTERACT
        case .display:
            return MessagingConstants.XDM.Inbound.EventType.DISPLAY
        case .disqualify:
            return MessagingConstants.XDM.Inbound.EventType.DISQUALIFY
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
        case MessagingConstants.XDM.Inbound.EventType.DISQUALIFY:
            self = .disqualify
        case MessagingConstants.XDM.Push.EventType.CUSTOM_ACTION:
            self = .pushCustomAction
        case MessagingConstants.XDM.Push.EventType.APPLICATION_OPENED:
            self = .pushApplicationOpened
        default:
            return nil
        }
    }
    
    /// Initializes `MessagingEdgeEventType` with the provided `decisioning.propositionEventType` value
    /// - Parameter type: Event type string
    init?(fromPropositionEventType type: String) {
        switch type {
        case MessagingConstants.XDM.Inbound.PropositionEventType.DISMISS:
            self = .dismiss
        case MessagingConstants.XDM.Inbound.PropositionEventType.TRIGGER:
            self = .trigger
        case MessagingConstants.XDM.Inbound.PropositionEventType.INTERACT:
            self = .interact
        case MessagingConstants.XDM.Inbound.PropositionEventType.DISPLAY:
            self = .display
        case MessagingConstants.XDM.Inbound.PropositionEventType.DISQUALIFY:
            self = .disqualify
        default:
            return nil
        }
    }
}

extension MessagingEdgeEventType {
    /// Used to generate `propositionEventType` payload in outgoing proposition interaction events
    var propositionEventType: String {
        switch self {
        case .dismiss:
            return MessagingConstants.XDM.Inbound.PropositionEventType.DISMISS
        case .interact:
            return MessagingConstants.XDM.Inbound.PropositionEventType.INTERACT
        case .trigger:
            return MessagingConstants.XDM.Inbound.PropositionEventType.TRIGGER
        case .display:
            return MessagingConstants.XDM.Inbound.PropositionEventType.DISPLAY
        case .disqualify:
            return MessagingConstants.XDM.Inbound.PropositionEventType.DISQUALIFY
        case .pushApplicationOpened, .pushCustomAction:
            return ""
        }
    }
}
