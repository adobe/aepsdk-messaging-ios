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

class PropositionInfoTests: XCTestCase {
    let mockId = "mockId"
    let mockScope = "mockScope"
    let mockCorrelationId = "mockCorrelationId"
    let mockActivityId = "552"
    var mockScopeDetails: [String: AnyCodable]!
    
    override func setUp() {
        mockScopeDetails = [
            "correlationID": AnyCodable(mockCorrelationId),
            "activity": [
                "id": mockActivityId
            ]
        ]
    }
    
    // MARK: - Happy path
    func testIsConstructable() throws {
        // setup
        let propositionInfo = PropositionInfo(id: mockId, scope: mockScope, scopeDetails: mockScopeDetails)
        
        // verify
        XCTAssertNotNil(propositionInfo)
        XCTAssertEqual(mockId, propositionInfo.id)
        XCTAssertEqual(mockScope, propositionInfo.scope)
        XCTAssertEqual(2, propositionInfo.scopeDetails.count)
        XCTAssertEqual(mockCorrelationId, propositionInfo.scopeDetails["correlationID"]?.stringValue)
        let activity = propositionInfo.scopeDetails["activity"]?.dictionaryValue
        XCTAssertEqual(mockActivityId, activity?["id"] as? String)
    }
    
    func testIsEncodable() throws {
        // setup
        let encoder = JSONEncoder()
        let propositionInfo = PropositionInfo(id: mockId, scope: mockScope, scopeDetails: mockScopeDetails)
        let expected = getAnyCodable("{\"id\":\"\(mockId)\",\"scope\":\"\(mockScope)\",\"scopeDetails\":{\"activity\":{\"id\":\"\(mockActivityId)\"},\"correlationID\":\"\(mockCorrelationId)\"}}") ?? "fail"
        
        // test
        guard let encodedPropositionInfo = try? encoder.encode(propositionInfo) else {
            XCTFail("unable to encode PropositionInfo")
            return
        }
        
        // verify
        let actual = getAnyCodable(String(data: encodedPropositionInfo, encoding: .utf8) ?? "")
        assertExactMatch(expected: expected, actual: actual)
    }
    
    func testIsDecodable() throws {
        // setup
        let decoder = JSONDecoder()
        let propositionInfo = "{\"id\":\"\(mockId)\",\"scope\":\"\(mockScope)\",\"scopeDetails\":{\"activity\":{\"id\":\"\(mockActivityId)\"},\"correlationID\":\"\(mockCorrelationId)\"}}".data(using: .utf8)!
        
        // test
        guard let decodedPropositionInfo = try? decoder.decode(PropositionInfo.self, from: propositionInfo) else {
            XCTFail("unable to decode PropositionInfo json")
            return
        }
        
        // verify
        XCTAssertNotNil(decodedPropositionInfo)
        XCTAssertEqual(mockId, decodedPropositionInfo.id)
        XCTAssertEqual(mockScope, decodedPropositionInfo.scope)
        XCTAssertEqual(2, decodedPropositionInfo.scopeDetails.count)
        XCTAssertEqual(mockCorrelationId, decodedPropositionInfo.scopeDetails["correlationID"]?.stringValue)
        let activity = decodedPropositionInfo.scopeDetails["activity"]?.dictionaryValue
        XCTAssertEqual(mockActivityId, activity?["id"] as? String)
    }
    
    func testCorrelationIdExtensionMethod() throws {
        // setup
        let propositionInfo = PropositionInfo(id: mockId, scope: mockScope, scopeDetails: mockScopeDetails)
        
        // verify
        XCTAssertEqual(mockCorrelationId, propositionInfo.correlationId)
    }
    
    func testActivityIdExtensionMethod() throws {
        // setup
        let propositionInfo = PropositionInfo(id: mockId, scope: mockScope, scopeDetails: mockScopeDetails)
        
        // verify
        XCTAssertEqual(mockActivityId, propositionInfo.activityId)
    }
    
    // MARK: - Exception path
    func testIdIsRequired() throws {
        // setup
        let decoder = JSONDecoder()
        let propositionInfo = "{\"scope\":\"\(mockScope)\",\"scopeDetails\":{\"correlationID\":\"\(mockCorrelationId)\"}}".data(using: .utf8)!
        
        // test
        let decodedPropositionInfo = try? decoder.decode(PropositionInfo.self, from: propositionInfo)
        
        // verify
        XCTAssertNil(decodedPropositionInfo)
    }
    
    func testScopeIsRequired() throws {
        // setup
        let decoder = JSONDecoder()
        let propositionInfo = "{\"id\":\"\(mockId)\",\"scopeDetails\":{\"correlationID\":\"\(mockCorrelationId)\"}}".data(using: .utf8)!
        
        // test
        let decodedPropositionInfo = try? decoder.decode(PropositionInfo.self, from: propositionInfo)
        
        // verify
        XCTAssertNil(decodedPropositionInfo)
    }
    
    func testScopeDetailsAreRequired() throws {
        // setup
        let decoder = JSONDecoder()
        let propositionInfo = "{\"id\":\"\(mockId)\",\"scope\":\"\(mockScope)\"}".data(using: .utf8)!
        
        // test
        let decodedPropositionInfo = try? decoder.decode(PropositionInfo.self, from: propositionInfo)
        
        // verify
        XCTAssertNil(decodedPropositionInfo)
    }
    
    func testCorrelationIdExtensionMethodNoCorrelationId() throws {
        // setup
        let propositionInfo = PropositionInfo(id: mockId, scope: mockScope, scopeDetails: [:])
        
        // verify
        XCTAssertEqual("", propositionInfo.correlationId)
    }
    
    func testActivityIdExtensionMethodWhenNoActivityId() throws {
        // setup
        let propositionInfo = PropositionInfo(id: mockId, scope: mockScope, scopeDetails: [:])
        
        // verify
        XCTAssertEqual("", propositionInfo.activityId)
    }
}
