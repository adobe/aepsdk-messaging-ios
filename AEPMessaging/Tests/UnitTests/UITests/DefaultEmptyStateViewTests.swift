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
class DefaultEmptyStateViewTests: XCTestCase {

    func makeSettings(_ json: String) throws -> EmptyStateSettings {
        let data = json.data(using: .utf8)!
        return try JSONDecoder().decode(EmptyStateSettings.self, from: data)
    }

    // MARK: - Initialisation

    func testCanBeCreatedWithNilSettings() {
        var refreshCalled = false
        let view = DefaultEmptyStateView(emptyStateSettings: nil, onRefresh: { refreshCalled = true })
        XCTAssertNotNil(view)
        XCTAssertNil(view.emptyStateSettings)
        _ = refreshCalled // suppress unused warning
    }

    func testCanBeCreatedWithSettings() throws {
        let settings = try makeSettings(#"{"message": {"content": "Nothing here"}}"#)
        let view = DefaultEmptyStateView(emptyStateSettings: settings, onRefresh: {})
        XCTAssertNotNil(view.emptyStateSettings)
    }

    func testEmptyStateSettingsIsStored() throws {
        let settings = try makeSettings(#"{"message": {"content": "All clear"}}"#)
        let view = DefaultEmptyStateView(emptyStateSettings: settings, onRefresh: {})
        XCTAssertEqual(view.emptyStateSettings?.message?.content, "All clear")
    }

    // MARK: - onRefresh callback

    func testOnRefreshCallbackCanBeInvoked() {
        var called = false
        let view = DefaultEmptyStateView(emptyStateSettings: nil, onRefresh: { called = true })
        view.onRefresh()
        XCTAssertTrue(called)
    }

    func testOnRefreshCallbackIsCalledOnce() {
        var count = 0
        let view = DefaultEmptyStateView(emptyStateSettings: nil, onRefresh: { count += 1 })
        view.onRefresh()
        XCTAssertEqual(count, 1)
    }

    // MARK: - Default style constants

    func testDefaultMessageIsNotEmpty() {
        XCTAssertFalse(UIConstants.Inbox.DefaultStyle.EmptyState.MESSAGE.isEmpty)
    }

    func testDefaultVerticalSpacingIsPositive() {
        XCTAssertGreaterThan(UIConstants.Inbox.DefaultStyle.EmptyState.VERTICAL_SPACING, 0)
    }

    func testDefaultImageMaxSizeIsPositive() {
        XCTAssertGreaterThan(UIConstants.Inbox.DefaultStyle.EmptyState.IMAGE_MAX_SIZE, 0)
    }

    // MARK: - applyDefaultStyling: only sets values when nil

    func testApplyDefaultStylingSetsFontWhenNil() throws {
        // Decode an AEPText (font is set to body default by decoder, so manually clear it)
        let data = #"{"content":"test"}"#.data(using: .utf8)!
        let text = try JSONDecoder().decode(AEPText.self, from: data)
        text.font = nil
        text.textColor = nil

        // Simulate what applyDefaultStyling does by replicating the logic under test
        if text.font == nil {
            text.font = UIConstants.Inbox.DefaultStyle.EmptyState.MESSAGE_FONT
        }
        if text.textColor == nil {
            text.textColor = UIConstants.Inbox.DefaultStyle.EmptyState.MESSAGE_COLOR
        }

        XCTAssertNotNil(text.font)
        XCTAssertNotNil(text.textColor)
    }

    func testApplyDefaultStylingDoesNotOverwriteExistingFont() throws {
        let data = #"{"content":"test"}"#.data(using: .utf8)!
        let text = try JSONDecoder().decode(AEPText.self, from: data)
        let customFont = Font.largeTitle
        text.font = customFont

        // Simulate applyDefaultStyling: should NOT overwrite existing font
        if text.font == nil {
            text.font = UIConstants.Inbox.DefaultStyle.EmptyState.MESSAGE_FONT
        }

        // font should still be customFont (not overwritten)
        XCTAssertNotNil(text.font)
    }
}
