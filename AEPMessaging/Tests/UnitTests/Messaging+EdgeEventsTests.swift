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

import Foundation
import XCTest

import AEPCore
@testable import AEPMessaging
import AEPServices
import AEPTestUtils

class MessagingEdgeEventsTests: XCTestCase {
    var mockRuntime: TestableExtensionRuntime!
    var messaging: Messaging!
    var mockMessagingRulesEngine: MockMessagingRulesEngine!
    var mockFeedRulesEngine: MockContentCardRulesEngine!
    var mockLaunchRulesEngine: MockLaunchRulesEngine!
    var mockCache: MockCache!
    var stateManager: MessagingStateManager!
    let mockIamSurface = "mobileapp://com.apple.dt.xctest.tool"

    // Mock constants
    let MOCK_ECID = "mock_ecid"
    let MOCK_EVENT_DATASET = "mock_event_dataset"
    let MOCK_EXP_ORG_ID = "mock_exp_org_id"
    let MOCK_PUSH_TOKEN = "mock_pushToken"
    let MOCK_PUSH_PLATFORM = "apns"

    override func setUp() {
        mockRuntime = TestableExtensionRuntime()
        mockCache = MockCache(name: "mockCache")
        mockLaunchRulesEngine = MockLaunchRulesEngine(name: "mcokLaunchRulesEngine", extensionRuntime: mockRuntime)
        mockMessagingRulesEngine = MockMessagingRulesEngine(extensionRuntime: mockRuntime, launchRulesEngine: mockLaunchRulesEngine, cache: mockCache)
        mockFeedRulesEngine = MockContentCardRulesEngine(extensionRuntime: mockRuntime, launchRulesEngine: mockLaunchRulesEngine)
        stateManager = MessagingStateManager()
        messaging = Messaging(runtime: mockRuntime, rulesEngine: mockMessagingRulesEngine, contentCardRulesEngine: mockFeedRulesEngine, expectedSurfaceUri: mockIamSurface, cache: mockCache, stateManager: stateManager)
    }

    // MARK: - helpers

    //    {
    //        "eventType" : "pushTracking.applicationOpened",
    //        "applicationOpened" : true,
    //        "id" : "Local Notification",
    //        "adobe_xdm" : {
    //            "cjm" : {
    //                "_experience" : {
    //                    "customerJourneyManagement" : {
    //                        "messageExecution" : {
    //                            "journeyVersionInstanceId" : "someJourneyVersionInstanceId",
    //                            "messageExecutionID" : "16-Sept-postman",
    //                            "journeyVersionID" : "some-journeyVersionId",
    //                            "messageID" : "567"
    //                        }
    //                    }
    //                }
    //            }
    //        }
    //    }
    func getMessageTrackingEventData(addAdobeXdm: Bool? = true, addMixins: Bool? = false, addCjm: Bool? = true) -> [String: Any] {
        var data: [String: Any] = [:]
        data[MessagingConstants.Event.Data.Key.EVENT_TYPE] = "testEventType"
        data[MessagingConstants.Event.Data.Key.ID] = "testMessageId"

        if addAdobeXdm! {
            var adobeXdmData: [String: Any] = [:]
            if addCjm! {
                adobeXdmData[MessagingConstants.XDM.AdobeKeys.CJM] = [
                    MessagingConstants.XDM.AdobeKeys.EXPERIENCE: [
                        MessagingConstants.XDM.AdobeKeys.CUSTOMER_JOURNEY_MANAGEMENT: [
                            "value": "present"
                        ]
                    ]
                ]
            }
            if addMixins! {
                adobeXdmData[MessagingConstants.XDM.AdobeKeys.MIXINS] = [
                    "mixin": "present"
                ]
            }
            data[MessagingConstants.XDM.Key.ADOBE_XDM] = adobeXdmData
        }

        return data
    }

