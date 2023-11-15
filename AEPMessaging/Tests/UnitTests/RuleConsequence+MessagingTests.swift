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
@testable import AEPCore

class RuleConsequenceMessagingTests: XCTestCase {
    
    let SCHEMA_FEED_ITEM = "https://ns.adobe.com/personalization/message/feed-item"
    let SCHEMA_IAM = "https://ns.adobe.com/personalization/message/in-app"
        
    func testIsFeedItemTrue() throws {
        // setup
        let consequence = RuleConsequence(id: "id", type: "type", details: [ "schema": SCHEMA_FEED_ITEM ])
        
        // verify
        XCTAssertTrue(consequence.isFeedItem)
    }
    
    func testIsFeedItemFalse() throws {
        // setup
        let consequence = RuleConsequence(id: "id", type: "type", details: [ "schema": "not a feed" ])
        
        // verify
        XCTAssertFalse(consequence.isFeedItem)
    }
    
    func testIsInAppTrueSchema() throws {
        // setup
        let consequence = RuleConsequence(id: "id", type: "type", details: [ "schema": SCHEMA_IAM ])
        
        // verify
        XCTAssertTrue(consequence.isInApp)
    }
    
    func testIsInAppFalse() throws {
        // setup
        let consequence = RuleConsequence(id: "id", type: "type", details: [ "schema": "not an iam" ])
        
        // verify
        XCTAssertFalse(consequence.isInApp)
    }
    
    func testWhenDetailsSchemaIsNotAString() throws {
        // setup
        let consequence = RuleConsequence(id: "id", type: "type", details: [ "schema": 552 ])
        
        // verify
        XCTAssertFalse(consequence.isInApp)
        XCTAssertFalse(consequence.isFeedItem)
    }
    
    func testWhenDetailsSchemaIsNotPresent() throws {
        // setup
        let consequence = RuleConsequence(id: "id", type: "type", details: [ "not a schema key": SCHEMA_IAM ])
        
        // verify
        XCTAssertFalse(consequence.isInApp)
        XCTAssertFalse(consequence.isFeedItem)
    }
}
