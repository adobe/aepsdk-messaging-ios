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

import AEPServices

class MessagingProperties {
    private var _pushIdentifier: String?

    public var pushIdentifier: String? {
        get {
            /// Check if we have a push identifier set. if not, retrieve it from the named key-value service
            if _pushIdentifier == nil {
                _pushIdentifier = ServiceProvider.shared.namedKeyValueService.get(collectionName: MessagingConstants.DATA_STORE_NAME, key: MessagingConstants.NamedCollectionKeys.PUSH_IDENTIFIER) as? String
            }
            return _pushIdentifier
        }

        set {
            /// Set the push identifier value to the local variable
            _pushIdentifier = newValue
            /// Save the new value to the named key-value service
            ServiceProvider.shared.namedKeyValueService.set(collectionName: MessagingConstants.DATA_STORE_NAME, key: MessagingConstants.NamedCollectionKeys.PUSH_IDENTIFIER, value: newValue)
        }
    }
}
