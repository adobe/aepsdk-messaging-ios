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
@testable import AEPServices

class EventPlusMessagingTests: XCTestCase {
    var messaging: Messaging!
    
    /// in-app values
    let testHtml = "<html>All ur base are belong to us</html>"
    let testAssets = ["asset1", "asset2"]
    let mockContent1 = "content1"
    let mockContent2 = "content2"
    let mockPayloadId1 = "id1"
    let mockPayloadId2 = "id2"
    let mockAppSurface = "mobileapp://com.apple.dt.xctest.tool"
    let mockRequestEventId = "abc123"

    /// Push values
    let mockXdmEventType = "xdmEventType"
    let mockMessagingId = "12345"
    let mockActionId = "67890"
    let mockApplicationOpened = false
    let mockMixins: [String: Any] = [
        "mixin": "present"
    ]
    let mockCjm: [String: Any] = [
        "cjm": "present"
    ]
    let mockPushToken = "thisIsOnlyAPushTokenTest"

    // before each
    override func setUp() {
        messaging = Messaging(runtime: TestableExtensionRuntime())
        messaging.onRegistered()
    }

    // MARK: - Helpers

    /// Gets an event to use for simulating a rules consequence
    func getRulesResponseEvent(type: String? = MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE,
                               triggeredConsequence: [String: Any]? = nil,
                               removeDetails: [String]? = nil) -> Event {

        // details are the same for postback and pii, different for open url
        var details: [String: Any] = type == MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE ? [
            MessagingConstants.Event.Data.Key.IAM.TEMPLATE: MessagingConstants.Event.Data.Values.IAM.FULLSCREEN,
            MessagingConstants.Event.Data.Key.IAM.HTML: testHtml,
            MessagingConstants.Event.Data.Key.IAM.REMOTE_ASSETS: testAssets
        ] : [:]

        if let keysToBeRemoved = removeDetails {
            for key in keysToBeRemoved {
                details.removeValue(forKey: key)
            }
        }
        
        let triggeredConsequence: [String: Any] = triggeredConsequence ?? [
            MessagingConstants.Event.Data.Key.ID: "552",
            MessagingConstants.Event.Data.Key.TYPE: type!,
            MessagingConstants.Event.Data.Key.DETAIL: details
        ]

        let triggeredConsequenceData: [String: Any] = [
            MessagingConstants.Event.Data.Key.TRIGGERED_CONSEQUENCE: triggeredConsequence
        ]
        
        let rulesEvent = Event(name: "Test Rules Engine response",
                               type: EventType.rulesEngine,
                               source: EventSource.responseContent,
                               data: triggeredConsequenceData)
        return rulesEvent
    }

    /* sample payload response:
     
    "payload": [
     {
        "id": "fe47f125-dc8f-454f-b4e8-cf462d65eb67",
        "scope": "mobileapp://com.adobe.MessagingDemoApp",
        "scopeDetails": {
            "decisionProvider": "AJO",
            "correlationID": "d7e644d7-9312-4d7b-8b52-7fa08ce5eccf",
            "characteristics": {
                "cjmEventToken": "aCm/+7TFk4ojIuGQc+N842qipfsIHvVzTQxHolz2IpTMromRrB5ztP5VMxjHbs7c6qPG9UF4rvQTJZniWgqbOw=="
            }
        },
        "items": [
            {
                "schema": "https://ns.adobe.com/personalization/json-content-item",
                "data": {
                    "content": "{\"version\":1,\"rules\":[{\"condition\":{...}],\"consequences\":[{\"id\":\"0517276e-70a5-4d89-bc5c-81ba77e35588\",\"type\":\"cjmiam\",\"detail\":{\"mobileParameters\":{...},\"html\":\"...\",\"remoteAssets\":[...]}}]}",
                    "id": "0ac7fe11-6fa0-4bcc-a986-bb6302c30059"
                },
                "id": "716708a1-eedb-4d50-8404-82edced7c06f"
            }
        ]
    },
    {
        ... another proposition for another campaign running on the surface ...
    }
  ]
     */
    
