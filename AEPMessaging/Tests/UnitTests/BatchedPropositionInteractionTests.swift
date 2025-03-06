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

import XCTest
import AEPCore
@testable import AEPMessaging
import AEPTestUtils

class BatchedPropositionInteractionTests: XCTestCase, AnyCodableAsserts {
    
    // Common test properties
    var scopeDetails1: [String: Any]!
    var scopeDetails2: [String: Any]!
    var proposition1: MockProposition!
    var proposition2: MockProposition!
    var propositionItem1: PropositionItem = PropositionItem(itemId: "item1", schema: .contentCard, itemData: [:])
    var propositionItem2: PropositionItem = PropositionItem(itemId: "item2", schema: .contentCard, itemData: [:])

    
    override func setUp() {
        super.setUp()
        
        // Setup common test data
        scopeDetails1 = ["key1": "value1"]
        scopeDetails2 = ["key2": "value2"]        
        proposition1 = MockProposition(uniqueId: "proposition1", scope: "scope1", scopeDetails: scopeDetails1, items: [propositionItem1])
        proposition2 = MockProposition(uniqueId: "proposition2", scope: "scope2", scopeDetails: scopeDetails2, items: [propositionItem2])

        propositionItem1.proposition = proposition1
        propositionItem2.proposition = proposition2
        
    }
    
    func testBatchPropositionInteractionXDM_forDisplayEvent() {
        // setup
        let propositionItems = [propositionItem1, propositionItem2]
        
        // test
        let batchedInteraction = BatchedPropositionInteraction(
            eventType: .display,
            interaction: nil,
            propositionItems: propositionItems
        )

        let xdm = batchedInteraction.generateXDM()
        
        // Then
        let expectedXdm = #"""
        {
          "eventType" : "decisioning.propositionDisplay",
          "_experience" : {
            "decisioning" : {
              "propositions" : [
                {
                  "id" : "proposition1",
                  "items" : [
                    {
                      "id" : "item1"
                    }
                  ],
                  "scopeDetails" : {
                    "key1" : "value1"
                  },
                  "scope" : "scope1"
                },
                {
                  "id" : "proposition2",
                  "items" : [
                    {
                      "id" : "item2"
                    }
                  ],
                  "scopeDetails" : {
                    "key2" : "value2"
                  },
                  "scope" : "scope2"
                }
              ],
              "propositionEventType" : {
                "display" : 1
              }
            }
          }
        }
        """#.toAnyCodable()!

        // Verify the XDM matches the expected structure
        assertExactMatch(expected: expectedXdm, actual: xdm.toAnyCodable())
    }
    
    func testBatchPropositionInteractionXDM_forInteractEvent_whenOneProposition() {
        // setup
        let propositionItems = [propositionItem1]
        
        // test
        let batchedInteraction = BatchedPropositionInteraction(
            eventType: .interact,
            interaction: "Clicked",
            propositionItems: propositionItems
        )        
        let xdm = batchedInteraction.generateXDM()

        // Then 
        let expectedXdm = #"""
        {
          "eventType" : "decisioning.propositionInteract",
          "_experience" : {
            "decisioning" : {
              "propositionAction" : {
                "id" : "Clicked",
                "label" : "Clicked"
              },
              "propositions" : [
                {
                  "id" : "proposition1",
                  "items" : [
                    {
                      "id" : "item1"
                    }
                  ],
                  "scopeDetails" : {
                    "key1" : "value1"
                  },
                  "scope" : "scope1"
                }
              ],
              "propositionEventType" : {
                "interact" : 1
              }
            }
          }
        }
        """#.toAnyCodable()!

        // Verify the XDM matches the expected structure
        assertExactMatch(expected: expectedXdm, actual: xdm.toAnyCodable())
    }
    
    func testBatchPropositionInteractionXDM_whenNoPropositions() {
        // setup
        let propositionItems : [PropositionItem] = []
        
        // test
        let batchedInteraction = BatchedPropositionInteraction(
            eventType: .display,
            interaction: nil,
            propositionItems: propositionItems
        )
        
        let xdm = batchedInteraction.generateXDM()
        
        // then
        XCTAssertTrue(xdm.isEmpty, "XDM should be empty when there are no propositions")
    }
    

    func testBatchPropositionInteractionXDM_whenSuppressDisplayEvent() {
        // setup
        let propositionItems = [propositionItem1, propositionItem2]
        
        // test
        let batchedInteraction = BatchedPropositionInteraction(
            eventType: .suppressDisplay,
            interaction: "Didnt want to display",
            propositionItems: propositionItems
        )
        
        let xdm = batchedInteraction.generateXDM()
        
        // then
        let expectedXdm = #"""
        {
          "eventType" : "decisioning.propositionSuppressDisplay",
          "_experience" : {
            "decisioning" : {
              "propositionAction" : {
                "reason" : "Didnt want to display"
              },
              "propositionEventType" : {
                "suppressDisplay" : 1
              },
              "propositions" : [
                {
                  "id" : "proposition1",
                  "items" : [
                    {
                      "id" : "item1"
                    }
                  ],
                  "scopeDetails" : {
                    "key1" : "value1"
                  },
                  "scope" : "scope1"
                },
                {
                  "id" : "proposition2",
                  "items" : [
                    {
                      "id" : "item2"
                    }
                  ],
                  "scopeDetails" : {
                    "key2" : "value2"
                  },
                  "scope" : "scope2"
                }
              ]
            }
          }
        }
        """#.toAnyCodable()!
        
        // Verify the XDM matches the expected structure
        assertExactMatch(expected: expectedXdm, actual: xdm.toAnyCodable())
    }
    
} 
