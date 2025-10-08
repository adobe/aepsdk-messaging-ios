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

import Foundation

/// An actor that stores and manages `Task`s associated with Live Activity types in a thread-safe way.
@available(iOS 13.0, *)
actor ActivityTaskStore<Key: Hashable> {
    private struct Entry {
        let id: UUID
        let task: Task<Void, Never>
    }

    private var entries: [Key: Entry] = [:]

    /// Sets or replaces the `Task` for the given key using the provided identifier.
    ///
    /// If an entry already exists for the key, the existing task is cancelled before
    /// the new task is stored. This prevents multiple tasks for the same key from
    /// running concurrently.
    ///
    /// - Parameters:
    ///   - key: The key representing the Live Activity type to associate with the task.
    ///   - id: A unique identifier for the task entry. Used to support identity based removal.
    ///   - task: The `Task` to associate with the key.
    func setEntry(for key: Key, id: UUID, task: Task<Void, Never>) {
        if let existing = entries[key] {
            existing.task.cancel()
        }
        entries[key] = Entry(id: id, task: task)
    }

    /// Retrieves the `Task` associated with the given key.
    ///
    /// - Parameter key: The key identifying the stored task.
    /// - Returns: The associated `Task` if one exists, or `nil` if no task is stored for the key.
    func task(for key: Key) -> Task<Void, Never>? {
        entries[key]?.task
    }

    /// Removes the task entry associated with the given key, unconditionally.
    ///
    /// This does not cancel the task. Callers should cancel the task separately if needed.
    ///
    /// - Parameter key: The key representing the task entry to remove.
    func removeTask(for key: Key) {
        entries[key] = nil
    }

    /// Removes the task entry only if the provided identifier matches the current entry.
    ///
    /// This is useful when tasks remove themselves on completion to avoid a stale task
    /// removing a newer entry that has replaced it.
    ///
    /// This does not cancel the task. Callers should cancel explicitly if needed.
    ///
    /// - Parameters:
    ///   - key: The key representing the task entry.
    ///   - id: The identifier expected to match the current entry for the removal to proceed.
    func removeIfCurrent(for key: Key, id: UUID) {
        guard let current = entries[key], current.id == id else { return }
        entries[key] = nil
    }

    /// Retrieves the identifier for the current task entry associated with the key.
    ///
    /// - Parameter key: The key identifying the stored task entry.
    /// - Returns: The identifier of the current entry, or `nil` if no entry is stored for the key.
    func currentId(for key: Key) -> UUID? {
        entries[key]?.id
    }

    /// Removes all stored task entries without cancelling their tasks.
    func removeAll() {
        entries.removeAll()
    }
}
