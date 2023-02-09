/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

@testable import AEPServices
import Foundation
import XCTest

class MockCache: Cache {
    var getCalled = false
    var getParamKey: String?
    var getReturnValue: CacheEntry?
    override func get(key: String) -> CacheEntry? {
        getCalled = true
        getParamKey = key
        return getReturnValue
    }

    var removeCalled = false
    var removeParamKey: String?
    var removeShouldThrow = false
    override func remove(key: String) throws {
        removeCalled = true
        removeParamKey = key
        if removeShouldThrow {
            throw MockCacheError.mockThrow
        }
    }

    var setCalled = false
    var setCalledExpectation: XCTestExpectation?
    var setParamKey: String?
    var setParamEntry: CacheEntry?
    var setShouldThrow = false
    override func set(key: String, entry: CacheEntry) throws {
        setCalled = true
        setParamKey = key
        setParamEntry = entry
        if setShouldThrow {
            throw MockCacheError.mockThrow
        }
        if let expectation = setCalledExpectation {
            expectation.fulfill()
        }
    }
}

enum MockCacheError: Error {
    case mockThrow
}
