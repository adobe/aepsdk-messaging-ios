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
class UnreadIndicatorSettingsTests: XCTestCase {

    typealias IconPlacement = UnreadIndicatorSettings.UnreadIconSettings.IconPlacement

    // MARK: - Helpers

    func decode(_ json: String) throws -> UnreadIndicatorSettings {
        let data = json.data(using: .utf8)!
        return try JSONDecoder().decode(UnreadIndicatorSettings.self, from: data)
    }

    let bgOnlyJSON = """
    {
        "unread_bg": {"clr": {"light": "#FF0000", "dark": "#AA0000"}}
    }
    """

    let iconOnlyJSON = """
    {
        "unread_icon": {
            "placement": "topleft",
            "image": {"url": "https://example.com/dot.png"}
        }
    }
    """

    let fullJSON = """
    {
        "unread_bg": {"clr": {"light": "#FFFFFF", "dark": "#000000"}},
        "unread_icon": {
            "placement": "bottomright",
            "image": {"icon": "circle.fill"}
        }
    }
    """

    // MARK: - UnreadBackgroundSettings

    func testDecodeBackgroundColor() throws {
        let settings = try decode(bgOnlyJSON)
        XCTAssertEqual(settings.unreadBackground?.color.light, "#FF0000")
        XCTAssertEqual(settings.unreadBackground?.color.dark, "#AA0000")
    }

    func testUnreadBackgroundIsNilWhenAbsent() throws {
        let settings = try decode(iconOnlyJSON)
        XCTAssertNil(settings.unreadBackground)
    }

    // MARK: - UnreadIconSettings

    func testUnreadIconIsNilWhenAbsent() throws {
        let settings = try decode(bgOnlyJSON)
        XCTAssertNil(settings.unreadIcon)
    }

    func testDecodeIconWithURLImage() throws {
        let settings = try decode(iconOnlyJSON)
        XCTAssertEqual(settings.unreadIcon?.image.url?.absoluteString, "https://example.com/dot.png")
    }

    func testDecodeIconWithSFSymbol() throws {
        let settings = try decode(fullJSON)
        XCTAssertEqual(settings.unreadIcon?.image.icon, "circle.fill")
    }

    // MARK: - IconPlacement decoding

    func testDecodeTopLeftPlacement() throws {
        let settings = try decode(iconOnlyJSON)
        XCTAssertEqual(settings.unreadIcon?.placement, .topLeft)
    }

    func testDecodeTopRightPlacement() throws {
        let json = """
        {"unread_icon": {"placement": "topright", "image": {"icon": "dot"}}}
        """
        let settings = try decode(json)
        XCTAssertEqual(settings.unreadIcon?.placement, .topRight)
    }

    func testDecodeBottomLeftPlacement() throws {
        let json = """
        {"unread_icon": {"placement": "bottomleft", "image": {"icon": "dot"}}}
        """
        let settings = try decode(json)
        XCTAssertEqual(settings.unreadIcon?.placement, .bottomLeft)
    }

    func testDecodeBottomRightPlacement() throws {
        let settings = try decode(fullJSON)
        XCTAssertEqual(settings.unreadIcon?.placement, .bottomRight)
    }

    func testDecodeUnknownPlacementDefaultsToUnknown() throws {
        let json = """
        {"unread_icon": {"placement": "center", "image": {"icon": "dot"}}}
        """
        let settings = try decode(json)
        XCTAssertEqual(settings.unreadIcon?.placement, .unknown)
    }

    func testDecodeEmptyStringPlacementDefaultsToUnknown() throws {
        let json = """
        {"unread_icon": {"placement": "", "image": {"icon": "dot"}}}
        """
        let settings = try decode(json)
        XCTAssertEqual(settings.unreadIcon?.placement, .unknown)
    }

    // MARK: - IconPlacement raw values

    func testIconPlacementRawValues() {
        XCTAssertEqual(IconPlacement.topLeft.rawValue, "topleft")
        XCTAssertEqual(IconPlacement.topRight.rawValue, "topright")
        XCTAssertEqual(IconPlacement.bottomLeft.rawValue, "bottomleft")
        XCTAssertEqual(IconPlacement.bottomRight.rawValue, "bottomright")
        XCTAssertEqual(IconPlacement.unknown.rawValue, "unknown")
    }

    func testIconPlacementAllCasesCount() {
        XCTAssertEqual(IconPlacement.allCases.count, 5)
    }

    // MARK: - Round-trip encode/decode

    func testRoundTripBackgroundOnly() throws {
        let original = try decode(bgOnlyJSON)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UnreadIndicatorSettings.self, from: data)
        XCTAssertEqual(decoded.unreadBackground?.color.light, original.unreadBackground?.color.light)
        XCTAssertEqual(decoded.unreadBackground?.color.dark, original.unreadBackground?.color.dark)
        XCTAssertNil(decoded.unreadIcon)
    }

    func testRoundTripFull() throws {
        let original = try decode(fullJSON)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UnreadIndicatorSettings.self, from: data)
        XCTAssertEqual(decoded.unreadIcon?.placement, original.unreadIcon?.placement)
        XCTAssertEqual(decoded.unreadIcon?.image.icon, original.unreadIcon?.image.icon)
        XCTAssertEqual(decoded.unreadBackground?.color.light, original.unreadBackground?.color.light)
    }

    // MARK: - Empty JSON decodes without crashing

    func testDecodeEmptyObjectYieldsNilFields() throws {
        let settings = try decode("{}")
        XCTAssertNil(settings.unreadBackground)
        XCTAssertNil(settings.unreadIcon)
    }
}
