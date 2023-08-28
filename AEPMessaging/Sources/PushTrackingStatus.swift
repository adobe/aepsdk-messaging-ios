/*
 Copyright 2023 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

/// Represents a specific outcome resulting from tracking push notification interaction
@objc(AEPPushTrackingStatus)
public enum PushTrackingStatus: Int {
    case trackingInitiated
    case noDatasetConfigured
    case noTrackingData
    case invalidMessageId
    case unknownError

    /// Converts an `Int` to its respective `MessagingPushTrackingStatus`
    /// If `fromRawValue` is not a valid `MessagingPushTrackingStatus`, calling this method will return `PlacesQueryResponseCode.unknownError`
    /// - Parameter fromRawValue: an `Int` representation of a `MessagingPushTrackingStatus`
    /// - Returns: a `MessagingPushTrackingStatus` representing the passed-in `Int`
    init(fromRawValue: Int) {
        self = PushTrackingStatus(rawValue: fromRawValue) ?? .unknownError
    }

    /// Returns the string description of the error    
    public func toString() -> String {
        switch self {
        case .trackingInitiated:
            return "Tracking initiated"
        case .noDatasetConfigured:
            return "No dataset configured"
        case .noTrackingData:
            return "Missing tracking data in Notification Response"
        case .invalidMessageId:
            return "MessageId provided for tracking is empty/null"
        case .unknownError:
            return "Unknown error"
        }
    }
}
