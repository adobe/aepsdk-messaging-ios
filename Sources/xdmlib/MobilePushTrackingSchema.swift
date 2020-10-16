/*
 Copyright 2020 Adobe. All rights reserved.

 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.

 ----
 XDM Schema Swift Object Generated 2020-06-18 09:41:36.003857 -0700 PDT m=+2.658142707 by XDMTool

 Title			:	Mobile Push Tracking Schema Test
 Version		:	1.1
 Description	:
 Alt ID			:	_acopprod3.schemas.85b5dd380a615a51d4636b23c9b5bfeea0b1ae5514b0869d
 Type			:	schemas
 IMS Org		:	FAF554945B90342F0A495E2C@AdobeOrg
 ----
 */

import AEPEdge
import Foundation

struct MobilePushTrackingSchema: XDMSchema {
    public let schemaVersion = "1.1"
    public let schemaIdentifier = ""
    public let datasetIdentifier = ""

    public init() {}

    public var pushNotificationTracking: PushNotificationTracking?
    public var eventMergeId: String?
    public var eventType: String?
    public var identityMap: IdentityMap?
    public var timestamp: Date?

    enum CodingKeys: String, CodingKey {
        case pushNotificationTracking = "pushNotificationTracking"
        case eventMergeId = "eventMergeId"
        case eventType = "eventType"
        case identityMap = "identityMap"
        case timestamp = "timestamp"
    }
}

extension MobilePushTrackingSchema {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let unwrapped = pushNotificationTracking { try container.encode(unwrapped, forKey: .pushNotificationTracking) }
        if let unwrapped = eventMergeId { try container.encode(unwrapped, forKey: .eventMergeId) }
        if let unwrapped = eventType { try container.encode(unwrapped, forKey: .eventType) }
        if let unwrapped = identityMap { try container.encode(unwrapped, forKey: .identityMap) }
        if let unwrapped = XDMFormatters.dateToISO8601String(from: timestamp) { try container.encode(unwrapped, forKey: .timestamp) }
    }
}
