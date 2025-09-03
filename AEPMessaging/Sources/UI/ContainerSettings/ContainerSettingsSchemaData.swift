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
@objc(AEPContainerSettingsSchemaData)
@objcMembers
public class ContainerSettingsSchemaData: NSObject, Codable {
    /// Heading content for the container
    public let heading: Heading?
    
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

/// Represents heading content
public struct Heading: Codable {
    public let content: String
    
    enum CodingKeys: String, CodingKey {
        case content
    }
}

/// Represents layout settings including orientation
public struct LayoutSettings: Codable {
    public let orientation: ContainerOrientation
    
    enum CodingKeys: String, CodingKey {
        case orientation
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let orientationString = try container.decode(String.self, forKey: .orientation)
        orientation = ContainerOrientation(from: orientationString)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(orientation.rawValue, forKey: .orientation)
    }
}

/// Container orientation enum
public enum ContainerOrientation: String, CaseIterable {
    case horizontal = "horizontal"
    case vertical = "vertical"
    case unknown = "unknown"
    
    init(from string: String) {
        self = ContainerOrientation(rawValue: string) ?? .unknown
    }
}

/// Container template type enum based on orientation and unread settings
@available(iOS 15.0, *)
public enum ContainerTemplateType: String, CaseIterable {
    /// Inbox template: vertical scrolling with unread indicator
    case inbox = "Inbox"
    
    /// Carousel template: horizontal scrolling without unread indicator
    case carousel = "Carousel"
    
    /// Custom template: configurable scrolling and unread settings
    case custom = "Custom"
    
    /// Unknown template type
    case unknown = "Unknown"
}

/// Represents empty state settings
public struct EmptyStateSettings: Codable {
    public let message: MessageContent?
    public let image: ImageContent?
    
    enum CodingKeys: String, CodingKey {
        case message
        case image
    }
}

/// Represents message content
public struct MessageContent: Codable {
    public let content: String
    
    enum CodingKeys: String, CodingKey {
        case content
    }
}

/// Represents image content with light and dark mode support
public struct ImageContent: Codable {
    public let url: String?
    public let darkUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case url
        case darkUrl
    }
}

/// Represents unread indicator settings
public struct UnreadIndicatorSettings: Codable {
    public let unreadBackground: UnreadBackgroundSettings?
    public let unreadIcon: UnreadIconSettings?
    
    enum CodingKeys: String, CodingKey {
        case unreadBackground = "unread_bg"
        case unreadIcon = "unread_icon"
    }
}

/// Represents unread background color settings
public struct UnreadBackgroundSettings: Codable {
    public let color: ColorSettings
    
    enum CodingKeys: String, CodingKey {
        case color = "clr"
    }
}

/// Represents color settings for light and dark modes
public struct ColorSettings: Codable {
    public let light: String
    public let dark: String
    
    enum CodingKeys: String, CodingKey {
        case light
        case dark
    }
}

/// Represents unread icon settings
public struct UnreadIconSettings: Codable {
    public let placement: IconPlacement
    public let image: ImageContent
    
    enum CodingKeys: String, CodingKey {
        case placement
        case image
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let placementString = try container.decode(String.self, forKey: .placement)
        placement = IconPlacement(from: placementString)
        image = try container.decode(ImageContent.self, forKey: .image)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(placement.rawValue, forKey: .placement)
        try container.encode(image, forKey: .image)
    }
}

/// Icon placement enum
public enum IconPlacement: String, CaseIterable {
    case topLeft = "topleft"
    case topRight = "topright"
    case bottomLeft = "bottomleft"
    case bottomRight = "bottomright"
    case unknown = "unknown"
    
    init(from string: String) {
        self = IconPlacement(rawValue: string) ?? .unknown
    }
}

// MARK: - Container Settings Tracking

public extension ContainerSettingsSchemaData {
    /// Tracks interaction with the given container settings schema data object.
    ///
    /// - Parameters
    ///     - interaction: a custom string value describing the interaction.
    ///     - eventType: an enum specifying event type for the interaction.
    func track(_ interaction: String? = nil, withEdgeEventType eventType: MessagingEdgeEventType) {
        guard let parent = parent else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Unable to track ContainerSettingsSchemaData, parent proposition item is unavailable.")
            return
        }
        parent.track(interaction, withEdgeEventType: eventType)
    }
}