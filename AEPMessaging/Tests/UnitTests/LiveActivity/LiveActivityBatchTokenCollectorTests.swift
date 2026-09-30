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

/// Thread-safe recorder for batches passed to the collector's dispatch handler.
private final class BatchRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var _batches: [[String: String]] = []

    var batches: [[String: String]] {
        lock.lock(); defer { lock.unlock() }
        return _batches
    }

    func record(_ batch: [String: String]) {
        lock.lock(); defer { lock.unlock() }
        _batches.append(batch)
    }
}

/// Covers the batching behavior that registration relies on when it seeds the collector with the
/// current push-to-start token (`Activity<T>.pushToStartToken`) before listening to
/// `pushToStartTokenUpdates`.
final class LiveActivityBatchTokenCollectorTests: XCTestCase {
    private let batchDelayMs = 50
    private let typeA = "TypeA"
    private let typeB = "TypeB"

    private func waitPastBatchWindow() async throws {
        try await Task.sleep(nanoseconds: UInt64(batchDelayMs * 4) * 1_000_000)
    }

    /// Seeded current token + the same token from the update stream within the batch window
    /// results in a single dispatch (no duplicate event).
    func test_sameTypeTwiceWithinWindow_dispatchesOnce() async throws {
        guard #available(iOS 17.2, *) else { throw XCTSkip("Requires iOS 17.2") }
        let recorder = BatchRecorder()
        let collector = LiveActivityBatchTokenCollector(delay: .milliseconds(batchDelayMs)) { recorder.record($0) }

        await collector.collectToken(attributeType: typeA, token: "token1")
        await collector.collectToken(attributeType: typeA, token: "token1")
        try await waitPastBatchWindow()

        XCTAssertEqual(1, recorder.batches.count)
        XCTAssertEqual(["TypeA": "token1"], recorder.batches.first)
    }

    /// If the stream delivers a newer token within the window, the latest token wins.
    func test_sameTypeTwiceWithinWindow_keepsLatestToken() async throws {
        guard #available(iOS 17.2, *) else { throw XCTSkip("Requires iOS 17.2") }
        let recorder = BatchRecorder()
        let collector = LiveActivityBatchTokenCollector(delay: .milliseconds(batchDelayMs)) { recorder.record($0) }

        await collector.collectToken(attributeType: typeA, token: "oldToken")
        await collector.collectToken(attributeType: typeA, token: "newToken")
        try await waitPastBatchWindow()

        XCTAssertEqual(1, recorder.batches.count)
        XCTAssertEqual(["TypeA": "newToken"], recorder.batches.first)
    }

    /// Re-registering multiple types seeds each current token; they are sent in one batch.
    func test_multipleTypesWithinWindow_dispatchedTogether() async throws {
        guard #available(iOS 17.2, *) else { throw XCTSkip("Requires iOS 17.2") }
        let recorder = BatchRecorder()
        let collector = LiveActivityBatchTokenCollector(delay: .milliseconds(batchDelayMs)) { recorder.record($0) }

        await collector.collectToken(attributeType: typeA, token: "tokenA")
        await collector.collectToken(attributeType: typeB, token: "tokenB")
        try await waitPastBatchWindow()

        XCTAssertEqual(1, recorder.batches.count)
        XCTAssertEqual(["TypeA": "tokenA", "TypeB": "tokenB"], recorder.batches.first)
    }

    /// A token arriving after the window starts a new batch (de-duplication then happens in the
    /// Messaging extension's token store).
    func test_tokenAfterWindow_dispatchesNewBatch() async throws {
        guard #available(iOS 17.2, *) else { throw XCTSkip("Requires iOS 17.2") }
        let recorder = BatchRecorder()
        let collector = LiveActivityBatchTokenCollector(delay: .milliseconds(batchDelayMs)) { recorder.record($0) }

        await collector.collectToken(attributeType: typeA, token: "token1")
        try await waitPastBatchWindow()
        await collector.collectToken(attributeType: typeA, token: "token1")
        try await waitPastBatchWindow()

        XCTAssertEqual(2, recorder.batches.count)
    }

    /// clearLiveActivities() cancels the collector; a pending (not yet dispatched) batch is dropped.
    func test_cancel_discardsPendingBatch() async throws {
        guard #available(iOS 17.2, *) else { throw XCTSkip("Requires iOS 17.2") }
        let recorder = BatchRecorder()
        let collector = LiveActivityBatchTokenCollector(delay: .milliseconds(batchDelayMs)) { recorder.record($0) }

        await collector.collectToken(attributeType: typeA, token: "token1")
        await collector.cancel()
        try await waitPastBatchWindow()

        XCTAssertTrue(recorder.batches.isEmpty)
    }

    /// After a cancel (clear), a re-registration seeding the token again is dispatched.
    func test_collectAfterCancel_dispatches() async throws {
        guard #available(iOS 17.2, *) else { throw XCTSkip("Requires iOS 17.2") }
        let recorder = BatchRecorder()
        let collector = LiveActivityBatchTokenCollector(delay: .milliseconds(batchDelayMs)) { recorder.record($0) }

        await collector.collectToken(attributeType: typeA, token: "token1")
        await collector.cancel()
        await collector.collectToken(attributeType: typeA, token: "token1")
        try await waitPastBatchWindow()

        XCTAssertEqual(1, recorder.batches.count)
        XCTAssertEqual(["TypeA": "token1"], recorder.batches.first)
    }
}
