//
// Copyright 2021 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

@testable import AEPCore
@testable import AEPServices
@testable import AEPMessaging
import UserNotifications
import XCTest

class MessagingPublicApiTest: XCTestCase {
    let ASYNC_TIMEOUT = 2.0
    var mockXdmData: [String: Any] = ["somekey": "somedata"]
    var notificationContent: [AnyHashable: Any] = [:]
    let MOCK_BUNDLE_IDENTIFIER = "mobileapp://com.apple.dt.xctest.tool/"
    let MOCK_FEEDS_SURFACE = "mobileapp://com.apple.dt.xctest.tool/promos/feed1"
    
    override func setUp() {
        notificationContent = [MessagingConstants.XDM.AdobeKeys._XDM: mockXdmData]
        MockExtension.reset()
        EventHub.shared.start()
        registerMockExtension(MockExtension.self)
    }

    private func registerMockExtension<T: Extension>(_ type: T.Type) {
        let semaphore = DispatchSemaphore(value: 0)
        EventHub.shared.registerExtension(type) { _ in
            semaphore.signal()
        }

        semaphore.wait()
    }

    // MARK: - handleNotificationResponse
    
    func testHandleNotificationResponse() {
        let expectation = XCTestExpectation(description: "Messaging request event")
        let mockCustomActionId = "mockCustomActionId"
        let mockIdentifier = "mockIdentifier"
        expectation.assertForOverFulfill = true

        EventHub.shared.getExtensionContainer(MockExtension.self)?.eventListeners.clear()

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent) { event in
            XCTAssertEqual(MessagingConstants.Event.Name.PUSH_NOTIFICATION_INTERACTION, event.name)
            XCTAssertEqual(MessagingConstants.Event.EventType.messaging, event.type)
            XCTAssertEqual(EventSource.requestContent, event.source)

            guard let eventData = event.data,
                  let applicationOpened = eventData[MessagingConstants.Event.Data.Key.APPLICATION_OPENED] as? Bool,
                  let eventDataType = eventData[MessagingConstants.Event.Data.Key.EVENT_TYPE] as? String,
                  let actionId = eventData[MessagingConstants.Event.Data.Key.ACTION_ID] as? String,
                  let messageId = eventData[MessagingConstants.Event.Data.Key.MESSAGE_ID] as? String,
                  let xdm = eventData[MessagingConstants.Event.Data.Key.ADOBE_XDM] as? [String: Any]
            else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertTrue(applicationOpened)
            XCTAssertEqual(MessagingConstants.XDM.Push.EventType.CUSTOM_ACTION, eventDataType)
            XCTAssertEqual(actionId, mockCustomActionId)
            XCTAssertEqual(messageId, mockIdentifier)
            XCTAssertNotNil(xdm)
            XCTAssertEqual(xdm.count, 1)
            XCTAssertEqual(xdm["somekey"] as? String, "somedata")

            expectation.fulfill()
        }

