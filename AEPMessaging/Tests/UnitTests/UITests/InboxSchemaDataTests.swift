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
import AEPTestUtils

@available(iOS 15.0, *)
class InboxSchemaDataTests: XCTestCase {

    // MARK: - Helpers

    let validJSON = """
    {
        "content": {
            "layout": {"orientation": "vertical"},
            "capacity": 5
        }
    }
    """

    let fullJSON = """
    {
        "content": {
            "layout": {"orientation": "horizontal"},
            "capacity": 15,
            "heading": {"content": "Notifications"},
            "isUnreadEnabled": true,
            "unread_indicator": {
                "unread_bg": {"clr": {"light": "#FFFFFF", "dark": "#000000"}}
            }
        }
    }
    """

    func decode(_ json: String) throws -> InboxSchemaData {
        let data = json.data(using: .utf8)!
        return try JSONDecoder().decode(InboxSchemaData.self, from: data)
    }

    // MARK: - Decoding

    func testIsDecodable() throws {
        let schemaData = try decode(validJSON)
        XCTAssertNotNil(schemaData)
    }

    func testContentDecodesLayoutOrientation() throws {
        let schemaData = try decode(validJSON)
        XCTAssertEqual(schemaData.content.layout.orientation, .vertical)
    }

    func testContentDecodesCapacity() throws {
        let schemaData = try decode(validJSON)
        XCTAssertEqual(schemaData.content.capacity, 5)
    }

    func testContentDecodesHeadingWhenPresent() throws {
        let schemaData = try decode(fullJSON)
        XCTAssertEqual(schemaData.content.heading?.content, "Notifications")
    }

    func testContentDecodesIsUnreadEnabled() throws {
        let schemaData = try decode(fullJSON)
        XCTAssertTrue(schemaData.content.isUnreadEnabled)
    }

    func testMissingContentThrows() {
        let json = #"{"layout": {"orientation": "vertical"}}"#
        XCTAssertThrowsError(try decode(json))
    }

    // MARK: - Parent reference

    func testParentIsNilByDefault() throws {
        let schemaData = try decode(validJSON)
        XCTAssertNil(schemaData.parent)
    }

    func testParentCanBeAssigned() throws {
        let schemaData = try decode(validJSON)
        let mockItem = MockPropositionItem(itemId: "test-id", schema: .unknown, itemData: [:])
        schemaData.parent = mockItem
        XCTAssertNotNil(schemaData.parent)
    }

    // MARK: - Track (no crash when parent is nil)

    func testTrackWithNilParentDoesNotCrash() throws {
        let schemaData = try decode(validJSON)
        XCTAssertNil(schemaData.parent)
        // Should log a debug message and return without crashing
        schemaData.track(withEdgeEventType: .display)
        schemaData.track("tap", withEdgeEventType: .interact)
    }

    // MARK: - Encoding round-trip

    func testRoundTripEncoding() throws {
        let original = try decode(validJSON)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(InboxSchemaData.self, from: data)
        XCTAssertEqual(decoded.content.capacity, original.content.capacity)
        XCTAssertEqual(decoded.content.layout.orientation, original.content.layout.orientation)
    }

    func testRoundTripFullEncoding() throws {
        let original = try decode(fullJSON)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(InboxSchemaData.self, from: data)
        XCTAssertEqual(decoded.content.capacity, original.content.capacity)
        XCTAssertEqual(decoded.content.heading?.content, original.content.heading?.content)
        XCTAssertEqual(decoded.content.isUnreadEnabled, original.content.isUnreadEnabled)
    }
}
