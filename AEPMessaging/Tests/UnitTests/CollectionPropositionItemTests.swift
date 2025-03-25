//
//  CollectionPropositionItemTests.swift
//  AEPMessaging
//
//  Created by Pravin Prakash Kumar on 3/25/25.
//


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
import AEPTestUtils
@testable import AEPCore
@testable import AEPMessaging

class CollectionPropositionItemTests: XCTestCase, AnyCodableAsserts {
    
    override func setUp() {
        EventHub.shared.start()
        registerMockExtension(MockExtension.self)
    }
    
    override func tearDown() {
        MobileCore.resetSDK()
    }
    
    private func registerMockExtension<T: Extension>(_ type: T.Type) {
        let semaphore = DispatchSemaphore(value: 0)
        EventHub.shared.registerExtension(type) { _ in
            semaphore.signal()
        }
        
        semaphore.wait()
    }
    
    func testTrack_whenEmptyPropositionArray() {
        // setup
        let propositionItems : [PropositionItem] = []
        
        // test
        propositionItems.track(withEdgeEventType: .dismiss)
        
        // verify
        let expectation = XCTestExpectation(description: "messaging requestContent event should NOT be dispatched")
        expectation.isInverted = true
        MobileCore.registerEventListener(type: EventType.messaging, source: EventSource.requestContent) { event in
            // This block should not be called if no event is dispatched
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testTrackDisplay_ForTwoPropositions() {
        // setup
        let proposition1 = Proposition(uniqueId: "1", scope: "scope1", scopeDetails: ["key1": "value1"], items: [PropositionItem(itemId: "1", schema: .contentCard, itemData: [:])])
        let proposition2 = Proposition(uniqueId: "2", scope: "scope2", scopeDetails: ["key2": "value2"], items: [PropositionItem(itemId: "2", schema: .contentCard, itemData: [:])])
        let propositionItem1 = PropositionItem(itemId: "1", schema: .contentCard, itemData: [:])
        propositionItem1.proposition = proposition1
        let propositionItem2 = PropositionItem(itemId: "2", schema: .contentCard, itemData: [:])
        propositionItem2.proposition = proposition2
        
        let propositionItems = [propositionItem1, propositionItem2]
        
        // set expectations
        let expectation = XCTestExpectation(description: "messaging requestContent event should be dispatched")
        MobileCore.registerEventListener(type: EventType.messaging, source: EventSource.requestContent) { event in
            // This block should be called if an event is dispatched
            NSLog("Event captured")
            XCTAssertEqual(event.name, MessagingConstants.Event.Name.TRACK_PROPOSITIONS)
            let expectedEventData = #"""
            {
              "propositioninteraction" : {
                "_experience" : {
                  "decisioning" : {
                    "propositions" : [
                      {
                        "scope" : "scope1",
                        "items" : [
                          {
                            "id" : "1"
                          }
                        ],
                        "scopeDetails" : {
                          "key1" : "value1"
                        },
                        "id" : "1"
                      },
                      {
                        "scope" : "scope2",
                        "id" : "2",
                        "scopeDetails" : {
                          "key2" : "value2"
                        },
                        "items" : [
                          {
                            "id" : "2"
                          }
                        ]
                      }
                    ],
                    "propositionEventType" : {
                      "trigger" : 1
                    }
                  }
                },
                "eventType" : "decisioning.propositionTrigger"
              },
              "trackpropositions" : true
            }
            """#.toAnyCodable()
            self.assertEqual(expected: event.data?.toAnyCodable(), actual: expectedEventData)
            expectation.fulfill()
        }

        // test
        propositionItems.track(withEdgeEventType: .trigger)

        // verify    
        wait(for: [expectation], timeout: 2.0)
    }

    func testTrack_shouldRecordPropositionHistory() {
        // setup
        let propositionItem1 = PropositionItem(itemId: "1", schema: .contentCard, itemData: [:])
        let propositionItem2 = PropositionItem(itemId: "2", schema: .contentCard, itemData: [:])
        
        let proposition1 = Proposition(uniqueId: "1", scope: "scope1", scopeDetails: ["activity": ["id" : "activityId1"]], items: [propositionItem1])
        propositionItem1.proposition = proposition1
        
        let proposition2 = Proposition(uniqueId: "2", scope: "scope2", scopeDetails: ["activity": ["id" : "activityId2"]], items: [propositionItem2])
        propositionItem2.proposition = proposition2

        let propositionItems = [propositionItem1, propositionItem2]

        // set expectations
        let eventHistoryWriteExpectation = XCTestExpectation(description: "event history write event should be dispatched")
        eventHistoryWriteExpectation.expectedFulfillmentCount = 2
        
        MobileCore.registerEventListener(type: EventType.messaging,
                                         source: MessagingConstants.Event.Source.EVENT_HISTORY_WRITE) { event in
            eventHistoryWriteExpectation.fulfill()
        }

        // test
        propositionItems.track(withEdgeEventType: .trigger)

        // verify
        wait(for: [eventHistoryWriteExpectation], timeout: 2.0)
    }
}
