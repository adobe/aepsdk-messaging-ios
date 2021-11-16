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

class MessagingEdgeEventsTests: XCTestCase {
    
    var mockRuntime: TestableExtensionRuntime!
    var messaging: Messaging!
    
    // Mock constants
    let MOCK_ECID = "mock_ecid"
    let MOCK_EVENT_DATASET = "mock_event_dataset"
    let MOCK_EXP_ORG_ID = "mock_exp_org_id"
    let MOCK_PUSH_TOKEN = "mock_pushToken"
    let MOCK_PUSH_PLATFORM = "apns"
    
    override func setUp() {
        mockRuntime = TestableExtensionRuntime()
        messaging = Messaging(runtime: mockRuntime)
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
        data[MessagingConstants.Event.Data.Key.MESSAGE_ID] = "testMessageId"
        
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
        let event = Event(name: "trackingInfo", type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent, data: getMessageTrackingEventData())
        
        // test
        messaging.handleTrackingInfo(event: event)
        
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedInfoEvent = mockRuntime.firstEvent
        XCTAssertEqual(EventType.edge, dispatchedInfoEvent?.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedInfoEvent?.source)
        let dispatchedEventData = dispatchedInfoEvent?.data
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
        let event = Event(name: "trackingInfo", type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent, data: getMessageTrackingEventData())
        
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
        let event = Event(name: "trackingInfo", type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent, data: getMessageTrackingEventData())
        
        // test
        let result = messaging.getPushPlatform(forEvent: event)
        
        // verify
        XCTAssertEqual(MessagingConstants.XDM.Push.Value.APNS_SANDBOX, result)
    }
    
    func testGetPushPlatformNoConfig() throws {
        // setup
        let event = Event(name: "trackingInfo", type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent, data: getMessageTrackingEventData())
        
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
        let event = Event(name: "trackingInfo", type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent, data: eventData)
        
        // test
        messaging.handleTrackingInfo(event: event)
        
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedInfoEvent = mockRuntime.firstEvent
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
        let event = Event(name: "trackingInfo", type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent, data: getMessageTrackingEventData())
        
        // test
        messaging.handleTrackingInfo(event: event)
        
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }
    
    func testHandleTrackingInfoEmptyDataset() throws {
        // setup
        setConfigSharedState([MessagingConstants.SharedState.Configuration.EXPERIENCE_EVENT_DATASET:""])
        setIdentitySharedState()
        let event = Event(name: "trackingInfo", type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent, data: getMessageTrackingEventData())
        
        // test
        messaging.handleTrackingInfo(event: event)
        
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }
    
    func testHandleTrackingInfoNoXdmMap() throws {
        // setup
        setConfigSharedState()
        setIdentitySharedState()
        let event = Event(name: "trackingInfo", type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent, data: [:])
        
        // test
        messaging.handleTrackingInfo(event: event)
        
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }
    
    func testHandleTrackingInfoXdmMapMessageIdNil() throws {
        // setup
        setConfigSharedState()
        setIdentitySharedState()
        let event = Event(name: "trackingInfo", type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent, data: [MessagingConstants.Event.Data.Key.EVENT_TYPE: "testEventType"])
        
        // test
        messaging.handleTrackingInfo(event: event)
        
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }
    
    func testHandleTrackingInfoXdmMapMessageIdEmpty() throws {
        // setup
        setConfigSharedState()
        setIdentitySharedState()
        let event = Event(name: "trackingInfo", type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent, data: [MessagingConstants.Event.Data.Key.EVENT_TYPE: "testEventType", MessagingConstants.Event.Data.Key.MESSAGE_ID: ""])
        
        // test
        messaging.handleTrackingInfo(event: event)
        
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }
    
