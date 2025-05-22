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

class MockNamedKeyValueService: NamedCollectionProcessing {
    func setAppGroup(_ appGroup: String?) {
        // no-op
    }

    func getAppGroup() -> String? {
        // no-op
        return nil
    }

    var getCalled = false
    var getCollectionName: String?
    var getKey: String?
    var mockValue: Any?

    var setCalled = false
    var setCollectionName: String?
    var setKey: String?
    var setValue: Any?

    var removeCalled = false
    var removeCollectionName: String?
    var removeKey: String?

    func set(collectionName: String, key: String, value: Any?) {
        setCalled = true
        setCollectionName = collectionName
        setKey = key
        setValue = value
    }

    func get(collectionName: String, key: String) -> Any? {
        getCalled = true
        getCollectionName = collectionName
        getKey = key
        return mockValue
    }

    func remove(collectionName: String, key: String) {
        removeCalled = true
        removeCollectionName = collectionName
        removeKey = key
    }
}
