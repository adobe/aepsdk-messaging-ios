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

import XCTest

@testable import AEPCore
@testable import AEPMessaging

class EventPlusMessagingTests: XCTestCase {
    var messaging: Messaging!
    let testHtml = "<html>All ur base are belong to us</html>"
    let testAssets = ["asset1", "asset2"]
    
    // before each
    override func setUp() {
        messaging = Messaging(runtime: TestableExtensionRuntime())
        messaging.onRegistered()
    }
        
    // MARK: - Testing Happy Path
    
    func testInAppMessageConsequenceType() throws {
        // setup
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE)
        
        // verify
        XCTAssertTrue(event.isInAppMessage)               
    }
        
    func testInAppMessageTemplate() throws {
        // setup
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE)

        // verify
        XCTAssertEqual(MessagingConstants.InAppMessageTemplates.FULLSCREEN, event.template!)
    }
    
    func testInAppMessageHtml() throws {
        // setup
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE)

        // verify
        XCTAssertEqual(testHtml, event.html!)
    }

    func testInAppMessageAssets() throws {
        // setup
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE)
        
        // verify
        XCTAssertEqual(2, event.remoteAssets!.count)
        XCTAssertEqual(testAssets[0], event.remoteAssets![0])
        XCTAssertEqual(testAssets[1], event.remoteAssets![1])
    }
    
    // MARK: - Testing Invalid Events
  
    func testWrongConsequenceType() throws {
        // setup
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE)
        let triggeredConsequence: [String : Any] = [
            MessagingConstants.EventDataKeys.TYPE : "Invalid",
            MessagingConstants.EventDataKeys.ID : UUID().uuidString,
            MessagingConstants.EventDataKeys.DETAIL : [:]
        ]
        event.data?[MessagingConstants.EventDataKeys.TRIGGERED_CONSEQUENCE] = triggeredConsequence
        
        // verify
        XCTAssertFalse(event.isInAppMessage)
        XCTAssertNil(event.template)
        XCTAssertNil(event.html)
        XCTAssertNil(event.remoteAssets)
    }
    
    func testNoConsequenceType() throws {
        // setup
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE)
        let triggeredConsequence: [String : Any] = [
            MessagingConstants.EventDataKeys.ID : UUID().uuidString,
            MessagingConstants.EventDataKeys.DETAIL : [:]
        ]
        event.data?[MessagingConstants.EventDataKeys.TRIGGERED_CONSEQUENCE] = triggeredConsequence

        // verify
        XCTAssertFalse(event.isInAppMessage)
        XCTAssertNil(event.template)
        XCTAssertNil(event.html)
        XCTAssertNil(event.remoteAssets)
    }
    
    func testMissingValuesInDetails() throws {
        // setup
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE)
        let triggeredConsequence: [String : Any] = [
            MessagingConstants.EventDataKeys.TYPE : MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE,
            MessagingConstants.EventDataKeys.ID : UUID().uuidString,
            MessagingConstants.EventDataKeys.DETAIL : ["unintersting":"data"]
        ]
        event.data?[MessagingConstants.EventDataKeys.TRIGGERED_CONSEQUENCE] = triggeredConsequence
        
        // verify
        XCTAssertTrue(event.isInAppMessage)
        XCTAssertNil(event.template)
        XCTAssertNil(event.html)
        XCTAssertNil(event.remoteAssets)
    }

    func testNoInDetails() throws {
        // setup
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE)
        let triggeredConsequence: [String : Any] = [
            MessagingConstants.EventDataKeys.TYPE : MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE,
            MessagingConstants.EventDataKeys.ID : UUID().uuidString
        ]
        event.data?[MessagingConstants.EventDataKeys.TRIGGERED_CONSEQUENCE] = triggeredConsequence
        
        // verify
        XCTAssertTrue(event.isInAppMessage)
        XCTAssertNil(event.template)
        XCTAssertNil(event.html)
        XCTAssertNil(event.remoteAssets)
    }
    
    // MARK: - Helpers
    
    /// Gets an event to use for simulating a rules consequence
    func getRulesResponseEvent(type: String) -> Event {
        // details are the same for postback and pii, different for open url
        let details = type == MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE ? [
            MessagingConstants.EventDataKeys.InAppMessages.TEMPLATE : MessagingConstants.InAppMessageTemplates.FULLSCREEN,
            MessagingConstants.EventDataKeys.InAppMessages.HTML : testHtml,
            MessagingConstants.EventDataKeys.InAppMessages.REMOTE_ASSETS : testAssets
        ] : [:]
        
        let triggeredConsequence = [
            MessagingConstants.EventDataKeys.TRIGGERED_CONSEQUENCE : [
                MessagingConstants.EventDataKeys.ID : UUID().uuidString,
                MessagingConstants.EventDataKeys.TYPE : type,
                MessagingConstants.EventDataKeys.DETAIL : details
            ]
        ]
        let rulesEvent = Event(name: "Test Rules Engine response",
                               type: EventType.rulesEngine,
                               source: EventSource.responseContent,
                               data: triggeredConsequence)
        return rulesEvent
    }
    
    /// Helper to update the nested detail dictionary in a consequence event's event data
    func updateDetailDict(dict: [String : Any], withValue: Any?, forKey: String) -> [String : Any] {
        var returnDict = dict
        guard var consequence = dict[MessagingConstants.EventDataKeys.TRIGGERED_CONSEQUENCE] as? [String : Any] else {
            return returnDict
        }
        guard var detail = consequence[MessagingConstants.EventDataKeys.DETAIL] as? [String : Any] else {
            return returnDict
        }
        
        detail[forKey] = withValue
        consequence[MessagingConstants.EventDataKeys.DETAIL] = detail
        returnDict[MessagingConstants.EventDataKeys.TRIGGERED_CONSEQUENCE] = consequence
        
        return returnDict
    }
}
