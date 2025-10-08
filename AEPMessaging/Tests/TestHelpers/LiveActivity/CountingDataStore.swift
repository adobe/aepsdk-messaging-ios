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

@testable import AEPTestUtils

/// A test helper subclass of `MockDataStore` that counts the number of times
/// the `get(collectionName:key:)` method is called.
class CountingDataStore: MockDataStore {
    /// The number of times `get(collectionName:key:)` has been called.
    private(set) var getCalls = 0

    /// Overrides the base method in order to increment the `getCalls` counter each time
    /// the datastore is accessed for a value.
    ///
    /// - Parameters:
    ///   - collectionName: The name of the collection being accessed.
    ///   - key: The key within the collection.
    /// - Returns: The value associated with the given key, or `nil` if not found.
    override func get(collectionName: String, key: String) -> Any? {
        getCalls += 1
        return super.get(collectionName: collectionName, key: key)
    }
}
