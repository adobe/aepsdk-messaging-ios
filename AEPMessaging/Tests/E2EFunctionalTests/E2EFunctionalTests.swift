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
// TODO: add in AEPOptimize reference once it has a public release
// import AEPOptimize
import AEPEdge
import AEPEdgeConsent
import AEPEdgeIdentity
@testable import AEPMessaging
@testable import AEPRulesEngine
@testable import AEPServices

import XCTest

class E2EFunctionalTests: XCTestCase {
    let activityIdBeingTested = "xcore:offer-activity:143614fd23c501cf"
    let placementIdBeingTested = "xcore:offer-placement:143f66555f80e367"

    override func setUp() {
        initializeSdk()
    }

    override func tearDown() {}

    // MARK: - helpers

    func initializeSdk() {
        let configDict = ConfigurationLoader.getConfig("functionalTestConfigStage")
        MobileCore.updateConfigurationWith(configDict: configDict)

        let extensions = [
            Optimize.self,
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

    func registerOptimizeRequestContentListener(_ listener: @escaping EventListener) {
        MobileCore.registerEventListener(type: MessagingConstants.Event.EventType.messaging, source: EventSource.requestContent, listener: listener)
    }

    func registerEdgePersonalizationDecisionsListener(_ listener: @escaping EventListener) {
        MobileCore.registerEventListener(type: EventType.edge, source: MessagingConstants.Event.Source.PERSONALIZATION_DECISIONS, listener: listener)
    }

    // MARK: - tests

    func testGetMessageDefinitionFromOptimize() throws {
        // setup
        let messagingRequestContentExpectation = XCTestExpectation(description: "messaging request content listener called")
        registerMessagingRequestContentListener { event in
            XCTAssertNotNil(event)
            let data = event.data
            XCTAssertNotNil(data)
            XCTAssertEqual(true, data?[MessagingConstants.Event.Data.Key.REFRESH_MESSAGES] as? Bool)
            messagingRequestContentExpectation.fulfill()
        }

        let optimizeRequestContentExpectation = XCTestExpectation(description: "optimize request content listener called")
        registerOptimizeRequestContentListener { _ in
            optimizeRequestContentExpectation.fulfill()
        }

        let edgePersonalizationDecisionsExpectation = XCTestExpectation(description: "edge personalization decisions listener called")
        registerEdgePersonalizationDecisionsListener { event in

            guard let data = event.data else { XCTFail(); return }
            guard let payloadArray = data["payload"] as? [[String: Any]] else { XCTFail(); return }
            let payload = payloadArray[0]

            // validate the correct activity/placement
            guard let activityDict = payload["activity"] as? [String: Any] else { XCTFail(); return }
            XCTAssertEqual(self.activityIdBeingTested, activityDict["id"] as? String)
            guard let placementDict = payload["placement"] as? [String: Any] else { XCTFail(); return }
            XCTAssertEqual(self.placementIdBeingTested, placementDict["id"] as? String)

            // validate the items array
            guard let itemsArray = payload["items"] as? [[String: Any]] else { XCTFail(); return }
            let item = itemsArray[0]
            guard let itemData = item["data"] as? [String: Any] else { XCTFail(); return }
            guard let content = itemData["content"] as? String else { XCTFail(); return }

            // validate the content is a valid rule containing a valid message
            let messagingRulesEngine = MessagingRulesEngine(name: "testRulesEngine", extensionRuntime: TestableExtensionRuntime())
            messagingRulesEngine.loadRules(rules: [content])
            // rules load async - brief sleep to allow it to finish
            sleep(1)
            XCTAssertEqual(1, messagingRulesEngine.rulesEngine.rulesEngine.rules.count)

            edgePersonalizationDecisionsExpectation.fulfill()
        }

        // test
        Messaging.refreshInAppMessages()

        // verify
        wait(for: [messagingRequestContentExpectation, optimizeRequestContentExpectation, edgePersonalizationDecisionsExpectation], timeout: 60)
    }
}
