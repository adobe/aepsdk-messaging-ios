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
import AEPServices

/// Represents the schema data object for container settings based on the exact JSON schema
@objc(AEPContainerSchemaData)
@objcMembers
@available(iOS 15.0, *)
public class ContainerSchemaData: NSObject, Codable {
    /// Heading content for the container
    public var heading: Heading?
    
    /// Layout configuration including orientation
    public let layout: LayoutSettings
    
    /// Maximum capacity of items in the container
    public let capacity: Int
    
    /// Empty state configuration when no content is available
    public let emptyStateSettings: EmptyStateSettings?
    
    /// Unread indicator configuration
    public let unreadIndicator: UnreadIndicatorSettings?
    
    /// Whether unread functionality is enabled
    public let isUnreadEnabled: Bool
    
    /// Reference to the parent proposition item for tracking purposes
    weak var parent: PropositionItem?
    
    enum CodingKeys: String, CodingKey {
        case heading
        case layout
        case capacity
        case emptyStateSettings
        case unreadIndicator = "unread_indicator"
        case isUnreadEnabled
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        heading = try? container.decode(Heading.self, forKey: .heading)
        layout = try container.decode(LayoutSettings.self, forKey: .layout)
        capacity = try container.decode(Int.self, forKey: .capacity)
        emptyStateSettings = try? container.decode(EmptyStateSettings.self, forKey: .emptyStateSettings)
        unreadIndicator = try? container.decode(UnreadIndicatorSettings.self, forKey: .unreadIndicator)
        isUnreadEnabled = try container.decodeIfPresent(Bool.self, forKey: .isUnreadEnabled) ?? false
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(heading, forKey: .heading)
        try container.encode(layout, forKey: .layout)
        try container.encode(capacity, forKey: .capacity)
        try container.encodeIfPresent(emptyStateSettings, forKey: .emptyStateSettings)
        try container.encodeIfPresent(unreadIndicator, forKey: .unreadIndicator)
        try container.encode(isUnreadEnabled, forKey: .isUnreadEnabled)
    }
    
    /// Determines the appropriate container template type based on settings
    @available(iOS 15.0, *)
    public var templateType: ContainerTemplateType {
        switch (layout.orientation, isUnreadEnabled) {
        case (.vertical, true):
            return .inbox
        case (.horizontal, false):
            return .carousel
        default:
            return .custom
        }
    }
}

// MARK: - Container Settings Tracking
@available(iOS 15.0, *)
public extension ContainerSchemaData {
    /// Tracks interaction with the given container settings schema data object.
    ///
    /// - Parameters
    ///     - interaction: a custom string value describing the interaction.
    ///     - eventType: an enum specifying event type for the interaction.
    func track(_ interaction: String? = nil, withEdgeEventType eventType: MessagingEdgeEventType) {
        guard let parent = parent else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Unable to track ContainerSchemaData, parent proposition item is unavailable.")
            return
        }
        parent.track(interaction, withEdgeEventType: eventType)
    }
}
