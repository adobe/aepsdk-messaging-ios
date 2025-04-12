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

/// An actor that stores and manages `Task`s associated with Live Activity types in a thread-safe way.
@available(iOS 13.0, *)
public actor ActivityTaskStore<Key: Hashable> {
    private var tasks: [Key: Task<Void, Never>] = [:]

    /// Sets or replaces the `Task` for the given key.
    ///
    /// If `task` is `nil`, any existing task for the key will be removed.
    ///
    /// - Parameters:
    ///   - key: A `Hashable` key representing the Live Activity type or instance.
    ///   - task: The `Task` to associate with the key, or `nil` to remove the task.
    func setTask(for key: Key, task: Task<Void, Never>?) {
        tasks[key] = task
    }

    /// Retrieves the `Task` associated with the given key.
    ///
    /// - Parameter key: The key identifying the task.
    /// - Returns: The associated `Task` if one exists, or `nil` if not found.
    func task(for key: Key) -> Task<Void, Never>? {
        tasks[key]
    }

    /// Removes the `Task` associated with the given key.
    ///
    /// - Parameter key: The key representing the task to be removed.
    func removeTask(for key: Key) {
        tasks[key] = nil
    }

    /// Removes all stored `Task`s.
    func removeAll() {
        tasks.removeAll()
    }
}
