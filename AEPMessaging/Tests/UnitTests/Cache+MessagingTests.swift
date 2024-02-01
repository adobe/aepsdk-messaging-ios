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

import Foundation
import XCTest

@testable import AEPMessaging
import AEPServices
import AEPTestUtils

class CacheMessagingTests: XCTestCase {
    let mockCache = MockCache(name: "mockCache")
    var mockSurface: MockSurface!
    
    var mockProposition: MessagingProposition!
    var mockPropositionItem: MessagingPropositionItem!
    let mockId = "6ac78390-84e3-4d35-b798-8e7080e69a67"
        
    override func setUp() {
        let propositionContent = JSONFileLoader.getRulesJsonFromFile("inappPropositionV2Content")
        mockPropositionItem = MessagingPropositionItem(itemId: "inapp2", schema: .ruleset, itemData: propositionContent)
        mockProposition = MessagingProposition(uniqueId: "inapp2", scope: "inapp2", scopeDetails: ["key": "value"], items: [mockPropositionItem])
        mockSurface = MockSurface(uri: "inapp2")
    }
        
    func getPropositionCacheEntry(_ seededPropositions: [String: [MessagingProposition]]? = nil) -> CacheEntry? {
        let seededPropositions = seededPropositions ?? [
            mockSurface.uri: [mockProposition]
        ]
        
        let encoder = JSONEncoder()
        guard let cacheData = try? encoder.encode(seededPropositions) else {
            return nil
        }
        
        return CacheEntry(data: cacheData, expiry: .never, metadata: nil)
    }
    
    func testPropositionsHappy() throws {
        // setup
        mockCache.getReturnValue = getPropositionCacheEntry()
        
        // test
        let result = mockCache.propositions
        
        // verify
        XCTAssertNotNil(result)
        XCTAssertEqual(1, result?.count)
        let propForSurface = result?[mockSurface]
        XCTAssertNotNil(propForSurface)
        let firstProp = propForSurface?.first
        XCTAssertNotNil(firstProp)
        XCTAssertEqual("inapp2", firstProp?.uniqueId)
        XCTAssertEqual("inapp2", firstProp?.scope)
        XCTAssertEqual("value", firstProp?.scopeDetails["key"] as? String)
        XCTAssertEqual(1, firstProp?.items.count)
        let propItem = firstProp?.items.first
        XCTAssertEqual("inapp2", propItem?.itemId)
        XCTAssertEqual(.ruleset, propItem?.schema)
        XCTAssertNotNil(propItem?.itemData)
        XCTAssertEqual(2, propItem?.itemData?.count)
        XCTAssertNotNil(propItem?.itemData?["rules"])
        XCTAssertNotNil(propItem?.itemData?["version"])
    }
    
    func testPropositionsNoneInCache() throws {
        // setup
        mockCache.getReturnValue = nil
        
        // test
        let result = mockCache.propositions
        
        // verify
        XCTAssertNil(result)
    }
    
    func testPropositionsCachedItemsAreNotDecodable() throws {
        // setup
        mockCache.getReturnValue = CacheEntry(data: "i am not valid propositions".data(using: .utf8)!, expiry: .never, metadata: nil)
        
        // test
        let result = mockCache.propositions
        
        // verify
        XCTAssertNil(result)
    }
    
