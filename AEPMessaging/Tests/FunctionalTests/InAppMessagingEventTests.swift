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

import XCTest

class InAppMessagingEventTests: XCTestCase {
    
    // testing variables
    var currentMessage: Message?
    let asyncTimeout: TimeInterval = 30
    let expectedScope = "mobileapp://com.adobe.ajo.e2eTestApp"

    override class func setUp() {
        // before all
        initializeSdk()
    }
    
    
    override class func tearDown() {
        // after all
    }
        
    override func setUp() {
        // before each
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
        MobileCore.registerEventListener(type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent, listener: listener)
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
    
    func payloadObjectIsValid(_ payload: [String: Any]) -> Bool {
        
        var objectIsValid = true
                
        /// {
        ///     "id": "string",
        ///     "scope": "string",
        ///     "scopeDetails": {
        ///         "activity": {
        ///             "id": "string"
        ///         },
        ///         "characteristics": {
        ///             "eventToken": "string"
        ///         },
        ///         "correlationID": "string",
        ///         "decisionProvider": "string"
        ///     },
        ///     "items": [
        ///         {
        ///             "id": "string",
        ///             "schema": "string",
        ///             "data": {
        ///                 "content": "string", // <<< sdk rule
        ///                 "id": "string"
        ///             }
        ///         }
        ///     ]
        /// }
        
        // validate required fields are in first payload item and their types are correct
        if !payload.contains(where: { $0.key == "id" }) {
            XCTFail(self.missingField("id"))
            objectIsValid = false
        } else {
            let value = payload["id"] as? String
            if value == nil {
                XCTFail(self.wrongType("id", expected: "String"))
                objectIsValid = false
            }
        }
        
        if !payload.contains(where: { $0.key == "scope" }) {
            XCTFail(self.missingField("scope"))
            objectIsValid = false
        } else {
            let value = payload["scope"] as? String
            if value == nil {
                XCTFail(self.wrongType("scope", expected: "String"))
                objectIsValid = false
            }
        }
        
        var scopeDetails: [String: Any]?
        if !payload.contains(where: { $0.key == "scopeDetails" }) {
            XCTFail(self.missingField("scopeDetails"))
            objectIsValid = false
        } else {
            scopeDetails = payload["scopeDetails"] as? [String: Any]
            if scopeDetails == nil {
                XCTFail(self.wrongType("scopeDetails", expected: "[String: Any]"))
                objectIsValid = false
            }
        }
        
        var activity: [String: Any]?
        if !(scopeDetails?.contains(where: { $0.key == "activity" }) ?? false) {
            XCTFail(self.missingField("scopeDetails.activity"))
            objectIsValid = false
        } else {
            activity = scopeDetails?["activity"] as? [String: Any]
            if activity == nil {
                XCTFail(self.wrongType("scopeDetails.activity", expected: "[String: Any]"))
                objectIsValid = false
            }
        }
        
        if !(activity?.contains(where: { $0.key == "id" }) ?? false) {
            XCTFail(self.missingField("scopeDetails.activity.id"))
            objectIsValid = false
        } else {
            let value = activity?["id"] as? String
            if value == nil {
                XCTFail(self.wrongType("scopeDetails.activity.id", expected: "String"))
                objectIsValid = false
            }
        }
        
        var characteristics: [String: Any]?
        if !(scopeDetails?.contains(where: { $0.key == "characteristics" }) ?? false) {
            XCTFail(self.missingField("scopeDetails.characteristics"))
            objectIsValid = false
        } else {
            characteristics = scopeDetails?["characteristics"] as? [String: Any]
            if characteristics == nil {
                XCTFail(self.wrongType("scopeDetails.characteristics", expected: "[String: Any]"))
                objectIsValid = false
            }
        }
        
        if !(characteristics?.contains(where: { $0.key == "eventToken" }) ?? false) {
            XCTFail(self.missingField("scopeDetails.characteristics.eventToken"))
            objectIsValid = false
        } else {
            let value = characteristics?["eventToken"] as? String
            if value == nil {
                XCTFail(self.wrongType("scopeDetails.characteristics.eventToken", expected: "String"))
                objectIsValid = false
            }
        }
        
        if !(scopeDetails?.contains(where: { $0.key == "correlationID" }) ?? false) {
            XCTFail(self.missingField("scopeDetails.correlationID"))
            objectIsValid = false
        } else {
            let value = scopeDetails?["correlationID"] as? String
            if value == nil {
                XCTFail(self.wrongType("scopeDetails.correlationID", expected: "String"))
                objectIsValid = false
            }
        }
        
        if !(scopeDetails?.contains(where: { $0.key == "decisionProvider" }) ?? false) {
            XCTFail(self.missingField("scopeDetails.decisionProvider"))
            objectIsValid = false
        } else {
            let value = scopeDetails?["decisionProvider"] as? String
            if value == nil {
                XCTFail(self.wrongType("scopeDetails.decisionProvider", expected: "String"))
                objectIsValid = false
            }
        }
        
        var items: [[String: Any]]?
        if !payload.contains(where: { $0.key == "items" }) {
            XCTFail(self.missingField("items"))
            objectIsValid = false
        } else {
            items = payload["items"] as? [[String: Any]]
            if items == nil {
                XCTFail(self.wrongType("items", expected: "[[String: Any]]"))
                objectIsValid = false
            }
        }
        
        let item = items?.first
        
        if !(item?.contains(where: { $0.key == "id" }) ?? false) {
            XCTFail(self.missingField("items[0].id"))
            objectIsValid = false
        } else {
            let value = item?["id"] as? String
            if value == nil {
                XCTFail(self.wrongType("items[0].id", expected: "String"))
                objectIsValid = false
            }
        }
        
        if !(item?.contains(where: { $0.key == "schema" }) ?? false) {
            XCTFail(self.missingField("items[0].schema"))
            objectIsValid = false
        } else {
            let value = item?["schema"] as? String
            if value == nil {
                XCTFail(self.wrongType("items[0].schema", expected: "String"))
                objectIsValid = false
            }
        }
        
        var itemData: [String: Any]?
        if !(item?.contains(where: { $0.key == "data" }) ?? false) {
            XCTFail(self.missingField("items[0].data"))
            objectIsValid = false
        } else {
            itemData = item?["data"] as? [String: Any]
            if itemData == nil {
                XCTFail(self.wrongType("items[0].data", expected: "[String: Any]"))
                objectIsValid = false
            }
        }
        
        if !(itemData?.contains(where: { $0.key == "content" }) ?? false) {
            XCTFail(self.missingField("items[0].data.content"))
            objectIsValid = false
        } else {
            let value = itemData?["content"] as? String
            if value == nil {
                XCTFail(self.wrongType("items[0].data.content", expected: "String"))
                objectIsValid = false
            }
        }
        
        if !(itemData?.contains(where: { $0.key == "id" }) ?? false) {
            XCTFail(self.missingField("items[0].data.id"))
            objectIsValid = false
        } else {
            let value = itemData?["id"] as? String
            if value == nil {
                XCTFail(self.wrongType("items[0].data.id", expected: "String"))
                objectIsValid = false
            }
        }
        
        return objectIsValid
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
        currentMessage?.track("clicked", withEdgeEventType: .inappInteract)
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
