/*
 Copyright 2023 Adobe. All rights reserved.
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
import AEPServices

class FeedTests: XCTestCase {
    func testFeedIsCreatable() throws {
        // setup
        let mockName = "aName"
        let mockSurface = Surface(uri: "mySurface")
        let mockFeedItem = FeedItemSchemaData.getEmpty()
        
        // test
        let feed = Feed(name: mockName, surface: mockSurface, items: [mockFeedItem])
        
        // verify
        XCTAssertEqual(mockName, feed.name)
        XCTAssertEqual(mockSurface, feed.surface)
        XCTAssertEqual(1, feed.items.count)
        XCTAssertEqual(mockFeedItem, feed.items.first)
    }
}
