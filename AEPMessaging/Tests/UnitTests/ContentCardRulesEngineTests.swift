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

@testable import AEPCore
@testable import AEPRulesEngine
@testable import AEPMessaging
import AEPServices
@testable import AEPTestUtils

// Extension runtime that can generate EventHistoryResult dynamically per request
class DynamicTestableExtensionRuntime: TestableExtensionRuntime {
    /// Optional closure that can generate a result for each `EventHistoryRequest`.
    var eventHistoryResultProvider: ((EventHistoryRequest) -> EventHistoryResult)?

    override func getHistoricalEvents(_ events: [EventHistoryRequest],
                                      enforceOrder: Bool,
                                      handler: @escaping ([EventHistoryResult]) -> Void) {
        // Capture what options were used
        receivedEventHistoryRequests = events
        receivedEnforceOrder = enforceOrder

        // Build results dynamically if a provider is supplied; otherwise fall back to the
        // default behaviour that uses `mockEventHistoryResults` configured by the tests.
        if let provider = eventHistoryResultProvider {
            let results = events.map { provider($0) }
            handler(results)
        } else {
            super.getHistoricalEvents(events, enforceOrder: enforceOrder, handler: handler)
        }
    }
}

class ContentCardRulesEngineTests: XCTestCase {
    // MARK: - Test properties
    var contentCardRulesEngine: ContentCardRulesEngine!
    var mockRuntime: DynamicTestableExtensionRuntime!
    var defaultEvent: Event!

    // MARK: - Setup / Teardown
    override func setUp() {
        super.setUp()
        mockRuntime = DynamicTestableExtensionRuntime()
        contentCardRulesEngine = ContentCardRulesEngine(name: "mockRulesEngine", extensionRuntime: mockRuntime)
        defaultEvent = Event(name: "event",
                             type: EventType.genericTrack,
                             source: EventSource.requestContent,
                             data: ["action": "fullscreen"])
    }

    // MARK: - Helper
    private func replaceRules(fromFile fileName: String) {
        // Attempt to load the JSON rule string from the test bundle. If the file does not
        // exist (will be provided later according to the author), skip the test so that
        // the suite compiles and runs without failures.
        let rulesString = JSONFileLoader.getRulesStringFromFile(fileName)
        guard !rulesString.isEmpty else {
            XCTFail("Rules file \(fileName).json is missing.")
            return
        }
        let rulesData = Data(rulesString.utf8)
        let parsedRules = JSONRulesParser.parse(rulesData, runtime: mockRuntime) ?? []
        contentCardRulesEngine.launchRulesEngine.replaceRules(with: parsedRules)
    }

    // MARK: - Tests
    func testEvaluate_withNoConsequencesRules_returnsNil() {
        replaceRules(fromFile: "ruleWithNoConsequence")

        let result = contentCardRulesEngine.evaluate(event: defaultEvent)
        XCTAssertNil(result)
    }

    func testEvaluate_withInAppV2Consequence_returnsEmptyDictionary() {
        replaceRules(fromFile: "inappPropositionV2Content")

        let result = contentCardRulesEngine.evaluate(event: defaultEvent)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.isEmpty)
    }

    func testEvaluate_withMultipleContentCardConsequences_returnsTwoItems() {
        replaceRules(fromFile: "contentCardPropositionMultipleCardConsequences")

        guard let result = contentCardRulesEngine.evaluate(event: defaultEvent) else {
            XCTFail("Expected non-nil result for multiple content card consequences.")
            return
        }

        XCTAssertEqual(1, result.count)

        let expectedSurface = Surface(uri: "mobileapp://com.feeds.testing/feeds/apifeed")
        guard let inboundMessageList = result[expectedSurface] else {
            XCTFail("Expected content cards for surface: \(expectedSurface.uri)")
            return
        }
        XCTAssertEqual(2, inboundMessageList.count)
    }

    func testEvaluate_withMissingDataInConsequenceDetail_returnsNil() {
        replaceRules(fromFile: "contentCardPropositionContentMissingData")

        let result = contentCardRulesEngine.evaluate(event: defaultEvent)
        XCTAssertNil(result)
    }

    func testEvaluate_withMissingSurfaceMetadata_returnsNil() {
        replaceRules(fromFile: "contentCardPropositionContentMissingSurfaceMetadata")

        let result = contentCardRulesEngine.evaluate(event: defaultEvent)
        XCTAssertNil(result)
    }

    func testEvaluate_withContentCardConsequence_firstTimeQualifyingEvent() {
        // setup – use custom qualifying event (Places entered)
        replaceRules(fromFile: "contentCardPropositionContent")

        // build qualifying event (Places entry)
        let qualifyingEvent = Event(name: "qualifyingEvent",
                                    type: EventType.places,
                                    source: EventSource.requestContent,
                                    data: [
                                        "regionEventType": "entered"
                                    ])

        // test
        guard let propositionItemsBySurface = contentCardRulesEngine.evaluate(event: qualifyingEvent) else {
            XCTFail("Expected proposition items for first-time qualifying event.")
            return
        }

        // verify
        XCTAssertEqual(1, propositionItemsBySurface.count)
        let expectedSurface = Surface(uri: "mobileapp://mockPackageName")
        guard let inboundMessageList = propositionItemsBySurface[expectedSurface] else {
            XCTFail("Expected content cards for surface: \(expectedSurface.uri)")
            return
        }
        XCTAssertEqual(1, inboundMessageList.count)
        XCTAssertEqual(.contentCard, inboundMessageList[0].schema)
    }

    func testEvaluate_withContentCardConsequence_alreadyQualifiedCard() {
        // setup – same rules
        replaceRules(fromFile: "contentCardPropositionContent")

        // Mock historical events to simulate that the user has already qualified for the card
        // The rules engine will request multiple historical checks; return non-zero counts where
        // a previous qualify event is expected and zero for any unqualify/disqualify checks.
        // Hash for disqualify event is 2655746408
        // Hash for unqualify event is 2655746409
        mockRuntime.eventHistoryResultProvider = { req in
            switch req.mask.fnv1a32() {
            case 2655746408, 2479650165:
                return EventHistoryResult(count: 0)
            default:
                return EventHistoryResult(count: 1,
                                          oldest: Date(timeIntervalSince1970: 123),
                                          newest: Date(timeIntervalSince1970: 456))
            }
        }

        // test
        guard let propositionItemsBySurface = contentCardRulesEngine.evaluate(event: defaultEvent) else {
            XCTFail("Expected proposition items for already-qualified scenario.")
            return
        }

        // verify – should still return the content card
        XCTAssertEqual(1, propositionItemsBySurface.count)
        let expectedSurface = Surface(uri: "mobileapp://mockPackageName")
        guard let inboundMessageList = propositionItemsBySurface[expectedSurface] else {
            XCTFail("Expected content cards for surface: \(expectedSurface.uri)")
            return
        }
        XCTAssertEqual(1, inboundMessageList.count)
        XCTAssertEqual(.contentCard, inboundMessageList[0].schema)
    }
}
