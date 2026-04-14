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
class EmptyStateSettingsTests: XCTestCase {

    // MARK: - Helpers

    func decode(_ json: String) throws -> EmptyStateSettings {
        let data = json.data(using: .utf8)!
        return try JSONDecoder().decode(EmptyStateSettings.self, from: data)
    }

    // MARK: - All fields nil

    func testDecodeEmptyObjectYieldsNilFields() throws {
        let settings = try decode("{}")
        XCTAssertNil(settings.message)
        XCTAssertNil(settings.image)
    }

    // MARK: - message

    func testMessageIsNilWhenAbsent() throws {
        let json = #"{"image": {"url": "https://example.com/empty.png"}}"#
        let settings = try decode(json)
        XCTAssertNil(settings.message)
    }

    func testMessageDecodesWhenPresent() throws {
        let json = #"{"message": {"content": "Nothing to show"}}"#
        let settings = try decode(json)
        XCTAssertEqual(settings.message?.content, "Nothing to show")
    }

    // MARK: - image

    func testImageIsNilWhenAbsent() throws {
        let json = #"{"message": {"content": "Empty"}}"#
        let settings = try decode(json)
        XCTAssertNil(settings.image)
    }

    func testImageDecodesURLWhenPresent() throws {
        let json = #"{"image": {"url": "https://example.com/empty.png"}}"#
        let settings = try decode(json)
        XCTAssertEqual(settings.image?.url?.absoluteString, "https://example.com/empty.png")
    }

    func testImageDecodesBundleWhenPresent() throws {
        let json = #"{"image": {"bundle": "empty_state_icon"}}"#
        let settings = try decode(json)
        XCTAssertEqual(settings.image?.bundle, "empty_state_icon")
    }

    func testImageDecodesSFSymbolWhenPresent() throws {
        let json = #"{"image": {"icon": "tray"}}"#
        let settings = try decode(json)
        XCTAssertEqual(settings.image?.icon, "tray")
    }

    // MARK: - both message and image present

    func testBothMessageAndImageDecode() throws {
        let json = """
        {
            "message": {"content": "All caught up!"},
            "image": {"icon": "checkmark.circle"}
        }
        """
        let settings = try decode(json)
        XCTAssertEqual(settings.message?.content, "All caught up!")
        XCTAssertEqual(settings.image?.icon, "checkmark.circle")
    }

    // MARK: - Round-trip

    func testRoundTripWithMessage() throws {
        let json = #"{"message": {"content": "Nothing here"}}"#
        let original = try decode(json)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(EmptyStateSettings.self, from: data)
        XCTAssertEqual(decoded.message?.content, original.message?.content)
    }

    func testRoundTripWithImage() throws {
        let json = #"{"image": {"url": "https://example.com/img.png"}}"#
        let original = try decode(json)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(EmptyStateSettings.self, from: data)
        XCTAssertEqual(decoded.image?.url?.absoluteString, original.image?.url?.absoluteString)
    }
}
