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

class PropositionInteractionTests: XCTestCase, AnyCodableAsserts {

    let mockDisplayEventType: MessagingEdgeEventType = .display
    let mockInteractEventType: MessagingEdgeEventType = .interact
    let mockItemId = "mockItemId"
    var mockPropositionInfo: PropositionInfo!
    
    override func setUp() {
        mockPropositionInfo = PropositionInfo(id: "mockPropositionId", scope: "mockScope", scopeDetails: AnyCodable.from(dictionary: ["key": "value"]) ?? [:])
    }
    
    func getDecodedObject(fromString: String) -> PropositionInteraction? {
        let decoder = JSONDecoder()
        let objectData = fromString.data(using: .utf8)!
        guard let propositionInteraction = try? decoder.decode(PropositionInteraction.self, from: objectData) else {
            return nil
        }
        return propositionInteraction
    }
    
    func testPropositionInteractionInit() {
        // test
        let propositionInteraction = PropositionInteraction(eventType: mockDisplayEventType, interaction: "", propositionInfo: mockPropositionInfo, itemId: mockItemId)
        
        // verify
        XCTAssertNotNil(propositionInteraction)
        XCTAssertEqual(mockDisplayEventType, propositionInteraction.eventType)
        XCTAssertEqual("", propositionInteraction.interaction)
        XCTAssertEqual(mockPropositionInfo.id, propositionInteraction.propositionInfo.id)
        XCTAssertEqual(mockPropositionInfo.scope, propositionInteraction.propositionInfo.scope)
        XCTAssertEqual(AnyCodable(mockPropositionInfo.scopeDetails), AnyCodable(propositionInteraction.propositionInfo.scopeDetails))
        XCTAssertEqual(mockItemId, propositionInteraction.itemId)
    }
    
