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

@testable import AEPCore
import AEPEdge
import AEPEdgeConsent
import AEPEdgeIdentity
@testable import AEPMessaging
@testable import AEPRulesEngine
@testable import AEPServices
import AEPTestUtils

import XCTest

class E2EFunctionalTests: XCTestCase, AnyCodableAsserts {
    
    // testing variables
    var currentMessage: Message?
    let asyncTimeout: TimeInterval = 30
    let appScope = "mobileapp://com.adobe.ajoinbounde2etestsonly"
    let cbeScope = "mobileapp://com.adobe.ajoinbounde2etestsonly/cbeJson"
    let cardScope = "mobileapp://com.adobe.ajoinbounde2etestsonly/cards/ms"
    var mockCache: MockCache!
    var mockRuntime: TestableExtensionRuntime!
    let lock = NSLock()
            
    /// before all
    override class func setUp() {
        configureSdk()
        initializeSdk()
    }
    
    /// before each
    override func setUp() {
        mockCache = MockCache(name: "mockCache")
        mockRuntime = TestableExtensionRuntime()
    }
    
    /// after each
    override func tearDown() {
        currentMessage = nil
//        E2EFunctionalTests.passTime(seconds: 2)
    }

    // MARK: - helpers

    class func configureSdk() {
        MobileCore.setLogLevel(.trace)
        
        // clear out previous runs that may contain settings for connecting w/ staging environment
        MobileCore.clearUpdatedConfiguration()
        
        MobileCore.updateConfigurationWith(configDict: Environment.get().configurationUpdates)
    }
    
    class func initializeSdk() {
        let extensions = [
            Consent.self,
            AEPEdgeIdentity.Identity.self,
            Messaging.self,
            Edge.self
        ]
        
        MobileCore.registerExtensions(extensions) {
            MobileCore.configureWith(appId: Environment.get().appId)
        }
        
        // wait 2 seconds to allow configuration to download
        passTime(seconds: 5)
    }

    func registerMessagingRequestContentListener(_ listener: @escaping EventListener) {
        MobileCore.registerEventListener(type: EventType.messaging, source: EventSource.requestContent, listener: listener)
    }

    func registerEdgePersonalizationDecisionsListener(_ listener: @escaping EventListener) {
        MobileCore.registerEventListener(type: EventType.edge, source: MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS, listener: listener)
    }
    
    func registerEdgeRequestContentListener(_ listener: @escaping EventListener) {
        MobileCore.registerEventListener(type: EventType.edge, source: EventSource.requestContent, listener: listener)
    }

    // MARK: - tests
    
    func testRefreshInAppMessagesHappy() throws {
        // setup
        lock.lock()
        var processed = false
        defer {
            processed = true
            lock.unlock()
        }
        let messagingRequestContentExpectation = XCTestExpectation(description: "messaging request content listener called")
        registerMessagingRequestContentListener() { event in
            guard !processed else {
                return
            }
            XCTAssertNotNil(event)
            let data = event.data
            XCTAssertNotNil(data)
            XCTAssertEqual(true, data?[MessagingConstants.Event.Data.Key.REFRESH_MESSAGES] as? Bool)
            messagingRequestContentExpectation.fulfill()
        }
        
        // test
        Messaging.refreshInAppMessages()
        
        // verify
        wait(for: [messagingRequestContentExpectation], timeout: asyncTimeout)
    }
    
    func testIAMMessagesReturnedFromIDSHaveCorrectJsonFormat() throws {
        // setup
        lock.lock()
        var processed = false
        defer {
            processed = true
            lock.unlock()
        }
        let edgePersonalizationDecisionsExpectation = XCTestExpectation(description: "edge personalization decisions listener called")
        registerEdgePersonalizationDecisionsListener() { event in
            guard !processed else {
                return
            }
            XCTAssertNotNil(event)
            
            // validate the payload exists
            guard let payload = event.data?["payload"] as? [[String: Any]],
                !payload.isEmpty else {
                // no payload means this event is a request, not a response
                XCTFail("SDK TEST ERROR - expected a payload object, but payload is empty")
                return
            }
            
            // loop through the payload and verify the format for each object
            for payloadObject in payload {
                guard payload.first?["scope"] as? String == self.appScope else {
                    break
                }
                self.validateIAMPayloadObject(payloadObject)
                self.validateIAMPayloadContainsMatchingScope(payloadObject)
            }
            edgePersonalizationDecisionsExpectation.fulfill()
        }

        // test
        Messaging.refreshInAppMessages()

        // verify
        wait(for: [edgePersonalizationDecisionsExpectation], timeout: asyncTimeout)
    }
    
