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

@testable import AEPMessaging
import XCTest

@available(iOS 13.0, *)
final class LiveActivityOperationQueueTests: XCTestCase {
    private actor Recorder {
        private(set) var events: [String] = []
        func record(_ event: String) { events.append(event) }
    }

    func test_enqueue_runsOperationsInEnqueueOrder() async {
        let queue = LiveActivityOperationQueue()
        let recorder = Recorder()

        queue.enqueue {
            try? await Task.sleep(nanoseconds: 100_000_000)
            await recorder.record("first")
        }
        queue.enqueue {
            await recorder.record("second")
        }
        let last = queue.enqueue {
            await recorder.record("third")
        }
        await last.value

        let events = await recorder.events
        XCTAssertEqual(["first", "second", "third"], events)
    }

    /// Mirrors clearLiveActivities() followed immediately by registerLiveActivities(): the teardown must
    /// complete before the registration stores its task, so the newly registered task survives.
    func test_teardownThenRegistration_registeredTaskIsNotCancelledByTeardown() async {
        let queue = LiveActivityOperationQueue()
        let store = ActivityTaskStore<String>()
        let staleTask = Task<Void, Never> { try? await Task.sleep(nanoseconds: 10_000_000_000) }
        await store.setEntry(for: "type", id: UUID(), task: staleTask)

        let newTask = Task<Void, Never> { try? await Task.sleep(nanoseconds: 10_000_000_000) }
        let newId = UUID()

        queue.enqueue {
            // Delay so an unordered implementation would let the registration win the race.
            try? await Task.sleep(nanoseconds: 100_000_000)
            await store.cancelAll()
        }
        let registration = queue.enqueue {
            await store.setEntry(for: "type", id: newId, task: newTask)
        }
        await registration.value

        XCTAssertTrue(staleTask.isCancelled)
        XCTAssertFalse(newTask.isCancelled)
        let currentId = await store.currentId(for: "type")
        XCTAssertEqual(newId, currentId)
        newTask.cancel()
    }

    /// Mirrors registerLiveActivities() followed immediately by clearLiveActivities(): the registration must
    /// complete before the teardown runs, so the clear cancels it.
    func test_registrationThenTeardown_registeredTaskIsCancelledByTeardown() async {
        let queue = LiveActivityOperationQueue()
        let store = ActivityTaskStore<String>()
        let newTask = Task<Void, Never> { try? await Task.sleep(nanoseconds: 10_000_000_000) }

        queue.enqueue {
            try? await Task.sleep(nanoseconds: 100_000_000)
            await store.setEntry(for: "type", id: UUID(), task: newTask)
        }
        let teardown = queue.enqueue {
            await store.cancelAll()
        }
        await teardown.value

        XCTAssertTrue(newTask.isCancelled)
        let currentTask = await store.task(for: "type")
        XCTAssertNil(currentTask)
    }
}
