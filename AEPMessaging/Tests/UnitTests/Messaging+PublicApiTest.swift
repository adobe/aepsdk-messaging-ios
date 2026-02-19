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
import AEPTestUtils

class MessagingPublicApiTest: XCTestCase, AnyCodableAsserts {
    
    let ASYNC_TIMEOUT = 2.0
    static let MOCK_TRACKING_DETAILS : [String:Any] = [MessagingConstants.XDM.AdobeKeys._XDM:
                                                        ["trackingKey": "trackingValue"]]
    static let WEB_URL = URL(string: "https://adobe.com")!
    static let DEEPLINK_URL = URL(string: "deeplink://")!
    let MOCK_BUNDLE_IDENTIFIER = "mobileapp://com.adobe.ajo.e2eTestApp"
    let MOCK_FEEDS_SURFACE = "mobileapp://com.adobe.ajo.e2eTestApp/promos/feed1"
    
    override func setUp() {
        registerNotificationCategories()
        EventHub.shared.start()
        registerMockExtension(MockExtension.self)
    }
    
    override func tearDown() {
        resetNotificationCategories()
        MobileCore.resetSDK()
    }
    
    private func registerMockExtension<T: Extension>(_ type: T.Type) {
        let semaphore = DispatchSemaphore(value: 0)
        EventHub.shared.registerExtension(type) { _ in
            semaphore.signal()
        }
        
        semaphore.wait()
    }
    
    
    func testHandleNotificationResponse_when_notificationTapped() {
        // mock notification response indicating click of notification
        let mockedResponse = createNotificationResponse(actionId: UNNotificationDefaultActionIdentifier)
        
        // create your expectations
        let expectation = XCTestExpectation(description: "messaging requestContent event dispatched")
        MobileCore.registerEventListener(type: EventType.messaging, source: EventSource.requestContent) { event in
            let expectedEventData = #"""
            {
                "eventType": "pushTracking.applicationOpened",
                "applicationOpened": true,
                "id": "mockIdentifier",
                "clickThroughUrl": "https://adobe.com",
                "adobe_xdm": {
                    "trackingKey": "trackingValue"
                }
            }
            """#.toAnyCodable()
            self.assertEqual(expected: event.data?.toAnyCodable(), actual: expectedEventData)
            expectation.fulfill()
        }
        
        // test
        Messaging.handleNotificationResponse(mockedResponse)
        
        // verify expectation
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
    }
    
    
    func testHandleNotificationResponse_when_notificationDismissed() {
        // mock notification response indicating notification dismiss
        let mockedResponse = createNotificationResponse(actionId: UNNotificationDismissActionIdentifier)
        
        // create your expectations
        let expectation = XCTestExpectation(description: "messaging requestContent event dispatched")
        MobileCore.registerEventListener(type: EventType.messaging, source: EventSource.requestContent) { event in
            let expectedEventData = #"""
            {
              "eventType": "pushTracking.customAction",
              "actionId": "Dismiss",
              "applicationOpened" : false,
              "id" : "mockIdentifier",
              "adobe_xdm": {
                "trackingKey": "trackingValue"
              }
            }
            """#.toAnyCodable()
            self.assertEqual(expected: expectedEventData, actual: event.data?.toAnyCodable())
            expectation.fulfill()
        }
        
        // test
        Messaging.handleNotificationResponse(mockedResponse)
        
        // verify expectation
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
    }
    
    func testHandleNotificationResponse_when_customAction_opensApp() {
        // mock notification response indicating custom action that opens the application
        // For more details about the actionIdentifier registered with the notification look at method `registerNotificationCategories`
        // the actionID "open" is regsitered to open the application
        let mockedResponse = createNotificationResponse(actionId: "open")
        
        // create your expectations
        let expectation = XCTestExpectation(description: "messaging requestContent event dispatched")
        MobileCore.registerEventListener(type: EventType.messaging, source: EventSource.requestContent) { event in
            let expectedEventData = #"""
            {
              "eventType": "pushTracking.customAction",
              "actionId": "open",
              "applicationOpened" : true,
              "id" : "mockIdentifier",
              "adobe_xdm": {
                "trackingKey": "trackingValue"
              }
            }
            """#.toAnyCodable()
            self.assertEqual(expected: expectedEventData, actual: event.data?.toAnyCodable())
            expectation.fulfill()
        }
        
        // test
        Messaging.handleNotificationResponse(mockedResponse)
        
        // verify expectation
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
    }
    
    
    func testHandleNotificationResponse_when_customAction_doesNotOpenApp() {
        // Mock notification response indicating custom action that does not opens the application
        // For more details about the actionIdentifier registered with the notification look at method `registerNotificationCategories`
        // the actionID "cancel" is regsitered to dismiss the notification
        let mockedResponse = createNotificationResponse(actionId: "cancel")
        
        // create your expectations
        let expectation = XCTestExpectation(description: "messaging requestContent event dispatched")
        MobileCore.registerEventListener(type: EventType.messaging, source: EventSource.requestContent) { event in
            let expectedEventData = #"""
            {
              "eventType": "pushTracking.customAction",
              "actionId": "cancel",
              "applicationOpened" : false,
              "id" : "mockIdentifier",
              "adobe_xdm": {
                "trackingKey": "trackingValue"
              }
            }
            """#.toAnyCodable()
            self.assertEqual(expected: expectedEventData, actual: event.data?.toAnyCodable())
            expectation.fulfill()
        }
        
        // test
        Messaging.handleNotificationResponse(mockedResponse)
        
        // verify expectation
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
    }
    
    
    func testHandleNotificationResponse_when_noTrackingData() {
        // Mock notification response that contains no tracking data
        let mockedResponse = createNotificationResponse(actionId: "cancel", trackingData: nil)
        
        // create your expectations
        let eventExpectation = XCTestExpectation(description: "messaging requestContent event not dispatched")
        eventExpectation.isInverted = true
        let callbackExpectation = XCTestExpectation(description: "correct push tracking status was returned")
        
        // register listener to verify messaging request content event
        MobileCore.registerEventListener(type: EventType.messaging, source: EventSource.requestContent) { event in
            eventExpectation.fulfill()
        }
        
        // test
        Messaging.handleNotificationResponse(mockedResponse, closure:  { status in
            XCTAssertEqual(status, .noTrackingData)
            callbackExpectation.fulfill()
        })
        
        // verify expectation
        wait(for: [eventExpectation, callbackExpectation], timeout: ASYNC_TIMEOUT)
    }
    
    func testHandleNotificationResponse_when_URLNotHandledByApplication() {
        // Mock notification response that contains no tracking data
        let mockedResponse = createNotificationResponse(url: MessagingPublicApiTest.WEB_URL)
        
        // create your expectations
        let eventExpectation = XCTestExpectation(description: "messaging requestContent event dispatched")
        
        // register listener to verify messaging request content event
        MobileCore.registerEventListener(type: EventType.messaging, source: EventSource.requestContent) { event in
            XCTAssertEqual(event.data!["clickThroughUrl"] as! String, MessagingPublicApiTest.WEB_URL.absoluteString)
            eventExpectation.fulfill()
        }
        
        // test
        Messaging.handleNotificationResponse(mockedResponse, urlHandler: { link in 
            // returning false to indicate that the URL was not handled by the application
            return false
        })
        
        // verify expectation
        wait(for: [eventExpectation], timeout: ASYNC_TIMEOUT)
    }

    func testHandleNotificationResponse_when_URLHandledByApplication() {
        // Mock notification response with a deeplink URL
        let mockedResponse = createNotificationResponse(url: MessagingPublicApiTest.DEEPLINK_URL)
        
        // create your expectations
        let eventExpectation = XCTestExpectation(description: "messaging requestContent event dispatched")
        
        // register listener to verify messaging request content event
        MobileCore.registerEventListener(type: EventType.messaging, source: EventSource.requestContent) { event in
            // verify clickThroughUrl is not present in the event data
            XCTAssertNil(event.data!["clickThroughUrl"])
            eventExpectation.fulfill()
        }
        
        // test
        Messaging.handleNotificationResponse(mockedResponse, urlHandler: { link in 
            // returning true to indicate that the URL was handled by the application
            return true
        })
        
        // verify expectation
        wait(for: [eventExpectation], timeout: ASYNC_TIMEOUT)
    }
    
    
    func testHandleNotificationResponse_when_customAction_then_NoClickThroughUrlAttached() {
        // Mock notification response indicating custom action being taken on a notification
        let mockedResponse = createNotificationResponse(actionId: "open", url: MessagingPublicApiTest.DEEPLINK_URL)
        
        // create your expectations
        let eventExpectation = XCTestExpectation(description: "clickthrough url should not be present in event payload")
        
        // register listener to verify messaging request content event
        MobileCore.registerEventListener(type: EventType.messaging, source: EventSource.requestContent) { event in
            // verify clickThroughUrl is not present in the event data
            // "ClickthroughUrl" key will only exist when notification body is tapped
            XCTAssertNil(event.data!["clickThroughUrl"])
            eventExpectation.fulfill()
        }
        
        // test
        Messaging.handleNotificationResponse(mockedResponse, urlHandler: { link in
            // returning true to indicate that the URL was handled by the application
            return true
        })
        
        // verify expectation
        wait(for: [eventExpectation], timeout: ASYNC_TIMEOUT)
    }
    
    
    func testHandleNotificationResponse_when_urlHandlerIsNil_then_ClickThroughUrlAttached() {
        // Mock notification response indicating custom action being taken on a notification
        let mockedResponse = createNotificationResponse(url: MessagingPublicApiTest.DEEPLINK_URL)
        
        // create your expectations
        let eventExpectation = XCTestExpectation(description: "clickthrough url should be present in event payload")
        
        // register listener to verify messaging request content event
        MobileCore.registerEventListener(type: EventType.messaging, source: EventSource.requestContent) { event in
            XCTAssertNotNil(event.data!["clickThroughUrl"])
            eventExpectation.fulfill()
        }
        
        // test
        Messaging.handleNotificationResponse(mockedResponse, urlHandler: nil)
        
        // verify expectation
        wait(for: [eventExpectation], timeout: ASYNC_TIMEOUT)
    }
    
    func testHandleNotificationResponse_when_userInfoHasPushToInapp_then_refreshMessagesCalled() throws {
        // setup
        RefreshInAppHandler.shared.reset()
        let iamId = "mockIamId"
        var trackingData = MessagingPublicApiTest.MOCK_TRACKING_DETAILS
        trackingData["adb_iam_id"] = iamId
        let notificationResponse = createNotificationResponse(trackingData: trackingData)
                
        // register listener for refresh messages call (Push-to-InApp now uses RefreshInAppHandler)
        let refreshMessagesExpectation = XCTestExpectation(description: "RefreshMessages should be called")
        MobileCore.registerEventListener(type: EventType.messaging, source: EventSource.requestContent) { event in
            if event.name == MessagingConstants.Event.Name.REFRESH_MESSAGES {
                refreshMessagesExpectation.fulfill()
            }
        }
        
        // test
        Messaging.handleNotificationResponse(notificationResponse)
        
        // verify
        wait(for: [refreshMessagesExpectation], timeout: ASYNC_TIMEOUT)
    }
    
    
    func testRefreshInAppMessages() throws {
        // setup
        RefreshInAppHandler.shared.reset()
        let expectation = XCTestExpectation(description: "Refresh In app messages event")
        expectation.assertForOverFulfill = true
        
        MobileCore.registerEventListener(type: EventType.messaging, source: EventSource.requestContent) { event in
            XCTAssertEqual(MessagingConstants.Event.Name.REFRESH_MESSAGES, event.name)
            let expectedEventData = #"""
            {
              "refreshmessages": true
            }
            """#.toAnyCodable()
            self.assertEqual(expected: expectedEventData, actual: event.data?.toAnyCodable())
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
                
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { event in
            XCTAssertEqual(testEvent.name, event.name)
            XCTAssertNotNil(event.data)
            XCTAssertEqual(true, event.data?["updatepropositions"] as? Bool)
            guard let surfaces = event.data?["surfaces"] as? [[String: Any]], !surfaces.isEmpty else {
                XCTFail("Surface path strings array should be valid.")
                return
            }
            XCTAssertEqual(2, surfaces.count)
            XCTAssertEqual("\(self.MOCK_BUNDLE_IDENTIFIER)/promos/feed1", surfaces[0]["uri"] as? String)
            XCTAssertEqual("\(self.MOCK_BUNDLE_IDENTIFIER)/promos/feed2", surfaces[1]["uri"] as? String)
            
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
        
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { event in
            XCTAssertEqual(testEvent.name, event.name)
            XCTAssertNotNil(event.data)
            XCTAssertEqual(true, event.data?["updatepropositions"] as? Bool)
            guard let surfaces = event.data?["surfaces"] as? [[String: Any]], !surfaces.isEmpty else {
                XCTFail("Surface path strings array should be valid.")
                return
            }
            XCTAssertEqual(2, surfaces.count)
            XCTAssertEqual(self.MOCK_BUNDLE_IDENTIFIER, surfaces[0]["uri"] as? String)
            XCTAssertEqual("\(self.MOCK_BUNDLE_IDENTIFIER)/promos/feed2", surfaces[1]["uri"] as? String)
            
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
        let expectation = XCTestExpectation(description: "updatePropositionsForSurfaces should dispatch an event.")
        expectation.assertForOverFulfill = true
        
        let testEvent = Event(name: "Update propositions",
                              type: "com.adobe.eventType.messaging",
                              source: "com.adobe.eventSource.requestContent",
                              data: [
                                "updatepropositions": true,
                                "surfaces": [
                                    [ : ]
                                ]
                              ])
        
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(
            type: "com.adobe.eventType.messaging",
            source: "com.adobe.eventSource.requestContent") { event in
                
                XCTAssertEqual(testEvent.name, event.name)
                XCTAssertNotNil(event.data)
                XCTAssertEqual(true, event.data?["updatepropositions"] as? Bool)
                guard let surfaces = event.data?["surfaces"] as? [[String: Any]], !surfaces.isEmpty else {
                    XCTFail("Surface path strings array should be valid.")
                    return
                }
                XCTAssertEqual(1, surfaces.count)
                XCTAssertEqual(self.MOCK_BUNDLE_IDENTIFIER, surfaces[0]["uri"] as? String)
                
                expectation.fulfill()
            }
        
        // test
        Messaging.updatePropositionsForSurfaces([
            Surface(path: "")
        ])
        
        // verify
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
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
        wait(for: [expectation], timeout: ASYNC_TIMEOUT)
    }
    
    // MARK: - getPropositionsForSurfaces
    
    func testGetPropositionsForSurfacesNoValidSurfaces() throws {
        // setup
        let expectation = XCTestExpectation(description: "completion should be called with invalidRequest")
        let eventExpectation = XCTestExpectation(description: "event should be dispatched")
        eventExpectation.isInverted = true
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.messaging, source: EventSource.requestContent) { _ in
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
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.messaging, source: EventSource.requestContent) { event in
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
        wait(for: [expectation, eventExpectation], timeout: 6.0) // timeout for request is 5 seconds, need to wait longer than that
    }
    
    func testGetPropositionsForSurfacesErrorPopulated() throws {
        // setup
        let expectation = XCTestExpectation(description: "completion should be called with responseEvent")
        let eventExpectation = XCTestExpectation(description: "event should be dispatched")
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.messaging, source: EventSource.requestContent) { event in
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
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.messaging, source: EventSource.requestContent) { event in
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
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.messaging, source: EventSource.requestContent) { event in
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
            let propositionJson = JSONFileLoader.getRulesJsonFromFile("inappPropositionV2")
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
    
    /// Private Helper methods
    private func createNotificationResponse(actionId : String = UNNotificationDefaultActionIdentifier,
                                            trackingData : [String : Any]? = MOCK_TRACKING_DETAILS,
                                            url : URL = WEB_URL) -> UNNotificationResponse {
        
        let dateInfo = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: false)
        let notificationContent = UNMutableNotificationContent()
        var userInfo : [String : Any] = [MessagingConstants.PushNotification.UserInfoKey.ACTION_URL : url.absoluteString]
        if let trackingData = trackingData {
            for (key, value) in trackingData {
                userInfo[key] = value
            }
        }
        notificationContent.userInfo = userInfo
        notificationContent.categoryIdentifier = "categoryId"
        let request = UNNotificationRequest(identifier: "mockIdentifier",
                                            content: notificationContent,
                                            trigger: trigger)
        let response = UNNotificationResponse(coder: MockNotificationResponseCoder(with: request,
                                                                                   actionIdentifier: actionId))!
        return response
    }
    
    private func registerNotificationCategories() {
        // Define actions
        let action1 = UNNotificationAction(identifier: "open", title: "OPEN", options: [.foreground])
        let action2 = UNNotificationAction(identifier: "cancel", title: "CANCEL", options: [.destructive])
        
        // Define category with actions
        let category = UNNotificationCategory(identifier: "categoryId", actions: [action1, action2], intentIdentifiers: [], options: [.customDismissAction])
        
        // Register the category
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    private func resetNotificationCategories() {
        // Register the category
        UNUserNotificationCenter.current().setNotificationCategories([])
    }
}
