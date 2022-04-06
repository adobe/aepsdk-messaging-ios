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
    let testHtml = "<html>All ur base are belong to us</html>"
    let testAssets = ["asset1", "asset2"]
    let mockActivityId = "mockActivityId"
    let mockPlacementId = "mockPlacementId"
    let mockContent1 = "content1"
    let mockContent2 = "content2"

    /// Push values
    let mockXdmEventType = "xdmEventType"
    let mockMessagingId = "12345"
    let mockActionId = "67890"
    let mockBundleIdentifier = "com.apple.dt.xctest.tool"
    let mockDecisionScopeEncoded = "eyJ4ZG06bmFtZSI6ImNvbS5hcHBsZS5kdC54Y3Rlc3QudG9vbCJ9" // {"xdm:name":"com.apple.dt.xctest.tool"}
    let mockApplicationOpened = false
    let mockMixins: [String: Any] = [
        "mixin": "present"
    ]
    let mockCjm: [String: Any] = [
        "cjm": "present"
    ]

    // before each
    override func setUp() {
        messaging = Messaging(runtime: TestableExtensionRuntime())
        messaging.onRegistered()
    }

    // MARK: - Helpers

    /// Gets an event to use for simulating a rules consequence
    func getRulesResponseEvent(type: String? = MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE,
                               triggeredConsequence: [String: Any]? = nil,
                               removeDetails: [String]? = nil,
                               xdmExperienceInfo: [String: Any]? = nil) -> Event {
        let xdmExperienceInfo = xdmExperienceInfo ?? [
            MessagingConstants.XDM.AdobeKeys.MIXINS: [
                MessagingConstants.XDM.AdobeKeys.EXPERIENCE: [
                    "experience": "everything",
                    MessagingConstants.XDM.AdobeKeys.CUSTOMER_JOURNEY_MANAGEMENT: [
                        MessagingConstants.XDM.AdobeKeys.MESSAGE_EXECUTION: [
                            MessagingConstants.XDM.AdobeKeys.MESSAGE_EXECUTION_ID: "552"
                        ]
                    ]
                ]
            ]
        ]

        // details are the same for postback and pii, different for open url
        var details = type == MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE ? [
            MessagingConstants.Event.Data.Key.IAM.TEMPLATE: MessagingConstants.Event.Data.Values.IAM.FULLSCREEN,
            MessagingConstants.Event.Data.Key.IAM.HTML: testHtml,
            MessagingConstants.Event.Data.Key.IAM.REMOTE_ASSETS: testAssets,
            MessagingConstants.XDM.AdobeKeys._XDM: xdmExperienceInfo
        ] : [:]

        if let keysToBeRemoved = removeDetails {
            for key in keysToBeRemoved {
                details.removeValue(forKey: key)
            }
        }

        let triggeredConsequence: [String: Any] = [
            MessagingConstants.Event.Data.Key.TRIGGERED_CONSEQUENCE: triggeredConsequence ?? [
                MessagingConstants.Event.Data.Key.ID: UUID().uuidString,
                MessagingConstants.Event.Data.Key.TYPE: type!,
                MessagingConstants.Event.Data.Key.DETAIL: details
            ],
        ]
        let rulesEvent = Event(name: "Test Rules Engine response",
                               type: EventType.rulesEngine,
                               source: EventSource.responseContent,
                               data: triggeredConsequence)
        return rulesEvent
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
                "scope": mockDecisionScopeEncoded,
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

    // MARK: - Testing Happy Path

    func testInAppMessageConsequenceType() throws {
        // setup
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE)

        // verify
        XCTAssertTrue(event.isInAppMessage)
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

    func testInAppMessageExperienceInfo() throws {
        // setup
        let event = getRulesResponseEvent()

        // verify
        XCTAssertNotNil(event.experienceInfo)
        XCTAssertEqual(2, event.experienceInfo?.count)
        let experienceData = event.experienceInfo!["experience"] as! String
        XCTAssertEqual("everything", experienceData)
    }

    func testInAppMessageExperienceInfoNoMixins() throws {
        // setup
        let badXdmDictionary = [
            MessagingConstants.XDM.AdobeKeys._XDM: [
                "no mixins here": true
            ]
        ]
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE, triggeredConsequence: nil, removeDetails: nil, xdmExperienceInfo: badXdmDictionary)

        // verify
        XCTAssertNil(event.experienceInfo)
    }

    func testInAppMessageExperienceInfoNoXDM() throws {
        // setup
        let badXdmDictionary = [
            "not xdm": true
        ]
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE, triggeredConsequence: nil, removeDetails: nil, xdmExperienceInfo: badXdmDictionary)

        // verify
        XCTAssertNil(event.experienceInfo)
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
                        MessagingConstants.Event.Data.Key.IAM.GESTURES: [:]
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

    // MARK: - Testing Invalid Events

    func testWrongConsequenceType() throws {
        // setup
        let triggeredConsequence: [String: Any] = [
            MessagingConstants.Event.Data.Key.TYPE: "Invalid",
            MessagingConstants.Event.Data.Key.ID: UUID().uuidString,
            MessagingConstants.Event.Data.Key.DETAIL: [:]
        ]
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE, triggeredConsequence: triggeredConsequence)

        // verify
        XCTAssertFalse(event.isInAppMessage)
        XCTAssertNil(event.template)
        XCTAssertNil(event.html)
        XCTAssertNil(event.remoteAssets)
    }

    func testNoConsequenceType() throws {
        // setup
        let triggeredConsequence: [String: Any] = [
            MessagingConstants.Event.Data.Key.ID: UUID().uuidString,
            MessagingConstants.Event.Data.Key.DETAIL: [:]
        ]
        let event = getRulesResponseEvent(type: MessagingConstants.ConsequenceTypes.IN_APP_MESSAGE, triggeredConsequence: triggeredConsequence)

        // verify
        XCTAssertFalse(event.isInAppMessage)
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
        XCTAssertTrue(event.isInAppMessage)
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
        XCTAssertTrue(event.isInAppMessage)
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
    
    func testOfferDecisionScopeHappy() {
        // setup
        let event = getAEPResponseEvent()
        
        // verify
        XCTAssertEqual(mockBundleIdentifier, event.offerDecisionScope)
    }
    
    func testOfferDecisionScopeEmpty() {
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
        XCTAssertNil(event.offerDecisionScope)
    }
    
    func testOfferDecisionScopeMalformedFormat() {
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
            "scope": "nope wrong scope",
            "items": [item1, item2]
        ]
        let event = getAEPResponseEvent(data: ["payload": [payload]])
        
        // verify
        XCTAssertNil(event.offerDecisionScope)
    }

    func testPayloadIsNil() {
        // setup
        let payload: [[String: Any]]? = nil
        let event = getAEPResponseEvent(data: ["payload": payload as Any])

        // verify
        XCTAssertNil(event.offerActivityId)
        XCTAssertNil(event.offerPlacementId)
        XCTAssertNil(event.offerDecisionScope)
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
}
