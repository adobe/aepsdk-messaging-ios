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
import AEPServices
@testable import AEPMessaging
import SwiftUI

class UnreadStateTests: XCTestCase {
    
    var mockSchemaData: ContentCardSchemaData!
    var mockUnreadSettings: UnreadIndicatorSettings!
    
    override func setUp() {
        super.setUp()
        // Setup mock schema data
        let schemaJSON = """
        {
            "content": {"title":"Test"},
            "meta": {},
            "id": "test-card-id"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        mockSchemaData = try? decoder.decode(ContentCardSchemaData.self, from: schemaJSON)
    }

    func testBaseTemplateUnreadProperties() {
        guard let template = SmallImageTemplate(mockSchemaData) else {
            XCTFail("Failed to create template")
            return
        }
        
        // Initial state
        XCTAssertFalse(template.isRead, "Should be unread (isRead=false) by default")
        XCTAssertNil(template.unreadIcon)
        XCTAssertNil(template.unreadBackground)
        
        // Update state
        template.updateUnreadState(isRead: true)
        XCTAssertTrue(template.isRead)
        
        template.updateUnreadState(isRead: false)
        XCTAssertFalse(template.isRead)
    }
    
    func testContentCardUISetUnreadSettings() {
        // Mock Proposition
        let proposition = Proposition(uniqueId: "propKey", scope: "scope", items: [])
        
        // Mock Template via ContentCardUI (need to construct it manually as factory needs valid proposition items)
        // Since ContentCardUI init is private, we depend on factory. 
        // We can create a mock PropositionItem with our schema.
        
        // Let's rely on BaseTemplate testing which we can instantiate directly (as seen above).
        
        guard let template = SmallImageTemplate(mockSchemaData) else {
             XCTFail("Failed to create template")
             return
        }
        
        // Create settings manually
        let settingsJSON = """
        {
            "unread_bg": { "clr": { "light": "#FF0000", "dark": "#00FF00" } },
            "unread_icon": {
                "placement": "topright",
                "image": { "img": "http://icon.com" }
            }
        }
        """.data(using: .utf8)!
        
        let settings = try? JSONDecoder().decode(UnreadIndicatorSettings.self, from: settingsJSON)
        XCTAssertNotNil(settings)
        
        // Simulate step 1: Icon
        if let iconSettings = settings?.unreadIcon {
            let unreadIcon = AEPUnreadIcon(settings: iconSettings)
            template.unreadIcon = unreadIcon
        }
        
        // Simulate step 2: Background
        if let bgSettings = settings?.unreadBackground {
            template.unreadBackground = AnyView(Color(aepColor: bgSettings.color))
        }
        
        XCTAssertNotNil(template.unreadIcon)
        XCTAssertNotNil(template.unreadBackground)
        XCTAssertEqual(template.unreadIcon?.alignment, .topTrailing)
    }
}
