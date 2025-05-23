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

@testable import AEPMessaging

/// A minimal concrete implementation of `TokenStoreBase` for use in unit tests.
///
/// `MockTokenStore` is intended for testing only. It works with `MockTokenMap` and provides
/// a simple `set(key:value:)` mutator for modifying token values and triggering persistence.
final class MockTokenStore: TokenStoreBase<MockTokenMap> {
    /// Sets the value for a specific key in the token map and persists the change.
    ///
    /// This method updates the in-memory token map, then persists the new state to the
    /// underlying key-value store by assigning to the `_persistedMap` property.
    ///
    /// - Parameters:
    ///   - key: The key to insert or update in the token map.
    ///   - value: The value to associate with the key.
    func set(key: String, value: String) {
        // Update the cached token map, mutate it, and persist the changes
        var map = _persistedMap
        map.values[key] = value
        _persistedMap = map
    }
}
