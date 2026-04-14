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

class LayoutSettingsTests: XCTestCase {

    // MARK: - Helpers

    func decode(_ json: String) throws -> LayoutSettings {
        let data = json.data(using: .utf8)!
        return try JSONDecoder().decode(LayoutSettings.self, from: data)
    }

    func encode(_ settings: LayoutSettings) throws -> [String: String] {
        let data = try JSONEncoder().encode(settings)
        return try JSONDecoder().decode([String: String].self, from: data)
    }

    // MARK: - InboxOrientation decoding

    func testDecodeVerticalOrientation() throws {
        let settings = try decode(#"{"orientation":"vertical"}"#)
        XCTAssertEqual(settings.orientation, .vertical)
    }

    func testDecodeHorizontalOrientation() throws {
        let settings = try decode(#"{"orientation":"horizontal"}"#)
        XCTAssertEqual(settings.orientation, .horizontal)
    }

    func testDecodeUnknownOrientationDefaultsToVertical() throws {
        let settings = try decode(#"{"orientation":"diagonal"}"#)
        XCTAssertEqual(settings.orientation, .vertical)
    }

    func testDecodeEmptyStringOrientationDefaultsToVertical() throws {
        let settings = try decode(#"{"orientation":""}"#)
        XCTAssertEqual(settings.orientation, .vertical)
    }

    // MARK: - InboxOrientation encoding

    func testEncodeVerticalOrientation() throws {
        let settings = try decode(#"{"orientation":"vertical"}"#)
        let encoded = try encode(settings)
        XCTAssertEqual(encoded["orientation"], "vertical")
    }

    func testEncodeHorizontalOrientation() throws {
        let settings = try decode(#"{"orientation":"horizontal"}"#)
        let encoded = try encode(settings)
        XCTAssertEqual(encoded["orientation"], "horizontal")
    }

    // MARK: - Round-trip

    func testRoundTripVertical() throws {
        let original = try decode(#"{"orientation":"vertical"}"#)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LayoutSettings.self, from: data)
        XCTAssertEqual(decoded.orientation, original.orientation)
    }

    func testRoundTripHorizontal() throws {
        let original = try decode(#"{"orientation":"horizontal"}"#)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LayoutSettings.self, from: data)
        XCTAssertEqual(decoded.orientation, original.orientation)
    }

    // MARK: - InboxOrientation raw values

    func testOrientationRawValues() {
        XCTAssertEqual(LayoutSettings.InboxOrientation.vertical.rawValue, "vertical")
        XCTAssertEqual(LayoutSettings.InboxOrientation.horizontal.rawValue, "horizontal")
    }

    func testOrientationAllCasesCount() {
        XCTAssertEqual(LayoutSettings.InboxOrientation.allCases.count, 2)
    }

    // MARK: - Missing required field

    func testDecodeMissingOrientationThrows() {
        XCTAssertThrowsError(try decode(#"{}"#))
    }
}