    func testPropositionInteractionIsDecodable() {
        // setup
        let propositionInteractionJsonString = #"""
        {
            "eventType": "decisioning.propositionDisplay",
            "propositionInfo": {
                "id": "mockPropositionId",
                "scope": "mockScope",
                "scopeDetails": {
                    "key": "value"
                }
            },
            "interaction": "",
            "itemId": "mockItemId"
        }
        """#
        
        // test
        guard let propositionInteraction = getDecodedObject(fromString: propositionInteractionJsonString) else {
            XCTFail("Proposition Interaction object should be decodable.")
            return
        }
        
        // verify
        XCTAssertNotNil(propositionInteraction)
        XCTAssertEqual(mockDisplayEventType, propositionInteraction.eventType)
        XCTAssertEqual("", propositionInteraction.interaction)
        XCTAssertEqual(mockPropositionInfo.id, propositionInteraction.propositionInfo.id)
        XCTAssertEqual(mockPropositionInfo.scope, propositionInteraction.propositionInfo.scope)
        XCTAssertEqual(AnyCodable(mockPropositionInfo.scopeDetails), AnyCodable(propositionInteraction.propositionInfo.scopeDetails))
        XCTAssertEqual(mockItemId, propositionInteraction.itemId)
    }
    
    func testPropositionInteractionIsEncodable() {
        // setup
        let propositionInteractionJsonString = #"""
        {
            "eventType": "decisioning.propositionInteract",
            "propositionInfo": {
                "id": "mockPropositionId",
                "scope": "mockScope",
                "scopeDetails": {
                    "key": "value"
                }
            },
            "interaction": "mockInteraction",
            "itemId": "mockItemId"
        }
        """#
        
        guard let propositionInteraction = getDecodedObject(fromString: propositionInteractionJsonString) else {
            XCTFail("Proposition Interaction object should be decodable.")
            return
        }
        
        let encoder = JSONEncoder()
        let expected = getAnyCodable(propositionInteractionJsonString) ?? "fail"

        // test
        guard let encodedObject = try? encoder.encode(propositionInteraction) else {
            XCTFail("Proposition Interaction object should be encodable.")
            return
        }
        
        // verify
        let actual = getAnyCodable(String(data: encodedObject, encoding: .utf8) ?? "")
        assertExactMatch(expected: expected, actual: actual)
    }
    
    func testPropositionInteractionDecodeInvalidEventType() {
        // setup
        let propositionInteractionJsonString = #"""
        {
            "eventType": "decisioning.propositionSomething",
            "propositionInfo": {
                "id": "mockPropositionId",
                "scope": "mockScope",
                "scopeDetails": {
                    "key": "value"
                }
            },
            "interaction": "",
            "itemId": "mockItemId"
        }
        """#
        
        // test
        let propositionInteraction = getDecodedObject(fromString: propositionInteractionJsonString)
        
        // verify
        XCTAssertNil(propositionInteraction)
    }

    func testPropositionInteractionXdmForInteract() throws {
        // setup
        let mockInteraction = "mockInteraction"
        let propositionInteraction = PropositionInteraction(eventType: mockInteractEventType, interaction: mockInteraction, propositionInfo: mockPropositionInfo, itemId: mockItemId)
        
        // test
        let xdm = propositionInteraction.xdm
        
        // verify
        XCTAssertTrue(!xdm.isEmpty)
        XCTAssertEqual(mockInteractEventType.toString(), xdm["eventType"] as? String)
        let experience = try XCTUnwrap(xdm["_experience"] as? [String: Any])
        let decisioning = try XCTUnwrap(experience["decisioning"] as? [String: Any])
        let propositionEventType = try XCTUnwrap(decisioning["propositionEventType"] as? [String: Any])
        XCTAssertEqual(1, propositionEventType["interact"] as? Int)
        
        let propositions = try XCTUnwrap(decisioning["propositions"] as? [[String: Any]])
        XCTAssertEqual(1, propositions.count)
        XCTAssertEqual(mockPropositionInfo.id, propositions[0]["id"] as? String)
        XCTAssertEqual(mockPropositionInfo.scope, propositions[0]["scope"] as? String)
        assertExactMatch(expected: AnyCodable(mockPropositionInfo.scopeDetails), actual: AnyCodable(propositions[0]["scopeDetails"]))

        let items = try XCTUnwrap(propositions[0]["items"] as? [[String: Any]])
        XCTAssertEqual(1, items.count)
        XCTAssertEqual(mockItemId, items[0]["id"] as? String)
        
        let propositionAction = try XCTUnwrap(decisioning["propositionAction"] as? [String: Any])
        XCTAssertEqual(2, propositionAction.count)
        XCTAssertEqual(mockInteraction, propositionAction["id"] as? String)
        XCTAssertEqual(mockInteraction, propositionAction["label"] as? String)
    }
    
    func testPropositionInteractionXdmForDisplay() throws {
        // setup
        let mockInteraction = ""
        let propositionInteraction = PropositionInteraction(eventType: mockDisplayEventType, interaction: mockInteraction, propositionInfo: mockPropositionInfo, itemId: mockItemId)
        
        // test
        let xdm = propositionInteraction.xdm
        
        // verify
        XCTAssertTrue(!xdm.isEmpty)
        XCTAssertEqual(mockDisplayEventType.toString(), xdm["eventType"] as? String)
        let experience = try XCTUnwrap(xdm["_experience"] as? [String: Any])
        let decisioning = try XCTUnwrap(experience["decisioning"] as? [String: Any])
        let propositionEventType = try XCTUnwrap(decisioning["propositionEventType"] as? [String: Any])
        XCTAssertEqual(1, propositionEventType["display"] as? Int)
        
        let propositions = try XCTUnwrap(decisioning["propositions"] as? [[String: Any]])
        XCTAssertEqual(1, propositions.count)
        XCTAssertEqual(mockPropositionInfo.id, propositions[0]["id"] as? String)
        XCTAssertEqual(mockPropositionInfo.scope, propositions[0]["scope"] as? String)
        assertExactMatch(expected: AnyCodable(mockPropositionInfo.scopeDetails), actual: AnyCodable(propositions[0]["scopeDetails"]))

        let items = try XCTUnwrap(propositions[0]["items"] as? [[String: Any]])
        XCTAssertEqual(1, items.count)
        XCTAssertEqual(mockItemId, items[0]["id"] as? String)
        
        XCTAssertNil(decisioning["propositionAction"])
    }
}
