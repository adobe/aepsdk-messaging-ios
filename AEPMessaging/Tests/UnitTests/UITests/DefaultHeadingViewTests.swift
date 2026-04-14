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
import SwiftUI
@testable import AEPMessaging

@available(iOS 15.0, *)
class DefaultHeadingViewTests: XCTestCase {

    func makeHeading(_ content: String = "Test Heading") throws -> AEPText {
        let data = "{\"content\":\"\(content)\"}".data(using: .utf8)!
        return try JSONDecoder().decode(AEPText.self, from: data)
    }

    // MARK: - Initialisation

    func testCanBeInstantiatedWithHeading() throws {
        let heading = try makeHeading()
        let view = DefaultHeadingView(heading: heading)
        XCTAssertNotNil(view)
    }

    func testHeadingPropertyMatchesPassedValue() throws {
        let heading = try makeHeading("My Inbox")
        let view = DefaultHeadingView(heading: heading)
        XCTAssertEqual(view.heading.content, "My Inbox")
    }

    func testHeadingIsIdenticalObject() throws {
        let heading = try makeHeading()
        let view = DefaultHeadingView(heading: heading)
        XCTAssertTrue(view.heading === heading)
    }

    // MARK: - Default style constants

    func testHorizontalPaddingConstantIsPositive() {
        XCTAssertGreaterThan(UIConstants.Inbox.DefaultStyle.Heading.HORIZONTAL_PADDING, 0)
    }

    func testVerticalPaddingConstantIsPositive() {
        XCTAssertGreaterThan(UIConstants.Inbox.DefaultStyle.Heading.VERTICAL_PADDING, 0)
    }
}
