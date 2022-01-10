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

import Foundation
import XCTest
import AEPCore
@testable import AEPMessaging
@testable import AEPServices

class MessagingRulesEngineCachingTests: XCTestCase {
    var messagingRulesEngine: MessagingRulesEngine!
    var mockRulesEngine: MockLaunchRulesEngine!
    var mockRuntime: TestableExtensionRuntime!
    var mockCache: MockCache!
    
    override func setUp() {
        mockRuntime = TestableExtensionRuntime()
        mockRulesEngine = MockLaunchRulesEngine(name: "mockRulesEngine", extensionRuntime: mockRuntime)
        mockCache = MockCache(name: "mockCache")
        messagingRulesEngine = MessagingRulesEngine(extensionRuntime: mockRuntime, rulesEngine: mockRulesEngine, cache: mockCache)
    }
    
    func testLoadCachedMessagesHappy() throws {
        // setup
        let aJsonString = JSONFileLoader.getRulesStringFromFile("showOnceRule")
        let cacheEntry = CacheEntry(data: aJsonString.data(using: .utf8)!, expiry: .never, metadata: nil)
        mockCache.getReturnValue = cacheEntry
        
        // test
        messagingRulesEngine.loadCachedMessages()
        
        // verify
        XCTAssertTrue(mockCache.getCalled)
        XCTAssertEqual("messages", mockCache.getParamKey)
        XCTAssertTrue(mockRulesEngine.replaceRulesCalled)
        XCTAssertEqual(1, mockRulesEngine.paramRules?.count)
    }
    
    func testLoadCachedMessagesNoCacheFound() throws {
        // setup
        mockCache.getReturnValue = nil
        
        // test
        messagingRulesEngine.loadCachedMessages()
        
        // verify
        XCTAssertTrue(mockCache.getCalled)
        XCTAssertEqual("messages", mockCache.getParamKey)
        XCTAssertFalse(mockRulesEngine.replaceRulesCalled)
    }
    
    /// The below tests for private func `cacheMessages` are executed via
    /// internal methods `setMessagingCache` and `clearMessagingCache`
    func testCacheMessagesClearCache() throws {
        // test
        messagingRulesEngine.clearMessagingCache()
        
        // verify
        XCTAssertTrue(mockCache.removeCalled)
        XCTAssertEqual("messages", mockCache.removeParamKey)
    }
    
    func testCacheMessagesClearCacheThrows() throws {
        // setup
        mockCache.removeShouldThrow = true
        
        // test
        messagingRulesEngine.clearMessagingCache()
        
        // verify
        XCTAssertTrue(mockCache.removeCalled)
        XCTAssertEqual("messages", mockCache.removeParamKey)
    }
    
    func testCacheMessagesSetCache() throws {
        // setup
        let messages = [JSONFileLoader.getRulesStringFromFile("showOnceRule")]
        
        // test
        messagingRulesEngine.setMessagingCache(messages)
        
        // verify
        XCTAssertTrue(mockCache.setCalled)
        XCTAssertEqual("messages", mockCache.setParamKey)
        XCTAssertNotNil(mockCache.setParamEntry)
        let cacheEntryData = mockCache.setParamEntry!.data
        let cacheString = String(data: cacheEntryData, encoding: .utf8)?.components(separatedBy: "||")
        XCTAssertEqual(messages, cacheString)
    }
    
    func testCacheMessagesSetCacheThrows() throws {
        // setup
        let messages = [JSONFileLoader.getRulesStringFromFile("showOnceRule")]
        mockCache.setShouldThrow = true
        
        // test
        messagingRulesEngine.setMessagingCache(messages)
        
        // verify
        XCTAssertTrue(mockCache.setCalled)
        XCTAssertEqual("messages", mockCache.setParamKey)
        XCTAssertNotNil(mockCache.setParamEntry)
        let cacheEntryData = mockCache.setParamEntry!.data
        let cacheString = String(data: cacheEntryData, encoding: .utf8)?.components(separatedBy: "||")
        XCTAssertEqual(messages, cacheString)
    }
}