    func testUpdatePropositionsForSurfacesCBEHappy() throws {
        // setup
        lock.lock()
        var processed = false
        defer {
            processed = true
            lock.unlock()
        }
        let messagingRequestContentExpectation = XCTestExpectation(description: "messaging request content listener called")
        registerMessagingRequestContentListener() { event in
            guard !processed else {
                return
            }
            XCTAssertNotNil(event)
            let data = event.data
            XCTAssertNotNil(data)
            XCTAssertEqual(true, data?[MessagingConstants.Event.Data.Key.UPDATE_PROPOSITIONS] as? Bool)
            messagingRequestContentExpectation.fulfill()
        }
        
        // test
        let surfaces: [Surface] = [
            Surface(path: "cbeJson")
        ]
        Messaging.updatePropositionsForSurfaces(surfaces)
        
        // verify
        wait(for: [messagingRequestContentExpectation], timeout: asyncTimeout)
    }
    
    func testCBEMessagesReturnedFromXASHaveCorrectJsonFormat() throws {
        // setup
        lock.lock()
        var processed = false
        defer {
            processed = true
            lock.unlock()
        }
        let edgePersonalizationDecisionsExpectation = XCTestExpectation(description: "edge personalization decisions listener called")
        registerEdgePersonalizationDecisionsListener() { event in
            guard !processed else {
                return
            }
            XCTAssertNotNil(event)
            
            // validate the payload exists
            guard let payload = event.data?["payload"] as? [[String: Any]] else {
                // no payload means this event is a request, not a response
                return
            }
            
            // validate the payload is not empty
            guard !payload.isEmpty else {
                XCTFail("SDK TEST ERROR - expected a payload object, but payload is empty")
                return
            }
            
            
            // loop through the payload and verify the format for each object
            for payloadObject in payload {
                self.validateCBEPayloadObject(payloadObject)
                self.validateCBEPayloadContainsMatchingScope(payloadObject)
            }
            
            edgePersonalizationDecisionsExpectation.fulfill()
        }

        // test
        let surfaces: [Surface] = [
            Surface(path: "cbeJson")
        ]
        Messaging.updatePropositionsForSurfaces(surfaces)

        // verify
        wait(for: [edgePersonalizationDecisionsExpectation], timeout: asyncTimeout)
    }
    
    func testUpdatePropositionsForSurfacesContentCardHappy() throws {
        // setup
        lock.lock()
        var processed = false
        defer {
            processed = true
            lock.unlock()
        }
        let messagingRequestContentExpectation = XCTestExpectation(description: "messaging request content listener called")
        registerMessagingRequestContentListener() { event in
            guard !processed else {
                return
            }
            XCTAssertNotNil(event)
            let data = event.data
            XCTAssertNotNil(data)
            XCTAssertEqual(true, data?[MessagingConstants.Event.Data.Key.UPDATE_PROPOSITIONS] as? Bool)
        
            messagingRequestContentExpectation.fulfill()
        }
        
        // test
        let surfaces: [Surface] = [
            Surface(path: "cards/ms")
        ]
        Messaging.updatePropositionsForSurfaces(surfaces)
        
        // verify
        wait(for: [messagingRequestContentExpectation], timeout: asyncTimeout)
    }
    
    func testContentCardMessagesReturnedFromXASHaveCorrectJsonFormat() throws {
        // setup
        lock.lock()
        var processed = false
        defer {
            processed = true
            lock.unlock()
        }
        let edgePersonalizationDecisionsExpectation = XCTestExpectation(description: "edge personalization decisions listener called")
        registerEdgePersonalizationDecisionsListener() { event in
            guard !processed else {
                return
            }
            XCTAssertNotNil(event)
            
            // validate the payload exists
            guard let payload = event.data?["payload"] as? [[String: Any]] else {
                // no payload means this event is a request, not a response
                return
            }
            
            // validate the payload is not empty
            guard !payload.isEmpty else {
                XCTFail("SDK TEST ERROR - expected a payload object, but payload is empty")
                return
            }
            
            
            // loop through the payload and verify the format for each object
            for payloadObject in payload {
                self.validateContentCardPayloadObject(payloadObject)
                self.validateContentCardPayloadContainsMatchingScope(payloadObject)
            }

            edgePersonalizationDecisionsExpectation.fulfill()
        }

        // test
        let surfaces: [Surface] = [
            Surface(path: "cards/ms")
        ]
        Messaging.updatePropositionsForSurfaces(surfaces)

        // verify
        wait(for: [edgePersonalizationDecisionsExpectation], timeout: asyncTimeout)
    }
    
