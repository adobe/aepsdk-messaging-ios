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

import AEPCore
import AEPServices
import Foundation

/// An Actor that collects and batches Live Activity push-to-start tokens.
///
/// When multiple Live Activity types are registered in quick succession, their tokens
/// arrive nearly simultaneously. This actor collects them and dispatches a single
/// batched event after a configurable delay, reducing the number of Edge events.
///
/// ## Thread Safety
/// As a Swift Actor, all access is automatically serialized, ensuring thread-safe
/// token collection and dispatch.
///
/// ## Usage
/// ```swift
/// await batchTokenCollector.collectToken(attributeType: "FoodDeliveryAttrs", token: "abc123")
/// // After 200ms delay, all collected tokens are dispatched in a single event
/// ```
@available(iOS 17.2, *)
actor LiveActivityBatchTokenCollector {

    // MARK: - Properties

    /// Accumulated tokens mapped by attribute type
    private var accumulatedTokens: [String: String] = [:]

    /// The current batch task that will dispatch tokens after the delay
    private var batchTask: Task<Void, Never>?

    /// The delay before dispatching collected tokens (default: 200ms)
    private let delay: Duration

    /// The dispatch handler called when tokens are ready to be dispatched
    private let dispatchHandler: @Sendable ([String: String]) -> Void

    // MARK: - Initialization

    /// Creates a new batch token collector.
    ///
    /// - Parameters:
    ///   - delay: The delay before dispatching collected tokens. Default is 200ms.
    ///   - dispatchHandler: The closure called with collected tokens after the delay.
    init(delay: Duration = .milliseconds(200),
         dispatchHandler: @escaping @Sendable ([String: String]) -> Void) {
        self.delay = delay
        self.dispatchHandler = dispatchHandler
    }

    // MARK: - Public Methods

    /// Collects a push-to-start token for batched dispatch.
    ///
    /// If this is the first token in a batch, a timer starts. Additional tokens
    /// arriving before the timer expires are added to the batch. When the timer
    /// fires, all accumulated tokens are dispatched together.
    ///
    /// - Parameters:
    ///   - attributeType: The Live Activity attribute type (e.g., "FoodDeliveryAttrs")
    ///   - token: The push-to-start token string
    func collectToken(attributeType: String, token: String) {
        // Store the token (overwrites if same attributeType arrives again)
        accumulatedTokens[attributeType] = token

        // If no batch task is running, start one
        if batchTask == nil {
            batchTask = Task {
                // Wait for the batch delay
                do {
                    try await Task.sleep(for: delay)
                } catch {
                    // Task was cancelled - exit gracefully without dispatching
                    return
                }

                dispatchAccumulatedTokens()
            }
        }
    }

    /// Cancels any pending batch dispatch and clears accumulated tokens.
    func cancel() {
        batchTask?.cancel()
        batchTask = nil
        accumulatedTokens.removeAll()
    }

    // MARK: - Private Methods

    /// Dispatches all accumulated tokens and resets state.
    private func dispatchAccumulatedTokens() {
        guard !accumulatedTokens.isEmpty else {
            batchTask = nil
            return
        }

        let tokens = accumulatedTokens
        accumulatedTokens.removeAll()
        batchTask = nil

        // Call the dispatch handler with collected tokens
        dispatchHandler(tokens)
    }
}
