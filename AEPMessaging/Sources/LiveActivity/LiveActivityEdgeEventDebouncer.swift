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

/// A debouncer specifically designed for Live Activity Edge events.
///
/// When multiple Live Activity tokens arrive in quick succession (e.g., when multiple
/// activity types are registered), this class batches them into a single Edge event
/// by waiting for a configurable interval after the last token arrives.
///
/// ## Thread Safety
/// All operations are serialized on the provided dispatch queue, ensuring thread-safe
/// access to internal state.
///
/// ## Usage
/// ```swift
/// let debouncer = LiveActivityEdgeEventDebouncer(interval: 0.2, queue: myQueue)
///
/// // Multiple rapid calls...
/// debouncer.schedule(ecid: "123", event: event1) { ecid, event in
///     // This only executes once, 200ms after the last call
///     sendToEdge(ecid: ecid, event: event)
/// }
/// ```
final class LiveActivityEdgeEventDebouncer {

    // MARK: - Types

    /// Context captured for the debounced action
    struct Context {
        let ecid: String
        let event: Event
    }

    /// The action to execute after the debounce interval
    typealias Action = (_ ecid: String, _ event: Event) -> Void

    // MARK: - Properties

    /// The debounce interval in seconds
    private let interval: TimeInterval

    /// The dispatch queue for serializing all operations
    private let queue: DispatchQueue

    /// The current pending work item
    private var workItem: DispatchWorkItem?

    /// The context (ECID + Event) for the current debounce cycle
    private var context: Context?

    /// Unique identifier for the current debounce cycle
    private var debounceID: UUID?

    // MARK: - Lifecycle

    deinit {
        // Cancel any pending work to allow prompt cleanup
        workItem?.cancel()
    }

    // MARK: - Initialization

    /// Creates a new Live Activity Edge event debouncer.
    ///
    /// - Parameters:
    ///   - interval: The debounce interval in seconds. Default is 0.2 (200ms).
    ///   - queue: The dispatch queue for serializing operations.
    init(interval: TimeInterval = 0.2, queue: DispatchQueue) {
        self.interval = interval
        self.queue = queue
    }

    // MARK: - Public Methods

    /// Schedules a debounced action with the given context.
    ///
    /// If called again before the interval elapses, the previous action is cancelled,
    /// the context is updated, and the timer resets. Only the last action executes.
    ///
    /// - Parameters:
    ///   - ecid: The Experience Cloud ID to use for the Edge event.
    ///   - event: The Event to use as parent for the Edge event.
    ///   - action: The closure to execute after the debounce interval.
    ///             Receives the stored ECID and Event as parameters.
    func schedule(ecid: String, event: Event, action: @escaping Action) {
        queue.async { [weak self] in
            guard let self = self else { return }

            // Cancel any pending work item
            self.workItem?.cancel()

            // Store the context for this debounce cycle
            self.context = Context(ecid: ecid, event: event)

            // Generate a unique ID for this debounce cycle
            let currentID = UUID()
            self.debounceID = currentID

            // Create the debounced work item
            let newWorkItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }

                // Verify this work item is still current
                guard self.debounceID == currentID else {
                    Log.debug(label: MessagingConstants.LOG_TAG,
                              "Skipping stale debounce work item for Live Activity Edge event.")
                    return
                }

                // Retrieve the stored context
                guard let storedContext = self.context else {
                    Log.warning(label: MessagingConstants.LOG_TAG,
                                "Unable to execute debounced Live Activity Edge event: missing context.")
                    return
                }

                // Execute the action with the stored context
                action(storedContext.ecid, storedContext.event)

                // Clear state only if still current
                if self.debounceID == currentID {
                    self.context = nil
                    self.debounceID = nil
                    self.workItem = nil
                }
            }

            self.workItem = newWorkItem

            // Schedule the work item
            self.queue.asyncAfter(deadline: .now() + self.interval, execute: newWorkItem)
        }
    }

    /// Cancels any pending debounced action.
    func cancel() {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.workItem?.cancel()
            self.workItem = nil
            self.context = nil
            self.debounceID = nil
        }
    }
}
