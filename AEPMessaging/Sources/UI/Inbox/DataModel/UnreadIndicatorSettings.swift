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

/// Represents unread indicator settings
@available(iOS 15.0, *)
public struct UnreadIndicatorSettings: Codable {
    public let unreadBackground: UnreadBackgroundSettings?
    public let unreadIcon: UnreadIconSettings?
    
    enum CodingKeys: String, CodingKey {
        case unreadBackground = "unread_bg"
        case unreadIcon = "unread_icon"
    }
    
    /// Represents unread background color settings
    public struct UnreadBackgroundSettings: Codable {
        public let color: AEPColor
        
        enum CodingKeys: String, CodingKey {
            case color = "clr"
        }
    }
    
    /// Represents unread icon settings
    @available(iOS 15.0, *)
    public struct UnreadIconSettings: Codable {
        public let placement: IconPlacement
        public let image: AEPImage
        
        enum CodingKeys: String, CodingKey {
            case placement
            case image
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let placementString = try container.decode(String.self, forKey: .placement)
            placement = IconPlacement(from: placementString)
            image = try container.decode(AEPImage.self, forKey: .image)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(placement.rawValue, forKey: .placement)
            try container.encode(image, forKey: .image)
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
    }


}