    // TODO: - update these tests with v2 format
    
//    func testMessagesReturnedFromXASHaveCorrectRuleFormat() throws {
//        // setup
//        let edgePersonalizationDecisionsExpectation = XCTestExpectation(description: "edge personalization decisions listener called")
//        registerEdgePersonalizationDecisionsListener() { event in
//
//            // validate the content is a valid rule containing a valid message
//            guard let propositions = event.payload else {
//                // no payload means this event is a request, not a response
//                return
//            }
//
//            let messagingRulesEngine = MessagingRulesEngine(name: "testRulesEngine", extensionRuntime: self.mockRuntime, cache: self.mockCache)
//            var rulesArray: [LaunchRule] = []
//
//            // loop though the payload and parse the rule
//            for proposition in propositions {
//                if let ruleString = proposition.items.first?.data.content,
//                    !ruleString.isEmpty,
//                    let rule = messagingRulesEngine.parseRule(ruleString) {
//                    rulesArray.append(contentsOf: rule)
//                }
//            }
//
//            // load the parsed rules into the rules engine
//            messagingRulesEngine.loadRules(rulesArray, clearExisting: true)
//
//            // rules load async - brief sleep to allow it to finish
//            self.runAfter(seconds: 3) {
//                XCTAssertTrue(messagingRulesEngine.rulesEngine.rulesEngine.rules.count > 0, "Message definition successfully loaded into the rules engine.")
//                edgePersonalizationDecisionsExpectation.fulfill()
//            }
//        }
//
//        // test
//        Messaging.refreshInAppMessages()
//
//        // verify
//        wait(for: [edgePersonalizationDecisionsExpectation], timeout: asyncTimeout)
//    }
    
//    func testMessagesDisplayInteractDismissEvents() throws {
//        // setup
//        let edgeRequestDisplayEventExpectation = XCTestExpectation(description: "edge event with propositionEventType == display received.")
//        let edgeRequestInteractEventExpectation = XCTestExpectation(description: "edge event with propositionEventType == interact received.")
//        let edgeRequestDismissEventExpectation = XCTestExpectation(description: "edge event with propositionEventType == dismiss received.")
//        registerEdgeRequestContentListener() { event in
//            if event.isPropositionEvent(withType: "display") {
//                self.currentMessage?.track("clicked", withEdgeEventType: .inappInteract)
//                edgeRequestDisplayEventExpectation.fulfill()
//            }
//            if event.isPropositionEvent(withType: "interact") {
//                self.currentMessage?.dismiss()
//                edgeRequestInteractEventExpectation.fulfill()
//            }
//            if event.isPropositionEvent(withType: "dismiss") {
//                edgeRequestDismissEventExpectation.fulfill()
//            }
//        }
//        MobileCore.messagingDelegate = self
//
//        // allow rules engine to be hydrated
//        runAfter(seconds: 5) {
//            MobileCore.track(action: "showModal", data: nil)
//        }
//
//        // verify
//        wait(for: [edgeRequestDisplayEventExpectation, edgeRequestInteractEventExpectation, edgeRequestDismissEventExpectation], timeout: asyncTimeout)
//    }

