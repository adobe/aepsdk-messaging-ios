/*
 Copyright 2020 Adobe. All rights reserved.

 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

internal struct PushNotificationTracking {
    public init() {}

    public var customAction: CustomAction?
    public var pushProviderMessageID: String?
    public var pushProvider: String?

    enum CodingKeys: String, CodingKey {
        case customAction
        case pushProviderMessageID
        case pushProvider
    }
}

extension PushNotificationTracking: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let unwrapped = customAction { try container.encode(unwrapped, forKey: .customAction) }
        if let unwrapped = pushProviderMessageID { try container.encode(unwrapped, forKey: .pushProviderMessageID) }
        if let unwrapped = pushProvider { try container.encode(unwrapped, forKey: .pushProvider) }
    }
}