    func testSendPushTokenHappy() throws {
        // test
        messaging.sendPushToken(ecid: MOCK_ECID, token: MOCK_PUSH_TOKEN, platform: MOCK_PUSH_PLATFORM)
        
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
        XCTAssertEqual("com.apple.dt.xctest.tool", appId)
        let token = pushDetails?[MessagingConstants.XDM.Push.TOKEN] as? String
        XCTAssertEqual(MOCK_PUSH_TOKEN, token)
        let platform = pushDetails?[MessagingConstants.XDM.Push.PLATFORM] as? String
        XCTAssertEqual(MOCK_PUSH_PLATFORM, platform)
        let denylisted = pushDetails?[MessagingConstants.XDM.Push.DENYLISTED] as? Bool
        XCTAssertFalse(denylisted!)
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
        let event = Event(name: "trackingInfo", type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent, data: eventData)
        
        // test
        messaging.handleTrackingInfo(event: event)
        
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.firstEvent
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
        let event = Event(name: "trackingInfo", type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent, data: eventData)
        
        // test
        messaging.handleTrackingInfo(event: event)
        
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.firstEvent
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
        let event = Event(name: "trackingInfo", type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent, data: eventData)
        
        // test
        messaging.handleTrackingInfo(event: event)
        
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.firstEvent
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
        let event = Event(name: "trackingInfo", type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent, data: eventData)
        
        // test
        messaging.handleTrackingInfo(event: event)
        
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.firstEvent
        let dispatchedXdmMap = dispatchedEvent?.data?[MessagingConstants.XDM.Key.XDM] as? [String: Any]
        XCTAssertEqual(3, dispatchedXdmMap?.count)
        XCTAssertNotNil(dispatchedXdmMap?[MessagingConstants.XDM.Key.PUSH_NOTIFICATION_TRACKING])
        XCTAssertNotNil(dispatchedXdmMap?[MessagingConstants.XDM.Key.EVENT_TYPE])
        XCTAssertNotNil(dispatchedXdmMap?[MessagingConstants.XDM.AdobeKeys.APPLICATION])
    }
    
    func testAddApplicationDataAppOpened() throws {
        // setup
        let eventData = getMessageTrackingEventData().merging([MessagingConstants.Event.Data.Key.APPLICATION_OPENED: true]) { _, new in new}
        setConfigSharedState()
        setIdentitySharedState()
        let event = Event(name: "trackingInfo", type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent, data: eventData)
        
        // test
        messaging.handleTrackingInfo(event: event)
        
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.firstEvent
        let dispatchedXdmMap = dispatchedEvent?.data?[MessagingConstants.XDM.Key.XDM] as? [String: Any]
        let applicationData = dispatchedXdmMap?[MessagingConstants.XDM.AdobeKeys.APPLICATION] as? [String: Any]
        XCTAssertNotNil(applicationData)
        let launchesData = applicationData?[MessagingConstants.XDM.AdobeKeys.LAUNCHES] as? [String: Any]
        XCTAssertNotNil(launchesData)
        XCTAssertEqual(1, launchesData?[MessagingConstants.XDM.AdobeKeys.LAUNCHES_VALUE] as? Int)
    }
    
    func testAddApplicationDataAppNotOpened() throws {
        // setup
        let eventData = getMessageTrackingEventData().merging([MessagingConstants.Event.Data.Key.APPLICATION_OPENED: false]) { _, new in new}
        setConfigSharedState()
        setIdentitySharedState()
        let event = Event(name: "trackingInfo", type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent, data: eventData)
        
        // test
        messaging.handleTrackingInfo(event: event)
        
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.firstEvent
        let dispatchedXdmMap = dispatchedEvent?.data?[MessagingConstants.XDM.Key.XDM] as? [String: Any]
        let applicationData = dispatchedXdmMap?[MessagingConstants.XDM.AdobeKeys.APPLICATION] as? [String: Any]
        XCTAssertNotNil(applicationData)
        let launchesData = applicationData?[MessagingConstants.XDM.AdobeKeys.LAUNCHES] as? [String: Any]
        XCTAssertNotNil(launchesData)
        XCTAssertEqual(0, launchesData?[MessagingConstants.XDM.AdobeKeys.LAUNCHES_VALUE] as? Int)
    }
    
    func testSendExperienceEventHappy() throws {
        // setup
        setConfigSharedState()
        setIdentitySharedState()
        let mockEvent = Event(name: "triggeringEvent", type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent, data: nil)
        let mockEdgeEventType = MessagingEdgeEventType.inappInteract
        let mockInteraction = "swords"
        let mockMessage = MockMessage(parent: messaging, event: mockEvent)
        
        // test
        messaging.sendExperienceEvent(withEventType: mockEdgeEventType, andInteraction: mockInteraction, forMessage: mockMessage)
        
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.firstEvent
        // validate type and source
        XCTAssertEqual(EventType.edge, dispatchedEvent?.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent?.source)
        // validate event mask entries
        XCTAssertEqual(MessagingConstants.Event.Mask.XDM.EVENT_TYPE, dispatchedEvent?.mask?[0])
        XCTAssertEqual(MessagingConstants.Event.Mask.XDM.MESSAGE_EXECUTION_ID, dispatchedEvent?.mask?[1])
        XCTAssertEqual(MessagingConstants.Event.Mask.XDM.TRACKING_ACTION, dispatchedEvent?.mask?[2])
        // validate xdm map
        let dispatchedEventData = dispatchedEvent?.data
        let dispatchedXdmMap = dispatchedEventData?[MessagingConstants.XDM.Key.XDM] as? [String: Any]
        let iamInteractionMap = dispatchedXdmMap?[MessagingConstants.XDM.IAM.IN_APP_MIXIN_NAME] as? [String: Any]
        XCTAssertEqual(mockInteraction, iamInteractionMap?[MessagingConstants.XDM.IAM.ACTION] as? String)
        XCTAssertEqual(mockEdgeEventType.toString(), dispatchedXdmMap?[MessagingConstants.XDM.Key.EVENT_TYPE] as? String)
        let experienceInfo = dispatchedXdmMap?[MessagingConstants.XDM.AdobeKeys.EXPERIENCE] as? [String: Any]
        XCTAssertEqual(0, experienceInfo?.count)
        // validate xdm meta data
        let dispatchedXdmMeta = dispatchedEventData?[MessagingConstants.XDM.Key.META] as? [String: Any]
        let xdmMetaCollectMap = dispatchedXdmMeta?[MessagingConstants.XDM.Key.COLLECT] as? [String: Any]
        XCTAssertEqual(MOCK_EVENT_DATASET, xdmMetaCollectMap?[MessagingConstants.XDM.Key.DATASET_ID] as? String)
    }
    
