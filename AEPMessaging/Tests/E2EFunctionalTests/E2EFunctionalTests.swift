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

import XCTest

class E2EFunctionalTests: XCTestCase {
    
    // testing variables
    var onShowExpectation: XCTestExpectation?
    var onDismissExpectation: XCTestExpectation?

    override func setUp() {
        initializeSdk()
    }

    override func tearDown() {
        onShowExpectation = nil
        onDismissExpectation = nil
    }

    // MARK: - helpers

    func initializeSdk() {
        MobileCore.setLogLevel(.trace)
        // ** staging environment **
        // sb_stage on "CJM Stage" (AJO Web sandbox)
        // App Surface - sb_app_configuration
        // com.adobe.MessagingDemoApp
        // staging/1b50a869c4a2/bcd1a623883f/launch-e44d085fc760-development
        let configDict = ConfigurationLoader.getConfig("functionalTestConfigStage")
        MobileCore.updateConfigurationWith(configDict: configDict)

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

    // MARK: - tests
    
    func testRefreshInAppMessagesHappy() throws {
        // setup
        let messagingRequestContentExpectation = XCTestExpectation(description: "messaging request content listener called")
        registerMessagingRequestContentListener() { event in
            XCTAssertNotNil(event)
            let data = event.data
            XCTAssertNotNil(data)
            XCTAssertEqual(true, data?[MessagingConstants.Event.Data.Key.REFRESH_MESSAGES] as? Bool)
            messagingRequestContentExpectation.fulfill()
        }
        
        // test
        Messaging.refreshInAppMessages()
        
        // verify
        wait(for: [messagingRequestContentExpectation], timeout: 2)
    }

    func testMessagesReturnedFromXAS() throws {
        // setup
        let edgePersonalizationDecisionsExpectation = XCTestExpectation(description: "edge personalization decisions listener called")
        registerEdgePersonalizationDecisionsListener() { event in
            XCTAssertNotNil(event)
            
            // validate the payload exists
            guard let payload = event.data?["payload"] as? [[String: Any]] else {
                XCTFail("expected a payload in the response but none was found")
                return
            }
            
            // validate the payload is not empty
            guard let payloadObject = payload.first else {
                XCTFail("expected a payload object, but payload is empty")
                return
            }
            
            // validate required fields are in first payload item and their types are correct
            let objectId = payloadObject["id"] as? String
            XCTAssertNotNil(objectId, "required field 'id' is missing or not the correct type 'String'")
            XCTAssertNotNil(payloadObject["scope"])
            
//            // validate the content is a valid rule containing a valid message
//            let messagingRulesEngine = MessagingRulesEngine(name: "testRulesEngine", extensionRuntime: TestableExtensionRuntime())
//            messagingRulesEngine.loadRules(rules: [content])

            // rules load async - brief sleep to allow it to finish
//            self.runAfter(seconds: 3) {
//                XCTAssertEqual(1, messagingRulesEngine.rulesEngine.rulesEngine.rules.count, "Message definition successfully loaded into the rules engine.")
//                edgePersonalizationDecisionsExpectation.fulfill()
//            }
            
            edgePersonalizationDecisionsExpectation.fulfill()
        }

        // test
        Messaging.refreshInAppMessages()

        // verify
        wait(for: [edgePersonalizationDecisionsExpectation], timeout: 10)

        // MARK: - trigger the loaded message

        //        // setup
        //        MobileCore.messagingDelegate = self
        //        onShowExpectation = XCTestExpectation(description: "Message was shown")
        //        onDismissExpectation = XCTestExpectation(description: "Message was dismissed")
        //
        //        // test
        //        MobileCore.track(action: nil, data: ["seahawks": "bad"])
        //
        //        // verify
        //        wait(for: [onShowExpectation!, onDismissExpectation!], timeout: 5, enforceOrder: true)
    }

    /// wait for `seconds` before running the code in the closure
    func runAfter(seconds: Int, closure: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(seconds), execute: closure)
    }
}

extension E2EFunctionalTests: MessagingDelegate {
    func onShow(message: Showable) {
        onShowExpectation?.fulfill()
        guard let message = message as? FullscreenMessage else {
            return
        }
        runAfter(seconds: 1) {
            message.dismiss()
        }
    }

    func onDismiss(message: Showable) {
        onDismissExpectation?.fulfill()
    }

    func shouldShowMessage(message: Showable) -> Bool {
        return true
    }
}
