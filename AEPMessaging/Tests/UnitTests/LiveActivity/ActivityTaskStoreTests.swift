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

@available(iOS 13.0, *)
final class ActivityTaskStoreTests: XCTestCase {

    /// Creates a never-ending task so the store holds a live, cancellable entry.
    private func makeLongRunningTask() -> Task<Void, Never> {
        Task {
            while !Task.isCancelled {
                await Task.yield()
            }
        }
    }

    func test_cancelAll_cancelsEveryTask_andRemovesEntries() async {
        let store = ActivityTaskStore<String>()

        let taskA = makeLongRunningTask()
        let taskB = makeLongRunningTask()
        await store.setEntry(for: "typeA", id: UUID(), task: taskA)
        await store.setEntry(for: "typeB", id: UUID(), task: taskB)

        // both entries are present before clearing
        let hadTaskA = await store.task(for: "typeA") != nil
        let hadTaskB = await store.task(for: "typeB") != nil
        XCTAssertTrue(hadTaskA)
        XCTAssertTrue(hadTaskB)

        await store.cancelAll()

        // entries are removed
        let taskAfterA = await store.task(for: "typeA")
        let taskAfterB = await store.task(for: "typeB")
        XCTAssertNil(taskAfterA)
        XCTAssertNil(taskAfterB)

        // underlying tasks were cancelled
        XCTAssertTrue(taskA.isCancelled)
        XCTAssertTrue(taskB.isCancelled)
    }

    func test_cancelAll_onEmptyStore_isNoOp() async {
        let store = ActivityTaskStore<String>()
        await store.cancelAll()
        let task = await store.task(for: "typeA")
        XCTAssertNil(task)
    }
}
