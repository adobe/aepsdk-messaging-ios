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

class InAppSchemaDataTests: XCTestCase {
                
    override func setUp() {
        
    }
    
    // MARK: - helpers
    
    
//    func testGetMessageSettingsHappy() throws {
//        // setup
//        let event = TestableMobileParameters.getMobileParametersEvent()
//
//        // test
//        let settings = event.getMessageSettings(withParent: self)
//
//        // verify
//        XCTAssertNotNil(settings)
//        XCTAssertTrue(settings.parent is EventPlusMessagingTests)
//        XCTAssertEqual(TestableMobileParameters.mockWidth, settings.width)
//        XCTAssertEqual(TestableMobileParameters.mockHeight, settings.height)
//        XCTAssertEqual(MessageAlignment.fromString(TestableMobileParameters.mockVAlign), settings.verticalAlign)
//        XCTAssertEqual(TestableMobileParameters.mockVInset, settings.verticalInset)
//        XCTAssertEqual(MessageAlignment.fromString(TestableMobileParameters.mockHAlign), settings.horizontalAlign)
//        XCTAssertEqual(TestableMobileParameters.mockHInset, settings.horizontalInset)
//        XCTAssertEqual(TestableMobileParameters.mockUiTakeover, settings.uiTakeover)
//        XCTAssertEqual(UIColor(red: 0xAA / 255.0, green: 0xBB / 255.0, blue: 0xCC / 255.0, alpha: 0), settings.getBackgroundColor(opacity: 0))
//        XCTAssertEqual(CGFloat(TestableMobileParameters.mockCornerRadius), settings.cornerRadius)
//        XCTAssertEqual(MessageAnimation.fromString(TestableMobileParameters.mockDisplayAnimation), settings.displayAnimation)
//        XCTAssertEqual(MessageAnimation.fromString(TestableMobileParameters.mockDismissAnimation), settings.dismissAnimation)
//        XCTAssertNotNil(settings.gestures)
//        XCTAssertEqual(1, settings.gestures?.count)
//        XCTAssertEqual(URL(string: "adbinapp://dismiss")!.absoluteString, (settings.gestures![.swipeDown]!).absoluteString)
//    }
//
//    func testGetMessageSettingsNoParent() throws {
//        // setup
//        let event = TestableMobileParameters.getMobileParametersEvent()
//
//        // test
//        let settings = event.getMessageSettings(withParent: nil)
//
//        // verify
//        XCTAssertNotNil(settings)
//        XCTAssertNil(settings.parent)
//        XCTAssertEqual(TestableMobileParameters.mockWidth, settings.width)
//        XCTAssertEqual(TestableMobileParameters.mockHeight, settings.height)
//        XCTAssertEqual(MessageAlignment.fromString(TestableMobileParameters.mockVAlign), settings.verticalAlign)
//        XCTAssertEqual(TestableMobileParameters.mockVInset, settings.verticalInset)
//        XCTAssertEqual(MessageAlignment.fromString(TestableMobileParameters.mockHAlign), settings.horizontalAlign)
//        XCTAssertEqual(TestableMobileParameters.mockHInset, settings.horizontalInset)
//        XCTAssertEqual(TestableMobileParameters.mockUiTakeover, settings.uiTakeover)
//        XCTAssertEqual(UIColor(red: 0xAA / 255.0, green: 0xBB / 255.0, blue: 0xCC / 255.0, alpha: 0), settings.getBackgroundColor(opacity: 0))
//        XCTAssertEqual(CGFloat(TestableMobileParameters.mockCornerRadius), settings.cornerRadius)
//        XCTAssertEqual(MessageAnimation.fromString(TestableMobileParameters.mockDisplayAnimation), settings.displayAnimation)
//        XCTAssertEqual(MessageAnimation.fromString(TestableMobileParameters.mockDismissAnimation), settings.dismissAnimation)
//        XCTAssertNotNil(settings.gestures)
//        XCTAssertEqual(1, settings.gestures?.count)
//        XCTAssertEqual(URL(string: "adbinapp://dismiss")!.absoluteString, (settings.gestures![.swipeDown]!).absoluteString)
//    }
//
//    func testGetMessageSettingsMobileParametersEmpty() throws {
//        // setup
//        let event = getRefreshMessagesEvent()
//
//        // test
//        let settings = event.getMessageSettings(withParent: self)
//
//        // verify
//        XCTAssertNotNil(settings)
//        XCTAssertTrue(settings.parent is EventPlusMessagingTests)
//        XCTAssertNil(settings.width)
//        XCTAssertNil(settings.height)
//        XCTAssertEqual(.center, settings.verticalAlign)
//        XCTAssertNil(settings.verticalInset)
//        XCTAssertEqual(.center, settings.horizontalAlign)
//        XCTAssertNil(settings.horizontalInset)
//        XCTAssertTrue(settings.uiTakeover!)
//        XCTAssertEqual(UIColor(red: 1, green: 1, blue: 1, alpha: 0), settings.getBackgroundColor(opacity: 0))
//        XCTAssertNil(settings.cornerRadius)
//        XCTAssertEqual(.none, settings.displayAnimation!)
//        XCTAssertEqual(.none, settings.dismissAnimation!)
//        XCTAssertNil(settings.gestures)
//    }
//
//    func testGetMessageSettingsEmptyGestures() throws {
//        // setup
//        let params: [String: Any] = [
//            MessagingConstants.Event.Data.Key.TRIGGERED_CONSEQUENCE: [
//                MessagingConstants.Event.Data.Key.DETAIL: [
//                    MessagingConstants.Event.Data.Key.IAM.MOBILE_PARAMETERS: [
//                        MessagingConstants.Event.Data.Key.IAM.GESTURES: [:] as [String: Any]
//                    ]
//                ]
//            ]
//        ]
//        let event = TestableMobileParameters.getMobileParametersEvent(withData: params)
//
//        // test
//        let settings = event.getMessageSettings(withParent: self)
//
//        // verify
//        XCTAssertNotNil(settings)
//        XCTAssertNil(settings.gestures)
//    }
}
