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
import AEPTestUtils

class InAppSchemaDataTests: XCTestCase, AnyCodableAsserts {
                
    let mockContentJson = "{\"key\":\"value\"}"
    let mockContentString = "contentString"
    let mockPublishedDate = 123456789
    let mockExpiryDate = 234567890
    let mockMetaKey = "metaKey"
    let mockMetaValue = "metaValue"
    let mockMobileParamsKey = "mobKey"
    let mockMobileParamsValue = "mobValue"
    let mockWebParamsKey = "webKey"
    let mockWebParamsValue = "webValue"
    let mockRemoteAsset = "https://somedomain.com/someimage.jpg"
        
    func getDecodedObject(fromString: String) -> InAppSchemaData? {
        let decoder = JSONDecoder()
        let objectData = fromString.data(using: .utf8)!
        guard let object = try? decoder.decode(InAppSchemaData.self, from: objectData) else {
            return nil
        }
        return object
    }
    
    // MARK: - codable tests
    
    func testIsDecodableJsonObject() throws {
        // setup
        let json = "{\"content\":\(mockContentJson),\"contentType\":\"\(ContentType.applicationJson.toString())\",\"publishedDate\":\(mockPublishedDate),\"expiryDate\":\(mockExpiryDate),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"mobileParameters\":{\"\(mockMobileParamsKey)\":\"\(mockMobileParamsValue)\"},\"webParameters\":{\"\(mockWebParamsKey)\":\"\(mockWebParamsValue)\"},\"remoteAssets\":[\"\(mockRemoteAsset)\"]}"
        
        // test
        guard let decodedObject = getDecodedObject(fromString: json) else {
            XCTFail("unable to decode json")
            return
        }
        
        // verify
        XCTAssertNotNil(decodedObject)
        let contentDictionary = decodedObject.content as? [String: Any]
        XCTAssertEqual("value", contentDictionary?["key"] as? String)
        XCTAssertEqual(.applicationJson, decodedObject.contentType)
        XCTAssertEqual(mockPublishedDate, decodedObject.publishedDate)
        XCTAssertEqual(mockExpiryDate, decodedObject.expiryDate)
        XCTAssertEqual(mockMetaValue, decodedObject.meta?[mockMetaKey] as? String)
        XCTAssertEqual(mockMobileParamsValue, decodedObject.mobileParameters?[mockMobileParamsKey] as? String)
        XCTAssertEqual(mockWebParamsValue, decodedObject.webParameters?[mockWebParamsKey] as? String)
        XCTAssertEqual(mockRemoteAsset, decodedObject.remoteAssets?.first)
    }
    
    func testIsDecodableJsonArray() throws {
        // setup
        let json = "{\"content\":[\(mockContentJson)],\"contentType\":\"\(ContentType.applicationJson.toString())\",\"publishedDate\":\(mockPublishedDate),\"expiryDate\":\(mockExpiryDate),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"mobileParameters\":{\"\(mockMobileParamsKey)\":\"\(mockMobileParamsValue)\"},\"webParameters\":{\"\(mockWebParamsKey)\":\"\(mockWebParamsValue)\"},\"remoteAssets\":[\"\(mockRemoteAsset)\"]}"
        
        // test
        guard let decodedObject = getDecodedObject(fromString: json) else {
            XCTFail("unable to decode json")
            return
        }
        
        // verify
        XCTAssertNotNil(decodedObject)
        let contentArray = decodedObject.content as? [[String: Any]]
        let contentDictionary = contentArray?.first
        XCTAssertEqual("value", contentDictionary?["key"] as? String)
        XCTAssertEqual(.applicationJson, decodedObject.contentType)
        XCTAssertEqual(mockPublishedDate, decodedObject.publishedDate)
        XCTAssertEqual(mockExpiryDate, decodedObject.expiryDate)
        XCTAssertEqual(mockMetaValue, decodedObject.meta?[mockMetaKey] as? String)
        XCTAssertEqual(mockMobileParamsValue, decodedObject.mobileParameters?[mockMobileParamsKey] as? String)
        XCTAssertEqual(mockWebParamsValue, decodedObject.webParameters?[mockWebParamsKey] as? String)
        XCTAssertEqual(mockRemoteAsset, decodedObject.remoteAssets?.first)
    }
    