    /// Gets an AEP Response Event for testing
    func getAEPResponseEvent(type: String = EventType.edge,
                             source: String = MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS,
                             data: [String: Any]? = nil) -> Event {
        var eventData = data
        if eventData == nil {
            let data1 = [
                "content": mockContent1,
                "id": "id"
            ]
            let item1: [String: Any] = [
                "data": data1,
                "id": "id",
                "schema": "schema"
            ]
            let payload1: [String: Any] = [
                "id": mockPayloadId1,
                "scope": mockAppSurface,
                "scopeDetails": [
                    "someInnerKey": "someInnerValue"
                ],
                "items": [item1]
            ]
            
            let data2 = [
                "content": mockContent2,
                "id": "id"
            ]
            let item2: [String: Any] = [
                "data": data2,
                "id": "id",
                "schema": "schema"
            ]
            let payload2: [String: Any] = [
                "id": mockPayloadId2,
                "scope": mockAppSurface,
                "scopeDetails": [
                    "someInnerKey": "someInnerValue"
                ],
                "items": [item2]
            ]
            
            eventData = [
                "payload": [payload1, payload2],
                "requestEventId": mockRequestEventId
            ]
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

    func getClickthroughEvent(_ data: [String: Any]? = nil) -> Event {
        let data = data ?? [
            MessagingConstants.Event.Data.Key.EVENT_TYPE: mockXdmEventType,
            MessagingConstants.Event.Data.Key.MESSAGE_ID: mockMessagingId,
            MessagingConstants.Event.Data.Key.ACTION_ID: mockActionId,
            MessagingConstants.Event.Data.Key.APPLICATION_OPENED: mockApplicationOpened,
            MessagingConstants.XDM.Key.ADOBE_XDM: [
                MessagingConstants.XDM.AdobeKeys.MIXINS: mockMixins,
                MessagingConstants.XDM.AdobeKeys.CJM: mockCjm
            ]
        ]

        return Event(name: "Test Push clickthrough event", type: MessagingConstants.Event.EventType.messaging,
                     source: EventSource.requestContent, data: data)
    }
    
    func getSetPushIdentifierEvent(overriddingData: [String: Any]? = nil) -> Event {
        let data = overriddingData ?? [
            MessagingConstants.Event.Data.Key.PUSH_IDENTIFIER: mockPushToken
        ]
        
        return Event(name: "Test Set Push Identifier Event", type: EventType.genericIdentity, source: EventSource.requestContent, data: data)
    }

    // MARK: - Testing Happy Path

    func testInAppMessageConsequenceType() throws {
        // setup
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE)

        // verify
        XCTAssertTrue(event.isCjmIamConsequence)
    }

    func testInAppMessageMessageId() throws {
        // setup
        let event = getRulesResponseEvent()

        // verify
        XCTAssertEqual("552", event.messageId!)
    }

    func testInAppMessageTemplate() throws {
        // setup
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE)

        // verify
        XCTAssertEqual(MessagingConstants.Event.Data.Values.IAM.FULLSCREEN, event.template!)
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

    // MARK: - Test mobileParameters

    func testGetMessageSettingsHappy() throws {
        // setup
        let event = TestableMobileParameters.getMobileParametersEvent()

        // test
        let settings = event.getMessageSettings(withParent: self)

        // verify
        XCTAssertNotNil(settings)
        XCTAssertTrue(settings.parent is EventPlusMessagingTests)
        XCTAssertEqual(TestableMobileParameters.mockWidth, settings.width)
        XCTAssertEqual(TestableMobileParameters.mockHeight, settings.height)
        XCTAssertEqual(MessageAlignment.fromString(TestableMobileParameters.mockVAlign), settings.verticalAlign)
        XCTAssertEqual(TestableMobileParameters.mockVInset, settings.verticalInset)
        XCTAssertEqual(MessageAlignment.fromString(TestableMobileParameters.mockHAlign), settings.horizontalAlign)
        XCTAssertEqual(TestableMobileParameters.mockHInset, settings.horizontalInset)
        XCTAssertEqual(TestableMobileParameters.mockUiTakeover, settings.uiTakeover)
        XCTAssertEqual(UIColor(red: 0xAA / 255.0, green: 0xBB / 255.0, blue: 0xCC / 255.0, alpha: 0), settings.getBackgroundColor(opacity: 0))
        XCTAssertEqual(CGFloat(TestableMobileParameters.mockCornerRadius), settings.cornerRadius)
        XCTAssertEqual(MessageAnimation.fromString(TestableMobileParameters.mockDisplayAnimation), settings.displayAnimation)
        XCTAssertEqual(MessageAnimation.fromString(TestableMobileParameters.mockDismissAnimation), settings.dismissAnimation)
        XCTAssertNotNil(settings.gestures)
        XCTAssertEqual(1, settings.gestures?.count)
        XCTAssertEqual(URL(string: "adbinapp://dismiss")!.absoluteString, (settings.gestures![.swipeDown]!).absoluteString)
    }

    func testGetMessageSettingsNoParent() throws {
        // setup
        let event = TestableMobileParameters.getMobileParametersEvent()

        // test
        let settings = event.getMessageSettings(withParent: nil)

        // verify
        XCTAssertNotNil(settings)
        XCTAssertNil(settings.parent)
        XCTAssertEqual(TestableMobileParameters.mockWidth, settings.width)
        XCTAssertEqual(TestableMobileParameters.mockHeight, settings.height)
        XCTAssertEqual(MessageAlignment.fromString(TestableMobileParameters.mockVAlign), settings.verticalAlign)
        XCTAssertEqual(TestableMobileParameters.mockVInset, settings.verticalInset)
        XCTAssertEqual(MessageAlignment.fromString(TestableMobileParameters.mockHAlign), settings.horizontalAlign)
        XCTAssertEqual(TestableMobileParameters.mockHInset, settings.horizontalInset)
        XCTAssertEqual(TestableMobileParameters.mockUiTakeover, settings.uiTakeover)
        XCTAssertEqual(UIColor(red: 0xAA / 255.0, green: 0xBB / 255.0, blue: 0xCC / 255.0, alpha: 0), settings.getBackgroundColor(opacity: 0))
        XCTAssertEqual(CGFloat(TestableMobileParameters.mockCornerRadius), settings.cornerRadius)
        XCTAssertEqual(MessageAnimation.fromString(TestableMobileParameters.mockDisplayAnimation), settings.displayAnimation)
        XCTAssertEqual(MessageAnimation.fromString(TestableMobileParameters.mockDismissAnimation), settings.dismissAnimation)
        XCTAssertNotNil(settings.gestures)
        XCTAssertEqual(1, settings.gestures?.count)
        XCTAssertEqual(URL(string: "adbinapp://dismiss")!.absoluteString, (settings.gestures![.swipeDown]!).absoluteString)
    }

    func testGetMessageSettingsMobileParametersEmpty() throws {
        // setup
        let event = getRefreshMessagesEvent()

        // test
        let settings = event.getMessageSettings(withParent: self)

        // verify
        XCTAssertNotNil(settings)
        XCTAssertTrue(settings.parent is EventPlusMessagingTests)
        XCTAssertNil(settings.width)
        XCTAssertNil(settings.height)
        XCTAssertEqual(.center, settings.verticalAlign)
        XCTAssertNil(settings.verticalInset)
        XCTAssertEqual(.center, settings.horizontalAlign)
        XCTAssertNil(settings.horizontalInset)
        XCTAssertTrue(settings.uiTakeover!)
        XCTAssertEqual(UIColor(red: 1, green: 1, blue: 1, alpha: 0), settings.getBackgroundColor(opacity: 0))
        XCTAssertNil(settings.cornerRadius)
        XCTAssertEqual(.none, settings.displayAnimation!)
        XCTAssertEqual(.none, settings.dismissAnimation!)
        XCTAssertNil(settings.gestures)
    }

    func testGetMessageSettingsEmptyGestures() throws {
        // setup
        let params: [String: Any] = [
            MessagingConstants.Event.Data.Key.TRIGGERED_CONSEQUENCE: [
                MessagingConstants.Event.Data.Key.DETAIL: [
                    MessagingConstants.Event.Data.Key.IAM.MOBILE_PARAMETERS: [
                        MessagingConstants.Event.Data.Key.IAM.GESTURES: [:] as [String: Any]
                    ]
                ]
            ]
        ]
        let event = TestableMobileParameters.getMobileParametersEvent(withData: params)

        // test
        let settings = event.getMessageSettings(withParent: self)

        // verify
        XCTAssertNotNil(settings)
        XCTAssertNil(settings.gestures)
    }

    // MARK: - Testing Message Object Validation

    func testInAppMessageObjectValidation() throws {
        // setup
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE)

        // verify
        XCTAssertTrue(event.containsValidInAppMessage)
    }
    
