/*
 Copyright 2024 Adobe. All rights reserved.
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

/// Manages read status tracking for content cards with multi-surface support.
///
/// This manager maintains two stores:
/// 1. **Read Status Store**: Maps activityId → isRead (Bool)
/// 2. **Registry Store**: Stores surface campaign tracking:
///    - `_surfaces` → Set<surfaceUri> (list of all known surfaces)
///    - `surface:{surfaceUri}` → Set<activityId> (which campaigns each surface displays)
///
/// When cleaning up, we check all known surfaces to determine if a campaign
/// is still in use before deleting its read status.
///
/// ## Example Flow:
/// ```
/// // Surface "inbox" loads Campaign A
/// manager.registerCards([cardA], for: "inbox")
/// // Registry: _surfaces → ["inbox"], surface:inbox → ["A"]
///
/// // Surface "home" also loads Campaign A
/// manager.registerCards([cardA], for: "home")
/// // Registry: _surfaces → ["inbox", "home"], surface:inbox → ["A"], surface:home → ["A"]
///
/// // "inbox" no longer has Campaign A
/// manager.cleanupStaleReadStatus(currentCards: [], surfaceUri: "inbox")
/// // Check all surfaces: home still has A, so keep read status
/// // Registry: _surfaces → ["inbox", "home"], surface:inbox → [], surface:home → ["A"]
///
/// // "home" no longer has Campaign A
/// manager.cleanupStaleReadStatus(currentCards: [], surfaceUri: "home")
/// // Check all surfaces: no surface has A, delete read status
/// // Registry: _surfaces → ["inbox", "home"], surface:inbox → [], surface:home → []
/// ```
@available(iOS 15.0, *)
class ReadStatusManager {
    
    // MARK: - Singleton
    
    /// Shared instance for managing read status across the application
    static let shared = ReadStatusManager()
    
    // MARK: - Private Properties
    
    /// Store for read status tracking (activityId → isRead)
    private let readStatusStore = NamedCollectionDataStore(name: "com.adobe.module.messaging.contentcard.readstatus")
    
    /// Registry store for surface tracking:
    /// - "_surfaces" → Set<surfaceUri> (list of known surfaces)
    /// - "surface:{surfaceUri}" → Set<activityId> (campaigns per surface)
    private let registryStore = NamedCollectionDataStore(name: "com.adobe.module.messaging.contentcard.registry")
    
    // Special key for storing the list of known surfaces
    private let surfacesListKey = "_surfaces"
    
    // Key prefix for surface data
    private let surfacePrefix = "surface:"
    
    // MARK: - Initialization
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    // MARK: - Read Status Operations
    
    /// Retrieves the read status for a given activity ID.
    ///
    /// - Parameter activityId: The activity ID of the campaign
    /// - Returns: The read status (true/false) if found, nil if not tracked or activityId is empty
    func getReadStatus(for activityId: String) -> Bool? {
        guard !activityId.isEmpty else { return nil }
        return readStatusStore.getBool(key: activityId)
    }
    
    /// Sets the read status for a given activity ID.
    ///
    /// - Parameters:
    ///   - isRead: The read status to set (true for read, false for unread)
    ///   - activityId: The activity ID of the campaign
    func setReadStatus(_ isRead: Bool, for activityId: String) {
        guard !activityId.isEmpty else { return }
        readStatusStore[activityId] = isRead
    }
    
    /// Removes the read status for a given activity ID.
    ///
    /// - Parameter activityId: The activity ID of the campaign
    func removeReadStatus(for activityId: String) {
        guard !activityId.isEmpty else { return }
        readStatusStore.remove(key: activityId)
    }
    
    // MARK: - Surface Registry Operations
    
    /// Registers content cards with the surface registry.
    ///
    /// For each card, this method adds the activityId to the set of campaigns
    /// displayed by this surface. Also registers the surface in the known surfaces list.
    ///
    /// - Parameters:
    ///   - cards: Array of content cards to register
    ///   - surfaceUri: The URI of the surface displaying these cards
    func registerCards(_ cards: [ContentCardUI], for surfaceUri: String) {
        // Extract activity IDs from cards
        let activityIds = Set(cards.compactMap { card -> String? in
            let activityId = card.proposition.activityId
            return activityId.isEmpty ? nil : activityId
        })
        
        // Save the campaigns for this surface
        saveActivityIdsForSurface(surfaceUri, activityIds: activityIds)
        
        // Add this surface to the known surfaces list
        addSurfaceToKnownList(surfaceUri)
        
        Log.trace(label: UIConstants.LOG_TAG,
                 "Registered \(cards.count) card(s) for surface: \(surfaceUri)")
    }
    
    /// Cleans up stale read status entries for campaigns no longer active on a surface.
    ///
    /// This method uses a batched I/O approach to minimize file reads:
    /// 1. Batch reads all necessary data upfront (previous state, known surfaces, all surface data)
    /// 2. Performs all checks in memory
    /// 3. Batch deletes stale read statuses
    /// 4. Updates the surface state
    ///
    /// ## Performance:
    /// - Reads: O(1 + 1 + S) where S = number of surfaces
    /// - Writes: O(D + 2) where D = number of activities to delete
    /// - Much better than O(R × S) reads where R = removed activities
    ///
    /// ## Example:
    /// ```
    /// // Before cleanup:
    /// Surfaces: inbox → ["A", "B"], home → ["A", "C"]
    /// ReadStatus: A → true, B → false, C → true
    ///
    /// // Surface "inbox" refreshes with only card A
    /// cleanupStaleReadStatus(currentCards: [A], surfaceUri: "inbox")
    ///
    /// // After cleanup:
    /// Surfaces: inbox → ["A"], home → ["A", "C"]
    /// ReadStatus: A → true, C → true (B deleted - not in any surface)
    /// ```
    ///
    /// - Parameters:
    ///   - currentCards: Array of content cards currently active on the surface
    ///   - surfaceUri: The URI of the surface being cleaned up
    func cleanupStaleReadStatus(currentCards: [ContentCardUI], surfaceUri: String) {
        // STEP 1: Batch read all data upfront (3 reads total)
        let previousActivityIds = getActivityIdsForSurface(surfaceUri)
        let currentActivityIds = Set(currentCards.compactMap { card -> String? in
            let activityId = card.proposition.activityId
            return activityId.isEmpty ? nil : activityId
        })
        let removedActivityIds = previousActivityIds.subtracting(currentActivityIds)
        
        // Early exit if nothing was removed
        guard !removedActivityIds.isEmpty else {
            // Still need to register current cards to update the surface
            registerCards(currentCards, for: surfaceUri)
            Log.trace(label: UIConstants.LOG_TAG,
                     "No activities removed for surface: \(surfaceUri)")
            return
        }
        
        // Batch load all surface data for efficient checking
        let allSurfaces = getKnownSurfaces()
        let allSurfaceData = loadAllSurfaceData(allSurfaces)
        
        // STEP 2: Check in memory which activities should be deleted (no I/O)
        var activitiesToDelete: [String] = []
        
        for activityId in removedActivityIds {
            var stillExists = false
            
            // Check if this activityId exists in any other surface
            for surface in allSurfaces where surface != surfaceUri {
                if allSurfaceData[surface]?.contains(activityId) == true {
                    stillExists = true
                    Log.trace(label: UIConstants.LOG_TAG,
                             "Kept activityId '\(activityId)' - still used by surface '\(surface)'")
                    break
                }
            }
            
            if !stillExists {
                activitiesToDelete.append(activityId)
            }
        }
        
        // STEP 3: Batch delete stale read statuses (M writes)
        for activityId in activitiesToDelete {
            removeReadStatus(for: activityId)
            Log.trace(label: UIConstants.LOG_TAG,
                     "Removed activityId '\(activityId)' - no longer used by any surface")
        }
        
        // STEP 4: Register current cards (updates surface state - 2 writes)
        registerCards(currentCards, for: surfaceUri)
        
        // Log results
        if !activitiesToDelete.isEmpty {
            Log.debug(label: UIConstants.LOG_TAG,
                     "Cleaned up \(activitiesToDelete.count) stale read status entries for surface: \(surfaceUri)")
        } else {
            Log.trace(label: UIConstants.LOG_TAG,
                     "No stale read status entries to clean up for surface: \(surfaceUri)")
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Retrieves the set of activity IDs currently associated with a surface.
    ///
    /// - Parameter surfaceUri: The surface URI to look up
    /// - Returns: Set of activity IDs, empty if none found
    private func getActivityIdsForSurface(_ surfaceUri: String) -> Set<String> {
        let key = surfacePrefix + surfaceUri
        guard let jsonString = registryStore.getString(key: key),
              let jsonData = jsonString.data(using: .utf8),
              let activityIds = try? JSONDecoder().decode(Set<String>.self, from: jsonData) else {
            return []
        }
        return activityIds
    }
    
    /// Saves the set of activity IDs currently associated with a surface.
    ///
    /// - Parameters:
    ///   - surfaceUri: The surface URI
    ///   - activityIds: Set of activity IDs to save
    private func saveActivityIdsForSurface(_ surfaceUri: String, activityIds: Set<String>) {
        let key = surfacePrefix + surfaceUri
        guard let jsonData = try? JSONEncoder().encode(activityIds),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            Log.warning(label: UIConstants.LOG_TAG,
                       "Failed to encode activity IDs for surface: \(surfaceUri)")
            return
        }
        registryStore[key] = jsonString
    }
    
    /// Retrieves the list of all known surfaces.
    ///
    /// - Returns: Set of surface URIs
    private func getKnownSurfaces() -> Set<String> {
        guard let jsonString = registryStore.getString(key: surfacesListKey),
              let jsonData = jsonString.data(using: .utf8),
              let surfaces = try? JSONDecoder().decode(Set<String>.self, from: jsonData) else {
            return []
        }
        return surfaces
    }
    
    /// Adds a surface to the known surfaces list.
    ///
    /// - Parameter surfaceUri: The surface URI to add
    private func addSurfaceToKnownList(_ surfaceUri: String) {
        var surfaces = getKnownSurfaces()
        surfaces.insert(surfaceUri)
        
        guard let jsonData = try? JSONEncoder().encode(surfaces),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            Log.warning(label: UIConstants.LOG_TAG,
                       "Failed to encode known surfaces list")
            return
        }
        registryStore[surfacesListKey] = jsonString
    }
    
    /// Batch loads activity IDs for all specified surfaces.
    ///
    /// This performs N reads (one per surface) but does them all upfront,
    /// avoiding repeated I/O operations in loops.
    ///
    /// - Parameter surfaces: Set of surface URIs to load data for
    /// - Returns: Dictionary mapping surface URI to its set of activity IDs
    private func loadAllSurfaceData(_ surfaces: Set<String>) -> [String: Set<String>] {
        var result: [String: Set<String>] = [:]
        
        for surfaceUri in surfaces {
            result[surfaceUri] = getActivityIdsForSurface(surfaceUri)
        }
        
        return result
    }
}

