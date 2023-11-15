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
@testable import AEPMessaging
@testable import AEPRulesEngine
@testable import AEPServices
import AEPTestUtils
import Foundation
import XCTest

class MessagingRulesEngineCachingTests: XCTestCase {
    let ASYNC_TIMEOUT = 2.0
    var messagingRulesEngine: MessagingRulesEngine!
    var mockRulesEngine: MockLaunchRulesEngine!
    var mockRuntime: TestableExtensionRuntime!
    var mockCache: MockCache!
    let mockIamSurface = "mobileapp://com.apple.dt.xctest.tool"

    struct MockEvaluable: Evaluable {
        public func evaluate(in context: Context) -> Result<Bool, RulesFailure> {
            return Result.success(true)
        }
    }

    override func setUp() {
        mockRuntime = TestableExtensionRuntime()
        mockRulesEngine = MockLaunchRulesEngine(name: "mockRulesEngine", extensionRuntime: mockRuntime)
        mockCache = MockCache(name: "mockCache")
        messagingRulesEngine = MessagingRulesEngine(extensionRuntime: mockRuntime, launchRulesEngine: mockRulesEngine, cache: mockCache)
    }

    func testCacheRemoteAssetsHappy() throws {
        // setup
        let setCalledExpecation = XCTestExpectation(description: "Set should be called in the mock cache")
        mockCache.setCalledExpectation = setCalledExpecation
        let thirtyDaysInSeconds = 60*60*24*30 as TimeInterval
        let thirtyDaysFromToday = Date().addingTimeInterval(thirtyDaysInSeconds)
        let assetString = "https://blog.adobe.com/en/publish/2020/05/28/media_1cc0fcc19cf0e64decbceb3a606707a3ad23f51dd.png"
        let consequence = RuleConsequence(id: "552", type: "cjmiam", details: [
            "remoteAssets": [assetString]
        ])
        let mockEvaluable = MockEvaluable()
        let rule = LaunchRule(condition: mockEvaluable, consequences: [consequence])
        let rules = [rule]

        // test
        messagingRulesEngine.cacheRemoteAssetsFor(rules)

        // verify
        wait(for: [setCalledExpecation], timeout: ASYNC_TIMEOUT)
        XCTAssertTrue(mockCache.setCalled)
        XCTAssertEqual(assetString, mockCache.setParamKey)
        XCTAssertNotNil(mockCache.setParamEntry?.data)
        XCTAssertEqual(.orderedSame, Calendar.current.compare(thirtyDaysFromToday, to: mockCache.setParamEntry!.expiry.date, toGranularity: .hour))
    }

    func testCacheRemoteAssetsMalformedAssetUrl() throws {
        // setup
        let setCalledExpecation = XCTestExpectation(description: "Set should be called in the mock cache")
        setCalledExpecation.isInverted = true
        mockCache.setCalledExpectation = setCalledExpecation
        let assetString = "omgi'mnota valid url"
        let consequence = RuleConsequence(id: "552", type: "cjmiam", details: [
            "remoteAssets": [assetString]
        ])
        let mockEvaluable = MockEvaluable()
        let rule = LaunchRule(condition: mockEvaluable, consequences: [consequence])
        let rules = [rule]

        // test
        messagingRulesEngine.cacheRemoteAssetsFor(rules)

        // verify
        wait(for: [setCalledExpecation], timeout: ASYNC_TIMEOUT)
        XCTAssertFalse(mockCache.setCalled)
    }

    func testCacheRemoteAssetsEmptyRules() throws {
        // setup
        let setCalledExpecation = XCTestExpectation(description: "Set should be called in the mock cache")
        setCalledExpecation.isInverted = true
        mockCache.setCalledExpectation = setCalledExpecation
        let rules: [LaunchRule] = []

        // test
        messagingRulesEngine.cacheRemoteAssetsFor(rules)

        // verify
        wait(for: [setCalledExpecation], timeout: ASYNC_TIMEOUT)
        XCTAssertFalse(mockCache.setCalled)
    }

    func testCacheRemoteAssetsNoRuleConsequences() throws {
        // setup
        let setCalledExpecation = XCTestExpectation(description: "Set should be called in the mock cache")
        setCalledExpecation.isInverted = true
        mockCache.setCalledExpectation = setCalledExpecation
        let mockEvaluable = MockEvaluable()
        let rule = LaunchRule(condition: mockEvaluable, consequences: [])
        let rules = [rule]

        // test
        messagingRulesEngine.cacheRemoteAssetsFor(rules)

        // verify
        wait(for: [setCalledExpecation], timeout: ASYNC_TIMEOUT)
        XCTAssertFalse(mockCache.setCalled)
    }

    func testCacheRemoteAssetsNoAssetsInRuleConsequence() throws {
        // setup
        let setCalledExpecation = XCTestExpectation(description: "Set should be called in the mock cache")
        setCalledExpecation.isInverted = true
        mockCache.setCalledExpectation = setCalledExpecation
        let consequence = RuleConsequence(id: "552", type: "cjmiam", details: [:])
        let mockEvaluable = MockEvaluable()
        let rule = LaunchRule(condition: mockEvaluable, consequences: [consequence])
        let rules = [rule]

        // test
        messagingRulesEngine.cacheRemoteAssetsFor(rules)

        // verify
        wait(for: [setCalledExpecation], timeout: ASYNC_TIMEOUT)
        XCTAssertFalse(mockCache.setCalled)
    }
}
