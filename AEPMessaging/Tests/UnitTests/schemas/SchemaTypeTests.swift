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
import AEPServices

class SchemaTypeTests: XCTestCase {
    func testUnknown() throws {
        // setup
        let value = SchemaType(rawValue: 0)
        
        // verify
        XCTAssertEqual(value, .unknown)
        XCTAssertEqual("", value?.toString())
    }
    
    func testInitFromSchemaUnknown() throws {
        // test
        let value = SchemaType(from: "this isn't a valid schema type")
        
        // verify
        XCTAssertEqual(.unknown, value)
    }
    
    func testHtmlContent() throws {
        // setup
        let value = SchemaType(rawValue: 1)

        // verify
        XCTAssertEqual(value, .htmlContent)
        XCTAssertEqual(MessagingConstants.PersonalizationSchemas.HTML_CONTENT, value?.toString())
    }
    
    func testInitFromSchemaHtmlContent() throws {
        // test
        let value = SchemaType(from: MessagingConstants.PersonalizationSchemas.HTML_CONTENT)
        
        // verify
        XCTAssertEqual(.htmlContent, value)
    }
    
    func testJsonContent() throws {
        // setup
        let value = SchemaType(rawValue: 2)

        // verify
        XCTAssertEqual(value, .jsonContent)
        XCTAssertEqual(MessagingConstants.PersonalizationSchemas.JSON_CONTENT, value?.toString())
    }
    
    func testInitFromSchemaJsonContent() throws {
        // test
        let value = SchemaType(from: MessagingConstants.PersonalizationSchemas.JSON_CONTENT)
        
        // verify
        XCTAssertEqual(.jsonContent, value)
    }
    
    func testRuleset() throws {
        // setup
        let value = SchemaType(rawValue: 3)

        // verify
        XCTAssertEqual(value, .ruleset)
        XCTAssertEqual(MessagingConstants.PersonalizationSchemas.RULESET_ITEM, value?.toString())
    }
    
    func testInitFromSchemaRulesetItem() throws {
        // test
        let value = SchemaType(from: MessagingConstants.PersonalizationSchemas.RULESET_ITEM)
        
        // verify
        XCTAssertEqual(.ruleset, value)
    }
    
    func testInapp() throws {
        // setup
        let value = SchemaType(rawValue: 4)

        // verify
        XCTAssertEqual(value, .inapp)
        XCTAssertEqual(MessagingConstants.PersonalizationSchemas.IN_APP, value?.toString())
    }
    
    func testInitFromSchemaInapp() throws {
        // test
        let value = SchemaType(from: MessagingConstants.PersonalizationSchemas.IN_APP)
        
        // verify
        XCTAssertEqual(.inapp, value)
    }
    
    @available(*, deprecated)
    func testFeed() throws {
        // setup
        let value = SchemaType(rawValue: 5)

        // verify
        XCTAssertEqual(value, .feed)
        XCTAssertEqual(MessagingConstants.PersonalizationSchemas.FEED_ITEM, value?.toString())
    }
    
    @available(*, deprecated)
    func testInitFromSchemaFeed() throws {
        // test
        let value = SchemaType(from: MessagingConstants.PersonalizationSchemas.FEED_ITEM)
        
        // verify
        XCTAssertEqual(.feed, value)
    }
    
    func testContentCard() throws {
        // setup
        let value = SchemaType(rawValue: 8)

        // verify
        XCTAssertEqual(value, .contentCard)
        XCTAssertEqual(MessagingConstants.PersonalizationSchemas.CONTENT_CARD, value?.toString())
    }
    
    func testInitFromSchemaContentCard() throws {
        // test
        let value = SchemaType(from: MessagingConstants.PersonalizationSchemas.CONTENT_CARD)
        
        // verify
        XCTAssertEqual(.contentCard, value)
    }
    
    func testNativeAlert() throws {
        // setup
        let value = SchemaType(rawValue: 6)

        // verify
        XCTAssertEqual(value, .nativeAlert)
        XCTAssertEqual(MessagingConstants.PersonalizationSchemas.NATIVE_ALERT, value?.toString())
    }
    
    func testInitFromSchemaNativeAlert() throws {
        // test
        let value = SchemaType(from: MessagingConstants.PersonalizationSchemas.NATIVE_ALERT)
        
        // verify
        XCTAssertEqual(.nativeAlert, value)
    }
    
    func testDefaultContent() throws {
        // setup
        let value = SchemaType(rawValue: 7)

        // verify
        XCTAssertEqual(value, .defaultContent)
        XCTAssertEqual(MessagingConstants.PersonalizationSchemas.DEFAULT_CONTENT, value?.toString())
    }
    
    func testInitFromSchemaDefaultContent() throws {
        // test
        let value = SchemaType(from: MessagingConstants.PersonalizationSchemas.DEFAULT_CONTENT)
        
        // verify
        XCTAssertEqual(.defaultContent, value)
    }

    func testRawValueContentCard() throws {
        // test
        let rawValue = SchemaType.contentCard.rawValue
        // verify
        XCTAssertEqual(8, rawValue)
    }

    func testRawValueEventHistoryOperation() throws {
        // test
        let rawValue = SchemaType.eventHistoryOperation.rawValue
        // verify
        XCTAssertEqual(9, rawValue)
    }

    func testEventHistoryOperation() throws {
        // setup
        let value = SchemaType(rawValue: 9)

        // verify
        XCTAssertEqual(value, .eventHistoryOperation)
        XCTAssertEqual(MessagingConstants.PersonalizationSchemas.EVENT_HISTORY_OPERATION, value?.toString())
    }

    func testInitFromSchemaEventHistoryOperation() throws {
        // test
        let value = SchemaType(from: MessagingConstants.PersonalizationSchemas.EVENT_HISTORY_OPERATION)

        // verify
        XCTAssertEqual(.eventHistoryOperation, value)
    }

    func testContainerItem() throws {
        // setup
        let value = SchemaType(rawValue: 11)

        // verify
        XCTAssertEqual(value, .containerItem)
        XCTAssertEqual(MessagingConstants.PersonalizationSchemas.INBOX_ITEM, value?.toString())
    }

    func testInitFromSchemaContainerItem() throws {
        // test
        let value = SchemaType(from: MessagingConstants.PersonalizationSchemas.INBOX_ITEM)

        // verify
        XCTAssertEqual(.containerItem, value)
    }

    func testRawValueContainerItem() throws {
        // test
        let rawValue = SchemaType.containerItem.rawValue
        
        // verify
        XCTAssertEqual(11, rawValue)
    }
}