    func setConfigSharedState(_ data: [String: Any]? = nil) {
        let mockConfig = [MessagingConstants.SharedState.Configuration.EXPERIENCE_EVENT_DATASET: MOCK_EVENT_DATASET] as [String: Any]
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME,
                                        data: (value: data ?? mockConfig, status: SharedStateStatus.set))
    }

    func setIdentitySharedState(_ data: [String: Any]? = nil) {
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: MOCK_ECID]]]]
        mockRuntime.simulateXDMSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME,
                                           data: (value: data ?? mockEdgeIdentity, status: SharedStateStatus.set))
    }

    // MARK: - tests

    func testHandleTrackingInfoHappy() throws {
        // setup
        setConfigSharedState()
        setIdentitySharedState()
        let event = Event(name: "trackingInfo", type: EventType.messaging, source: EventSource.requestContent, data: getMessageTrackingEventData())

        // test
        messaging.sendPushInteraction(event: event)

        // verify tracking status event
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        let dispatchedStatusEvent = mockRuntime.firstEvent
        XCTAssertEqual(EventType.messaging, dispatchedStatusEvent?.type)
        XCTAssertEqual(EventSource.responseContent, dispatchedStatusEvent?.source)
        XCTAssertEqual(dispatchedStatusEvent?.pushTrackingStatus, .trackingInitiated)
        
        
        // verify edge request event
        let dispatchedEdgeRequestEvent = mockRuntime.secondEvent
        XCTAssertEqual(EventType.edge, dispatchedEdgeRequestEvent?.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEdgeRequestEvent?.source)
        let dispatchedEventData = dispatchedEdgeRequestEvent?.data
        XCTAssertNotNil(dispatchedEventData)
        XCTAssertEqual(2, dispatchedEventData?.count)
        let meta = dispatchedEventData?["meta"] as? [String: Any]
        let xdm = dispatchedEventData?["xdm"] as? [String: Any]
        let collect = meta?["collect"] as? [String: Any]
        XCTAssertEqual(MOCK_EVENT_DATASET, collect?["datasetId"] as? String)
        let pushTracking = xdm?["pushNotificationTracking"] as? [String: Any]
        let pushProvider = pushTracking?["pushProvider"] as? String
        XCTAssertEqual("apns", pushProvider)
        let pushProviderMessageId = pushTracking?["pushProviderMessageID"] as? String
        XCTAssertEqual("testMessageId", pushProviderMessageId)
        let application = xdm?["application"] as? [String: Any]
        XCTAssertEqual(0, (application?["launches"] as? [String: Any])?["value"] as? Int)
        let eventType = xdm?["eventType"] as? String
        XCTAssertEqual("testEventType", eventType)
    }

    func testGetPushPlatformNormal() throws {
        // setup
        setConfigSharedState()
        let event = Event(name: "trackingInfo", type: EventType.messaging, source: EventSource.requestContent, data: getMessageTrackingEventData())

        // test
        let result = messaging.getPushPlatform(forEvent: event)

        // verify
        XCTAssertEqual(MessagingConstants.XDM.Push.Value.APNS, result)
    }

    func testGetPushPlatformSandbox() throws {
        // setup
        setConfigSharedState([
            MessagingConstants.SharedState.Configuration.EXPERIENCE_EVENT_DATASET: MOCK_EVENT_DATASET,
            MessagingConstants.SharedState.Configuration.USE_SANDBOX: true
        ])
        let event = Event(name: "trackingInfo", type: EventType.messaging, source: EventSource.requestContent, data: getMessageTrackingEventData())

        // test
        let result = messaging.getPushPlatform(forEvent: event)

        // verify
        XCTAssertEqual(MessagingConstants.XDM.Push.Value.APNS_SANDBOX, result)
    }

    func testGetPushPlatformNoConfig() throws {
        // setup
        let event = Event(name: "trackingInfo", type: EventType.messaging, source: EventSource.requestContent, data: getMessageTrackingEventData())

        // test
        let result = messaging.getPushPlatform(forEvent: event)

        // verify
        XCTAssertEqual(MessagingConstants.XDM.Push.Value.APNS, result)
    }

    func testHandleTrackingInfoActionIdPresent() throws {
        // setup
        let eventData = getMessageTrackingEventData().merging([MessagingConstants.Event.Data.Key.ACTION_ID: "superActionId"]) { _, new in new }
        setConfigSharedState()
        setIdentitySharedState()
        let event = Event(name: "trackingInfo", type: EventType.messaging, source: EventSource.requestContent, data: eventData)

        // test
        messaging.sendPushInteraction(event: event)

        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        let dispatchedInfoEvent = mockRuntime.secondEvent
        XCTAssertEqual(EventType.edge, dispatchedInfoEvent?.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedInfoEvent?.source)
        let dispatchedEventData = dispatchedInfoEvent?.data
        XCTAssertNotNil(dispatchedEventData)
        XCTAssertEqual(2, dispatchedEventData?.count)
        let xdm = dispatchedEventData?["xdm"] as? [String: Any]
        let pushTracking = xdm?["pushNotificationTracking"] as? [String: Any]
        let customAction = pushTracking?[MessagingConstants.XDM.Key.CUSTOM_ACTION] as? [String: Any]
        XCTAssertEqual("superActionId", customAction?[MessagingConstants.XDM.Key.ACTION_ID] as? String)
    }

    func testHandleTrackingInfoNoDataset() throws {
        // setup
        setConfigSharedState([:])
        setIdentitySharedState()
        let event = Event(name: "trackingInfo", type: EventType.messaging, source: EventSource.requestContent, data: getMessageTrackingEventData())

        // test
        messaging.sendPushInteraction(event: event)

        // verify tracking status event
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedStatusEvent = mockRuntime.firstEvent
        XCTAssertEqual(EventType.messaging, dispatchedStatusEvent?.type)
        XCTAssertEqual(EventSource.responseContent, dispatchedStatusEvent?.source)
        XCTAssertEqual(dispatchedStatusEvent?.pushTrackingStatus, .noDatasetConfigured)
    }

    func testHandleTrackingInfoEmptyDataset() throws {
        // setup
        setConfigSharedState([MessagingConstants.SharedState.Configuration.EXPERIENCE_EVENT_DATASET: ""])
        setIdentitySharedState()
        let event = Event(name: "trackingInfo", type: EventType.messaging, source: EventSource.requestContent, data: getMessageTrackingEventData())

        // test
        messaging.sendPushInteraction(event: event)

        // verify tracking status event
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedStatusEvent = mockRuntime.firstEvent
        XCTAssertEqual(EventType.messaging, dispatchedStatusEvent?.type)
        XCTAssertEqual(EventSource.responseContent, dispatchedStatusEvent?.source)
        XCTAssertEqual(dispatchedStatusEvent?.pushTrackingStatus, .noDatasetConfigured)
    }

    func testHandleTrackingInfoNoXdmMap() throws {
        // setup
        setConfigSharedState()
        setIdentitySharedState()
        let event = Event(name: "trackingInfo", type: EventType.messaging, source: EventSource.requestContent, data: [:])

        // test
        messaging.sendPushInteraction(event: event)

        // verify tracking status event
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedStatusEvent = mockRuntime.firstEvent
        XCTAssertEqual(EventType.messaging, dispatchedStatusEvent?.type)
        XCTAssertEqual(EventSource.responseContent, dispatchedStatusEvent?.source)
        XCTAssertEqual(dispatchedStatusEvent?.pushTrackingStatus, .unknownError)
    }

    func testHandleTrackingInfoXdmMapMessageIdNil() throws {
        // setup
        setConfigSharedState()
        setIdentitySharedState()
        let event = Event(name: "trackingInfo", type: EventType.messaging, source: EventSource.requestContent, data: [MessagingConstants.Event.Data.Key.EVENT_TYPE: "testEventType"])

        // test
        messaging.sendPushInteraction(event: event)

        // verify tracking status event
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedStatusEvent = mockRuntime.firstEvent
        XCTAssertEqual(EventType.messaging, dispatchedStatusEvent?.type)
        XCTAssertEqual(EventSource.responseContent, dispatchedStatusEvent?.source)
        XCTAssertEqual(dispatchedStatusEvent?.pushTrackingStatus, .invalidMessageId)
    }

    func testHandleTrackingInfoXdmMapMessageIdEmpty() throws {
        // setup
        setConfigSharedState()
        setIdentitySharedState()
        let event = Event(name: "trackingInfo", type: EventType.messaging, source: EventSource.requestContent, data: [MessagingConstants.Event.Data.Key.EVENT_TYPE: "testEventType", MessagingConstants.Event.Data.Key.ID: ""])

        // test
        messaging.sendPushInteraction(event: event)

        // verify tracking status event
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedStatusEvent = mockRuntime.firstEvent
        XCTAssertEqual(EventType.messaging, dispatchedStatusEvent?.type)
        XCTAssertEqual(EventSource.responseContent, dispatchedStatusEvent?.source)
        XCTAssertEqual(dispatchedStatusEvent?.pushTrackingStatus, .invalidMessageId)
    }

    func testSendPushTokenHappy() throws {
        // setup
        setConfigSharedState(["messaging.useSandbox": "false"])
        let mockEvent = Event(name: "mockName", type: "mockType", source: "mockSource", data: nil)
        
        // test
        messaging.sendPushToken(ecid: MOCK_ECID, token: MOCK_PUSH_TOKEN, event: mockEvent)

        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let pushTokenEvent = mockRuntime.firstEvent
        XCTAssertEqual(EventType.edge, pushTokenEvent?.type)
        XCTAssertEqual(EventSource.requestContent, pushTokenEvent?.source)
        let data = pushTokenEvent?.data
        let xdm = data?[MessagingConstants.XDM.Key.DATA] as? [String: Any]
        let pushDetailsArray = xdm?[MessagingConstants.XDM.Push.PUSH_NOTIFICATION_DETAILS] as? [[String: Any]]
        let pushDetails = pushDetailsArray?[0]
        XCTAssertEqual(5, pushDetails?.count)
        let appId = pushDetails?[MessagingConstants.XDM.Push.APP_ID] as? String
        XCTAssertEqual("com.adobe.ajo.e2eTestApp", appId)
        let token = pushDetails?[MessagingConstants.XDM.Push.TOKEN] as? String
        XCTAssertEqual(MOCK_PUSH_TOKEN, token)
        let platform = pushDetails?[MessagingConstants.XDM.Push.PLATFORM] as? String
        XCTAssertEqual(MOCK_PUSH_PLATFORM, platform)
        let denylisted = pushDetails?[MessagingConstants.XDM.Push.DENYLISTED] as? Bool
        XCTAssertFalse(denylisted ?? true)
        let identity = pushDetails?[MessagingConstants.XDM.Push.IDENTITY] as? [String: Any]
        XCTAssertEqual(2, identity?.count)
        let pushId = identity?[MessagingConstants.XDM.Push.ID] as? String
        XCTAssertEqual(MOCK_ECID, pushId)
        let namespace = identity?[MessagingConstants.XDM.Push.NAMESPACE] as? [String: Any]
        XCTAssertEqual(1, namespace?.count)
        let pushCode = namespace?[MessagingConstants.XDM.Push.CODE] as? String
        XCTAssertEqual(MessagingConstants.XDM.Push.Value.ECID, pushCode)
    }

    func testAddAdobeDataHappy() throws {
        // setup
        let eventData = getMessageTrackingEventData()
        setConfigSharedState()
        setIdentitySharedState()
        let event = Event(name: "trackingInfo", type: EventType.messaging, source: EventSource.requestContent, data: eventData)

        // test
        messaging.sendPushInteraction(event: event)

        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.secondEvent
        let dispatchedXdmMap = dispatchedEvent?.data?[MessagingConstants.XDM.Key.XDM] as? [String: Any]
        XCTAssertEqual(4, dispatchedXdmMap?.count)
        XCTAssertNotNil(dispatchedXdmMap?[MessagingConstants.XDM.Key.PUSH_NOTIFICATION_TRACKING])
        XCTAssertNotNil(dispatchedXdmMap?[MessagingConstants.XDM.Key.EVENT_TYPE])
        XCTAssertNotNil(dispatchedXdmMap?[MessagingConstants.XDM.AdobeKeys.APPLICATION])
        let experienceDict = dispatchedXdmMap?[MessagingConstants.XDM.AdobeKeys.EXPERIENCE] as? [String: Any]
        XCTAssertNotNil(experienceDict)
        let cjmDict = experienceDict?[MessagingConstants.XDM.AdobeKeys.CUSTOMER_JOURNEY_MANAGEMENT] as? [String: Any]
        XCTAssertEqual(3, cjmDict?.count)
        XCTAssertEqual("present", cjmDict?["value"] as? String)
        let pushChannelDict = cjmDict?["pushChannelContext"] as? [String: Any]
        XCTAssertEqual(1, pushChannelDict?.count)
        XCTAssertEqual("apns", pushChannelDict?["platform"] as? String)
        let messageProfileDict = cjmDict?["messageProfile"] as? [String: Any]
        XCTAssertEqual(1, messageProfileDict?.count)
        let channelDict = messageProfileDict?["channel"] as? [String: Any]
        XCTAssertEqual(1, channelDict?.count)
        XCTAssertEqual("https://ns.adobe.com/xdm/channels/push", channelDict?["_id"] as? String)
    }

    func testAddAdobeDataNoAdobeXdm() throws {
        // setup
        let eventData = getMessageTrackingEventData(addAdobeXdm: false)
        setConfigSharedState()
        setIdentitySharedState()
        let event = Event(name: "trackingInfo", type: EventType.messaging, source: EventSource.requestContent, data: eventData)

        // test
        messaging.sendPushInteraction(event: event)

        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.secondEvent
        let dispatchedXdmMap = dispatchedEvent?.data?[MessagingConstants.XDM.Key.XDM] as? [String: Any]
        XCTAssertEqual(3, dispatchedXdmMap?.count)
        XCTAssertNotNil(dispatchedXdmMap?[MessagingConstants.XDM.Key.PUSH_NOTIFICATION_TRACKING])
        XCTAssertNotNil(dispatchedXdmMap?[MessagingConstants.XDM.Key.EVENT_TYPE])
        XCTAssertNotNil(dispatchedXdmMap?[MessagingConstants.XDM.AdobeKeys.APPLICATION])
    }

    func testAddAdobeDataMixins() throws {
        // setup
        let eventData = getMessageTrackingEventData(addMixins: true)
        setConfigSharedState()
        setIdentitySharedState()
        let event = Event(name: "trackingInfo", type: EventType.messaging, source: EventSource.requestContent, data: eventData)

        // test
        messaging.sendPushInteraction(event: event)

        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.secondEvent
        let dispatchedXdmMap = dispatchedEvent?.data?[MessagingConstants.XDM.Key.XDM] as? [String: Any]
        XCTAssertEqual(4, dispatchedXdmMap?.count)
        XCTAssertNotNil(dispatchedXdmMap?[MessagingConstants.XDM.Key.PUSH_NOTIFICATION_TRACKING])
        XCTAssertNotNil(dispatchedXdmMap?[MessagingConstants.XDM.Key.EVENT_TYPE])
        XCTAssertNotNil(dispatchedXdmMap?[MessagingConstants.XDM.AdobeKeys.APPLICATION])
        XCTAssertEqual("present", dispatchedXdmMap?["mixin"] as? String)
    }

    func testAddAdobeDataNoMixinsNoCjmTracking() throws {
        // setup
        let eventData = getMessageTrackingEventData(addMixins: false, addCjm: false)
        setConfigSharedState()
        setIdentitySharedState()
        let event = Event(name: "trackingInfo", type: EventType.messaging, source: EventSource.requestContent, data: eventData)

        // test
        messaging.sendPushInteraction(event: event)

        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.secondEvent
        let dispatchedXdmMap = dispatchedEvent?.data?[MessagingConstants.XDM.Key.XDM] as? [String: Any]
        XCTAssertEqual(3, dispatchedXdmMap?.count)
        XCTAssertNotNil(dispatchedXdmMap?[MessagingConstants.XDM.Key.PUSH_NOTIFICATION_TRACKING])
        XCTAssertNotNil(dispatchedXdmMap?[MessagingConstants.XDM.Key.EVENT_TYPE])
        XCTAssertNotNil(dispatchedXdmMap?[MessagingConstants.XDM.AdobeKeys.APPLICATION])
    }

    func testAddApplicationDataAppOpened() throws {
        // setup
        let eventData = getMessageTrackingEventData().merging([MessagingConstants.Event.Data.Key.APPLICATION_OPENED: true]) { _, new in new }
        setConfigSharedState()
        setIdentitySharedState()
        let event = Event(name: "trackingInfo", type: EventType.messaging, source: EventSource.requestContent, data: eventData)

        // test
        messaging.sendPushInteraction(event: event)

        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.secondEvent
        let dispatchedXdmMap = dispatchedEvent?.data?[MessagingConstants.XDM.Key.XDM] as? [String: Any]
        let applicationData = dispatchedXdmMap?[MessagingConstants.XDM.AdobeKeys.APPLICATION] as? [String: Any]
        XCTAssertNotNil(applicationData)
        let launchesData = applicationData?[MessagingConstants.XDM.AdobeKeys.LAUNCHES] as? [String: Any]
        XCTAssertNotNil(launchesData)
        XCTAssertEqual(1, launchesData?[MessagingConstants.XDM.AdobeKeys.LAUNCHES_VALUE] as? Int)
    }

    func testAddApplicationDataAppNotOpened() throws {
        // setup
        let eventData = getMessageTrackingEventData().merging([MessagingConstants.Event.Data.Key.APPLICATION_OPENED: false]) { _, new in new }
        setConfigSharedState()
        setIdentitySharedState()
        let event = Event(name: "trackingInfo", type: EventType.messaging, source: EventSource.requestContent, data: eventData)

        // test
        messaging.sendPushInteraction(event: event)

        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.secondEvent
        let dispatchedXdmMap = dispatchedEvent?.data?[MessagingConstants.XDM.Key.XDM] as? [String: Any]
        let applicationData = dispatchedXdmMap?[MessagingConstants.XDM.AdobeKeys.APPLICATION] as? [String: Any]
        XCTAssertNotNil(applicationData)
        let launchesData = applicationData?[MessagingConstants.XDM.AdobeKeys.LAUNCHES] as? [String: Any]
        XCTAssertNotNil(launchesData)
        XCTAssertEqual(0, launchesData?[MessagingConstants.XDM.AdobeKeys.LAUNCHES_VALUE] as? Int)
    }
    