    func testIsDecodableString() throws {
        // setup
        let json = "{\"content\":\"\(mockContentString)\",\"contentType\":\"\(ContentType.textHtml.toString())\",\"publishedDate\":\(mockPublishedDate),\"expiryDate\":\(mockExpiryDate),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"mobileParameters\":{\"\(mockMobileParamsKey)\":\"\(mockMobileParamsValue)\"},\"webParameters\":{\"\(mockWebParamsKey)\":\"\(mockWebParamsValue)\"},\"remoteAssets\":[\"\(mockRemoteAsset)\"]}"
        
        // test
        guard let decodedObject = getDecodedObject(fromString: json) else {
            XCTFail("unable to decode json")
            return
        }
        
        // verify
        XCTAssertNotNil(decodedObject)
        XCTAssertEqual(mockContentString, decodedObject.content as? String)
        XCTAssertEqual(.textHtml, decodedObject.contentType)
        XCTAssertEqual(mockPublishedDate, decodedObject.publishedDate)
        XCTAssertEqual(mockExpiryDate, decodedObject.expiryDate)
        XCTAssertEqual(mockMetaValue, decodedObject.meta?[mockMetaKey] as? String)
        XCTAssertEqual(mockMobileParamsValue, decodedObject.mobileParameters?[mockMobileParamsKey] as? String)
        XCTAssertEqual(mockWebParamsValue, decodedObject.webParameters?[mockWebParamsKey] as? String)
        XCTAssertEqual(mockRemoteAsset, decodedObject.remoteAssets?.first)
    }

    func testIsEncodableJsonObjectContent() throws {
        // setup
        let json = "{\"content\":\(mockContentJson),\"contentType\":\"\(ContentType.applicationJson.toString())\",\"publishedDate\":\(mockPublishedDate),\"expiryDate\":\(mockExpiryDate),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"mobileParameters\":{\"\(mockMobileParamsKey)\":\"\(mockMobileParamsValue)\"},\"webParameters\":{\"\(mockWebParamsKey)\":\"\(mockWebParamsValue)\"},\"remoteAssets\":[\"\(mockRemoteAsset)\"]}"
        guard let object = getDecodedObject(fromString: json) else {
            XCTFail("unable to decode json")
            return
        }
        let encoder = JSONEncoder()
        let expected = "{\"content\":\(mockContentJson),\"contentType\":\"\(ContentType.applicationJson.toString())\",\"publishedDate\":\(mockPublishedDate),\"expiryDate\":\(mockExpiryDate),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"mobileParameters\":{\"\(mockMobileParamsKey)\":\"\(mockMobileParamsValue)\"},\"webParameters\":{\"\(mockWebParamsKey)\":\"\(mockWebParamsValue)\"},\"remoteAssets\":[\"\(mockRemoteAsset)\"]}".toAnyCodable() ?? "fail"

        // test
        guard let encodedObject = try? encoder.encode(object) else {
            XCTFail("unable to encode object")
            return
        }

        // verify
        let actual = String(data: encodedObject, encoding: .utf8)?.toAnyCodable() ?? ""
        assertExactMatch(expected: expected, actual: actual, pathOptions: [])
    }
    
    func testIsEncodableJsonArrayContent() throws {
        // setup
        let json = "{\"content\":[\(mockContentJson)],\"contentType\":\"\(ContentType.applicationJson.toString())\",\"publishedDate\":\(mockPublishedDate),\"expiryDate\":\(mockExpiryDate),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"mobileParameters\":{\"\(mockMobileParamsKey)\":\"\(mockMobileParamsValue)\"},\"webParameters\":{\"\(mockWebParamsKey)\":\"\(mockWebParamsValue)\"},\"remoteAssets\":[\"\(mockRemoteAsset)\"]}"
        guard let object = getDecodedObject(fromString: json) else {
            XCTFail("unable to decode json")
            return
        }
        let encoder = JSONEncoder()
        let expected = "{\"content\":[\(mockContentJson)],\"contentType\":\"\(ContentType.applicationJson.toString())\",\"publishedDate\":\(mockPublishedDate),\"expiryDate\":\(mockExpiryDate),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"mobileParameters\":{\"\(mockMobileParamsKey)\":\"\(mockMobileParamsValue)\"},\"webParameters\":{\"\(mockWebParamsKey)\":\"\(mockWebParamsValue)\"},\"remoteAssets\":[\"\(mockRemoteAsset)\"]}".toAnyCodable() ?? "fail"

        // test
        guard let encodedObject = try? encoder.encode(object) else {
            XCTFail("unable to encode object")
            return
        }

        // verify
        let actual = String(data: encodedObject, encoding: .utf8)?.toAnyCodable() ?? ""
        assertExactMatch(expected: expected, actual: actual, pathOptions: [])
    }
    