    func testUpdatePropositionsHappy() throws {
        // setup
        let newSurface = Surface(uri: "newSurface")
        let newPropositionContent = JSONFileLoader.getRulesJsonFromFile("inappPropositionV2Content")
        let newPropositionItem = MessagingPropositionItem(itemId: "inapp4", schema: .ruleset, itemData: newPropositionContent)
        let newProposition = MessagingProposition(uniqueId: "inapp4", scope: "inapp4", scopeDetails: ["key": "value"], items: [newPropositionItem])
        let newProps: [Surface: [MessagingProposition]] = [
            newSurface: [newProposition]
        ]
        
        // test
        mockCache.updatePropositions(newProps)
        
        // verify
        XCTAssertTrue(mockCache.setCalled)
        XCTAssertEqual("propositions", mockCache.setParamKey)
        guard let setParamCache = mockCache.setParamEntry else {
            XCTFail("no cache parameter in 'set' call")
            return
        }
        let decoder = JSONDecoder()
        guard let decodedSetParam = try? decoder.decode([String: [MessagingProposition]].self, from: setParamCache.data) else {
            XCTFail("failed to decode cache parameter sent during 'set' call")
            return
        }
        XCTAssertEqual(1, decodedSetParam.count)
        let paramProp = decodedSetParam["newSurface"]?.first
        XCTAssertEqual("inapp4", paramProp?.uniqueId)
        XCTAssertEqual("inapp4", paramProp?.scope)
        XCTAssertEqual(1, paramProp?.items.count)
    }
    
    func testUpdatePropositionsExistingPropositions() throws {
        // setup
        mockCache.getReturnValue = getPropositionCacheEntry()
        let newSurface = Surface(uri: "newSurface")
        let newPropositionContent = JSONFileLoader.getRulesJsonFromFile("inappPropositionV2Content")
        let newPropositionItem = MessagingPropositionItem(itemId: "inapp4", schema: .ruleset, itemData: newPropositionContent)
        let newProposition = MessagingProposition(uniqueId: "inapp4", scope: "inapp4", scopeDetails: ["key": "value"], items: [newPropositionItem])
        let newProps: [Surface: [MessagingProposition]] = [
            newSurface: [newProposition]
        ]
        
        // test
        mockCache.updatePropositions(newProps)
        
        // verify
        XCTAssertTrue(mockCache.setCalled)
        XCTAssertEqual("propositions", mockCache.setParamKey)
        guard let setParamCache = mockCache.setParamEntry else {
            XCTFail("no cache parameter in 'set' call")
            return
        }
        let decoder = JSONDecoder()
        guard let decodedSetParam = try? decoder.decode([String: [MessagingProposition]].self, from: setParamCache.data) else {
            XCTFail("failed to decode cache parameter sent during 'set' call")
            return
        }
        XCTAssertEqual(2, decodedSetParam.count)
    }
    
    func testUpdatePropositionsRemovingSurfaces() throws {
        // setup
        mockCache.getReturnValue = getPropositionCacheEntry()
        let newSurface = Surface(uri: "newSurface")
        let newPropositionContent = JSONFileLoader.getRulesJsonFromFile("inappPropositionV2Content")
        let newPropositionItem = MessagingPropositionItem(itemId: "inapp4", schema: .ruleset, itemData: newPropositionContent)
        let newProposition = MessagingProposition(uniqueId: "inapp4", scope: "inapp4", scopeDetails: ["key": "value"], items: [newPropositionItem])
        let newProps: [Surface: [MessagingProposition]] = [
            newSurface: [newProposition]
        ]
        
        // test
        mockCache.updatePropositions(newProps, removing: [mockSurface])
        
        // verify
        XCTAssertTrue(mockCache.setCalled)
        XCTAssertEqual("propositions", mockCache.setParamKey)
        guard let setParamCache = mockCache.setParamEntry else {
            XCTFail("no cache parameter in 'set' call")
            return
        }
        let decoder = JSONDecoder()
        guard let decodedSetParam = try? decoder.decode([String: [MessagingProposition]].self, from: setParamCache.data) else {
            XCTFail("failed to decode cache parameter sent during 'set' call")
            return
        }
        XCTAssertEqual(1, decodedSetParam.count)
        let paramProp = decodedSetParam["newSurface"]?.first
        XCTAssertEqual("inapp4", paramProp?.uniqueId)
        XCTAssertEqual("inapp4", paramProp?.scope)
        XCTAssertEqual(1, paramProp?.items.count)
    }
}
