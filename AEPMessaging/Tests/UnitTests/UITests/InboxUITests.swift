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
import Combine
import SwiftUI
@testable import AEPMessaging
@testable import AEPCore

@available(iOS 15.0, *)
class InboxUITests: XCTestCase {

    var inbox: InboxUI!
    let testSurface = Surface(uri: "mobileapp://test.app/inbox")
    var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        EventHub.shared.start()
        inbox = InboxUI(surface: testSurface)
    }

    override func tearDown() {
        cancellables.removeAll()
        inbox = nil
        super.tearDown()
    }

    // MARK: - Helpers

    func makeContentCard() -> ContentCardUI? {
        let proposition = ContentCardTestUtil.createProposition(fromFile: "SmallImageTemplate")
        return ContentCardUI.createInstance(with: proposition, customizer: nil, listener: nil)
    }

    // MARK: - Initialisation

    func testIdIsUUID() {
        XCTAssertNotNil(inbox.id)
    }

    func testSurfaceIsStored() {
        XCTAssertEqual(inbox.surface.uri, testSurface.uri)
    }

    func testInitialStateIsLoading() {
        if case .loading = inbox.state {
            // passes
        } else {
            XCTFail("Expected initial state to be .loading, got \(inbox.state)")
        }
    }

    func testInitialContentCardsIsEmpty() {
        XCTAssertTrue(inbox.contentCards.isEmpty)
    }

    func testInitialInboxSchemaDataIsNil() {
        XCTAssertNil(inbox.inboxSchemaData)
    }

    func testListenerIsNilByDefault() {
        XCTAssertNil(inbox.listener)
    }

    func testListenerCanBeAssigned() {
        let listener = MockInboxEventListener()
        inbox.listener = listener
        XCTAssertTrue(inbox.listener is MockInboxEventListener)
    }

    // MARK: - Default property values

    func testIsPullToRefreshEnabledDefaultsFalse() {
        XCTAssertFalse(inbox.isPullToRefreshEnabled)
    }

    func testCardSpacingDefaultIs16() {
        XCTAssertEqual(inbox.cardSpacing, 16)
    }

    func testUnreadIconSizeDefaultIs16() {
        XCTAssertEqual(inbox.unreadIconSize, 16)
    }

    func testContentPaddingDefaults() {
        XCTAssertEqual(inbox.contentPadding.top, 12)
        XCTAssertEqual(inbox.contentPadding.leading, 16)
        XCTAssertEqual(inbox.contentPadding.bottom, 12)
        XCTAssertEqual(inbox.contentPadding.trailing, 16)
    }

    // MARK: - Custom view builders

    func testSetLoadingViewStoresBuilder() {
        XCTAssertNil(inbox.customLoadingView)
        inbox.setLoadingView { AnyView(Text("Loading...")) }
        XCTAssertNotNil(inbox.customLoadingView)
    }

    func testSetLoadingViewBuilderCanBeInvoked() {
        inbox.setLoadingView { AnyView(Text("Loading")) }
        let view = inbox.customLoadingView?()
        XCTAssertNotNil(view)
    }

    func testSetErrorViewStoresBuilder() {
        XCTAssertNil(inbox.customErrorView)
        inbox.setErrorView { _ in AnyView(Text("Error")) }
        XCTAssertNotNil(inbox.customErrorView)
    }

    func testSetErrorViewBuilderCanBeInvoked() {
        inbox.setErrorView { error in AnyView(Text(error.localizedDescription)) }
        let view = inbox.customErrorView?(InboxError.dataUnavailable)
        XCTAssertNotNil(view)
    }

    func testSetEmptyViewStoresBuilder() {
        XCTAssertNil(inbox.customEmptyView)
        inbox.setEmptyView { _ in AnyView(Text("Empty")) }
        XCTAssertNotNil(inbox.customEmptyView)
    }

    func testSetEmptyViewBuilderCanBeInvoked() {
        inbox.setEmptyView { _ in AnyView(Text("Empty")) }
        let view = inbox.customEmptyView?(nil)
        XCTAssertNotNil(view)
    }

    func testSetHeadingViewStoresBuilder() {
        XCTAssertNil(inbox.customHeadingView)
        inbox.setHeadingView { _ in AnyView(Text("Heading")) }
        XCTAssertNotNil(inbox.customHeadingView)
    }

    func testSetHeadingViewBuilderCanBeInvoked() throws {
        inbox.setHeadingView { heading in AnyView(Text(heading.content)) }
        let data = #"{"content":"My Inbox"}"#.data(using: .utf8)!
        let heading = try JSONDecoder().decode(AEPText.self, from: data)
        let view = inbox.customHeadingView?(heading)
        XCTAssertNotNil(view)
    }

    func testSetBackgroundStoresView() {
        inbox.setBackground(Color.red)
        // background is internal var AnyView — verify no crash and the setter runs
        XCTAssertNotNil(inbox.background)
    }

    // MARK: - ContentCardUIEventListening — delegation to listener

    func testOnCreateCallsListenerOnCardCreated() {
        guard let card = makeContentCard() else {
            XCTFail("Could not create ContentCardUI")
            return
        }
        let listener = MockInboxEventListener()
        inbox.listener = listener
        inbox.onCreate(card)
        XCTAssertEqual(listener.onCardCreatedCallCount, 1)
    }

    func testOnDisplayCallsListenerOnCardDisplayed() {
        guard let card = makeContentCard() else {
            XCTFail("Could not create ContentCardUI")
            return
        }
        let listener = MockInboxEventListener()
        inbox.listener = listener
        inbox.onDisplay(card)
        XCTAssertEqual(listener.onCardDisplayedCallCount, 1)
    }

    func testOnDismissCallsListenerOnCardDismissed() {
        guard let card = makeContentCard() else {
            XCTFail("Could not create ContentCardUI")
            return
        }
        let listener = MockInboxEventListener()
        inbox.listener = listener
        inbox.onDismiss(card)
        XCTAssertEqual(listener.onCardDismissedCallCount, 1)
    }

    func testOnDismissUpdatesStateToLoaded() {
        guard let card = makeContentCard() else {
            XCTFail("Could not create ContentCardUI")
            return
        }
        inbox.onDismiss(card)
        if case .loaded(let cards) = inbox.state {
            XCTAssertTrue(cards.isEmpty)
        } else {
            XCTFail("Expected state .loaded after dismiss")
        }
    }

    func testOnInteractReturnsFalseWithNoListener() {
        guard let card = makeContentCard() else {
            XCTFail("Could not create ContentCardUI")
            return
        }
        let result = inbox.onInteract(card, "tap", actionURL: nil)
        XCTAssertFalse(result)
    }

    func testOnInteractCallsListenerAndReturnsValue() {
        guard let card = makeContentCard() else {
            XCTFail("Could not create ContentCardUI")
            return
        }
        let listener = MockInboxEventListener()
        listener.interactedReturnValue = true
        inbox.listener = listener
        let result = inbox.onInteract(card, "tap", actionURL: nil)
        XCTAssertTrue(result)
        XCTAssertEqual(listener.onCardInteractedCallCount, 1)
    }

    func testOnInteractPassesInteractionIdToListener() {
        guard let card = makeContentCard() else {
            XCTFail("Could not create ContentCardUI")
            return
        }
        let listener = MockInboxEventListener()
        inbox.listener = listener
        _ = inbox.onInteract(card, "button-cta", actionURL: nil)
        XCTAssertEqual(listener.lastInteractionId, "button-cta")
    }

    func testOnInteractPassesActionURLToListener() {
        guard let card = makeContentCard() else {
            XCTFail("Could not create ContentCardUI")
            return
        }
        let listener = MockInboxEventListener()
        inbox.listener = listener
        let url = URL(string: "https://adobe.com")!
        _ = inbox.onInteract(card, "tap", actionURL: url)
        XCTAssertEqual(listener.lastActionURL, url)
    }

    // MARK: - view property

    func testViewPropertyDoesNotCrash() {
        let view = inbox.view
        XCTAssertNotNil(view)
    }
}