    func testIsEncodableStringContent() throws {
        // setup
        let json = "{\"content\":\"\(mockContentString)\",\"contentType\":\"\(ContentType.textHtml.toString())\",\"publishedDate\":\(mockPublishedDate),\"expiryDate\":\(mockExpiryDate),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"mobileParameters\":{\"\(mockMobileParamsKey)\":\"\(mockMobileParamsValue)\"},\"webParameters\":{\"\(mockWebParamsKey)\":\"\(mockWebParamsValue)\"},\"remoteAssets\":[\"\(mockRemoteAsset)\"]}"
        guard let object = getDecodedObject(fromString: json) else {
            XCTFail("unable to decode json")
            return
        }
        let encoder = JSONEncoder()
        let expected = "{\"content\":\"\(mockContentString)\",\"contentType\":\"\(ContentType.textHtml.toString())\",\"publishedDate\":\(mockPublishedDate),\"expiryDate\":\(mockExpiryDate),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"mobileParameters\":{\"\(mockMobileParamsKey)\":\"\(mockMobileParamsValue)\"},\"webParameters\":{\"\(mockWebParamsKey)\":\"\(mockWebParamsValue)\"},\"remoteAssets\":[\"\(mockRemoteAsset)\"]}".toAnyCodable() ?? "fail"

        // test
        guard let encodedObject = try? encoder.encode(object) else {
            XCTFail("unable to encode object")
            return
        }

        // verify
        let actual = String(data: encodedObject, encoding: .utf8)?.toAnyCodable() ?? ""
        assertExactMatch(expected: expected, actual: actual, pathOptions: [])
    }
    
    // MARK: - required vs. not required properties
    
    func testContentIsRequired() throws {
        // setup
        let json = "{\"contentType\":\"\(ContentType.applicationJson.toString())\",\"publishedDate\":\(mockPublishedDate),\"expiryDate\":\(mockExpiryDate),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"mobileParameters\":{\"\(mockMobileParamsKey)\":\"\(mockMobileParamsValue)\"},\"webParameters\":{\"\(mockWebParamsKey)\":\"\(mockWebParamsValue)\"},\"remoteAssets\":[\"\(mockRemoteAsset)\"]}"
        
        // test
        let decodedObject = getDecodedObject(fromString: json)
        
        // verify
        XCTAssertNil(decodedObject)
    }
    
    func testContentTypeIsRequired() throws {
        // setup
        let json = "{\"content\":\(mockContentJson),\"publishedDate\":\(mockPublishedDate),\"expiryDate\":\(mockExpiryDate),\"meta\":{\"\(mockMetaKey)\":\"\(mockMetaValue)\"},\"mobileParameters\":{\"\(mockMobileParamsKey)\":\"\(mockMobileParamsValue)\"},\"webParameters\":{\"\(mockWebParamsKey)\":\"\(mockWebParamsValue)\"},\"remoteAssets\":[\"\(mockRemoteAsset)\"]}"
        
        // test
        let decodedObject = getDecodedObject(fromString: json)
        
        // verify
        XCTAssertNil(decodedObject)
    }
    
    func testOnlyContentAndContentTypeAreRequired() throws {
        // setup
        let json = "{\"content\":\(mockContentJson),\"contentType\":\"\(ContentType.applicationJson.toString())\"}"
        
        // test
        let decodedObject = getDecodedObject(fromString: json)
        
        // verify
        XCTAssertNotNil(decodedObject)
        let contentDictionary = decodedObject?.content as? [String: Any]
        XCTAssertEqual("value", contentDictionary?["key"] as? String)
        XCTAssertEqual(.applicationJson, decodedObject?.contentType)
        XCTAssertNil(decodedObject?.publishedDate)
        XCTAssertNil(decodedObject?.expiryDate)
        XCTAssertNil(decodedObject?.meta)
        XCTAssertNil(decodedObject?.mobileParameters)
        XCTAssertNil(decodedObject?.webParameters)
        XCTAssertNil(decodedObject?.remoteAssets)
    }
    
