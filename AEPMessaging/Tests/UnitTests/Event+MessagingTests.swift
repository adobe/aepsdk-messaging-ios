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
    let mockActivityId = "mockActivityId"
    let mockPlacementId = "mockPlacementId"
    let mockContent1 = "content1"
    let mockContent2 = "content2"

    // before each
    override func setUp() {
        messaging = Messaging(runtime: TestableExtensionRuntime())
        messaging.onRegistered()
    }

    // MARK: - Helpers
    /// Gets an event to use for simulating a rules consequence
    func getRulesResponseEvent(type: String) -> Event {
        // details are the same for postback and pii, different for open url
        let details = type == MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE ? [
            MessagingConstants.Event.Data.Key.IAM.TEMPLATE: MessagingConstants.InAppMessageTemplates.FULLSCREEN,
            MessagingConstants.Event.Data.Key.IAM.HTML: testHtml,
            MessagingConstants.Event.Data.Key.IAM.REMOTE_ASSETS: testAssets
        ] : [:]

        let triggeredConsequence = [
            MessagingConstants.Event.Data.Key.TRIGGERED_CONSEQUENCE: [
                MessagingConstants.Event.Data.Key.ID: UUID().uuidString,
                MessagingConstants.Event.Data.Key.TYPE: type,
                MessagingConstants.Event.Data.Key.DETAIL: details
            ]
        ]
        let rulesEvent = Event(name: "Test Rules Engine response",
                               type: EventType.rulesEngine,
                               source: EventSource.responseContent,
                               data: triggeredConsequence)
        return rulesEvent
    }

    /// Helper to update the nested detail dictionary in a consequence event's event data
    func updateDetailDict(dict: [String: Any], withValue: Any?, forKey: String) -> [String: Any] {
        var returnDict = dict
        guard var consequence = dict[MessagingConstants.Event.Data.Key.TRIGGERED_CONSEQUENCE] as? [String: Any] else {
            return returnDict
        }
        guard var detail = consequence[MessagingConstants.Event.Data.Key.DETAIL] as? [String: Any] else {
            return returnDict
        }

        detail[forKey] = withValue
        consequence[MessagingConstants.Event.Data.Key.DETAIL] = detail
        returnDict[MessagingConstants.Event.Data.Key.TRIGGERED_CONSEQUENCE] = consequence

        return returnDict
    }

    /// Gets an AEP Response Event for testing
    func getAEPResponseEvent(type: String = EventType.edge,
                             source: String = MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS,
                             data: [String: Any]? = nil) -> Event {
        var eventData = data
        if eventData == nil {
            let data1 = ["content": mockContent1]
            let item1 = ["data": data1]
            let data2 = ["content": mockContent2]
            let item2 = ["data": data2]
            let placement = ["id": mockPlacementId]
            let activity = ["id": mockActivityId]
            let payload: [String: Any] = [
                "activity": activity,
                "placement": placement,
                "items": [item1, item2]
            ]

            eventData = ["payload": [payload]]
        }

        let rulesEvent = Event(name: "Test AEP Response Event",
                               type: type,
                               source: source,
                               data: eventData)

        return rulesEvent
    }

    func getRefreshMessagesEvent(type: String = MessagingConstants.Event.EventType.messaging,
                                 source: String = EventSource.requestContent,
                                 data: [String: Any]? = nil) -> Event {
        var eventData = data
        if eventData == nil {
            eventData = [MessagingConstants.Event.Data.Key.REFRESH_MESSAGES: true]
        }

        let event = Event(name: "Test Refresh Messages",
                          type: type,
                          source: source,
                          data: eventData)

        return event
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

    // MARK: - Testing Message Object Validation
    func testInAppMessageObjectValidation() throws {
        // setup
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE)

        // verify
        XCTAssertTrue(event.containsValidInAppMessage)
    }

    // MARK: - Testing Invalid Events
    func testWrongConsequenceType() throws {
        // setup
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE)
        let triggeredConsequence: [String: Any] = [
            MessagingConstants.Event.Data.Key.TYPE: "Invalid",
            MessagingConstants.Event.Data.Key.ID: UUID().uuidString,
            MessagingConstants.Event.Data.Key.DETAIL: [:]
        ]
        event.data?[MessagingConstants.Event.Data.Key.TRIGGERED_CONSEQUENCE] = triggeredConsequence

        // verify
        XCTAssertFalse(event.isInAppMessage)
        XCTAssertNil(event.template)
        XCTAssertNil(event.html)
        XCTAssertNil(event.remoteAssets)
    }

    func testNoConsequenceType() throws {
        // setup
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE)
        let triggeredConsequence: [String: Any] = [
            MessagingConstants.Event.Data.Key.ID: UUID().uuidString,
            MessagingConstants.Event.Data.Key.DETAIL: [:]
        ]
        event.data?[MessagingConstants.Event.Data.Key.TRIGGERED_CONSEQUENCE] = triggeredConsequence

        // verify
        XCTAssertFalse(event.isInAppMessage)
        XCTAssertNil(event.template)
        XCTAssertNil(event.html)
        XCTAssertNil(event.remoteAssets)
    }

    func testMissingValuesInDetails() throws {
        // setup
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE)
        let triggeredConsequence: [String: Any] = [
            MessagingConstants.Event.Data.Key.TYPE: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE,
            MessagingConstants.Event.Data.Key.ID: UUID().uuidString,
            MessagingConstants.Event.Data.Key.DETAIL: ["unintersting": "data"]
        ]
        event.data?[MessagingConstants.Event.Data.Key.TRIGGERED_CONSEQUENCE] = triggeredConsequence

        // verify
        XCTAssertTrue(event.isInAppMessage)
        XCTAssertNil(event.template)
        XCTAssertNil(event.html)
        XCTAssertNil(event.remoteAssets)
    }

    func testNoInDetails() throws {
        // setup
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE)
        let triggeredConsequence: [String: Any] = [
            MessagingConstants.Event.Data.Key.TYPE: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE,
            MessagingConstants.Event.Data.Key.ID: UUID().uuidString
        ]
        event.data?[MessagingConstants.Event.Data.Key.TRIGGERED_CONSEQUENCE] = triggeredConsequence

        // verify
        XCTAssertTrue(event.isInAppMessage)
        XCTAssertNil(event.template)
        XCTAssertNil(event.html)
        XCTAssertNil(event.remoteAssets)
    }

    func testInAppMessageObjectValidationNoTemplate() throws {
        // setup
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE)
        event.data = updateDetailDict(dict: event.data!,
                                      withValue: nil,
                                      forKey: MessagingConstants.Event.Data.Key.IAM.TEMPLATE)

        // verify
        XCTAssertNil(event.template)
        XCTAssertFalse(event.containsValidInAppMessage)
    }

    func testInAppMessageObjectValidationNoHtml() throws {
        // setup
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE)
        event.data = updateDetailDict(dict: event.data!,
                                      withValue: nil,
                                      forKey: MessagingConstants.Event.Data.Key.IAM.HTML)

        // verify
        XCTAssertNil(event.html)
        XCTAssertFalse(event.containsValidInAppMessage)
    }

    // MARK: - AEP Response Event Handling
    func testIsPersonalizationDecisionResponseHappy() {
        // setup
        let event = getAEPResponseEvent()

        // verify
        XCTAssertTrue(event.isPersonalizationDecisionResponse)
    }

    func testIsPersonalizationDecisionResponseNotEdgeType() {
        // setup
        let event = getAEPResponseEvent(type: "notEdge")

        // verify
        XCTAssertFalse(event.isPersonalizationDecisionResponse)
    }

    func testIsPersonalizationDecisionResponseNotPersonalizationSource() {
        // setup
        let event = getAEPResponseEvent(source: "notPersonalization")

        // verify
        XCTAssertFalse(event.isPersonalizationDecisionResponse)
    }

    func testOfferActivityIdHappy() {
        // setup
        let event = getAEPResponseEvent()

        // verify
        XCTAssertEqual(mockActivityId, event.offerActivityId)
    }

    func testOfferActivityIdEmpty() {
        // setup
        let data1 = ["content": mockContent1]
        let item1 = ["data": data1]
        let data2 = ["content": mockContent2]
        let item2 = ["data": data2]
        let placement = ["id": mockPlacementId]
        let activity: [String: Any] = [:]
        let payload: [String: Any] = [
            "activity": activity,
            "placement": placement,
            "items": [item1, item2]
        ]
        let event = getAEPResponseEvent(data: ["payload": [payload]])

        // verify
        XCTAssertNil(event.offerActivityId)
    }

    func testOfferPlacementIdHappy() {
        // setup
        let event = getAEPResponseEvent()

        // verify
        XCTAssertEqual(mockPlacementId, event.offerPlacementId)
    }

    func testOfferPlacementIdEmpty() {
        // setup
        let data1 = ["content": mockContent1]
        let item1 = ["data": data1]
        let data2 = ["content": mockContent2]
        let item2 = ["data": data2]
        let placement: [String: Any] = [:]
        let activity = ["id": mockActivityId]
        let payload: [String: Any] = [
            "activity": activity,
            "placement": placement,
            "items": [item1, item2]
        ]
        let event = getAEPResponseEvent(data: ["payload": [payload]])

        // verify
        XCTAssertNil(event.offerPlacementId)
    }

    func testPayloadIsNil() {
        // setup
        let payload: [[String: Any]]? = nil
        let event = getAEPResponseEvent(data: ["payload": payload as Any])

        // verify
        XCTAssertNil(event.offerActivityId)
        XCTAssertNil(event.offerPlacementId)
        XCTAssertNil(event.rulesJson)
    }

    func testPayloadIsEmpty() {
        // setup
        let payload: [[String: Any]]? = []
        let event = getAEPResponseEvent(data: ["payload": payload as Any])

        // verify
        XCTAssertNil(event.offerActivityId)
        XCTAssertNil(event.offerPlacementId)
        XCTAssertNil(event.rulesJson)
    }

    func testRulesJsonHappy() {
        // setup
        let event = getAEPResponseEvent()

        // test
        let rulesJson = event.rulesJson

        // verify
        XCTAssertNotNil(rulesJson)
        XCTAssertEqual(2, rulesJson?.count)
        XCTAssertEqual(mockContent1, rulesJson?[0])
        XCTAssertEqual(mockContent2, rulesJson?[1])
    }

    func testRulesJsonBadPayloadKey() {
        // setup
        let data1 = ["content": mockContent1]
        let item1 = ["data": data1]
        let payload: [String: Any] = ["items": [item1]]
        let event = getAEPResponseEvent(data: ["notthecorrectpayload": [payload]])

        // verify
        XCTAssertNil(event.rulesJson)
    }

    func testRulesJsonPayloadNotArrayOfDictionaries() {
        // setup
        let data1 = ["content": mockContent1]
        let item1 = ["data": data1]
        let payload: [String: Any] = ["items": [item1]]
        let event = getAEPResponseEvent(data: ["payload": payload])

        // verify
        XCTAssertNil(event.rulesJson)
    }

    func testRulesJsonBadItemsKey() {
        // setup
        let data1 = ["content": mockContent1]
        let item1 = ["data": data1]
        let payload: [String: Any] = ["itemsbutnotreally": [item1]]
        let event = getAEPResponseEvent(data: ["payload": [payload]])

        // verify
        XCTAssertNil(event.rulesJson)
    }

    func testRulesJsonItemsNotArray() {
        // setup
        let data1 = ["content": mockContent1]
        let item1 = ["data": data1]
        let payload: [String: Any] = ["items": item1]
        let event = getAEPResponseEvent(data: ["payload": [payload]])

        // verify
        XCTAssertNil(event.rulesJson)
    }

    func testRulesJsonBadDataKey() {
        // setup
        let data1 = ["content": mockContent1]
        let item1 = ["databutnotreally": data1]
        let payload: [String: Any] = ["items": [item1]]
        let event = getAEPResponseEvent(data: ["payload": [payload]])

        // verify
        XCTAssertNil(event.rulesJson)
    }

    func testRulesJsonDataNotDictionary() {
        // setup
        let data1 = "content"
        let item1 = ["data": data1]
        let payload: [String: Any] = ["items": [item1]]
        let event = getAEPResponseEvent(data: ["payload": [payload]])

        // verify
        XCTAssertNil(event.rulesJson)
    }

    func testRulesJsonBadContentKey() {
        // setup
        let data1 = ["contentbutnotreally": mockContent1]
        let item1 = ["data": data1]
        let payload: [String: Any] = ["items": [item1]]
        let event = getAEPResponseEvent(data: ["payload": [payload]])

        // verify
        XCTAssertNil(event.rulesJson)
    }

    func testRulesJsonContentIsNotString() {
        // setup
        let data1 = ["content": 12345]
        let item1 = ["data": data1]
        let payload: [String: Any] = ["items": [item1]]
        let event = getAEPResponseEvent(data: ["payload": [payload]])

        // verify
        XCTAssertNil(event.rulesJson)
    }

    // MARK: - Test Refresh Messages Public API Event
    func testIsRefreshMessageEventHappy() {
        // setup
        let event = getRefreshMessagesEvent()

        // verify
        XCTAssertTrue(event.isRefreshMessageEvent)
    }

    func testIsRefreshMessageEventWrongType() {
        // setup
        let event = getRefreshMessagesEvent(type: "wrong type")

        // verify
        XCTAssertFalse(event.isRefreshMessageEvent)
    }

    func testIsRefreshMessageEventWrongSource() {
        // setup
        let event = getRefreshMessagesEvent(source: "wrong source")

        // verify
        XCTAssertFalse(event.isRefreshMessageEvent)
    }

    func testIsRefreshMessageEventWrongData() {
        // setup
        let event = getRefreshMessagesEvent(data: ["wrongkey": "nope"])

        // verify
        XCTAssertFalse(event.isRefreshMessageEvent)
    }
}
