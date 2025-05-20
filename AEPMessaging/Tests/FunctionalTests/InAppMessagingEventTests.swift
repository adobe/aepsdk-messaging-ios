/*
 Copyright 2022 Adobe. All rights reserved.
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

class InAppMessagingEventTests: XCTestCase, AnyCodableAsserts {
    
    // testing variables
    var currentMessage: Message?
    let asyncTimeout: TimeInterval = 30
    let expectedScope = "mobileapp://com.adobe.ajo.e2eTestApp"
    var mockCache: MockCache!
    var mockRuntime: TestableExtensionRuntime!

    override class func setUp() {
        // before all
        initializeSdk()
    }
    
    override class func tearDown() {
        // after all
    }
        
    override func setUp() {
        // before each
        mockCache = MockCache(name: "mockCache")
        mockRuntime = TestableExtensionRuntime()
    }
    
    override func tearDown() {
        // after each
        currentMessage = nil
    }

    // MARK: - helpers

    class func initializeSdk() {
        MobileCore.setLogLevel(.trace)
        
        /// Environment: Production
        /// Org: AEM Assets Departmental - Campaign
        /// Sandbox: Prod (VA7)
        /// Data Collection Tag: AJO - IAM Functional Tests
        /// App Surface: AJO - IAM Functional Tests (com.adobe.ajo.e2eTestApp)
        /// DC Environment App ID: 3149c49c3910/04253786b724/launch-0cb6f35aacd0-development
        MobileCore.configureWith(appId: "3149c49c3910/04253786b724/launch-0cb6f35aacd0-development")

        let extensions = [
            Consent.self,
            Identity.self,
            Messaging.self,
            Edge.self
        ]

        MobileCore.registerExtensions(extensions)
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
    
    // func testRefreshInAppMessagesHappy() throws {
    //     // setup
    //     let messagingRequestContentExpectation = XCTestExpectation(description: "messaging request content listener called")
    //     registerMessagingRequestContentListener() { event in
    //         XCTAssertNotNil(event)
    //         let data = event.data
    //         XCTAssertNotNil(data)
    //         XCTAssertEqual(true, data?[MessagingConstants.Event.Data.Key.REFRESH_MESSAGES] as? Bool)
    //         messagingRequestContentExpectation.fulfill()
    //     }
        
    //     // test
    //     Messaging.refreshInAppMessages()
        
    //     // verify
    //     wait(for: [messagingRequestContentExpectation], timeout: asyncTimeout)
    // }

//    func testMessagesReturnedFromXASHaveCorrectJsonFormat() throws {
//        // setup
//        let edgePersonalizationDecisionsExpectation = XCTestExpectation(description: "edge personalization decisions listener called")
//        registerEdgePersonalizationDecisionsListener() { event in
//            XCTAssertNotNil(event)
//            
//            // validate the payload exists
//            guard let payload = event.data?["payload"] as? [[String: Any]] else {
//                // no payload means this event is a request, not a response
//                return
//            }
//            
//            // validate the payload is not empty
//            guard !payload.isEmpty else {
//                XCTFail("SDK TEST ERROR - expected a payload object, but payload is empty")
//                return
//            }
//            
//            // loop through the payload and verify the format for each object
//            for payloadObject in payload {
//                XCTAssertTrue(self.payloadObjectIsValid(payloadObject), "SDK TEST ERROR - payload object returned was invalid: \(payloadObject)")
//            }
//            
//            edgePersonalizationDecisionsExpectation.fulfill()
//        }
//
//        // test
//        Messaging.refreshInAppMessages()
//
//        // verify
//        wait(for: [edgePersonalizationDecisionsExpectation], timeout: asyncTimeout)
//    }
//
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
//            let messagingRulesEngine = MessagingRulesEngine(name: "testRulesEngine", extensionRuntime: TestableExtensionRuntime())
//            messagingRulesEngine.loadPropositions(propositions, clearExisting: true, expectedScope: self.expectedScope)
//            
//            // rules load async - brief sleep to allow it to finish
//            self.runAfter(seconds: 3) {
//                XCTAssertEqual(3, messagingRulesEngine.rulesEngine.rulesEngine.rules.count, "Message definition successfully loaded into the rules engine.")
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
//    
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
    
    func validatePayloadObject(_ payload: [String: Any]) {
        let expectedJSON = """
        {
          "id": "mockMessageId",
          "items": [
            {
              "id": "mockItemId",
              "schema": "https://ns.adobe.com/personalization/json-content-item",
              "data": {
                "id": "mockItemId",
                "content": "mockContent"
              }
            }
          ],
          "scope": "mockScope",
          "scopeDetails": {
            "decisionProvider": "TGT",
            "activity": {
              "id": "mockActivityId"
            }
          }
        }
        """
        
        assertTypeMatch(expected: expectedJSON, actual: payload)
    }
    
    func missingField(_ key: String) -> String {
        return "SDK TEST ERROR - Required field '\(key)' is missing from the map."
    }
    
    func wrongType(_ key: String, expected: String) -> String {
        return "SDK TEST ERROR - Required field '\(key)' is present, but is not expected type '\(expected)'."
    }
}

extension InAppMessagingEventTests: MessagingDelegate {
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