    // MARK: - getMessageSettings

    /// sample `mobileParameters` json which gets represented by a `MessageSettings` object:
    /// {
    ///     "mobileParameters": {
    ///         "schemaVersion": "1.0",
    ///         "width": 80,
    ///         "height": 50,
    ///         "verticalAlign": "center",
    ///         "verticalInset": 0,
    ///         "horizontalAlign": "center",
    ///         "horizontalInset": 0,
    ///         "uiTakeover": true,
    ///         "fitToContent": true,  // << added in AEPMessaging 5.6.1, compatible with AEPServices 5.4.1
    ///         "displayAnimation": "top",
    ///         "dismissAnimation": "top",
    ///         "backdropColor": "000000",    // RRGGBB
    ///         "backdropOpacity: 0.3,
    ///         "cornerRadius": 15,
    ///         "gestures": {
    ///             "swipeUp": "adbinapp://dismiss",
    ///             "swipeDown": "adbinapp://dismiss",
    ///             "swipeLeft": "adbinapp://dismiss?interaction=negative",
    ///             "swipeRight": "adbinapp://dismiss?interaction=positive",
    ///             "tapBackground": "adbinapp://dismiss"
    ///         }
    ///     }
    /// }
    
    func testGetMessageSettingsHappy() throws {
        // setup
        let testMobileParameters = "{\"schemaVersion\":\"1.0\",\"width\":80,\"height\":50,\"verticalAlign\":\"center\",\"verticalInset\":0,\"horizontalAlign\":\"center\",\"horizontalInset\":0,\"uiTakeover\":true,\"fitToContent\":true,\"displayAnimation\":\"top\",\"dismissAnimation\":\"top\",\"backdropColor\":\"000000\",\"backdropOpacity\":0.3,\"cornerRadius\":15,\"gestures\":{\"swipeUp\":\"adbinapp://dismiss?interaction=swipeUp\",\"swipeDown\":\"adbinapp://dismiss?interaction=swipeDown\",\"swipeLeft\":\"adbinapp://dismiss?interaction=swipeLeft\",\"swipeRight\":\"adbinapp://dismiss?interaction=swipeRight\",\"tapBackground\":\"adbinapp://dismiss?interaction=tapBackground\"}}"
        
        let json = "{\"content\":\(mockContentJson),\"contentType\":\"\(ContentType.applicationJson.toString())\",\"mobileParameters\":\(testMobileParameters)}"
        guard let decodedObject = getDecodedObject(fromString: json) else {
            XCTFail("unable to decode json")
            return
        }
        
        // test
        let result = decodedObject.getMessageSettings(with: self)
        
        // verify
        XCTAssertEqual(self, result.parent as? InAppSchemaDataTests)
        XCTAssertEqual(80, result.width)
        XCTAssertEqual(50, result.height)
        XCTAssertEqual(.center, result.verticalAlign)
        XCTAssertEqual(0, result.verticalInset)
        XCTAssertEqual(.center, result.horizontalAlign)
        XCTAssertEqual(0, result.horizontalInset)
        XCTAssertEqual(true, result.uiTakeover)
        XCTAssertEqual(true, result.fitToContent)
        XCTAssertEqual(.top, result.displayAnimation)
        XCTAssertEqual(.top, result.dismissAnimation)
        XCTAssertEqual(UIColor(hue: 0, saturation: 0, brightness: 0, alpha: 0.3), result.getBackgroundColor()) // 000000 color and 0.3 opacity
        XCTAssertEqual(URL(string: "adbinapp://dismiss?interaction=swipeUp"), result.gestures?[.swipeUp])
        XCTAssertEqual(URL(string: "adbinapp://dismiss?interaction=swipeDown"), result.gestures?[.swipeDown])
        XCTAssertEqual(URL(string: "adbinapp://dismiss?interaction=swipeLeft"), result.gestures?[.swipeLeft])
        XCTAssertEqual(URL(string: "adbinapp://dismiss?interaction=swipeRight"), result.gestures?[.swipeRight])
        XCTAssertEqual(URL(string: "adbinapp://dismiss?interaction=tapBackground"), result.gestures?[.tapBackground])
    }
    
