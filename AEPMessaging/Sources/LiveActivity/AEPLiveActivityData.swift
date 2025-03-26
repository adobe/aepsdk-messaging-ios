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

/// AEPLiveActivityData is a struct that contains the necessary AEP data to track a Live Activity.
/// - Note: This struct is available on iOS 16.1 and above.
@available(iOS 16.1, *)
public struct AEPLiveActivityData: Codable {
    /// Unique identifier for identifying the Live Activity in the Adobe Experience Platform.
    var liveActivityID: String?

    /// Creates an AEPLiveActivityData instance with the given live activity ID.
    ///
    /// - Parameter liveActivityID: The unique identifier for the Live Activity.
    /// - Returns: An AEPLiveActivityData instance.
    static func create(liveActivityID: String) -> AEPLiveActivityData {
        AEPLiveActivityData(liveActivityID: liveActivityID)
    }
}
