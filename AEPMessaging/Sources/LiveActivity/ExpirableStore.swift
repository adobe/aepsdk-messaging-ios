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

final class ExpirableStore<Map: LiveActivity.DictionaryBacked>: PersistenceStoreBase<Map> {
    typealias Element = Map.Element
    typealias Equivalence = (_ old: Element, _ new: Element) -> Bool

    private let ttl: TimeInterval
    private let customEquivalence: Equivalence?

    init(storeKey: String, ttl: TimeInterval, customEquivalence: Equivalence? = nil) {
        self.ttl = ttl
        self.customEquivalence = customEquivalence
        super.init(storeKey: storeKey)
        removeExpiredEntries()
    }

    override func all() -> Map {
        removeExpiredEntries()
        return _persistedMap
    }

    func value(for id: LiveActivity.ID) -> Element? {
        guard let element = _persistedMap.storage[id] else {
            return nil
        }

        guard !isExpired(element) else {
            // Remove expired value from the store
            _persistedMap.storage.removeValue(forKey: id)
            return nil
        }

        return element
    }

    @discardableResult
    func set(_ element: Element, id: LiveActivity.ID) -> Bool {
        guard !isExpired(element) else {
            return false
        }

        var workingMap = _persistedMap
        let previous = workingMap.storage.updateValue(element, forKey: id)
        let changed: Bool

        // If there is a previously stored value, and a custom equivalence closure was provided, apply it
        // to determine if it should be written
        if let previous = previous, let customEquivalence = customEquivalence {
            changed = customEquivalence(previous, element)
        } else {
            // Otherwise, if custom equivalence is not provided, the default is to always overwrite
            // Or if there was no previous entry regardless of custom equivalence
            changed = previous == nil || customEquivalence == nil
        }

        if changed {
            _persistedMap = workingMap
        }

        return changed
    }

    @discardableResult
    func remove(id: LiveActivity.ID) -> Bool {
        var working = _persistedMap
        guard working.storage.removeValue(forKey: id) != nil else {
            return false
        }
        _persistedMap = working
        return true
    }

    // MARK: - Private helpers

    private func isExpired(_ element: Element, now: Date = Date()) -> Bool {
        now.timeIntervalSince(element.referenceDate) > ttl
    }

    private func removeExpiredEntries() {
        let now = Date()
        let filtered = _persistedMap.storage.filter { _, element in
            !isExpired(element, now: now)
        }
        if filtered.count != _persistedMap.storage.count {
            _persistedMap.storage = filtered
        }
    }
}
