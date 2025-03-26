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

// Extension for Messaging class for Live Activity public APIs
@available(iOS 16.1, *)
public extension Messaging {
    /// Registers a Live Activity type with the Adobe Experience Platform SDK.
    ///
    /// When called, this method enables the SDK to:
    /// - Track push-to-start tokens automatically for devices running iOS 17.2 or later
    /// - Monitor the complete lifecycle of Live Activities including:
    ///   - Activity token generation
    ///   - State transitions (start, update, end)
    ///   - Event tracking for the registered activity type
    ///
    /// - Parameter type: The Live Activity type that conforms to the `AEPLiveActivityAttributes` protocol.
    ///                   This type defines the structure and content of your Live Activity.
    static func registerLiveActivity<T: AEPLiveActivityAttributes>(_: T.Type) {
        if #available(iOS 17.2, *) {
            // register to track push-to-start token
        }

        // register to track activity updates
    }
}