        let dateInfo = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: false)
        let notificationContent = UNMutableNotificationContent()
        notificationContent.userInfo = self.notificationContent

        let request = UNNotificationRequest(identifier: mockIdentifier, content: notificationContent, trigger: trigger)
        guard let response = UNNotificationResponse(coder: MockNotificationResponseCoder(with: request)) else {
            XCTFail()
            return
        }

        Messaging.handleNotificationResponse(response, applicationOpened: true, customActionId: mockCustomActionId)
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
    }

    func testHandleNotificationResponse_whenApplicationOpenedFalse_AndNilCustomActionID() {
        let expectation = XCTestExpectation(description: "Messaging request event")
        expectation.assertForOverFulfill = true

        EventHub.shared.getExtensionContainer(MockExtension.self)?.eventListeners.clear()
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent) { event in
            XCTAssertEqual(MessagingConstants.Event.Name.PUSH_NOTIFICATION_INTERACTION, event.name)
            XCTAssertEqual(MessagingConstants.Event.EventType.messaging, event.type)
            XCTAssertEqual(EventSource.requestContent, event.source)

            guard let eventData = event.data else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertFalse(eventData[MessagingConstants.Event.Data.Key.APPLICATION_OPENED] as? Bool ?? true)
            XCTAssertNil(eventData[MessagingConstants.Event.Data.Key.ACTION_ID] as? String)
            expectation.fulfill()
        }

        let dateInfo = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: false)
        let notificationContent = UNMutableNotificationContent()
        notificationContent.userInfo = self.notificationContent

        let request = UNNotificationRequest(identifier: "mockIdentifier", content: notificationContent, trigger: trigger)
        guard let response = UNNotificationResponse(coder: MockNotificationResponseCoder(with: request)) else {
            XCTFail()
            return
        }
        Messaging.handleNotificationResponse(response, applicationOpened: false, customActionId: nil)
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
    }

    func testHandleNotificationResponseNoXdmInNotification() {
        let expectation = XCTestExpectation(description: "Messaging request event")
        let mockCustomActionId = "mockCustomActionId"
        let mockIdentifier = "mockIdentifier"
        expectation.assertForOverFulfill = true

        EventHub.shared.getExtensionContainer(MockExtension.self)?.eventListeners.clear()

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent) { event in
            XCTAssertEqual(MessagingConstants.Event.Name.PUSH_NOTIFICATION_INTERACTION, event.name)
            XCTAssertEqual(MessagingConstants.Event.EventType.messaging, event.type)
            XCTAssertEqual(EventSource.requestContent, event.source)

            guard let eventData = event.data,
                  let applicationOpened = eventData[MessagingConstants.Event.Data.Key.APPLICATION_OPENED] as? Bool,
                  let eventDataType = eventData[MessagingConstants.Event.Data.Key.EVENT_TYPE] as? String,
                  let actionId = eventData[MessagingConstants.Event.Data.Key.ACTION_ID] as? String,
                  let messageId = eventData[MessagingConstants.Event.Data.Key.MESSAGE_ID] as? String,
                  let xdm = eventData[MessagingConstants.Event.Data.Key.ADOBE_XDM] as? [String: Any]
            else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertTrue(applicationOpened)
            XCTAssertEqual(MessagingConstants.XDM.Push.EventType.CUSTOM_ACTION, eventDataType)
            XCTAssertEqual(actionId, mockCustomActionId)
            XCTAssertEqual(messageId, mockIdentifier)
            XCTAssertEqual(0, xdm.count)

            expectation.fulfill()
        }

        let dateInfo = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: false)
        let notificationContent = UNMutableNotificationContent()

        let request = UNNotificationRequest(identifier: mockIdentifier, content: notificationContent, trigger: trigger)
        guard let response = UNNotificationResponse(coder: MockNotificationResponseCoder(with: request)) else {
            XCTFail()
            return
        }

        Messaging.handleNotificationResponse(response, applicationOpened: true, customActionId: mockCustomActionId)
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
    }

    func testHandleNotificationResponseEmptyMessageId() {
        let expectation = XCTestExpectation(description: "Messaging request event")
        let mockCustomActionId = "mockCustomActionId"
        let mockIdentifier = ""
        expectation.assertForOverFulfill = true
        expectation.isInverted = true

        EventHub.shared.getExtensionContainer(MockExtension.self)?.eventListeners.clear()
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent) { _ in
            XCTFail()
            expectation.fulfill()
        }

        let dateInfo = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: false)
        let notificationContent = UNMutableNotificationContent()

        let request = UNNotificationRequest(identifier: mockIdentifier, content: notificationContent, trigger: trigger)
        guard let response = UNNotificationResponse(coder: MockNotificationResponseCoder(with: request)) else {
            XCTFail()
            return
        }

        Messaging.handleNotificationResponse(response, applicationOpened: true, customActionId: mockCustomActionId)
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
    }

    func testRefreshInAppMessages() throws {
        // setup
        let expectation = XCTestExpectation(description: "Refresh In app messages event")
        expectation.assertForOverFulfill = true

        EventHub.shared.getExtensionContainer(MockExtension.self)?.eventListeners.clear()
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent) { event in
            XCTAssertEqual(MessagingConstants.Event.Name.REFRESH_MESSAGES, event.name)
            XCTAssertEqual(MessagingConstants.Event.EventType.messaging, event.type)
            XCTAssertEqual(EventSource.requestContent, event.source)

            guard let eventData = event.data else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertTrue(eventData[MessagingConstants.Event.Data.Key.REFRESH_MESSAGES] as? Bool ?? false)
            expectation.fulfill()
        }

        // test
        Messaging.refreshInAppMessages()

        // verify
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
    }
    
    // MARK: - updatePropositionsForSurfaces
    
    func testUpdatePropositionsForSurfaces() throws {
        // setup
        let expectation = XCTestExpectation(description: "updatePropositionsForSurfaces should dispatch an event with expected data.")
        expectation.assertForOverFulfill = true

        let testEvent = Event(name: "Update propositions",
                              type: "com.adobe.eventType.messaging",
                              source: "com.adobe.eventSource.requestContent",
                              data: [
                                "updatepropositions": true,
                                "surfaces": [
                                    [ "uri": "promos/feed1" ],
                                    [ "uri": "promos/feed2" ]
                                ]
                              ])

        
        EventHub.shared.getExtensionContainer(MockExtension.self)?.eventListeners.clear()
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { event in
            XCTAssertEqual(testEvent.name, event.name)
            XCTAssertNotNil(event.data)
            XCTAssertEqual(true, event.data?["updatepropositions"] as? Bool)
            guard let surfaces = event.data?["surfaces"] as? [[String: Any]], !surfaces.isEmpty else {
                XCTFail("Surface path strings array should be valid.")
                return
            }
            XCTAssertEqual(2, surfaces.count)
            XCTAssertEqual("\(self.MOCK_BUNDLE_IDENTIFIER)promos/feed1", surfaces[0]["uri"] as? String)
            XCTAssertEqual("\(self.MOCK_BUNDLE_IDENTIFIER)promos/feed2", surfaces[1]["uri"] as? String)

            expectation.fulfill()
        }

        // test
        Messaging.updatePropositionsForSurfaces([
            Surface(path: "promos/feed1"),
            Surface(path: "promos/feed2")
        ])
        
        // verify
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
    }
    
    func testUpdatePropositionsForSurfaces_whenValidAndEmptySurfacesInArray() throws {
        // setup
        let expectation = XCTestExpectation(description: "updatePropositionsForSurfaces should dispatch an event with expected data.")
        expectation.assertForOverFulfill = true

        let testEvent = Event(name: "Update propositions",
                              type: "com.adobe.eventType.messaging",
                              source: "com.adobe.eventSource.requestContent",
                              data: [
                                "updatepropositions": true,
                                "surfaces": [
                                    [ : ],
                                    [ "uri": "promos/feed2" ]
                                ]
                              ])
                
        EventHub.shared.getExtensionContainer(MockExtension.self)?.eventListeners.clear()
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { event in
            XCTAssertEqual(testEvent.name, event.name)
            XCTAssertNotNil(event.data)
            XCTAssertEqual(true, event.data?["updatepropositions"] as? Bool)
            guard let surfaces = event.data?["surfaces"] as? [[String: Any]], !surfaces.isEmpty else {
                XCTFail("Surface path strings array should be valid.")
                return
            }
            XCTAssertEqual(1, surfaces.count)
            XCTAssertEqual("\(self.MOCK_BUNDLE_IDENTIFIER)promos/feed2", surfaces[0]["uri"] as? String)

            expectation.fulfill()
        }

        // test
        Messaging.updatePropositionsForSurfaces([
            Surface(path: ""),
            Surface(path: "promos/feed2")
        ])
        
        // verify
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
    }
    
    func testUpdatePropositionsForSurfaces_whenEmptySurfaceInArray() {
        // setup
        let expectation = XCTestExpectation(description: "updatePropositionsForSurfaces should not dispatch an event.")
        expectation.isInverted = true

        // test
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(
            type: "com.adobe.eventType.messaging",
            source: "com.adobe.eventSource.requestContent") { _ in
            expectation.fulfill()
        }

        // test
        Messaging.updatePropositionsForSurfaces([
            Surface(path: "")
        ])

        // verify
        wait(for: [expectation], timeout: 1)
    }
    
    func testUpdatePropositionsForSurfaces_whenEmptySurfacesArray() {
        // setup
        let expectation = XCTestExpectation(description: "updatePropositionsForSurfaces should not dispatch an event.")
        expectation.isInverted = true

        // test
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(
            type: "com.adobe.eventType.messaging",
            source: "com.adobe.eventSource.requestContent") { _ in
            expectation.fulfill()
        }

        // test
        Messaging.updatePropositionsForSurfaces([])

        // verify
        wait(for: [expectation], timeout: 1)
    }
    
    // MARK: - getPropositionsForSurfaces
    
    func testGetPropositionsForSurfacesNoValidSurfaces() throws {
        // setup
        let expectation = XCTestExpectation(description: "completion should be called with invalidRequest")
        let eventExpectation = XCTestExpectation(description: "event should be dispatched")
        eventExpectation.isInverted = true
        EventHub.shared.getExtensionContainer(MockExtension.self)?.eventListeners.clear()
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent) { _ in
            eventExpectation.fulfill()
        }
        
        let surfacePaths = [Surface(uri: "")]
        
        // test
        Messaging.getPropositionsForSurfaces(surfacePaths) { surfacePropositions, error in
            XCTAssertNil(surfacePropositions)
            XCTAssertNotNil(error)
            XCTAssertEqual(AEPError.invalidRequest, error as? AEPError)
            expectation.fulfill()
        }
        
        // verify
        wait(for: [expectation, eventExpectation], timeout: ASYNC_TIMEOUT)
    }
    
    func testGetPropositionsForSurfacesTimeoutCallback() throws {
        // setup
        let expectation = XCTestExpectation(description: "completion should be called with responseEvent")
        let eventExpectation = XCTestExpectation(description: "event should be dispatched")
        EventHub.shared.getExtensionContainer(MockExtension.self)?.eventListeners.clear()
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent) { event in
            eventExpectation.fulfill()
            // don't send a response event
        }
        
        let surfacePaths = [Surface(uri: MOCK_FEEDS_SURFACE)]
        
        // test
        Messaging.getPropositionsForSurfaces(surfacePaths) { surfacePropositions, error in
            XCTAssertNil(surfacePropositions)
            XCTAssertEqual(AEPError.callbackTimeout, error as? AEPError)
            expectation.fulfill()
        }
        
        // verify
        wait(for: [expectation, eventExpectation], timeout: ASYNC_TIMEOUT)
    }
    
    func testGetPropositionsForSurfacesErrorPopulated() throws {
        // setup
        let expectation = XCTestExpectation(description: "completion should be called with responseEvent")
        let eventExpectation = XCTestExpectation(description: "event should be dispatched")
        EventHub.shared.getExtensionContainer(MockExtension.self)?.eventListeners.clear()
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent) { event in
            eventExpectation.fulfill()
            
            // dispatch the response
            let propositionJson = JSONFileLoader.getRulesJsonFromFile("inappPropositionV1")
            let responseEvent = event.createResponseEvent(name: "name", type: "type", source: "source", data: [
                "propositions": [ propositionJson ],
                "responseerror": AEPError.serverError.rawValue
            ])
            MobileCore.dispatch(event: responseEvent)
        }
        
        let surfacePaths = [Surface(uri: MOCK_FEEDS_SURFACE)]
        
        // test
        Messaging.getPropositionsForSurfaces(surfacePaths) { surfacePropositions, error in
            XCTAssertNil(surfacePropositions)
            XCTAssertEqual(AEPError.serverError, error as? AEPError)            
            expectation.fulfill()
        }
        
        // verify
        wait(for: [expectation, eventExpectation], timeout: ASYNC_TIMEOUT)
    }
    
    func testGetPropositionsForSurfacesNoSurfaces() throws {
        // setup
        let expectation = XCTestExpectation(description: "completion should be called with responseEvent")
        let eventExpectation = XCTestExpectation(description: "event should be dispatched")
        EventHub.shared.getExtensionContainer(MockExtension.self)?.eventListeners.clear()
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent) { event in
            eventExpectation.fulfill()
            
            // dispatch the response
            let responseEvent = event.createResponseEvent(name: "name", type: "type", source: "source", data: [:])
            MobileCore.dispatch(event: responseEvent)
        }
        
        let surfacePaths = [Surface(uri: MOCK_FEEDS_SURFACE)]
        
        // test
        Messaging.getPropositionsForSurfaces(surfacePaths) { surfacePropositions, error in
            XCTAssertNil(surfacePropositions)
            XCTAssertEqual(AEPError.unexpected, error as? AEPError)
            expectation.fulfill()
        }
        
        // verify
        wait(for: [expectation, eventExpectation], timeout: ASYNC_TIMEOUT)
    }
        
    func testGetPropositionsForSurfacesHappy() throws {
        // setup
        let expectation = XCTestExpectation(description: "completion should be called with responseEvent")
        let eventExpectation = XCTestExpectation(description: "event should be dispatched")
        EventHub.shared.getExtensionContainer(MockExtension.self)?.eventListeners.clear()
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent) { event in
            // verify incoming request
            XCTAssertNotNil(event)
            let eventData = event.data
            XCTAssertEqual(true, eventData?["getpropositions"] as? Bool)
            let surfacesMap = eventData?["surfaces"] as? [[String: Any]]
            let dispatchedSurface = surfacesMap?.first
            let surfaceUri = dispatchedSurface?["uri"] as? String
            XCTAssertNotNil(surfaceUri)
            XCTAssertEqual(self.MOCK_FEEDS_SURFACE, surfaceUri)
            eventExpectation.fulfill()
            
            // dispatch the response
            let propositionJson = JSONFileLoader.getRulesJsonFromFile("inappPropositionV1")
            let responseEvent = event.createResponseEvent(name: "name", type: "type", source: "source", data: ["propositions": [ propositionJson ]])
            MobileCore.dispatch(event: responseEvent)
        }
        
        let surfacePaths = [Surface(uri: MOCK_FEEDS_SURFACE)]
        
        // test
        Messaging.getPropositionsForSurfaces(surfacePaths) { surfacePropositions, error in
            XCTAssertEqual(1, surfacePropositions?.count)
            if let aepError = error as? AEPError {
                XCTAssertEqual(aepError, .none)
            }
            expectation.fulfill()
        }
        
        // verify
        wait(for: [expectation, eventExpectation], timeout: ASYNC_TIMEOUT)
    }
    
    // MARK: - setPropositionsHandler
    
    func testSetPropositionsHandler() {
        // setup
        let expectation = XCTestExpectation(description: "setPropositionsHandler should be called with response event upon personalization notification.")
        expectation.assertForOverFulfill = true
        
        let contentString = """
{\"id\":\"183639c4-cb37-458e-a8ef-4e130d767ebf\",\"schema\":\"https://ns.adobe.com/personalization/inbound/feed-item\",\"data\":{\"expiryDate\":1723163897,\"meta\":{\"surface\":\"\(MOCK_BUNDLE_IDENTIFIER)promos/feed1\",\"feedName\":\"Winter Promo\"},\"content\":\"{\\\"body\\\":\\\"All winter gear is now up to 30% off at checkout.\\\",\\\"imageUrl\\\":\\\"https://luma.com/wintersale.png\\\",\\\"actionTitle\\\":\\\"Shop the sale!\\\",\\\"actionUrl\\\":\\\"https://luma.com/sale\\\",\\\"title\\\":\\\"Flash sale!\\\"}\",\"contentType\":\"application/json\",\"publishedDate\":1691541497}}
"""
        
        let testEvent = Event(name: "Message feeds notification",
                              type: "com.adobe.eventType.messaging",
                              source: "com.adobe.eventSource.notification",
                              data: [
                                "propositions": [
                                    [
                                        "id": "5c2ec561-49dd-4c8d-80bb-ffffffffffff",
                                        "scope": "\(MOCK_BUNDLE_IDENTIFIER)promos/feed1",
                                        "scopeDetails": [
                                            "sdKey": "sdValue"
                                        ],
                                        "items": [
                                            [
                                                "id": "5c2ec561-49dd-4c8d-80bb-eeeeeeeeeeee",
                                                "schema": "https://ns.adobe.com/personalization/json-content-item",
                                                "data": [
                                                    "content": "\(contentString)"
                                                ]
                                            ] as [String: Any]
                                        ]
                                    ] as [String: Any]
                                ]
                            ])

        // test
        Messaging.setPropositionsHandler { surfacesDictionary in
            XCTAssertEqual(1, surfacesDictionary.count)
            guard let surface = surfacesDictionary.first?.key, let propositions = surfacesDictionary.first?.value else {
                XCTFail("Response does not contain the expected surface and propositions.")
                return
            }
            
            XCTAssertEqual("\(self.MOCK_BUNDLE_IDENTIFIER)promos/feed1", surface.uri)
            XCTAssertEqual(1, propositions.count)
            guard let proposition = propositions.first else {
                XCTFail("Response does not contain the expected propositions.")
                return
            }
            
            XCTAssertNotNil(proposition.items)
            XCTAssertEqual(1, proposition.items.count)
            guard let inboundItem = proposition.items.first?.decodeContent() else {
                XCTFail("Response does not contain valid inbound.")
                return
            }
            guard let feedItem = inboundItem.decodeContent(FeedItem.self) else {
                XCTFail("Response does not contain valid feed item.")
                return
            }
            
            XCTAssertEqual("Flash sale!", feedItem.title)
            XCTAssertEqual("All winter gear is now up to 30% off at checkout.", feedItem.body)
            XCTAssertEqual("https://luma.com/wintersale.png", feedItem.imageUrl)
            XCTAssertEqual("https://luma.com/sale", feedItem.actionUrl)
            XCTAssertEqual("Shop the sale!", feedItem.actionTitle)
            XCTAssertEqual(1691541497, inboundItem.publishedDate)
            XCTAssertEqual(1723163897, inboundItem.expiryDate)
            XCTAssertNotNil(inboundItem.meta)
            XCTAssertEqual(2, inboundItem.meta?.count)
            XCTAssertEqual("\(self.MOCK_BUNDLE_IDENTIFIER)promos/feed1", inboundItem.meta?["surface"] as? String)
            XCTAssertEqual("Winter Promo", inboundItem.meta?["feedName"] as? String)
            XCTAssertNotNil(proposition.scopeDetails)
            XCTAssertEqual(1, proposition.scopeDetails.count)
            XCTAssertEqual("sdValue", proposition.scopeDetails["sdKey"] as? String)
            expectation.fulfill()
        }

        EventHub.shared.dispatch(event: testEvent)

        // verify
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
    }
    
    func testSetPropositionsHandler_emptyPropositions() {
        // setup
        let expectation = XCTestExpectation(description: "setPropositionsHandler should not be called for empty propositions in personalization notification response.")
        expectation.isInverted = true

        let testEvent = Event(name: "Message feeds notification",
                              type: "com.adobe.eventType.messaging",
                              source: "com.adobe.eventSource.notification",
                              data: [
                                "propositions": [] as [String]
                              ])

        // test
        Messaging.setPropositionsHandler { _ in
            expectation.fulfill()
        }

        EventHub.shared.dispatch(event: testEvent)

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testSetPropositionsHandler_noPropositions() {
        // setup
        let expectation = XCTestExpectation(description: "setPropositionsHandler should not be called for no propositions in personalization notification response.")
        expectation.isInverted = true
        let testEvent = Event(name: "Meesage feeds notification",
                              type: "com.adobe.eventType.messaging",
                              source: "com.adobe.eventSource.notification",
                              data: [:])

        // test
        Messaging.setPropositionsHandler { _ in
            expectation.fulfill()
        }

        EventHub.shared.dispatch(event: testEvent)

        // verify
        wait(for: [expectation], timeout: 1)
    }
    
    func testSetPropositionsHandler_nilEventData() {
        // setup
        let expectation = XCTestExpectation(description: "setPropositionsHandler should not be called for nil event data in personalization notification response.")
        expectation.isInverted = true
        let testEvent = Event(name: "Meesage feeds notification",
                              type: "com.adobe.eventType.messaging",
                              source: "com.adobe.eventSource.notification",
                              data: nil)

        // test
        Messaging.setPropositionsHandler { _ in
            expectation.fulfill()
        }

        EventHub.shared.dispatch(event: testEvent)

        // verify
        wait(for: [expectation], timeout: 1)
    }
}
