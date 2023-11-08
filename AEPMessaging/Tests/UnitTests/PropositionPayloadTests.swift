/*
 Copyright 2022 Adobe. All rights reserved.
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

class PropositionPayloadTests: XCTestCase {
    let mockId = "mockId"
    let mockScope = "mockScope"
    let mockCorrelationId = "mockCorrelationId"
    var mockScopeDetails: [String: AnyCodable]!
    var mockPropositionInfo: PropositionInfo!
    
    let mockDataId = "mockDataId"
    let mockDataContent = "mockDataContent"
    
    let mockItemId = "mockItemId"
    let mockItemSchema: SchemaType = .htmlContent
    var mockPropositionItem: MessagingPropositionItem!
    var mockItems: [MessagingPropositionItem]!
    
    override func setUp() {
        mockScopeDetails = [
            "correlationID": AnyCodable(mockCorrelationId)
        ]
        mockPropositionItem = MessagingPropositionItem(itemId: mockItemId, schema: mockItemSchema, itemData: ["content": mockDataContent])
        
        mockItems = [mockPropositionItem]
    }
    
    func getDecodedPropositionPayload(fromString: String? = nil) -> PropositionPayload? {
        let decoder = JSONDecoder()
        let propositionPayloadString = fromString ??  "{\"id\":\"\(mockId)\",\"scope\":\"\(mockScope)\",\"scopeDetails\":{\"correlationID\":\"\(mockCorrelationId)\"},\"items\":[{\"id\":\"\(mockItemId)\",\"schema\":\"\(mockItemSchema.toString())\",\"data\":{\"id\":\"\(mockDataId)\",\"content\":\"\(mockDataContent)\"}}]}"
 
        let propositionPayloadData = propositionPayloadString.data(using: .utf8)!
        
        guard let propositionPayload = try? decoder.decode(PropositionPayload.self, from: propositionPayloadData) else {
            return nil
        }
        
        return propositionPayload
    }
    
    // MARK: - Happy path
    func testIsDecodable() throws {
        // test
        guard let propositionPayload = getDecodedPropositionPayload() else {
            XCTFail("unable to decode PropositionPayload json")
            return
        }
        
        // verify
        XCTAssertNotNil(propositionPayload)
        XCTAssertEqual(mockId, propositionPayload.propositionInfo.id)
        XCTAssertEqual(mockScope, propositionPayload.propositionInfo.scope)
        XCTAssertEqual(mockScopeDetails, propositionPayload.propositionInfo.scopeDetails)
        XCTAssertEqual(1, propositionPayload.items.count)
        let decodedItem = propositionPayload.items.first!
        XCTAssertEqual(mockItemId, decodedItem.itemId)
        XCTAssertEqual(mockItemSchema, decodedItem.schema)
        XCTAssertEqual(mockDataContent, decodedItem.htmlContent)
    }
    
    func testIsEncodable() throws {
        // setup
        guard let propositionPayload = getDecodedPropositionPayload() else {
            XCTFail("unable to decode PropositionPayload json")
            return
        }
        let encoder = JSONEncoder()
        let expected = getAnyCodable("{\"id\":\"mockId\",\"scope\":\"mockScope\",\"scopeDetails\":{\"correlationID\":\"mockCorrelationId\"},\"items\":[{\"id\":\"mockItemId\",\"schema\":\"https://ns.adobe.com/personalization/html-content-item\",\"data\":{\"id\":\"mockDataId\",\"content\":\"mockDataContent\"}}]}") ?? "fail"

        // test
        guard let encodedPropositionPayload = try? encoder.encode(propositionPayload) else {
            XCTFail("unable to encode PropositionInfo")
            return
        }

        // verify
        let actual = getAnyCodable(String(data: encodedPropositionPayload, encoding: .utf8) ?? "")
        assertExactMatch(expected: expected, actual: actual)
    }
    
    // MARK: - Exception path
    func testIdIsRequired() throws {
        // setup
        let propositionPayload = getDecodedPropositionPayload(fromString: "{\"scope\":\"\(mockScope)\",\"scopeDetails\":{\"correlationID\":\"\(mockCorrelationId)\"},\"items\":[{\"id\":\"\(mockItemId)\",\"schema\":\"\(mockItemSchema)\",\"data\":{\"id\":\"\(mockDataId)\",\"content\":\"\(mockDataContent)\"}}]}")
        
        // verify
        XCTAssertNil(propositionPayload)
    }
    
    func testScopeIsRequired() throws {
        // setup
        let propositionPayload = getDecodedPropositionPayload(fromString: "{\"id\":\"\(mockId)\",\"scopeDetails\":{\"correlationID\":\"\(mockCorrelationId)\"},\"items\":[{\"id\":\"\(mockItemId)\",\"schema\":\"\(mockItemSchema)\",\"data\":{\"id\":\"\(mockDataId)\",\"content\":\"\(mockDataContent)\"}}]}")
        
        // verify
        XCTAssertNil(propositionPayload)
    }
    
    func testScopeDetailsAreRequired() throws {
        // setup
        let propositionPayload = getDecodedPropositionPayload(fromString: "{\"id\":\"\(mockId)\",\"scope\":\"\(mockScope)\",\"items\":[{\"id\":\"\(mockItemId)\",\"schema\":\"\(mockItemSchema)\",\"data\":{\"id\":\"\(mockDataId)\",\"content\":\"\(mockDataContent)\"}}]}")
        
        // verify
        XCTAssertNil(propositionPayload)
    }
    
    func testItemsAreRequired() throws {
        // setup
        let propositionPayload = getDecodedPropositionPayload(fromString: "{\"id\":\"\(mockId)\",\"scope\":\"\(mockScope)\",\"scopeDetails\":{\"correlationID\":\"\(mockCorrelationId)\"}}")
        
        // verify
        XCTAssertNil(propositionPayload)
    }
}