    func testContainsValidInAppMessageNotIAMEvent() throws {
        // setup
        let event = Event(name: "not iam", type: "type", source: "source", data: nil)

        // verify
        XCTAssertFalse(event.containsValidInAppMessage)
    }

    // MARK: - Testing Invalid Events

    func testWrongConsequenceType() throws {
        // setup
        let triggeredConsequence: [String: Any] = [
            MessagingConstants.Event.Data.Key.TYPE: "Invalid",
            MessagingConstants.Event.Data.Key.ID: UUID().uuidString,
            MessagingConstants.Event.Data.Key.DETAIL: [:] as [String: Any]
        ]
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE, triggeredConsequence: triggeredConsequence)

        // verify
        XCTAssertFalse(event.isCjmIamConsequence)
        XCTAssertNil(event.template)
        XCTAssertNil(event.html)
        XCTAssertNil(event.remoteAssets)
    }

    func testNoConsequenceType() throws {
        // setup
        let triggeredConsequence: [String: Any] = [
            MessagingConstants.Event.Data.Key.ID: UUID().uuidString,
            MessagingConstants.Event.Data.Key.DETAIL: [:] as [String: Any]
        ]
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE, triggeredConsequence: triggeredConsequence)

        // verify
        XCTAssertFalse(event.isCjmIamConsequence)
        XCTAssertNil(event.template)
        XCTAssertNil(event.html)
        XCTAssertNil(event.remoteAssets)
    }

    func testMissingValuesInDetails() throws {
        // setup
        let triggeredConsequence: [String: Any] = [
            MessagingConstants.Event.Data.Key.TYPE: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE,
            MessagingConstants.Event.Data.Key.ID: UUID().uuidString,
            MessagingConstants.Event.Data.Key.DETAIL: ["unintersting": "data"]
        ]
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE, triggeredConsequence: triggeredConsequence)

        // verify
        XCTAssertTrue(event.isCjmIamConsequence)
        XCTAssertNil(event.template)
        XCTAssertNil(event.html)
        XCTAssertNil(event.remoteAssets)
    }

    func testNoDetails() throws {
        // setup
        let triggeredConsequence: [String: Any] = [
            MessagingConstants.Event.Data.Key.TYPE: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE,
            MessagingConstants.Event.Data.Key.ID: UUID().uuidString
        ]
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE, triggeredConsequence: triggeredConsequence)

        // verify
        XCTAssertTrue(event.isCjmIamConsequence)
        XCTAssertNil(event.template)
        XCTAssertNil(event.html)
        XCTAssertNil(event.remoteAssets)
    }

    func testInAppMessageObjectValidationNoRemoteAssets() throws {
        // setup
        let keysToRemove = [MessagingConstants.Event.Data.Key.IAM.REMOTE_ASSETS]
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE, removeDetails: keysToRemove)

        // verify
        XCTAssertNil(event.remoteAssets)
        XCTAssertTrue(event.containsValidInAppMessage, "remoteAssets is not a required field")
    }

    func testInAppMessageObjectValidationNoTemplate() throws {
        // setup
        let keysToRemove = [MessagingConstants.Event.Data.Key.IAM.TEMPLATE]
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE, removeDetails: keysToRemove)

        // verify
        XCTAssertNil(event.template)
        XCTAssertTrue(event.containsValidInAppMessage, "template is not a required field")
    }

    func testInAppMessageObjectValidationNoHtml() throws {
        // setup
        let keysToRemove = [MessagingConstants.Event.Data.Key.IAM.HTML]
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE, removeDetails: keysToRemove)

        // verify
        XCTAssertNil(event.html)
        XCTAssertFalse(event.containsValidInAppMessage, "html is a required field")
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

    func testIsPersonalizationDecisionResponseNotPersonalizationSource() throws {
        // setup
        let event = getAEPResponseEvent(source: "notPersonalization")

        // verify
        XCTAssertFalse(event.isPersonalizationDecisionResponse)
    }
    
    func testRequestEventIdHappy() throws {
        // setup
        let event = getAEPResponseEvent()

        // verify
        XCTAssertEqual(mockRequestEventId, event.requestEventId)
    }
    
    func testRequestEventIdNotPresent() throws {
        // setup
        let event = getAEPResponseEvent(data: [:])

        // verify
        XCTAssertNil(event.requestEventId)
    }
    
    func testPayloadHappy() throws {
        // setup
        let event = getAEPResponseEvent()
        
        // verify
        XCTAssertEqual(2, event.payload?.count)
        
        let p1 = event.payload?[0]
        XCTAssertNotNil(p1)
        XCTAssertEqual(mockPayloadId1, p1?.uniqueId)
        XCTAssertEqual(mockAppSurface, p1?.scope)
        let scopeDetails1 = p1?.scopeDetails
        XCTAssertNotNil(scopeDetails1)
        XCTAssertEqual(1, scopeDetails1?.count)
        let item1 = p1?.items.first
        XCTAssertNotNil(item1)
        XCTAssertEqual(mockContent1, item1?.itemData?["content"] as? String)
        
        let p2 = event.payload?[1]
        XCTAssertNotNil(p2)
        XCTAssertEqual(mockPayloadId2, p2?.uniqueId)
        XCTAssertEqual(mockAppSurface, p2?.scope)
        let scopeDetails2 = p2?.scopeDetails
        XCTAssertNotNil(scopeDetails2)
        XCTAssertEqual(1, scopeDetails2?.count)
        let item2 = p2?.items.first
        XCTAssertNotNil(item2)
        XCTAssertEqual(mockContent2, item2?.itemData?["content"] as? String)
    }
    
    func testPayloadIsNil() throws {
        // setup
        let payload: [[String: Any]]? = nil
        let event = getAEPResponseEvent(data: ["payload": payload as Any])

        // verify
        XCTAssertNil(event.payload)
        XCTAssertNil(event.scope)
    }

    func testPayloadIsEmpty() throws {
        // setup
        let payload: [[String: Any]]? = []
        let event = getAEPResponseEvent(data: ["payload": payload as Any])

        // verify
        XCTAssertEqual(0, event.payload?.count)
        XCTAssertNil(event.scope)
    }
    
    func testPayloadContainsInvalidProposition() throws {
        // setup
        let payload: [[String: Any]]? = [
            [
                "i am not a valid payload": "and will throw a json decoder error"
            ]
        ]
        let event = getAEPResponseEvent(data: ["payload": payload as Any])

        // verify
        XCTAssertEqual(0, event.payload?.count)
        XCTAssertNil(event.scope)
    }
    
    func testScopeHappy() throws {
        // setup
        let event = getAEPResponseEvent()

        // verify
        XCTAssertEqual(mockAppSurface, event.scope)
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

    // MARK: - Testing push click-through events

    func testXdmEventType() throws {
        // setup
        let event = getClickthroughEvent()

        // verify
        XCTAssertEqual(mockXdmEventType, event.xdmEventType)
    }

    func testMessagingId() throws {
        // setup
        let event = getClickthroughEvent()

        // verify
        XCTAssertEqual(mockMessagingId, event.messagingId)
    }

    func testActionId() throws {
        // setup
        let event = getClickthroughEvent()

        // verify
        XCTAssertEqual(mockActionId, event.actionId)
    }

    func testApplicationOpened() throws {
        // setup
        let event = getClickthroughEvent()

        // verify
        XCTAssertEqual(mockApplicationOpened, event.applicationOpened)
    }

    func testXdmMixins() throws {
        // setup
        let event = getClickthroughEvent()

        // verify
        XCTAssertNotNil(event.mixins)
        XCTAssertEqual(1, event.mixins?.count)
        XCTAssertEqual("present", event.mixins?["mixin"] as! String)
    }

    func testXdmCjmData() throws {
        // setup
        let event = getClickthroughEvent()

        // verify
        XCTAssertNotNil(event.cjm)
        XCTAssertEqual(1, event.cjm?.count)
        XCTAssertEqual("present", event.cjm?["cjm"] as! String)
    }

    func testMessagingRequestContentEvent() throws {
        // setup
        let event = getClickthroughEvent()

        // verify
        XCTAssertTrue(event.isMessagingRequestContentEvent)
    }

    func testEmptyPushMessageEventData() throws {
        // setup
        let event = Event(name: "name", type: "type", source: "source", data: nil)

        // verify
        XCTAssertNil(event.xdmEventType)
        XCTAssertNil(event.messagingId)
        XCTAssertNil(event.actionId)
        XCTAssertFalse(event.applicationOpened)
        XCTAssertNil(event.mixins)
        XCTAssertNil(event.cjm)
        XCTAssertNil(event.adobeXdm)
    }
    
    // MARK: - Test SetPushIdentifier Events
    
    func testIsGenericIdentityRequestContentEventHappy() throws {
        // setup
        let event = getSetPushIdentifierEvent()
        
        // verify
        XCTAssertTrue(event.isGenericIdentityRequestContentEvent)
    }
    
    func testIsGenericIdentityRequestContentEventNotHappy() throws {
        // setup
        let event = getClickthroughEvent()
        
        // verify
        XCTAssertFalse(event.isGenericIdentityRequestContentEvent)
    }
    
    func testPushTokenHappy() throws {
        // setup
        let event = getSetPushIdentifierEvent()
        
        // verify
        XCTAssertEqual(mockPushToken, event.token)
    }
    
    func testPushTokenNoToken() throws {
        // setup
        let event = getSetPushIdentifierEvent(overriddingData: [:])
        
        // verify
        XCTAssertNil(event.token)
    }
    
    // MARK: - update propositions api events
    
    func testIsUpdatePropositionsEvent() throws {
        // setup
        let event = Event(name: "s", type: EventType.messaging, source: EventSource.requestContent, data: ["updatepropositions": true])
        let event2 = Event(name: "s", type: EventType.rulesEngine, source: EventSource.requestContent, data: ["updatepropositions": true])
        let event3 = Event(name: "s", type: EventType.messaging, source: EventSource.requestIdentity, data: ["updatepropositions": true])
        let event4 = Event(name: "s", type: EventType.messaging, source: EventSource.requestContent, data: ["nope": true])
        let event5 = Event(name: "s", type: EventType.messaging, source: EventSource.requestContent, data: ["updatepropositions": false])
        
        // verify
        XCTAssertTrue(event.isUpdatePropositionsEvent)
        XCTAssertFalse(event2.isUpdatePropositionsEvent)
        XCTAssertFalse(event3.isUpdatePropositionsEvent)
        XCTAssertFalse(event4.isUpdatePropositionsEvent)
        XCTAssertFalse(event5.isUpdatePropositionsEvent)
    }
    
    func testSurfaces() throws {
        // setup
        let event = Event(name: "s", type: EventType.messaging, source: EventSource.requestContent, data: ["surfaces": [
            [ "uri": "https://blah" ],
            [ "uri": "https://otherBlah/somepath/yay" ]
        ]])
        
        // verify
        let result = event.surfaces
        XCTAssertEqual(2, result?.count)
        let first = result?.first
        XCTAssertEqual("https://blah", first?.uri)
        let second = result?[1]
        XCTAssertEqual("https://otherBlah/somepath/yay", second?.uri)
    }
    
    func testSurfacesNoSurfaces() throws {
        // setup
        let event = Event(name: "s", type: EventType.messaging, source: EventSource.requestContent, data: [:])
        
        // verify
        XCTAssertNil(event.surfaces)        
    }
    
    // MARK: - get propositions api events
    
    func testIsGetPropositionsEvent() throws {
        // setup
        let event = Event(name: "s", type: EventType.messaging, source: EventSource.requestContent, data: ["getpropositions": true])
        let event2 = Event(name: "s", type: EventType.rulesEngine, source: EventSource.requestContent, data: ["getpropositions": true])
        let event3 = Event(name: "s", type: EventType.messaging, source: EventSource.requestIdentity, data: ["getpropositions": true])
        let event4 = Event(name: "s", type: EventType.messaging, source: EventSource.requestContent, data: ["nope": true])
        let event5 = Event(name: "s", type: EventType.messaging, source: EventSource.requestContent, data: ["getpropositions": false])
        
        // verify
        XCTAssertTrue(event.isGetPropositionsEvent)
        XCTAssertFalse(event2.isGetPropositionsEvent)
        XCTAssertFalse(event3.isGetPropositionsEvent)
        XCTAssertFalse(event4.isGetPropositionsEvent)
        XCTAssertFalse(event5.isGetPropositionsEvent)
    }
    
    func testPropositions() throws {
        // setup
        let propositionJson = JSONFileLoader.getRulesJsonFromFile("inappPropositionV1")
        let event = Event(name: "name", type: "type", source: "source", data: ["propositions": [ propositionJson ]])
        
        // verify
        XCTAssertNotNil(event.propositions)
        XCTAssertEqual(1, event.propositions?.count)
    }
    
    func testPropositionsBUTTHEREARENONE() throws {
        // setup
        let propositionJson = JSONFileLoader.getRulesJsonFromFile("inappPropositionV1")
        let event = Event(name: "name", type: "type", source: "source", data: ["THESEARENOTpropositions": [ propositionJson ]])
        
        // verify
        XCTAssertNil(event.propositions)
    }
    
    func testResponseError() throws {
        // setup
        let event = Event(name: "name", type: "type", source: "source", data: ["responseerror": 1 ])
        let event2 = Event(name: "name", type: "type", source: "source", data: ["nothing": 1 ])
        
        // verify
        XCTAssertNotNil(event.responseError)
        XCTAssertEqual(event.responseError, .callbackTimeout)
        XCTAssertNil(event2.responseError)        
    }
    
    // MARK: - error response event
    
    func testCreateErrorResponseEvent() throws {
        // setup
        let event = getClickthroughEvent()
        
        // test
        let responseEvent = event.createErrorResponseEvent(.invalidResponse)
        
        // verify
        XCTAssertEqual("Message propositions response", responseEvent.name)
        XCTAssertEqual(EventType.messaging, responseEvent.type)
        XCTAssertEqual(EventSource.responseContent, responseEvent.source)
        XCTAssertEqual(1, responseEvent.data?.count)
        let error = AEPError(rawValue: responseEvent.data?["responseerror"] as? Int ?? 0)
        XCTAssertEqual(error, .invalidResponse)
    }
}
