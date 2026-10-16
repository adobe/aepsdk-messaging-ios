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

import AEPServices
import Foundation

/// Runs async Live Activity operations (registration and teardown) strictly in the order they were enqueued.
///
/// Public APIs such as `registerLiveActivities(_:)` and `clearLiveActivities()` are synchronous and hand their
/// work off to unstructured `Task`s, which the Swift runtime may start in any order. Enqueueing is synchronous and
/// each operation awaits the one enqueued before it, so the call order of the public APIs is preserved.
/// For example, a registration requested right after a clear can never have its listener tasks cancelled by that
/// clear's teardown.
@available(iOS 13.0, *)
final class LiveActivityOperationQueue: @unchecked Sendable {
    private let lock = NSLock()
    private var tail: Task<Void, Never>?
    private var nextSequenceNumber = 0

    /// Enqueues `operation` to run after every previously enqueued operation has completed.
    ///
    /// - Parameters:
    ///   - name: A description of the operation, used for logging.
    ///   - operation: The async work to run.
    /// - Returns: The `Task` running the operation.
    @discardableResult
    func enqueue(_ name: String, _ operation: @escaping @Sendable () async -> Void) -> Task<Void, Never> {
        lock.lock()
        defer { lock.unlock() }
        nextSequenceNumber += 1
        let label = "#\(nextSequenceNumber) \(name)"
        let previous = tail
        Log.trace(label: MessagingConstants.LOG_TAG, "Live Activity operation queued: \(label)")
        let task = Task {
            await previous?.value
            Log.trace(label: MessagingConstants.LOG_TAG, "Live Activity operation started: \(label)")
            await operation()
            Log.trace(label: MessagingConstants.LOG_TAG, "Live Activity operation completed: \(label)")
        }
        tail = task
        return task
    }
}