//    func testSendPropositionInteractionInteract() throws {
//        // setup
//        setConfigSharedState()
//        setIdentitySharedState()
//        let mockEvent = Event(name: "triggeringEvent", type: EventType.messaging, source: EventSource.requestContent, data: nil)
//        let mockEdgeEventType = MessagingEdgeEventType.interact
//        let mockInteraction = "swords"
//        let mockMessage = MockMessage(parent: messaging, triggeringEvent: mockEvent)
//        mockMessage.propositionInfo = PropositionInfo(id: "propId", scope: "propScope", scopeDetails: ["correlationID": "mockCorrelationID", "characteristics":["cjmEventToken":"abcd"]])
//        
//        // test
//        messaging.sendPropositionInteraction(withXdm: [:])
//        
//        // verify
//        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
//        let dispatchedEvent = mockRuntime.firstEvent
//        // validate type and source
//        XCTAssertEqual(EventType.edge, dispatchedEvent?.type)
//        XCTAssertEqual(EventSource.requestContent, dispatchedEvent?.source)
//        // validate event mask entries
//        XCTAssertEqual("iam.eventType", dispatchedEvent?.mask?[0])
//        XCTAssertEqual("iam.id", dispatchedEvent?.mask?[1])
//        XCTAssertEqual("iam.action", dispatchedEvent?.mask?[2])
//        // validate xdm map
//        let dispatchedEventData = dispatchedEvent?.data
//        let dispatchedXdmMap = dispatchedEventData?["xdm"] as? [String: Any]
//        XCTAssertEqual("decisioning.propositionInteract", dispatchedXdmMap?["eventType"] as? String)
//        let experienceMap = dispatchedXdmMap?["_experience"] as? [String: Any]
//        let decisioningMap = experienceMap?["decisioning"] as? [String: Any]
//        let propositionEventTypeMap = decisioningMap?["propositionEventType"] as? [String: Any]
//        XCTAssertEqual(1, propositionEventTypeMap?["interact"] as? Int)
//        let propositionActionMap = decisioningMap?["propositionAction"] as? [String: Any]
//        XCTAssertEqual(2, propositionActionMap?.count)
//        XCTAssertEqual(mockInteraction, propositionActionMap?["id"] as? String)
//        XCTAssertEqual(mockInteraction, propositionActionMap?["label"] as? String)
//        let propositionsArray = decisioningMap?["propositions"] as? [[String: Any]]
//        XCTAssertEqual(1, propositionsArray?.count)
//        let prop = propositionsArray?.first!
//        XCTAssertEqual("propId", prop?["id"] as? String)
//        XCTAssertEqual("propScope", prop?["scope"] as? String)
//        let scopeDetails = prop?["scopeDetails"] as? [String: Any]
//        XCTAssertEqual("mockCorrelationID", scopeDetails?["correlationID"] as? String)
//        let characteristics = scopeDetails?["characteristics"] as? [String: Any]
//        XCTAssertEqual("abcd", characteristics?["cjmEventToken"] as? String)
//    }
//    
//    func testSendPropositionInteractionDisplay() throws {
//        // setup
//        setConfigSharedState()
//        setIdentitySharedState()
//        let mockEvent = Event(name: "triggeringEvent", type: EventType.messaging, source: EventSource.requestContent, data: nil)
//        let mockEdgeEventType = MessagingEdgeEventType.display
//        let mockInteraction = "swords"
//        let mockMessage = MockMessage(parent: messaging, triggeringEvent: mockEvent)
//        mockMessage.propositionInfo = PropositionInfo(id: "propId", scope: "propScope", scopeDetails: ["correlationID": "mockCorrelationID", "characteristics":["cjmEventToken":"abcd"]])
//        
//        // test
//        messaging.sendPropositionInteraction(withXdm: [:])
//        
//        // verify
//        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
//        let dispatchedEvent = mockRuntime.firstEvent
//        // validate type and source
//        XCTAssertEqual(EventType.edge, dispatchedEvent?.type)
//        XCTAssertEqual(EventSource.requestContent, dispatchedEvent?.source)
//        // validate event mask entries
//        XCTAssertEqual("iam.eventType", dispatchedEvent?.mask?[0])
//        XCTAssertEqual("iam.id", dispatchedEvent?.mask?[1])
//        XCTAssertEqual("iam.action", dispatchedEvent?.mask?[2])
//        // validate xdm map
//        let dispatchedEventData = dispatchedEvent?.data
//        let dispatchedXdmMap = dispatchedEventData?["xdm"] as? [String: Any]
//        XCTAssertEqual("decisioning.propositionDisplay", dispatchedXdmMap?["eventType"] as? String)
//        let experienceMap = dispatchedXdmMap?["_experience"] as? [String: Any]
//        let decisioningMap = experienceMap?["decisioning"] as? [String: Any]
//        let propositionEventTypeMap = decisioningMap?["propositionEventType"] as? [String: Any]
//        XCTAssertEqual(1, propositionEventTypeMap?["display"] as? Int)
//        let propositionActionMap = decisioningMap?["propositionAction"] as? [String: Any]
//        XCTAssertNil(propositionActionMap)
//        let propositionsArray = decisioningMap?["propositions"] as? [[String: Any]]
//        XCTAssertEqual(1, propositionsArray?.count)
//        let prop = propositionsArray?.first!
//        XCTAssertEqual("propId", prop?["id"] as? String)
//        XCTAssertEqual("propScope", prop?["scope"] as? String)
//        let scopeDetails = prop?["scopeDetails"] as? [String: Any]
//        XCTAssertEqual("mockCorrelationID", scopeDetails?["correlationID"] as? String)
//        let characteristics = scopeDetails?["characteristics"] as? [String: Any]
//        XCTAssertEqual("abcd", characteristics?["cjmEventToken"] as? String)
//    }
//    
//    func testSendPropositionInteractionDismiss() throws {
//        // setup
//        setConfigSharedState()
//        setIdentitySharedState()
//        let mockEvent = Event(name: "triggeringEvent", type: EventType.messaging, source: EventSource.requestContent, data: nil)
//        let mockEdgeEventType = MessagingEdgeEventType.dismiss
//        let mockInteraction = "swords"
//        let mockMessage = MockMessage(parent: messaging, triggeringEvent: mockEvent)
//        mockMessage.propositionInfo = PropositionInfo(id: "propId", scope: "propScope", scopeDetails: ["correlationID": "mockCorrelationID", "characteristics":["cjmEventToken":"abcd"]])
//        
//        // test
//        messaging.sendPropositionInteraction(withXdm: [:])
//        
//        // verify
//        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
//        let dispatchedEvent = mockRuntime.firstEvent
//        // validate type and source
//        XCTAssertEqual(EventType.edge, dispatchedEvent?.type)
//        XCTAssertEqual(EventSource.requestContent, dispatchedEvent?.source)
//        // validate event mask entries
//        XCTAssertEqual("iam.eventType", dispatchedEvent?.mask?[0])
//        XCTAssertEqual("iam.id", dispatchedEvent?.mask?[1])
//        XCTAssertEqual("iam.action", dispatchedEvent?.mask?[2])
//        // validate xdm map
//        let dispatchedEventData = dispatchedEvent?.data
//        let dispatchedXdmMap = dispatchedEventData?["xdm"] as? [String: Any]
//        XCTAssertEqual("decisioning.propositionDismiss", dispatchedXdmMap?["eventType"] as? String)
//        let experienceMap = dispatchedXdmMap?["_experience"] as? [String: Any]
//        let decisioningMap = experienceMap?["decisioning"] as? [String: Any]
//        let propositionEventTypeMap = decisioningMap?["propositionEventType"] as? [String: Any]
//        XCTAssertEqual(1, propositionEventTypeMap?["dismiss"] as? Int)
//        let propositionActionMap = decisioningMap?["propositionAction"] as? [String: Any]
//        XCTAssertNil(propositionActionMap)
//        let propositionsArray = decisioningMap?["propositions"] as? [[String: Any]]
//        XCTAssertEqual(1, propositionsArray?.count)
//        let prop = propositionsArray?.first!
//        XCTAssertEqual("propId", prop?["id"] as? String)
//        XCTAssertEqual("propScope", prop?["scope"] as? String)
//        let scopeDetails = prop?["scopeDetails"] as? [String: Any]
//        XCTAssertEqual("mockCorrelationID", scopeDetails?["correlationID"] as? String)
//        let characteristics = scopeDetails?["characteristics"] as? [String: Any]
//        XCTAssertEqual("abcd", characteristics?["cjmEventToken"] as? String)
//    }
//    
//    func testSendPropositionInteractionTrigger() throws {
//        // setup
//        setConfigSharedState()
//        setIdentitySharedState()
//        let mockEvent = Event(name: "triggeringEvent", type: EventType.messaging, source: EventSource.requestContent, data: nil)
//        let mockEdgeEventType = MessagingEdgeEventType.trigger
//        let mockInteraction = "swords"
//        let mockMessageId = "SUCHMESSAGEVERYID"
//        let mockMessage = MockMessage(parent: messaging, triggeringEvent: mockEvent)
//        mockMessage.propositionInfo = PropositionInfo(id: "propId", scope: "propScope", scopeDetails: ["activity":["id":mockMessageId], "correlationID": "mockCorrelationID", "characteristics":["cjmEventToken":"abcd"]])
//        
//        // test
//        messaging.sendPropositionInteraction(withXdm: [:])
//        
//        // verify
//        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
//        let dispatchedEvent = mockRuntime.firstEvent
//        // validate type and source
//        XCTAssertEqual(EventType.edge, dispatchedEvent?.type)
//        XCTAssertEqual(EventSource.requestContent, dispatchedEvent?.source)
//        // validate event mask entries
//        XCTAssertEqual("iam.eventType", dispatchedEvent?.mask?[0])
//        XCTAssertEqual("iam.id", dispatchedEvent?.mask?[1])
//        XCTAssertEqual("iam.action", dispatchedEvent?.mask?[2])
//        // validate xdm map
//        let dispatchedEventData = dispatchedEvent?.data
//        let dispatchedEventHistoryData = dispatchedEventData?["iam"] as? [String: Any]
//        XCTAssertEqual(mockInteraction, dispatchedEventHistoryData?["action"] as? String)
//        XCTAssertEqual(mockEdgeEventType.propositionEventType, dispatchedEventHistoryData?["eventType"] as? String)
//        XCTAssertEqual(mockMessageId, dispatchedEventHistoryData?["id"] as? String)
//        let dispatchedXdmMap = dispatchedEventData?["xdm"] as? [String: Any]
//        XCTAssertEqual("decisioning.propositionTrigger", dispatchedXdmMap?["eventType"] as? String)
//        let experienceMap = dispatchedXdmMap?["_experience"] as? [String: Any]
//        let decisioningMap = experienceMap?["decisioning"] as? [String: Any]
//        let propositionEventTypeMap = decisioningMap?["propositionEventType"] as? [String: Any]
//        XCTAssertEqual(1, propositionEventTypeMap?["trigger"] as? Int)
//        let propositionActionMap = decisioningMap?["propositionAction"] as? [String: Any]
//        XCTAssertNil(propositionActionMap)
//        let propositionsArray = decisioningMap?["propositions"] as? [[String: Any]]
//        XCTAssertEqual(1, propositionsArray?.count)
//        let prop = propositionsArray?.first!
//        XCTAssertEqual("propId", prop?["id"] as? String)
//        XCTAssertEqual("propScope", prop?["scope"] as? String)
//        let scopeDetails = prop?["scopeDetails"] as? [String: Any]
//        XCTAssertEqual("mockCorrelationID", scopeDetails?["correlationID"] as? String)
//        let characteristics = scopeDetails?["characteristics"] as? [String: Any]
//        XCTAssertEqual("abcd", characteristics?["cjmEventToken"] as? String)
//    }
//    
//    func testSendPropositionInteractionNoScopeDetails() throws {
//        // setup
//        setConfigSharedState()
//        setIdentitySharedState()
//        let mockEvent = Event(name: "triggeringEvent", type: EventType.messaging, source: EventSource.requestContent, data: nil)
//        let mockEdgeEventType = MessagingEdgeEventType.interact
//        let mockInteraction = "swords"
//        let mockMessage = MockMessage(parent: messaging, triggeringEvent: mockEvent)
//                
//        // test
//        messaging.sendPropositionInteraction(withXdm: [:])
//        
//        // verify
//        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
//    }
}
