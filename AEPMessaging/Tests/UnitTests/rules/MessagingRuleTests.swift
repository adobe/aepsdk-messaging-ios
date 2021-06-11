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

import Foundation
import XCTest

@testable import AEPMessaging
@testable @_implementationOnly import AEPRulesEngine

class MessagingRuleTests: XCTestCase {

    let testConsequence1 = MessagingConsequence(id: "1", type: "1", details: ["1": 1])
    let testConsequence2 = MessagingConsequence(id: "2", type: "2", details: ["2": 2])
    let testCondition = MockEvaluable()
    let mockContext = Context(data: MockTraversable(), evaluator: MockEvaluating(), transformer: MockTransforming())
    class MockEvaluable: Evaluable {
        func evaluate(in context: Context) -> Result<Bool, RulesFailure> {
            return Result.success(true)
        }
    }

    class MockTraversable: Traversable {
        func get(key: String) -> Any? {
            return nil
        }
    }

    class MockEvaluating: Evaluating {
        func evaluate<A>(operation: String, lhs: A) -> Result<Bool, RulesFailure> {
            return Result.success(true)
        }
        func evaluate<A, B>(operation: String, lhs: A, rhs: B) -> Result<Bool, RulesFailure> {
            return Result.success(true)
        }
    }

    class MockTransforming: Transforming {
        func transform(name: String, parameter: Any) -> Any {
            return parameter
        }
    }

    func testConstructor() {
        // setup
        let rule = MessagingRule(condition: testCondition, consequences: [testConsequence1, testConsequence2])

        // verify
        let r1 = testCondition.evaluate(in: mockContext)
        let r2 = rule.condition.evaluate(in: mockContext)
        XCTAssertEqual(r1.value, r2.value)
        let ruleConsequence1 = rule.consequences[0]
        XCTAssertEqual(testConsequence1.id, ruleConsequence1.id)
        XCTAssertEqual(testConsequence1.type, ruleConsequence1.type)
        XCTAssertEqual(testConsequence1.details["1"] as? Int, ruleConsequence1.details["1"] as? Int)
        let ruleConsequence2 = rule.consequences[1]
        XCTAssertEqual(testConsequence2.id, ruleConsequence2.id)
        XCTAssertEqual(testConsequence2.type, ruleConsequence2.type)
        XCTAssertEqual(testConsequence2.details["2"] as? Int, ruleConsequence2.details["2"] as? Int)
    }
}