    func testSendExperienceEventNoDataset() throws {
        // setup
        setConfigSharedState([:])
        setIdentitySharedState()
        let mockEvent = Event(name: "triggeringEvent", type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent, data: nil)
        let mockEdgeEventType = MessagingEdgeEventType.inappInteract
        let mockInteraction = "swords"
        let mockMessage = MockMessage(parent: messaging, event: mockEvent)
        
        // test
        messaging.sendExperienceEvent(withEventType: mockEdgeEventType, andInteraction: mockInteraction, forMessage: mockMessage)
        
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)        
    }
    
    func testSendExperienceEventNotInteractEventType() throws {
        // setup
        setConfigSharedState()
        setIdentitySharedState()
        let mockEvent = Event(name: "triggeringEvent", type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent, data: nil)
        let mockEdgeEventType = MessagingEdgeEventType.inappTrigger
        let mockInteraction = "swords"
        let mockMessage = MockMessage(parent: messaging, event: mockEvent)
        
        // test
        messaging.sendExperienceEvent(withEventType: mockEdgeEventType, andInteraction: mockInteraction, forMessage: mockMessage)
        
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.firstEvent
        // validate no mixin in xdm map
        let dispatchedEventData = dispatchedEvent?.data
        let dispatchedXdmMap = dispatchedEventData?[MessagingConstants.XDM.Key.XDM] as? [String: Any]
        XCTAssertNil(dispatchedXdmMap?[MessagingConstants.XDM.IAM.IN_APP_MIXIN_NAME])
    }
    
    func testSendExperienceEventInteractEventTypeEmptyInteraction() throws {
        // setup
        setConfigSharedState()
        setIdentitySharedState()
        let mockEvent = Event(name: "triggeringEvent", type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent, data: nil)
        let mockEdgeEventType = MessagingEdgeEventType.inappInteract
        let mockInteraction = ""
        let mockMessage = MockMessage(parent: messaging, event: mockEvent)
        
        // test
        messaging.sendExperienceEvent(withEventType: mockEdgeEventType, andInteraction: mockInteraction, forMessage: mockMessage)
        
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.firstEvent
        // validate no mixin in xdm map
        let dispatchedEventData = dispatchedEvent?.data
        let dispatchedXdmMap = dispatchedEventData?[MessagingConstants.XDM.Key.XDM] as? [String: Any]
        XCTAssertNil(dispatchedXdmMap?[MessagingConstants.XDM.IAM.IN_APP_MIXIN_NAME])
    }
    
    func testSendExperienceEventInteractEventTypeNilInteraction() throws {
        // setup
        setConfigSharedState()
        setIdentitySharedState()
        let mockEvent = Event(name: "triggeringEvent", type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent, data: nil)
        let mockEdgeEventType = MessagingEdgeEventType.inappInteract
        let mockInteraction: String? = nil
        let mockMessage = MockMessage(parent: messaging, event: mockEvent)
        
        // test
        messaging.sendExperienceEvent(withEventType: mockEdgeEventType, andInteraction: mockInteraction, forMessage: mockMessage)
        
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.firstEvent
        // validate no mixin in xdm map
        let dispatchedEventData = dispatchedEvent?.data
        let dispatchedXdmMap = dispatchedEventData?[MessagingConstants.XDM.Key.XDM] as? [String: Any]
        XCTAssertNil(dispatchedXdmMap?[MessagingConstants.XDM.IAM.IN_APP_MIXIN_NAME])
    }
}
