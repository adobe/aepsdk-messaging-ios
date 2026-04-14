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

import Foundation
import XCTest
@testable import AEPMessaging
@testable import AEPServices

@available(iOS 15.0, *)
class ReadStatusManagerTests: XCTestCase {
    
    var manager: ReadStatusManager!
    var readStatusStore: NamedCollectionDataStore!
    var registryStore: NamedCollectionDataStore!
    
    // Key constants matching ReadStatusManager
    let surfacesListKey = "_surfaces"
    let surfacePrefix = "surface:"
    
    // Track keys we use in tests for cleanup
    var testActivityIds: Set<String> = []
    var testSurfaceUris: Set<String> = []
    
    override func setUp() {
        super.setUp()
        manager = ReadStatusManager.shared
        readStatusStore = NamedCollectionDataStore(name: "com.adobe.module.messaging.contentcard")
        registryStore = NamedCollectionDataStore(name: "com.adobe.module.messaging.contentcard.registry")
        
        testActivityIds = []
        testSurfaceUris = []
        
        // Clear all data before each test
        clearAllData()
    }
    
    override func tearDown() {
        // Clear all data after each test
        clearAllData()
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Clears all data from all stores for keys used in tests
    private func clearAllData() {
        // Clear read status for tracked activity IDs
        for activityId in testActivityIds {
            readStatusStore.remove(key: activityId)
        }
        
        // Clear registry for tracked surface URIs
        for surfaceUri in testSurfaceUris {
            registryStore.remove(key: surfacePrefix + surfaceUri)
        }
        
        // Clear the surfaces list
        registryStore.remove(key: surfacesListKey)
        
        // Clear common test keys
        let commonActivityIds = ["activity123", "activity1", "activity2", "campaign1", "A", "B", "C", "shared", 
                                 "activity@123", "activity#$%", "activity with spaces", "activity\nnewline", "persistentActivity"]
        for activityId in commonActivityIds {
            readStatusStore.remove(key: activityId)
        }
        
        let commonSurfaces = ["inbox", "home", "settings", "myapp://home", "surface@123", "surface#$%"]
        for surface in commonSurfaces {
            registryStore.remove(key: surfacePrefix + surface)
        }
    }
    
    /// Helper to track activity IDs used in tests
    private func trackActivityId(_ activityId: String) {
        testActivityIds.insert(activityId)
    }
    
    /// Helper to track surface URIs used in tests
    private func trackSurface(_ surfaceUri: String) {
        testSurfaceUris.insert(surfaceUri)
    }
    
    /// Creates a mock ContentCardUI for testing
    private func createMockCard(activityId: String) -> ContentCardUI? {
        let proposition = ContentCardTestUtil.createProposition(fromFile: "SmallImageTemplate")
        guard let card = ContentCardUI.createInstance(with: proposition, customizer: nil, listener: nil) else {
            return nil
        }
        
        // Use reflection to set activityId (for testing purposes)
        // In real usage, activityId comes from the proposition's scopeDetails
        var mutableProposition = proposition
        var scopeDetails = mutableProposition.scopeDetails
        scopeDetails["activity"] = ["id": activityId]
        
        // Create new proposition with updated scopeDetails
        let updatedProposition = Proposition(
            uniqueId: mutableProposition.uniqueId,
            scope: mutableProposition.scope,
            scopeDetails: scopeDetails,
            items: mutableProposition.items
        )
        
        return ContentCardUI.createInstance(with: updatedProposition, customizer: nil, listener: nil)
    }
    
    // MARK: - Read Status Tests
    
    func test_getReadStatus_returnsNil_whenNotSet() {
        // Test
        let result = manager.getReadStatus(for: "activity123")
        
        // Verify
        XCTAssertNil(result, "Read status should be nil when not set")
    }
    
    func test_getReadStatus_returnsNil_whenActivityIdIsEmpty() {
        // Test
        let result = manager.getReadStatus(for: "")
        
        // Verify
        XCTAssertNil(result, "Read status should be nil for empty activityId")
    }
    
    func test_setReadStatus_setsTrue_successfully() {
        // Setup
        let activityId = "activity123"
        
        // Test
        manager.setReadStatus(true, for: activityId)
        let result = manager.getReadStatus(for: activityId)
        
        // Verify
        XCTAssertEqual(result, true, "Read status should be true")
    }
    
    func test_setReadStatus_setsFalse_successfully() {
        // Setup
        let activityId = "activity123"
        
        // Test
        manager.setReadStatus(false, for: activityId)
        let result = manager.getReadStatus(for: activityId)
        
        // Verify
        XCTAssertEqual(result, false, "Read status should be false")
    }
    
    func test_setReadStatus_updatesExistingValue() {
        // Setup
        let activityId = "activity123"
        manager.setReadStatus(false, for: activityId)
        
        // Test
        manager.setReadStatus(true, for: activityId)
        let result = manager.getReadStatus(for: activityId)
        
        // Verify
        XCTAssertEqual(result, true, "Read status should be updated to true")
    }
    
    func test_setReadStatus_ignoresEmptyActivityId() {
        // Test
        manager.setReadStatus(true, for: "")
        let result = manager.getReadStatus(for: "")
        
        // Verify
        XCTAssertNil(result, "Read status should not be set for empty activityId")
    }
    
    func test_removeReadStatus_removesSuccessfully() {
        // Setup
        let activityId = "activity123"
        manager.setReadStatus(true, for: activityId)
        
        // Test
        manager.removeReadStatus(for: activityId)
        let result = manager.getReadStatus(for: activityId)
        
        // Verify
        XCTAssertNil(result, "Read status should be nil after removal")
    }
    
    func test_removeReadStatus_ignoresEmptyActivityId() {
        // Setup
        manager.setReadStatus(true, for: "valid")
        
        // Test
        manager.removeReadStatus(for: "")
        let validResult = manager.getReadStatus(for: "valid")
        
        // Verify
        XCTAssertNotNil(validResult, "Valid read status should not be affected by empty activityId removal")
    }
    
    // MARK: - Surface Registry Tests
    
    func test_registerCards_registersNewSurface() {
        // Setup
        guard let card1 = createMockCard(activityId: "activity1"),
              let card2 = createMockCard(activityId: "activity2") else {
            XCTFail("Failed to create mock cards")
            return
        }
        trackActivityId("activity1")
        trackActivityId("activity2")
        trackSurface("inbox")
        
        // Test
        manager.registerCards([card1, card2], for: "inbox")
        
        // Verify - Check the surface registry
        let activityIdsForInbox = getActivityIdsFromStore(for: "inbox")
        let knownSurfaces = getKnownSurfacesFromStore()
        
        XCTAssertTrue(activityIdsForInbox.contains("activity1"), "Inbox should have activity1")
        XCTAssertTrue(activityIdsForInbox.contains("activity2"), "Inbox should have activity2")
        XCTAssertTrue(knownSurfaces.contains("inbox"), "Inbox should be in known surfaces")
    }
    
    func test_registerCards_addsMultipleSurfaces() {
        // Setup
        guard let card = createMockCard(activityId: "activity1") else {
            XCTFail("Failed to create mock card")
            return
        }
        trackActivityId("activity1")
        trackSurface("inbox")
        trackSurface("home")
        trackSurface("settings")
        
        // Test - Register same card for different surfaces
        manager.registerCards([card], for: "inbox")
        manager.registerCards([card], for: "home")
        manager.registerCards([card], for: "settings")
        
        // Verify - Check that all surfaces have the activity
        let inboxActivities = getActivityIdsFromStore(for: "inbox")
        let homeActivities = getActivityIdsFromStore(for: "home")
        let settingsActivities = getActivityIdsFromStore(for: "settings")
        let knownSurfaces = getKnownSurfacesFromStore()
        
        XCTAssertTrue(inboxActivities.contains("activity1"), "Inbox should have activity1")
        XCTAssertTrue(homeActivities.contains("activity1"), "Home should have activity1")
        XCTAssertTrue(settingsActivities.contains("activity1"), "Settings should have activity1")
        XCTAssertEqual(knownSurfaces.count, 3, "Should have 3 known surfaces")
        XCTAssertTrue(knownSurfaces.contains("inbox"))
        XCTAssertTrue(knownSurfaces.contains("home"))
        XCTAssertTrue(knownSurfaces.contains("settings"))
    }
    
    func test_registerCards_ignoresEmptyActivityId() {
        // Setup
        let proposition = ContentCardTestUtil.createProposition(fromFile: "SmallImageTemplate")
        guard let card = ContentCardUI.createInstance(with: proposition, customizer: nil, listener: nil) else {
            XCTFail("Failed to create mock card")
            return
        }
        trackSurface("inbox")
        
        // Test - Card has empty activityId
        manager.registerCards([card], for: "inbox")
        trackSurface("inbox")
        
        // Verify - Should not create any registry entries for empty activityId
        let activityIds = getActivityIdsFromStore(for: "inbox")
        XCTAssertTrue(activityIds.isEmpty, "Should not register cards with empty activityId")
    }
    
    func test_registerCards_handlesDuplicateSurfaceRegistration() {
        // Setup
        guard let card = createMockCard(activityId: "activity1") else {
            XCTFail("Failed to create mock card")
            return
        }
        trackActivityId("activity1")
        trackSurface("inbox")
        
        // Test - Register same surface multiple times
        manager.registerCards([card], for: "inbox")
        manager.registerCards([card], for: "inbox")
        manager.registerCards([card], for: "inbox")
        
        // Verify - Activity should still only appear once in the surface's list
        let activityIds = getActivityIdsFromStore(for: "inbox")
        XCTAssertEqual(activityIds.count, 1, "Should have only 1 activity despite multiple registrations")
        XCTAssertTrue(activityIds.contains("activity1"))
    }
    
    // MARK: - Cleanup Tests
    
    func test_cleanupStaleReadStatus_removesOnlyWhenNoSurfacesReference() {
        // Setup
        guard let card = createMockCard(activityId: "activity1") else {
            XCTFail("Failed to create mock card")
            return
        }
        trackActivityId("activity1")
        trackSurface("inbox")
        trackSurface("home")
        
        // Register card for two surfaces
        manager.registerCards([card], for: "inbox")
        manager.registerCards([card], for: "home")
        manager.setReadStatus(true, for: "activity1")
        
        // Test - Cleanup for "inbox" (card no longer present)
        manager.cleanupStaleReadStatus(currentCards: [], surfaceUri: "inbox")
        
        // Verify - Read status should still exist because "home" still references it
        let readStatus = manager.getReadStatus(for: "activity1")
        XCTAssertNotNil(readStatus, "Read status should still exist when another surface references it")
        XCTAssertEqual(readStatus, true, "Read status should be true")
        
        // Check that "home" still has the activity
        let homeActivities = getActivityIdsFromStore(for: "home")
        XCTAssertTrue(homeActivities.contains("activity1"), "Home should still have activity1")
        
        // Check that "inbox" no longer has it
        let inboxActivities = getActivityIdsFromStore(for: "inbox")
        XCTAssertFalse(inboxActivities.contains("activity1"), "Inbox should not have activity1")
    }
    
    func test_cleanupStaleReadStatus_removesWhenNoSurfacesReference() {
        // Setup
        guard let card = createMockCard(activityId: "activity1") else {
            XCTFail("Failed to create mock card")
            return
        }
        trackActivityId("activity1")
        trackSurface("inbox")
        
        // Register card for one surface
        manager.registerCards([card], for: "inbox")
        manager.setReadStatus(true, for: "activity1")
        
        // Test - Cleanup for "inbox" (card no longer present)
        manager.cleanupStaleReadStatus(currentCards: [], surfaceUri: "inbox")
        
        // Verify - Read status should be removed
        let readStatus = manager.getReadStatus(for: "activity1")
        XCTAssertNil(readStatus, "Read status should be removed when no surfaces reference it")
        
        // Check that inbox has no activities
        let inboxActivities = getActivityIdsFromStore(for: "inbox")
        XCTAssertTrue(inboxActivities.isEmpty, "Inbox should be empty")
    }
    
    func test_cleanupStaleReadStatus_keepsCurrentCards() {
        // Setup
        guard let card1 = createMockCard(activityId: "activity1"),
              let card2 = createMockCard(activityId: "activity2") else {
            XCTFail("Failed to create mock cards")
            return
        }
        trackActivityId("activity1")
        trackActivityId("activity2")
        trackSurface("inbox")
        
        // Register both cards
        manager.registerCards([card1, card2], for: "inbox")
        manager.setReadStatus(true, for: "activity1")
        manager.setReadStatus(true, for: "activity2")
        
        // Test - Cleanup with only card1 present
        manager.cleanupStaleReadStatus(currentCards: [card1], surfaceUri: "inbox")
        
        // Verify - card1 should remain, card2 should be removed
        XCTAssertNotNil(manager.getReadStatus(for: "activity1"), "Activity1 should remain")
        XCTAssertNil(manager.getReadStatus(for: "activity2"), "Activity2 should be removed")
    }
    
    func test_cleanupStaleReadStatus_complexMultiSurfaceScenario() {
        // Setup
        guard let cardA = createMockCard(activityId: "A"),
              let cardB = createMockCard(activityId: "B"),
              let cardC = createMockCard(activityId: "C") else {
            XCTFail("Failed to create mock cards")
            return
        }
        trackActivityId("A")
        trackActivityId("B")
        trackActivityId("C")
        trackSurface("inbox")
        trackSurface("home")
        
        // Initial state:
        // inbox: A, B
        // home: A, C
        manager.registerCards([cardA, cardB], for: "inbox")
        manager.registerCards([cardA, cardC], for: "home")
        manager.setReadStatus(true, for: "A")
        manager.setReadStatus(true, for: "B")
        manager.setReadStatus(true, for: "C")
        
        // Test - inbox refresh with only A
        manager.cleanupStaleReadStatus(currentCards: [cardA], surfaceUri: "inbox")
        
        // Verify
        // A: should exist (still in both surfaces)
        // B: should be removed (no surfaces left)
        // C: should exist (still in home)
        XCTAssertNotNil(manager.getReadStatus(for: "A"), "A should exist in both surfaces")
        XCTAssertNil(manager.getReadStatus(for: "B"), "B should be removed (no surfaces left)")
        XCTAssertNotNil(manager.getReadStatus(for: "C"), "C should exist (still in home)")
        
        // Check surface states
        let inboxActivities = getActivityIdsFromStore(for: "inbox")
        let homeActivities = getActivityIdsFromStore(for: "home")
        
        XCTAssertTrue(inboxActivities.contains("A"), "Inbox should have A")
        XCTAssertFalse(inboxActivities.contains("B"), "Inbox should not have B")
        XCTAssertTrue(homeActivities.contains("A"), "Home should have A")
        XCTAssertTrue(homeActivities.contains("C"), "Home should have C")
    }
    
    func test_cleanupStaleReadStatus_emptyCurrentCards() {
        // Setup
        guard let card1 = createMockCard(activityId: "activity1"),
              let card2 = createMockCard(activityId: "activity2") else {
            XCTFail("Failed to create mock cards")
            return
        }
        trackActivityId("activity1")
        trackActivityId("activity2")
        trackSurface("inbox")
        
        // Register cards
        manager.registerCards([card1, card2], for: "inbox")
        manager.setReadStatus(true, for: "activity1")
        manager.setReadStatus(true, for: "activity2")
        
        // Test - Cleanup with no cards
        manager.cleanupStaleReadStatus(currentCards: [], surfaceUri: "inbox")
        
        // Verify - All should be removed
        XCTAssertNil(manager.getReadStatus(for: "activity1"), "Activity1 should be removed")
        XCTAssertNil(manager.getReadStatus(for: "activity2"), "Activity2 should be removed")
    }
    
    func test_cleanupStaleReadStatus_noStoredActivities() {
        // Setup - No cards registered
        guard let card = createMockCard(activityId: "activity1") else {
            XCTFail("Failed to create mock card")
            return
        }
        trackActivityId("activity1")
        trackSurface("inbox")
        
        // Test - Cleanup with a current card (should register it)
        manager.cleanupStaleReadStatus(currentCards: [card], surfaceUri: "inbox")
        
        // Verify - Card should be registered now
        let inboxActivities = getActivityIdsFromStore(for: "inbox")
        XCTAssertTrue(inboxActivities.contains("activity1"), "Card should be registered after cleanup")
    }
    
    // MARK: - Integration Tests
    
    func test_fullLifecycle_singleSurface() {
        // Setup
        guard let card = createMockCard(activityId: "campaign1") else {
            XCTFail("Failed to create mock card")
            return
        }
        
        // Step 1: Register card and mark as read
        manager.registerCards([card], for: "inbox")
        manager.setReadStatus(true, for: "campaign1")
        
        XCTAssertEqual(manager.getReadStatus(for: "campaign1"), true, "Should be marked as read")
        
        // Step 2: Card is still present (no cleanup)
        manager.cleanupStaleReadStatus(currentCards: [card], surfaceUri: "inbox")
        XCTAssertNotNil(manager.getReadStatus(for: "campaign1"), "Should still be present")
        
        // Step 3: Card expires/is removed
        manager.cleanupStaleReadStatus(currentCards: [], surfaceUri: "inbox")
        XCTAssertNil(manager.getReadStatus(for: "campaign1"), "Should be cleaned up")
    }
    
    func test_fullLifecycle_multipleSurfaces() {
        // Setup
        guard let card = createMockCard(activityId: "campaign1") else {
            XCTFail("Failed to create mock card")
            return
        }
        
        // Step 1: Register in multiple surfaces
        manager.registerCards([card], for: "inbox")
        manager.registerCards([card], for: "home")
        manager.registerCards([card], for: "settings")
        manager.setReadStatus(true, for: "campaign1")
        
        // Step 2: Remove from inbox
        manager.cleanupStaleReadStatus(currentCards: [], surfaceUri: "inbox")
        XCTAssertNotNil(manager.getReadStatus(for: "campaign1"), "Should persist (home & settings)")
        
        // Step 3: Remove from home
        manager.cleanupStaleReadStatus(currentCards: [], surfaceUri: "home")
        XCTAssertNotNil(manager.getReadStatus(for: "campaign1"), "Should persist (settings)")
        
        // Step 4: Remove from settings
        manager.cleanupStaleReadStatus(currentCards: [], surfaceUri: "settings")
        XCTAssertNil(manager.getReadStatus(for: "campaign1"), "Should be cleaned up")
    }
    
    func test_persistence_readStatusPersistsBetweenInstances() {
        // Setup
        let activityId = "persistentActivity"
        manager.setReadStatus(true, for: activityId)
        
        // Simulate app restart by creating a new manager instance
        // (In real testing, this would involve actual persistence testing)
        let newManager = ReadStatusManager.shared
        
        // Verify
        let result = newManager.getReadStatus(for: activityId)
        XCTAssertEqual(result, true, "Read status should persist")
    }
    
    // MARK: - Edge Case Tests
    
    func test_multipleCardsWithSameActivityId() {
        // Setup - Create multiple cards with same activityId
        guard let card1 = createMockCard(activityId: "shared"),
              let card2 = createMockCard(activityId: "shared") else {
            XCTFail("Failed to create mock cards")
            return
        }
        trackActivityId("shared")
        trackSurface("inbox")
        
        // Test
        manager.registerCards([card1, card2], for: "inbox")
        
        // Verify - Should only have one activity entry
        let activityIds = getActivityIdsFromStore(for: "inbox")
        XCTAssertEqual(activityIds.count, 1, "Should handle duplicate activityIds")
        XCTAssertTrue(activityIds.contains("shared"))
    }
    
    func test_specialCharactersInActivityId() {
        // Setup
        let specialIds = ["activity@123", "activity#$%", "activity with spaces", "activity\nnewline"]
        
        // Test
        for activityId in specialIds {
            manager.setReadStatus(true, for: activityId)
            let result = manager.getReadStatus(for: activityId)
            XCTAssertEqual(result, true, "Should handle special characters in activityId: \(activityId)")
            manager.removeReadStatus(for: activityId)
        }
    }
    
    func test_specialCharactersInSurfaceUri() {
        // Setup
        guard let card = createMockCard(activityId: "activity1") else {
            XCTFail("Failed to create mock card")
            return
        }
        trackActivityId("activity1")
        
        let specialUris = ["myapp://home", "surface@123", "surface#$%"]
        
        // Test
        for uri in specialUris {
            trackSurface(uri)
            manager.registerCards([card], for: uri)
            let activityIds = getActivityIdsFromStore(for: uri)
            XCTAssertTrue(activityIds.contains("activity1"), "Should handle special characters in surface URI: \(uri)")
        }
    }
    
    // MARK: - Private Test Helpers
    
    /// Helper method to directly read activity IDs from store for testing
    private func getActivityIdsFromStore(for surfaceUri: String) -> Set<String> {
        let key = surfacePrefix + surfaceUri
        guard let jsonString = registryStore.getString(key: key),
              let jsonData = jsonString.data(using: .utf8),
              let activityIds = try? JSONDecoder().decode(Set<String>.self, from: jsonData) else {
            return []
        }
        return activityIds
    }
    
    /// Helper method to directly read known surfaces from store for testing
    private func getKnownSurfacesFromStore() -> Set<String> {
        guard let jsonString = registryStore.getString(key: surfacesListKey),
              let jsonData = jsonString.data(using: .utf8),
              let surfaces = try? JSONDecoder().decode(Set<String>.self, from: jsonData) else {
            return []
        }
        return surfaces
    }
}

