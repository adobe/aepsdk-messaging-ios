/*
 Copyright 2025 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

// Extension for Messaging class for Live Activity public APIs
import AEPMessagingLiveActivity

@available(iOS 16.1, *)
public extension Messaging {
    /// Registers a Live Activity type with the Adobe Experience Platform SDK.
    ///
    /// When called, this method enables the SDK to:
    /// - Automatically collect push-to-start tokens for devices running iOS 17.2 or later
    /// - Manage the complete lifecycle of Live Activities including:
    ///   - Automatically collect the generated Live Activity update token
    ///   - Monitor state transitions (start, update, end)
    ///   - Event tracking for the registered activity type
    ///
    /// - Parameter type: The Live Activity type that conforms to the `LiveActivityAttributes` protocol.
    ///                   This type defines the structure and content of your Live Activity.
    static func registerLiveActivity<T: LiveActivityAttributes>(_: T.Type) {
        if #available(iOS 17.2, *) {
            // register to track push-to-start token
        }

        // register to track activity updates
    }
}
