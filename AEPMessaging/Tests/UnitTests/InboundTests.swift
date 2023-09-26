//
// Copyright 2023 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

@testable import AEPCore
@testable import AEPServices
@testable import AEPMessaging
import XCTest

class InboundTests: XCTestCase {
    
    var mockInbound: Inbound!
    let mockInboundId = "552"
    
    override func setUp() {
        let inboundJson = JSONFileLoader.getRulesJsonFromFile("inboundConsequenceDetail")
        mockInbound = Inbound.from(consequenceDetail: inboundJson, id: mockInboundId)
    }
    
    func testIsEncodable() throws {
        // setup
        let encoder = JSONEncoder()
        let expectedContentAsAnyCodable = getAnyCodable("{\"title\":\"contentTitle\",\"body\":\"contentBody\",\"imageUrl\":\"contentImageUrl\",\"actionUrl\":\"contentActionUrl\",\"actionTitle\":\"contentActionTitle\"                   }")!
        
        // test
        guard let encodedInbound = try? encoder.encode(mockInbound) else {
            XCTFail("unable to encode Inbound")
            return
        }
        
        // verify
        let actualJsonAsAnyCodable = getAnyCodable(String(data: encodedInbound, encoding: .utf8) ?? "")
        XCTAssertNotNil(actualJsonAsAnyCodable)
        let inboundMap = actualJsonAsAnyCodable?.asDictionary()
        XCTAssertEqual("552", inboundMap?["id"] as? String)
        XCTAssertEqual("https://ns.adobe.com/personalization/inbound/feed-item", inboundMap?["schema"] as? String)
        let inboundData = inboundMap?["data"] as? [String: Any]
        let contentAsAnyCodable = getAnyCodable(inboundData!["content"] as! String)
        assertExactMatch(expected: expectedContentAsAnyCodable, actual: contentAsAnyCodable)
        XCTAssertEqual("application/json", inboundData?["contentType"] as? String)
        XCTAssertEqual(1691541497, inboundData?["publishedDate"] as? Int)
        XCTAssertEqual(1723163897, inboundData?["expiryDate"] as? Int)
        let inboundMeta = inboundData?["meta"] as? [String: Any]
        XCTAssertEqual("mobileapp://com.feeds.testing/feeds/apifeed", inboundMeta?["surface"] as? String)
        XCTAssertEqual("testCampaign", inboundMeta?["campaignName"] as? String)
        XCTAssertEqual("testFeed", inboundMeta?["feedName"] as? String)
    }
    
    func testIsDecoable() throws {
        // setup
        let decoder = JSONDecoder()
        let inboundJsonString = #"""
{
    "id": "183639c4-cb37-458e-a8ef-4e130d767ebf",
    "schema": "https://ns.adobe.com/personalization/inbound/feed-item",
    "data": {
        "expiryDate": 1723163897,
        "meta": {
            "feedName": "testFeed",
            "campaignName": "testCampaign",
            "surface": "mobileapp://com.feeds.testing/feeds/apifeed"
        },
        "content": {
            "title": "contentTitle",
            "body": "contentBody",
            "imageUrl": "contentImageUrl",
            "actionUrl": "contentActionUrl",
            "actionTitle": "contentActionTitle"
        },
        "contentType": "application/json",
        "publishedDate": 1691541497
    }
}
"""#
        let inbound = inboundJsonString.data(using: .utf8)!
        
        // test
        guard let decodedInbound = try? decoder.decode(Inbound.self, from: inbound) else {
            XCTFail("unable to decode inbound json")
            return
        }
        
        // verify
        XCTAssertNotNil(decodedInbound)
    }
}
