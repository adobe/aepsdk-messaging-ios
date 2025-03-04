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

import XCTest
@testable import YourModuleName

class CollectionPropositionItemTests: XCTestCase {

    func testTrackWithValidPropositions() {
        // Arrange
        let mockProposition = Proposition(uniqueId: "uniqueId", scope: "scope", scopeDetails: [:])
        let mockItem = PropositionItem(proposition: mockProposition, itemId: "itemId")
        let collection: [PropositionItem] = [mockItem]
        
        let mockEventType = MessagingEdgeEventType.someEventType
        let mockInteraction = "interaction"
        
        // Mock the dependencies
        PropositionHistory.record = { activityId, eventType, interaction in
            XCTAssertEqual(activityId, "uniqueId")
            XCTAssertEqual(eventType, mockEventType)
            XCTAssertEqual(interaction, mockInteraction)
        }
        
        var dispatchedEvent: Event?
        MobileCore.dispatch = { event in
            dispatchedEvent = event
        }
        
        // Act
        collection.track(mockInteraction, withEdgeEventType: mockEventType)
        
        // Assert
        XCTAssertNotNil(dispatchedEvent)
        XCTAssertEqual(dispatchedEvent?.name, MessagingConstants.Event.Name.TRACK_PROPOSITIONS)
        XCTAssertEqual(dispatchedEvent?.type, EventType.messaging)
        XCTAssertEqual(dispatchedEvent?.source, EventSource.requestContent)
        XCTAssertEqual(dispatchedEvent?.data?[MessagingConstants.Event.Data.Key.TRACK_PROPOSITIONS] as? Bool, true)
    }
    
    func testTrackWithNoValidPropositions() {
        // Arrange
        let collection: [PropositionItem] = []
        
        let mockEventType = MessagingEdgeEventType.someEventType
        let mockInteraction = "interaction"
        
        // Mock the dependencies
        var recordCalled = false
        PropositionHistory.record = { _, _, _ in
            recordCalled = true
        }
        
        var dispatchCalled = false
        MobileCore.dispatch = { _ in
            dispatchCalled = true
        }
        
        // Act
        collection.track(mockInteraction, withEdgeEventType: mockEventType)
        
        // Assert
        XCTAssertFalse(recordCalled)
        XCTAssertFalse(dispatchCalled)
    }
}
