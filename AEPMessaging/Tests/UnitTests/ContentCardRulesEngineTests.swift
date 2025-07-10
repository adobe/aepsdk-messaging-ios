/*
 Copyright 2024 Adobe. All rights reserved.
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
import AEPTestUtils
@testable import AEPMessaging
import AEPServices

class ContentCardRulesEngineTests: XCTestCase {

    private var runtime: TestableExtensionRuntime!
    private var contentCardRulesEngine: ContentCardRulesEngine!

    /// Default event used by most tests. The event matches the matcher criteria contained in the JSON rules
    /// (generic track / request content with an `action == fullscreen`).
    private var defaultEvent: Event!

    override func setUp() {
        super.setUp()

        runtime = TestableExtensionRuntime()
        contentCardRulesEngine = ContentCardRulesEngine(name: "mockRulesEngine", extensionRuntime: runtime)

        // Build the default event so that it satisfies the rule conditions contained in the test rules JSON.
        defaultEvent = Event(
            name: "event",
            type: EventType.genericTrack,
            source: EventSource.requestContent,
            data: [
                "action": "fullscreen"
            ]
        )
    }

    // MARK: - Helpers

    /// Utility that loads the rules from the bundled JSON file, parses them into `[LaunchRule]` and replaces the
    /// rules in the rules engine under test.
    private func loadRulesAndReplace(from fileName: String) {
        let ruleString = JSONFileLoader.getRulesStringFromFile(fileName)
        XCTAssertFalse(ruleString.isEmpty, "Failed to load \(fileName).json from the test bundle.")

        let ruleData = ruleString.data(using: .utf8) ?? Data()
        let rules = JSONRulesParser.parse(ruleData, runtime: runtime) ?? []
        contentCardRulesEngine.launchRulesEngine.replaceRules(with: rules)
    }

    // MARK: - Tests

    func testEvaluate_withNoConsequencesRules() {
        // setup – rule has no consequences
        loadRulesAndReplace(from: "ruleWithNoConsequence")

        // test
        let propositionItemsBySurface = contentCardRulesEngine.evaluate(event: defaultEvent)

        // verify – should be nil or empty
        XCTAssertTrue(propositionItemsBySurface == nil || propositionItemsBySurface?.isEmpty == true)
    }

    func testEvaluate_withInAppV2Consequence() {
        // setup – JSON contains only in-app v2 consequences (no content cards)
        loadRulesAndReplace(from: "inappPropositionV2Content")

        // test
        let propositionItemsBySurface = contentCardRulesEngine.evaluate(event: defaultEvent)

        // verify – engine should return an empty map when no content-card consequences are found
        XCTAssertNotNil(propositionItemsBySurface)
        XCTAssertTrue(propositionItemsBySurface?.isEmpty == true)
    }

    func testEvaluate_withMultipleFeedItemConsequences() {
        // setup – rules file contains two feed-item consequences for the same surface
        loadRulesAndReplace(from: "feedPropositionContentFeedItemConsequences")

        // test
        let propositionItemsBySurface = contentCardRulesEngine.evaluate(event: defaultEvent)

        // verify
        XCTAssertNotNil(propositionItemsBySurface)
        XCTAssertEqual(1, propositionItemsBySurface?.count)

        let surface = Surface(uri: "mobileapp://com.feeds.testing/feeds/apifeed")
        guard let inboundMessageList = propositionItemsBySurface?[surface] else {
            XCTFail("Expected proposition items for surface \(surface.uri)")
            return
        }

        XCTAssertEqual(2, inboundMessageList.count)
        // Ensure both items are content-card schema
        XCTAssertTrue(inboundMessageList.allSatisfy { $0.schema == .contentCard })
    }

    func testEvaluate_withMissingDataInConsequencesDetail() {
        // setup – rule has consequence missing critical data required to build a PropositionItem
        loadRulesAndReplace(from: "feedPropositionContentMissingData")

        // test
        let propositionItemsBySurface = contentCardRulesEngine.evaluate(event: defaultEvent)

        // verify – should be nil or empty because the consequence cannot be parsed
        XCTAssertTrue(propositionItemsBySurface == nil || propositionItemsBySurface?.isEmpty == true)
    }

    func testEvaluate_withMissingSurfaceInConsequencesDetailMetadata() {
        // setup – rule is missing surface metadata; items cannot be associated with a surface
        loadRulesAndReplace(from: "feedPropositionContentMissingSurfaceMetadata")

        // test
        let propositionItemsBySurface = contentCardRulesEngine.evaluate(event: defaultEvent)

        // verify – should be nil or empty
        XCTAssertTrue(propositionItemsBySurface == nil || propositionItemsBySurface?.isEmpty == true)
    }
}
