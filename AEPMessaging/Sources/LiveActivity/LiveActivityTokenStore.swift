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

/// Actor that manages and stores Live Activity push-to-start tokens in a thread-safe way.
@available(iOS 13.0, *)
actor LiveActivityTokenStore {
    /// A dictionary storing push-to-start tokens associated with their corresponding ``LiveActivityAttributes`` type name.
    private var tokens: [String: String] = [:]

    /// Updates the push-to-start token for the given ``LiveActivityAttributes`` type name associated with the Live Activity.
    ///
    /// - Parameters:
    ///   - attributeTypeName: A unique string identifier representing the ``LiveActivityAttributes`` type associated with the Live Activity.
    ///   - token: The new push-to-start token to store.
    /// - Returns: `true` if the token was updated, `false` if the token was already set to the given value.
    func updatePushToken(for attributeTypeName: String, token: String) -> Bool {
        tokens.updateValue(token, forKey: attributeTypeName) != token
    }

    /// Retrieves the push token associated with the given ``LiveActivityAttributes`` type name.
    ///
    /// - Parameter attributeTypeName: The ``LiveActivityAttributes`` type name for which to retrieve the push-to-start token.
    /// - Returns: The push-to-start token if it exists, or `nil` if not found.
    func pushToken(for attributeTypeName: String) -> String? {
        tokens[attributeTypeName]
    }

    /// Removes all stored push-to-start tokens.
    func removeAll() {
        tokens.removeAll()
    }
}