    /// wait for `seconds` before running the code in the closure
    func runAfter(seconds: Int, closure: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(seconds), execute: closure)
    }
    
    class func passTime(seconds: Int) {
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(seconds)) {
            semaphore.signal()
        }
        semaphore.wait()
    }
    
    func validateIAMPayloadObject(_ payload: [String: Any]) {
        let expectedPayloadJSON = #"""
        {
            "id": "string",
            "scope": "string",
            "scopeDetails": {
                "activity": {
                    "id": "string",
                    "matchedSurfaces": []
                },
                "characteristics": {
                    "eventToken": "string"
                },
                "correlationID": "string",
                "decisionProvider": "string"
            },
            "items": [
                {
                    "id": "string",
                    "schema": "string",
                    "data": {
                        "rules" : [
                            {
                                "condition": {},
                                "consequences": []
                            }
                        ],
                        "version": 12.34
                    }
                }
            ]
        }
        """#

        // validate required fields are in first payload item and their types are correct
        assertTypeMatch(expected: expectedPayloadJSON.toAnyCodable()!, actual: AnyCodable(payload), pathOptions: [])
    }
    
    func validateCBEPayloadObject(_ payload: [String: Any]) {
        let expectedPayloadJSON = #"""
        {
            "id": "string",
            "scope": "string",
            "scopeDetails": {
                "activity": {
                    "id": "string",
                    "matchedSurfaces": []
                },
                "characteristics": {
                    "eventToken": "string"
                },
                "correlationID": "string",
                "decisionProvider": "string"
            },
            "items": [
                {
                    "id": "string",
                    "schema": "string",
                    "data": {
                        "content" : {}
                    }
                }
            ]
        }
        """#

        // validate required fields are in first payload item and their types are correct
        assertTypeMatch(expected: expectedPayloadJSON.toAnyCodable()!, actual: AnyCodable(payload), pathOptions: [])
    }
    
    func validateContentCardPayloadObject(_ payload: [String: Any]) {
        let expectedPayloadJSON = #"""
        {
            "id": "string",
            "scope": "string",
            "scopeDetails": {
                "activity": {
                    "id": "string",
                    "matchedSurfaces": []
                },
                "characteristics": {
                    "eventToken": "string"
                },
                "correlationID": "string",
                "decisionProvider": "string"
            },
            "items": [
                {
                    "id": "string",
                    "schema": "string",
                    "data": {
                        "rules" : [
                            {
                                "condition": {},
                                "consequences": []
                            }
                        ],
                        "version": 12.34
                    }
                }
            ]
        }
        """#

        // validate required fields are in first payload item and their types are correct
        assertTypeMatch(expected: expectedPayloadJSON.toAnyCodable()!, actual: AnyCodable(payload), pathOptions: [])
    }
    
    func validateIAMPayloadContainsMatchingScope(_ payload: [String: Any]) {
        let expectedPayloadJSON = #"""
        {
            "scope": "mobileapp://com.adobe.ajoinbounde2etestsonly"
        }
        """#
        
        // validate only the scope and that it has the correct value
        assertExactMatch(expected: expectedPayloadJSON.toAnyCodable()!, actual: AnyCodable(payload))
    }
    
    func validateCBEPayloadContainsMatchingScope(_ payload: [String: Any]) {
        let expectedPayloadJSON = #"""
        {
            "scope": "mobileapp://com.adobe.ajoinbounde2etestsonly/cbeJson"
        }
        """#
        
        // validate only the scope and that it has the correct value
        assertExactMatch(expected: expectedPayloadJSON.toAnyCodable()!, actual: AnyCodable(payload))
    }
    
    func validateContentCardPayloadContainsMatchingScope(_ payload: [String: Any]) {
        let expectedPayloadJSON = #"""
        {
            "scope": "mobileapp://com.adobe.ajoinbounde2etestsonly/cards/ms"
        }
        """#
        
        // validate only the scope and that it has the correct value
        assertExactMatch(expected: expectedPayloadJSON.toAnyCodable()!, actual: AnyCodable(payload))
    }
    
    func missingField(_ key: String) -> String {
        return "SDK TEST ERROR - Required field '\(key)' is missing from the map."
    }
    
    func wrongType(_ key: String, expected: String) -> String {
        return "SDK TEST ERROR - Required field '\(key)' is present, but is not expected type '\(expected)'."
    }
}

extension E2EFunctionalTests: MessagingDelegate {
    func onShow(message: Showable) {
        currentMessage?.track("clicked", withEdgeEventType: .interact)
    }

    func onDismiss(message: Showable) {
        
    }

    func shouldShowMessage(message: Showable) -> Bool {
        currentMessage = (message as? FullscreenMessage)?.parent
        return true
    }
}

extension Event {
    func isPropositionEvent(withType type: String) -> Bool {
        guard let data = data,
              let xdm = data["xdm"] as? [String: Any],
              let experience = xdm["_experience"] as? [String: Any],
              let decisioning = experience["decisioning"] as? [String: Any],
              let propositionEventType = decisioning["propositionEventType"] as? [String: Any] else {
            return false
        }
        
        return propositionEventType.contains(where: { $0.key == type})
    }
}

