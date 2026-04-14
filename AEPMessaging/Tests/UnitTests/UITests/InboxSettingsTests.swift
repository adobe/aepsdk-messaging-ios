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

@available(iOS 15.0, *)
class InboxSettingsTests: XCTestCase {

    // MARK: - Helpers

    func decode(_ json: String) throws -> InboxSettings {
        let data = json.data(using: .utf8)!
        return try JSONDecoder().decode(InboxSettings.self, from: data)
    }

    let minimalJSON = """
    {
        "layout": {"orientation": "vertical"},
        "capacity": 10
    }
    """

    let fullJSON = """
    {
        "layout": {"orientation": "horizontal"},
        "capacity": 20,
        "heading": {"content": "My Inbox"},
        "emptyStateSettings": {
            "message": {"content": "Nothing here yet"}
        },
        "unread_indicator": {
            "unread_bg": {"clr": {"light": "#FF0000", "dark": "#AA0000"}},
            "unread_icon": {
                "placement": "topright",
                "image": {"url": "https://example.com/icon.png"}
            }
        },
        "isUnreadEnabled": true
    }
    """

    // MARK: - Required fields

    func testDecodeMinimalRequiredFields() throws {
        let settings = try decode(minimalJSON)
        XCTAssertEqual(settings.capacity, 10)
        XCTAssertEqual(settings.layout.orientation, .vertical)
    }

    func testDecodeMissingLayoutThrows() {
        let json = #"{"capacity": 5}"#
        XCTAssertThrowsError(try decode(json))
    }

    func testDecodeMissingCapacityThrows() {
        let json = #"{"layout": {"orientation": "vertical"}}"#
        XCTAssertThrowsError(try decode(json))
    }

    // MARK: - Optional heading

    func testHeadingIsNilWhenAbsent() throws {
        let settings = try decode(minimalJSON)
        XCTAssertNil(settings.heading)
    }

    func testHeadingDecodesWhenPresent() throws {
        let settings = try decode(fullJSON)
        XCTAssertEqual(settings.heading?.content, "My Inbox")
    }

    // MARK: - isUnreadEnabled

    func testIsUnreadEnabledDefaultsFalse() throws {
        let settings = try decode(minimalJSON)
        XCTAssertFalse(settings.isUnreadEnabled)
    }

    func testIsUnreadEnabledDecodesTrue() throws {
        let settings = try decode(fullJSON)
        XCTAssertTrue(settings.isUnreadEnabled)
    }

    // MARK: - emptyStateSettings

    func testEmptyStateSettingsIsNilWhenAbsent() throws {
        let settings = try decode(minimalJSON)
        XCTAssertNil(settings.emptyStateSettings)
    }

    func testEmptyStateSettingsMessageDecodesWhenPresent() throws {
        let settings = try decode(fullJSON)
        XCTAssertEqual(settings.emptyStateSettings?.message?.content, "Nothing here yet")
    }

    // MARK: - unreadIndicator

    func testUnreadIndicatorIsNilWhenAbsent() throws {
        let settings = try decode(minimalJSON)
        XCTAssertNil(settings.unreadIndicator)
    }

    func testUnreadIndicatorBackgroundColorDecodesWhenPresent() throws {
        let settings = try decode(fullJSON)
        XCTAssertEqual(settings.unreadIndicator?.unreadBackground?.color.light, "#FF0000")
        XCTAssertEqual(settings.unreadIndicator?.unreadBackground?.color.dark, "#AA0000")
    }

    func testUnreadIndicatorIconPlacementDecodesWhenPresent() throws {
        let settings = try decode(fullJSON)
        XCTAssertEqual(settings.unreadIndicator?.unreadIcon?.placement, .topRight)
    }

    func testUnreadIndicatorIconURLDecodesWhenPresent() throws {
        let settings = try decode(fullJSON)
        XCTAssertEqual(settings.unreadIndicator?.unreadIcon?.image.url?.absoluteString, "https://example.com/icon.png")
    }

    // MARK: - layout orientation

    func testLayoutOrientationHorizontalDecodes() throws {
        let settings = try decode(fullJSON)
        XCTAssertEqual(settings.layout.orientation, .horizontal)
    }

    // MARK: - capacity

    func testCapacityDecodes() throws {
        let settings = try decode(fullJSON)
        XCTAssertEqual(settings.capacity, 20)
    }

    // MARK: - Round-trip encode/decode

    func testRoundTripMinimal() throws {
        let original = try decode(minimalJSON)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(InboxSettings.self, from: data)
        XCTAssertEqual(decoded.capacity, original.capacity)
        XCTAssertEqual(decoded.layout.orientation, original.layout.orientation)
        XCTAssertFalse(decoded.isUnreadEnabled)
    }

    func testRoundTripFull() throws {
        let original = try decode(fullJSON)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(InboxSettings.self, from: data)
        XCTAssertEqual(decoded.capacity, original.capacity)
        XCTAssertEqual(decoded.layout.orientation, original.layout.orientation)
        XCTAssertTrue(decoded.isUnreadEnabled)
        XCTAssertEqual(decoded.heading?.content, original.heading?.content)
        XCTAssertEqual(decoded.unreadIndicator?.unreadBackground?.color.light, original.unreadIndicator?.unreadBackground?.color.light)
    }
}
