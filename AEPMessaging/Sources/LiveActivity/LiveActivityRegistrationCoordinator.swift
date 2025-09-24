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

import Foundation

/// Coordinates Live Activity type exclusive registration to prevent concurrent duplicate registrations.
///
/// Guarantees at most one registration body runs at a time for a given `attributeType`.
/// Other callers attempting to register the same type will yield until the in progress
/// registration completes. Different types can register concurrently.
@available(iOS 13.0, *)
actor LiveActivityRegistrationCoordinator {
    private var registeringTypes: Set<String> = []

    /// Runs the provided async `body` under an exclusive per type critical section.
    ///
    /// - Parameters:
    ///   - attributeType: The Live Activity attribute type.
    ///   - body: The async closure that performs registration work for the given type.
    /// - Returns: The value returned by `body` when it completes.
    func withExclusiveRegistration<T>(for attributeType: String, _ body: @escaping @Sendable () async -> T) async -> T {
        // If the type is already in the process of registering, have the task yield until the
        // in progress one is finished
        while registeringTypes.contains(attributeType) {
            await Task.yield()
        }
        registeringTypes.insert(attributeType)
        defer { registeringTypes.remove(attributeType) }
        // Otherwise run the task to register the type, and once finished remove the type from the
        // in progress list
        return await body()
    }
}
