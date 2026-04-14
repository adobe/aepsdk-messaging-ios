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
class HeadingTests: XCTestCase {

    // MARK: - Helpers

    func decode(_ json: String) throws -> Heading {
        let data = json.data(using: .utf8)!
        return try JSONDecoder().decode(Heading.self, from: data)
    }

    // MARK: - Decoding

    func testIsDecodable() throws {
        let heading = try decode(#"{"text": {"content": "My Inbox"}}"#)
        XCTAssertNotNil(heading)
    }

    func testTextContentDecodes() throws {
        let heading = try decode(#"{"text": {"content": "Notifications"}}"#)
        XCTAssertEqual(heading.text.content, "Notifications")
    }

    func testMissingTextThrows() {
        XCTAssertThrowsError(try decode("{}"))
    }

    func testMissingContentInTextThrows() {
        XCTAssertThrowsError(try decode(#"{"text": {}}"#))
    }

    // MARK: - Round-trip

    func testRoundTrip() throws {
        let original = try decode(#"{"text": {"content": "Hello"}}"#)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Heading.self, from: data)
        XCTAssertEqual(decoded.text.content, original.text.content)
    }
}
