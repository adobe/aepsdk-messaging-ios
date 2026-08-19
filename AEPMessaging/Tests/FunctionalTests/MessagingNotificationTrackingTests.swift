/*
 Copyright 2023 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation
@testable import AEPCore
@testable import AEPMessaging
import AEPEdgeIdentity
import AEPServices
import AEPTestUtils
import XCTest

class MessagingNotificationTrackingTests: TestBase, AnyCodableAsserts {
    private let mockNetworkService: MockNetworkService = MockNetworkService()
    
    private let ASYNC_TIMEOUT: TimeInterval = 5

    static let mockUserInfo = ["_xdm" :
                                ["cjm":
                                    ["_experience":
                                        ["customerJourneyManagement":
                                            ["messageExecution":
                                                ["messageExecutionID": "mockExecutionID",
                                                 "journeyVersionID": "mockJourneyVersionID",
                                                 "journeyVersionInstanceId": "mockJourneyVersionInstanceId",
                                                 "messageID": "mockMessageId"]
                                            ]
                                        ]
                                    ]
                                ]
    ]
    
    static let mockUserInfoWithDecisioning = ["_xdm" :
                                ["mixins":
                                    ["_experience":
                                        ["customerJourneyManagement":
                                            ["messageExecution":
                                                ["messageExecutionID": "mockExecutionID",
                                                 "messageID": "mockMessageId",
                                                 "messageType": "transactional",
                                                 "campaignID": "mockCampaignID",
                                                 "campaignVersionID": "mockCampaignVersionID",
                                                 "batchInstanceID": "mockBatchInstanceID"]
                                            ],
                                         "decisioning":
                                            ["exdRequestID": "mockExdRequestID",
                                             "propositions":
                                                [["scopeDetails":
                                                    ["correlationID": "mockCorrelationID"]
                                                ]]
                                            ]
                                        ]
                                    ]
                                ]
    ]
    
    
    public class override func setUp() {
        super.setUp()
    }

    override func setUp() {
        super.setUp()

        ServiceProvider.shared.networkService = mockNetworkService
        continueAfterFailure = true
        FileManager.default.clearCache()
        FileManager.default.clearDirectory()

        // hub shared state update for 1 extension versions (InstrumentedExtension (registered in FunctionalTestBase), IdentityEdge, Edge Identity, Config
        setExpectationEvent(type: EventType.hub, source: EventSource.sharedState, expectedCount: 4)
        
        // expectations for update config request&response events
        setExpectationEvent(type: EventType.configuration, source: EventSource.requestContent, expectedCount: 1)
        setExpectationEvent(type: EventType.configuration, source: EventSource.responseContent, expectedCount: 1)
        setExpectationEvent(type: EventType.edge, source: EventSource.requestContent, expectedCount: 1)
        
        // wait for async registration because the EventHub is already started in FunctionalTestBase
        let waitForRegistration = CountDownLatch(1)
        MobileCore.registerExtensions([Messaging.self, Identity.self], {
            print("Extensions registration is complete")
            waitForRegistration.countDown()
        })
        XCTAssertEqual(DispatchTimeoutResult.success, waitForRegistration.await(timeout: ASYNC_TIMEOUT))
        MobileCore.updateConfigurationWith(configDict: ["messaging.eventDataset": "mockDataset"])

        assertExpectedEvents(ignoreUnexpectedEvents: false)
        resetTestExpectations()
        setNotificationCategories()
    }
    
    override func tearDown() {
        super.tearDown()
        mockNetworkService.reset()
    }
    
    // MARK: - Tests
    
    func test_notificationTracking_whenUser_tapsNotificationBody() {
        // setup
        var actualStatus : PushTrackingStatus?
        let expectation = XCTestExpectation(description: "Messaging Push Tracking Response")
        setExpectationEvent(type: EventType.edge, source: EventSource.requestContent, expectedCount: 1)
        let response = prepareNotificationResponse()!
        
        // test
        Messaging.handleNotificationResponse(response,closure: { status in
            actualStatus = status
            expectation.fulfill()
        })
        
        // verify tracking status value
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
        XCTAssertEqual(.trackingInitiated, actualStatus)
        
        // verify
        let events = getDispatchedEventsWith(type: EventType.edge, source: EventSource.requestContent)
        XCTAssertEqual(1, events.count)
        let edgeEvent = events.first!

        // Note: JSON comparison tool cannot currently validate that a key does not exist
        // it also cannot strictly validate the count of collections when using assertExact/TypeMatch modes
        if let xdm = edgeEvent.data?["xdm"] as? [String: Any],
           let pushNotificationTracking = xdm["pushNotificationTracking"] as? [String: Any],
           let customAction = pushNotificationTracking["customAction"] as? [String: Any],
           let actionID = customAction["actionID"] as? String {
            // use actionID here
            XCTAssertNil(actionID)
        }
        
        // verify push tracking information
        // verify cjm/mixins and other xdm related data
        let expectedJSON = """
        {
          "meta": {
            "collect": {
              "datasetId": "mockDataset"
            }
          },
          "xdm": {
            "_experience": {
              "customerJourneyManagement": {
                "messageExecution": {
                  "journeyVersionID": "mockJourneyVersionID",
                  "journeyVersionInstanceId": "mockJourneyVersionInstanceId",
                  "messageExecutionID": "mockExecutionID",
                  "messageID": "mockMessageId"
                },
                "messageProfile": {
                  "channel": {
                    "_id": "https://ns.adobe.com/xdm/channels/push"
                  }
                },
                "pushChannelContext": {
                  "platform": "apns"
                }
              }
            },
            "application": {
              "launches": {
                "value": 1
              }
            },
            "eventType": "pushTracking.applicationOpened",
            "pushNotificationTracking": {
              "pushProvider": "apns",
              "pushProviderMessageID": "messageId"
            }
          }
        }
        """
        assertExactMatch(expected: expectedJSON, actual: edgeEvent)
    }
    
    func test_notificationTracking_whenUser_DismissesNotification() {
        // setup
        setExpectationEvent(type: EventType.edge, source: EventSource.requestContent, expectedCount: 1)
        let response = prepareNotificationResponse(actionIdentifier: UNNotificationDismissActionIdentifier)!
        
        // test
        Messaging.handleNotificationResponse(response)
        
        // verify
        let events = getDispatchedEventsWith(type: EventType.edge, source: EventSource.requestContent)
        XCTAssertEqual(1, events.count)
        let edgeEvent = events.first!
        
        // verify push tracking information
        let expectedJSON = """
        {
          "xdm" : {
            "pushNotificationTracking" : {
              "customAction" : {
                "actionID" : "Dismiss"
              }
            },
            "eventType" : "pushTracking.customAction",
            "application" : {
              "launches" : {
                "value" : 0
              }
            }
          }
        }
        """
        assertExactMatch(expected: expectedJSON, actual: edgeEvent)
    }
    
    func test_notificationTracking_whenUser_tapsNotificationActionThatOpensTheApp() {
        // setup
        setExpectationEvent(type: EventType.edge, source: EventSource.requestContent, expectedCount: 1)
        let response = prepareNotificationResponse(actionIdentifier: "ForegroundActionId", categoryIdentifier: "CategoryId")!
        
        // test
        Messaging.handleNotificationResponse(response)
        
        // verify
        let events = getDispatchedEventsWith(type: EventType.edge, source: EventSource.requestContent)
        XCTAssertEqual(1, events.count)
        let edgeEvent = events.first!
        
        // verify push tracking information
        let expectedJSON = """
        {
          "xdm": {
            "application": {
              "launches": {
                "value": 1
              }
            },
            "eventType": "pushTracking.customAction",
            "pushNotificationTracking": {
              "customAction": {
                "actionID": "ForegroundActionId"
              }
            }
          }
        }
        """
        
        assertExactMatch(expected: expectedJSON, actual: edgeEvent)
    }
    
    func test_notificationOpen_whenNotAJONotification() {
        // This test simulates the reaction of handleNotificationResponse API when the notifcation is not generated from AJO
        // "_xdm" key in userInfo contains all the tracking information from AJO. Absense of this key mean this notification is not generated from AJO
        setExpectationEvent(type: EventType.messaging, source: EventSource.requestContent, expectedCount: 1)
        var actualStatus : PushTrackingStatus?
        let expectation = XCTestExpectation(description: "Messaging Push Tracking Response")
        let response = prepareNotificationResponse(withUserInfo: ["nospecificAJOKey":"noAJOKey"])!
        
        // test
        Messaging.handleNotificationResponse(response,closure: { status in
            actualStatus = status
            expectation.fulfill()
        })
        
        // verify the tracking status
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
        XCTAssertEqual(PushTrackingStatus.noTrackingData, actualStatus)
                                             
        // verify no tracking event is dispatched
        let events = getDispatchedEventsWith(type: EventType.edge, source: EventSource.requestContent)
        XCTAssertEqual(0, events.count)
    }
    
    func test_notificationOpen_whenAJONotification_withEmptyTrackingInformation() {
        // This test simulates the reaction of handleNotificationResponse API when the notifcation from AJO contains no information in the tracking field "_xdm"
        var actualStatus : PushTrackingStatus?
        let expectation = XCTestExpectation(description: "Messaging Push Tracking Response")
        setExpectationEvent(type: EventType.messaging, source: EventSource.requestContent, expectedCount: 1)
        let response = prepareNotificationResponse(withUserInfo: ["_xdm": [:] as [String:Any]])!
        
        // test
        Messaging.handleNotificationResponse(response,closure: { status in
            actualStatus = status
            expectation.fulfill()
        })
        
        // verify the tracking status
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
        XCTAssertEqual(PushTrackingStatus.noTrackingData, actualStatus)
        
        // verify no tracking event is dispatched
        let events = getDispatchedEventsWith(type: EventType.edge, source: EventSource.requestContent)
        XCTAssertEqual(0, events.count)
    }

    
    func test_notificationTracking_whenUser_tapsNotificationActionThatDoNotOpenTheApp() {
        // setup
        setExpectationEvent(type: EventType.edge, source: EventSource.requestContent, expectedCount: 1)
        let response = prepareNotificationResponse(actionIdentifier: "DeclineActionId", categoryIdentifier: "CategoryId")!
        
        // test
        Messaging.handleNotificationResponse(response)
        
        // verify
        let events = getDispatchedEventsWith(type: EventType.edge, source: EventSource.requestContent)
        XCTAssertEqual(1, events.count)
        let edgeEvent = events.first!
        
        // verify push tracking information
        let expectedJSON = """
        {
          "xdm": {
            "application": {
              "launches": {
                "value": 0
              }
            },
            "eventType": "pushTracking.customAction",
            "pushNotificationTracking": {
              "customAction": {
                "actionID": "DeclineActionId"
              }
            }
          }
        }
        """
        
        assertExactMatch(expected: expectedJSON, actual: edgeEvent)
    }
    
    func test_notificationTracking_whenUser_tapsNotificationActionThatDoNotOpenTheApp_Case2() {
        // This test simulates clicking on a notification action button for which notification options buttons are empty
        // setup
        setExpectationEvent(type: EventType.edge, source: EventSource.requestContent, expectedCount: 1)
        let response = prepareNotificationResponse(actionIdentifier: "notForegroundActionId", categoryIdentifier: "CategoryId")!
        
        // test
        Messaging.handleNotificationResponse(response)
        
        // verify
        let events = getDispatchedEventsWith(type: EventType.edge, source: EventSource.requestContent)
        XCTAssertEqual(1, events.count)
        let edgeEvent = events.first!
        
        // verify push tracking information
        let expectedJSON = """
        {
          "xdm": {
            "application": {
              "launches": {
                "value": 0
              }
            },
            "eventType": "pushTracking.customAction",
            "pushNotificationTracking": {
              "customAction": {
                "actionID": "notForegroundActionId"
              }
            }
          }
        }
        """
        
        assertExactMatch(expected: expectedJSON, actual: edgeEvent)
    }
    
    func test_notificationOpen_willLaunchUrl() {
        // This test simulates clicking on a notification action button for which notification options buttons are empty
        // setup
        setExpectationEvent(type: EventType.messaging, source: EventSource.requestContent, expectedCount: 1)
        let response = prepareNotificationResponse(withUserInfo: ["adb_uri":"https://google.com", "_xdm": ["trackingKey": "trackingValue"]])!
        
        // test
        Messaging.handleNotificationResponse(response)
        
        // verify
        let events = getDispatchedEventsWith(type: EventType.messaging, source: EventSource.requestContent)
        XCTAssertEqual(1, events.count)
        let messagingEvent = events.first!
        
        // verify push tracking information
        let expectedJSON = """
        {
          "applicationOpened": true,
          "clickThroughUrl": "https://google.com",
          "eventType": "pushTracking.applicationOpened"
        }
        """
        
        assertExactMatch(expected: expectedJSON, actual: messagingEvent)
    }
    
    func test_notificationCustomAction_willNotLaunchUrl() {
        // This test simulates clicking on a notification action button for which notification options buttons are empty
        // setup
        setExpectationEvent(type: EventType.messaging, source: EventSource.requestContent, expectedCount: 1)
        let response = prepareNotificationResponse(withUserInfo: ["adb_uri":"https://google.com","_xdm": ["trackingKey": "trackingValue"]], actionIdentifier: "ForegroundActionId", categoryIdentifier: "CategoryId")!
        
        // test
        Messaging.handleNotificationResponse(response)
        
        // verify
        let events = getDispatchedEventsWith(type: EventType.messaging, source: EventSource.requestContent)
        XCTAssertEqual(1, events.count)
        let messagingEvent = events.first!
        let flattenedEvent = messagingEvent.data?.flattening()
        
        // verify push tracking information
        XCTAssertNil(flattenedEvent?["pushClickThroughUrl"] as? String)
    }
    
    func test_notificationTracking_whenNoDatasetConfigured() {
        MobileCore.clearUpdatedConfiguration()
        var actualStatus : PushTrackingStatus?
        let expectation = XCTestExpectation(description: "Messaging Push Tracking Response")
        setExpectationEvent(type: EventType.messaging, source: EventSource.requestContent, expectedCount: 1)
        let response = prepareNotificationResponse()!
        
        // test
        Messaging.handleNotificationResponse(response, closure: { status in
            actualStatus = status
            expectation.fulfill()
        })
        
        // verify tracking status
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
        XCTAssertEqual(.noDatasetConfigured, actualStatus)
        
        // verify
        let events = getDispatchedEventsWith(type: EventType.messaging, source: EventSource.requestContent)
        XCTAssertEqual(1, events.count)
        let messagingEvent = events.first!
        let flattenedEvent = messagingEvent.data?.flattening()
        
        // verify push tracking information
        XCTAssertNil(flattenedEvent?["pushClickThroughUrl"] as? String)
    }
    
    
    // MARK: - Private Helpers functions
    
    private func prepareNotificationResponse(withUserInfo userInfo : [String:Any] = mockUserInfo,
                                             actionIdentifier: String = UNNotificationDefaultActionIdentifier,
                                             categoryIdentifier: String = "") -> UNNotificationResponse? {
        let dateInfo = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: false)
        let notificationContent = UNMutableNotificationContent()
        notificationContent.userInfo = userInfo
        notificationContent.categoryIdentifier = categoryIdentifier

        let request = UNNotificationRequest(identifier: "messageId" , content: notificationContent, trigger: trigger)
        guard let response = UNNotificationResponse(coder: MockNotificationResponseCoder(with: request,
                                                                                         actionIdentifier:actionIdentifier)) else {
            XCTFail()
            return nil
        }
        return response
    }
    
    private func setNotificationCategories() {
        let acceptAction = UNNotificationAction(identifier: "ForegroundActionId",
              title: "Foreground",
              options: [.foreground])
        let declineAction = UNNotificationAction(identifier: "DeclineActionId",
              title: "Decline",
              options: [.destructive,.authenticationRequired])
        let notForegroundAction = UNNotificationAction(identifier: "notForegroundActionId",
              title: "NotForeground",
              options: [])
        // Define the notification type
        let meetingInviteCategory =
              UNNotificationCategory(identifier: "CategoryId",
              actions: [acceptAction, declineAction, notForegroundAction],
              intentIdentifiers: [],
              hiddenPreviewsBodyPlaceholder: "",
              options: .customDismissAction)
        // Register the notification type.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([meetingInviteCategory])
    }
    
    // MARK: - propositionEventType Tests
    
    func test_pushNotification_applicationOpened_addsPropositionEventType_interact() {
        // setup
        var actualStatus : PushTrackingStatus?
        let expectation = XCTestExpectation(description: "Messaging Push Tracking Response with propositionEventType")
        setExpectationEvent(type: EventType.edge, source: EventSource.requestContent, expectedCount: 1)
        let response = prepareNotificationResponse(withUserInfo: Self.mockUserInfoWithDecisioning)!
        
        // test
        Messaging.handleNotificationResponse(response, closure: { status in
            actualStatus = status
            expectation.fulfill()
        })
        
        // verify tracking status value
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
        XCTAssertEqual(.trackingInitiated, actualStatus)
        
        // verify
        let events = getDispatchedEventsWith(type: EventType.edge, source: EventSource.requestContent)
        XCTAssertEqual(1, events.count)
        let edgeEvent = events.first!
        
        // verify propositionEventType is added to decisioning section
        if let xdm = edgeEvent.data?[MessagingConstants.XDM.Key.XDM] as? [String: Any],
           let experience = xdm[MessagingConstants.XDM.AdobeKeys.EXPERIENCE] as? [String: Any],
           let decisioning = experience[MessagingConstants.XDM.Inbound.Key.DECISIONING] as? [String: Any],
           let propositionEventType = decisioning[MessagingConstants.XDM.Inbound.Key.PROPOSITION_EVENT_TYPE] as? [String: Int] {
            XCTAssertEqual(1, propositionEventType[MessagingConstants.XDM.Inbound.PropositionEventType.INTERACT])
            XCTAssertNil(propositionEventType[MessagingConstants.XDM.Inbound.PropositionEventType.DISMISS])
        } else {
            XCTFail("propositionEventType not found in decisioning section")
        }
        
        // verify event type is applicationOpened
        if let xdm = edgeEvent.data?[MessagingConstants.XDM.Key.XDM] as? [String: Any] {
            XCTAssertEqual("pushTracking.applicationOpened", xdm[MessagingConstants.XDM.Key.EVENT_TYPE] as? String)
        }
    }
    
    func test_pushNotification_customAction_addsPropositionEventType_interact() {
        // setup
        setExpectationEvent(type: EventType.edge, source: EventSource.requestContent, expectedCount: 1)
        let response = prepareNotificationResponse(withUserInfo: Self.mockUserInfoWithDecisioning,
                                                   actionIdentifier: "ForegroundActionId", 
                                                   categoryIdentifier: "CategoryId")!
        
        // test
        Messaging.handleNotificationResponse(response)
        
        // verify
        let events = getDispatchedEventsWith(type: EventType.edge, source: EventSource.requestContent)
        XCTAssertEqual(1, events.count)
        let edgeEvent = events.first!
        
        // verify propositionEventType is set to interact for custom actions
        if let xdm = edgeEvent.data?[MessagingConstants.XDM.Key.XDM] as? [String: Any],
           let experience = xdm[MessagingConstants.XDM.AdobeKeys.EXPERIENCE] as? [String: Any],
           let decisioning = experience[MessagingConstants.XDM.Inbound.Key.DECISIONING] as? [String: Any],
           let propositionEventType = decisioning[MessagingConstants.XDM.Inbound.Key.PROPOSITION_EVENT_TYPE] as? [String: Int] {
            XCTAssertEqual(1, propositionEventType[MessagingConstants.XDM.Inbound.PropositionEventType.INTERACT])
            XCTAssertNil(propositionEventType[MessagingConstants.XDM.Inbound.PropositionEventType.DISMISS])
        } else {
            XCTFail("propositionEventType not found in decisioning section")
        }
        
        // verify event type is customAction with custom actionID
        if let xdm = edgeEvent.data?[MessagingConstants.XDM.Key.XDM] as? [String: Any] {
            XCTAssertEqual("pushTracking.customAction", xdm[MessagingConstants.XDM.Key.EVENT_TYPE] as? String)
            if let pushTracking = xdm[MessagingConstants.XDM.Key.PUSH_NOTIFICATION_TRACKING] as? [String: Any],
               let customAction = pushTracking[MessagingConstants.XDM.Key.CUSTOM_ACTION] as? [String: Any] {
                XCTAssertEqual("ForegroundActionId", customAction[MessagingConstants.XDM.Key.ACTION_ID] as? String)
            }
        }
    }
    
    func test_pushNotification_withoutDecisioningSection_doesNotAddPropositionEventType() {
        // setup - using mockUserInfo without decisioning section
        var actualStatus : PushTrackingStatus?
        let expectation = XCTestExpectation(description: "Messaging Push Tracking Response")
        setExpectationEvent(type: EventType.edge, source: EventSource.requestContent, expectedCount: 1)
        let response = prepareNotificationResponse(withUserInfo: Self.mockUserInfo)!
        
        // test
        Messaging.handleNotificationResponse(response, closure: { status in
            actualStatus = status
            expectation.fulfill()
        })
        
        // verify tracking status value
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
        XCTAssertEqual(.trackingInitiated, actualStatus)
        
        // verify
        let events = getDispatchedEventsWith(type: EventType.edge, source: EventSource.requestContent)
        XCTAssertEqual(1, events.count)
        let edgeEvent = events.first!
        
        // verify propositionEventType is NOT added when decisioning section doesn't exist
        if let xdm = edgeEvent.data?[MessagingConstants.XDM.Key.XDM] as? [String: Any],
           let experience = xdm[MessagingConstants.XDM.AdobeKeys.EXPERIENCE] as? [String: Any] {
            // Use optional chaining to safely access propositionEventType even if decisioning doesn't exist
            let propositionEventType = (experience[MessagingConstants.XDM.Inbound.Key.DECISIONING] as? [String: Any])?[MessagingConstants.XDM.Inbound.Key.PROPOSITION_EVENT_TYPE]
            XCTAssertNil(propositionEventType, "propositionEventType should not be added when decisioning section doesn't exist in original payload")
            
            // verify event still processes correctly
            XCTAssertEqual("pushTracking.applicationOpened", xdm[MessagingConstants.XDM.Key.EVENT_TYPE] as? String)
        } else {
            XCTFail("xdm or _experience not found in edge event")
        }
    }
    
    func test_pushNotification_dismissWithUNNotificationDismissActionIdentifier_addsPropositionEventType_dismiss() {
        // setup - test iOS system dismiss identifier
        setExpectationEvent(type: EventType.edge, source: EventSource.requestContent, expectedCount: 1)
        let response = prepareNotificationResponse(withUserInfo: Self.mockUserInfoWithDecisioning,
                                                   actionIdentifier: UNNotificationDismissActionIdentifier)!
        
        // test
        Messaging.handleNotificationResponse(response)
        
        // verify
        let events = getDispatchedEventsWith(type: EventType.edge, source: EventSource.requestContent)
        XCTAssertEqual(1, events.count)
        let edgeEvent = events.first!
        
        // verify propositionEventType is set to dismiss
        if let xdm = edgeEvent.data?[MessagingConstants.XDM.Key.XDM] as? [String: Any],
           let experience = xdm[MessagingConstants.XDM.AdobeKeys.EXPERIENCE] as? [String: Any],
           let decisioning = experience[MessagingConstants.XDM.Inbound.Key.DECISIONING] as? [String: Any],
           let propositionEventType = decisioning[MessagingConstants.XDM.Inbound.Key.PROPOSITION_EVENT_TYPE] as? [String: Int] {
            XCTAssertEqual(1, propositionEventType[MessagingConstants.XDM.Inbound.PropositionEventType.DISMISS])
            XCTAssertNil(propositionEventType[MessagingConstants.XDM.Inbound.PropositionEventType.INTERACT])
        } else {
            XCTFail("propositionEventType not found in decisioning section")
        }
        
        // verify event type is customAction with Dismiss actionID
        if let xdm = edgeEvent.data?[MessagingConstants.XDM.Key.XDM] as? [String: Any] {
            XCTAssertEqual("pushTracking.customAction", xdm[MessagingConstants.XDM.Key.EVENT_TYPE] as? String)
        }
    }
    
    func test_pushNotification_withoutExdRequestID_doesNotAddPropositionEventType() {
        // setup - create mock data with decisioning section but WITHOUT exdRequestID
        let mockUserInfoWithoutExdRequestID = ["_xdm" :
                                    ["mixins":
                                        ["_experience":
                                            ["customerJourneyManagement":
                                                ["messageExecution":
                                                    ["messageExecutionID": "mockExecutionID",
                                                     "messageID": "mockMessageId",
                                                     "messageType": "transactional",
                                                     "campaignID": "mockCampaignID",
                                                     "campaignVersionID": "mockCampaignVersionID",
                                                     "batchInstanceID": "mockBatchInstanceID"]
                                                ],
                                             "decisioning":
                                                ["propositions":
                                                    [["scopeDetails":
                                                        ["correlationID": "mockCorrelationID"]
                                                    ]]
                                                ]
                                            ]
                                        ]
                                    ]
        ]
        
        var actualStatus : PushTrackingStatus?
        let expectation = XCTestExpectation(description: "Messaging Push Tracking Response")
        setExpectationEvent(type: EventType.edge, source: EventSource.requestContent, expectedCount: 1)
        let response = prepareNotificationResponse(withUserInfo: mockUserInfoWithoutExdRequestID)!
        
        // test
        Messaging.handleNotificationResponse(response, closure: { status in
            actualStatus = status
            expectation.fulfill()
        })
        
        // verify tracking status value
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
        XCTAssertEqual(.trackingInitiated, actualStatus)
        
        // verify
        let events = getDispatchedEventsWith(type: EventType.edge, source: EventSource.requestContent)
        XCTAssertEqual(1, events.count)
        let edgeEvent = events.first!
        
        // verify propositionEventType is NOT added when exdRequestID is missing
        if let xdm = edgeEvent.data?[MessagingConstants.XDM.Key.XDM] as? [String: Any],
           let experience = xdm[MessagingConstants.XDM.AdobeKeys.EXPERIENCE] as? [String: Any],
           let decisioning = experience[MessagingConstants.XDM.Inbound.Key.DECISIONING] as? [String: Any] {
            // decisioning section should exist (from original payload)
            XCTAssertNotNil(decisioning)
            
            // but propositionEventType should NOT be added
            let propositionEventType = decisioning[MessagingConstants.XDM.Inbound.Key.PROPOSITION_EVENT_TYPE]
            XCTAssertNil(propositionEventType, "propositionEventType should not be added when exdRequestID is missing")
            
            // verify event still processes correctly
            XCTAssertEqual("pushTracking.applicationOpened", xdm[MessagingConstants.XDM.Key.EVENT_TYPE] as? String)
        } else {
            XCTFail("xdm, _experience, or decisioning not found in edge event")
        }
    }
}

