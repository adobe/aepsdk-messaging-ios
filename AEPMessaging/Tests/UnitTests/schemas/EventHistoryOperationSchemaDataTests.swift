/*
 Copyright 2025 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import XCTest
@testable import AEPMessaging

class EventHistoryOperationSchemaDataTests: XCTestCase {

    func testInit_setsAllFieldsCorrectly_whenValidJsonProvided() throws {
        let jsonString = """
        {
          "operation": "insert",
          "content": {
            \"iam.eventType\": \"customEvent\",
            \"iam.id\": \"activity123\"
          }
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(EventHistoryOperationSchemaData.self, from: jsonData)
        XCTAssertEqual("insert", decoded.operation)
        XCTAssertEqual("customEvent", decoded.eventType)
        XCTAssertEqual("activity123", decoded.messageId)
        let contentDict = decoded.content.compactMapValues { $0.value }
        XCTAssertEqual(2, contentDict.count)
    }

    func testInit_returnsError_whenOperationMissing() {
        let jsonString = #"{"content":{"iam.id":"123"}}"#
        let data = jsonString.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(EventHistoryOperationSchemaData.self, from: data))
    }

    func testInit_returnsError_whenContentMissing() {
        let jsonString = #"{"operation":"deleteEvent"}"#
        let data = jsonString.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(EventHistoryOperationSchemaData.self, from: data))
    }

    func testEventType_nil_whenContentEmpty() throws {
        let jsonString = #"{"operation":"clearEvents","content":{}}"#
        let data = jsonString.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(EventHistoryOperationSchemaData.self, from: data)
        XCTAssertNil(decoded.eventType)
    }

    func testMessageId_nil_whenContentEmpty() throws {
        let jsonString = #"{"operation":"clearEvents","content":{}}"#
        let data = jsonString.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(EventHistoryOperationSchemaData.self, from: data)
        XCTAssertNil(decoded.messageId)
    }
}
