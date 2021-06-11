/*
 Copyright 2021 Adobe. All rights reserved.
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

@testable import AEPCore
@testable import AEPMessaging
@testable @_implementationOnly import AEPRulesEngine

class MessagingConsequenceTests: XCTestCase {
    var mockEventData: [String: String] = [:]
    var mockDetails: [String: Any?] = [:]
    let mockId = "mockId"
    let mockType = "mockType"

    override func setUp() {
        mockEventData = ["myKey": "myValue"]
        mockDetails = ["eventdata": mockEventData]
    }

    func testGettersAndSetters() {
        // setup
        let messagingConsequence = MessagingConsequence(id: mockId, type: mockType, details: mockDetails)

        // verify
        XCTAssertEqual(mockId, messagingConsequence.id)
        XCTAssertEqual(mockType, messagingConsequence.type)
        XCTAssertEqual(mockDetails.count, messagingConsequence.details.count)
        XCTAssertEqual(mockEventData["myKey"], messagingConsequence.eventData?["myKey"] as? String)
    }

    func testNoEventData() {
        // setup
        let messagingConsequence = MessagingConsequence(id: mockId, type: mockType, details: ["noeventdata": "foundhere"])

        // verify
        XCTAssertNil(messagingConsequence.eventData)
    }
}
