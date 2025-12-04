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
    
    
    public enum ContainerOrientation: String, CaseIterable {
        case horizontal = "horizontal"
        case vertical = "vertical"
        case unknown = "unknown"
        
        init(from string: String) {
            self = ContainerOrientation(rawValue: string) ?? .unknown
        }
    }

}