    func testGetMessageSettingsNoMobileParameters() throws {
        // setup
        let json = "{\"content\":\(mockContentJson),\"contentType\":\"\(ContentType.applicationJson.toString())\"}"
        guard let decodedObject = getDecodedObject(fromString: json) else {
            XCTFail("unable to decode json")
            return
        }
        
        // test
        let result = decodedObject.getMessageSettings(with: self)
        
        // verify
        XCTAssertEqual(self, result.parent as? InAppSchemaDataTests)
        XCTAssertNil(result.width)
        XCTAssertNil(result.width)
        XCTAssertNil(result.height)
        XCTAssertNil(result.verticalAlign)
        XCTAssertNil(result.verticalInset)
        XCTAssertNil(result.horizontalAlign)
        XCTAssertNil(result.horizontalInset)
        XCTAssertNil(result.uiTakeover)
        XCTAssertNil(result.fitToContent)
        XCTAssertNil(result.displayAnimation)
        XCTAssertNil(result.dismissAnimation)
        XCTAssertEqual(UIColor(red: 1, green: 1, blue: 1, alpha: 0), result.getBackgroundColor()) // default color
        XCTAssertNil(result.gestures)
    }
    
    func testGetMessageSettingsDefaultValues() throws {
        // setup
        let testMobileParameters = "{\"schemaVersion\":\"1.0\",\"width\":80,\"height\":50,\"verticalInset\":0,\"horizontalInset\":0,\"backdropColor\":\"000000\",\"backdropOpacity\":0.3,\"cornerRadius\":15,\"gestures\":{\"swipeUp\":\"adbinapp://dismiss?interaction=swipeUp\",\"swipeDown\":\"adbinapp://dismiss?interaction=swipeDown\",\"swipeLeft\":\"adbinapp://dismiss?interaction=swipeLeft\",\"swipeRight\":\"adbinapp://dismiss?interaction=swipeRight\",\"tapBackground\":\"adbinapp://dismiss?interaction=tapBackground\"}}"
        
        let json = "{\"content\":\(mockContentJson),\"contentType\":\"\(ContentType.applicationJson.toString())\",\"mobileParameters\":\(testMobileParameters)}"
        guard let decodedObject = getDecodedObject(fromString: json) else {
            XCTFail("unable to decode json")
            return
        }
        
        // test
        let result = decodedObject.getMessageSettings(with: self)
        
        // verify
        XCTAssertEqual(self, result.parent as? InAppSchemaDataTests)
        XCTAssertEqual(80, result.width)
        XCTAssertEqual(50, result.height)
        XCTAssertEqual(.center, result.verticalAlign)
        XCTAssertEqual(0, result.verticalInset)
        XCTAssertEqual(.center, result.horizontalAlign)
        XCTAssertEqual(0, result.horizontalInset)
        XCTAssertEqual(true, result.uiTakeover)
        XCTAssertEqual(false, result.fitToContent)
        XCTAssertEqual(MessageAnimation.none, result.displayAnimation)
        XCTAssertEqual(MessageAnimation.none, result.dismissAnimation)
        XCTAssertEqual(UIColor(hue: 0, saturation: 0, brightness: 0, alpha: 0.3), result.getBackgroundColor()) // 000000 color and 0.3 opacity
        XCTAssertEqual(URL(string: "adbinapp://dismiss?interaction=swipeUp"), result.gestures?[.swipeUp])
        XCTAssertEqual(URL(string: "adbinapp://dismiss?interaction=swipeDown"), result.gestures?[.swipeDown])
        XCTAssertEqual(URL(string: "adbinapp://dismiss?interaction=swipeLeft"), result.gestures?[.swipeLeft])
        XCTAssertEqual(URL(string: "adbinapp://dismiss?interaction=swipeRight"), result.gestures?[.swipeRight])
        XCTAssertEqual(URL(string: "adbinapp://dismiss?interaction=tapBackground"), result.gestures?[.tapBackground])
    }
}
