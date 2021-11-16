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
import AEPServices

class SharedStateResultMessagingTests: XCTestCase {
    func testExperienceEventDatasetHappy() throws {
        // setup
        let mockDatasetId = "mockDatasetId"
        let sharedState = SharedStateResult(status: .set, value: [
            MessagingConstants.SharedState.Configuration.EXPERIENCE_EVENT_DATASET: mockDatasetId
        ])
        
        // test
        let result = sharedState.experienceEventDataset
        
        // verify
        XCTAssertEqual(mockDatasetId, result)
    }
    
    func testExperienceEventDatasetNoDataset() throws {
        // setup
        let sharedState = SharedStateResult(status: .set, value: [:])
        
        // test
        let result = sharedState.experienceEventDataset
        
        // verify
        XCTAssertNil(result)
    }
    
    func testPushPlatformProd() throws {
        // setup
        let mockUseSandbox = false
        let sharedState = SharedStateResult(status: .set, value: [
            MessagingConstants.SharedState.Configuration.USE_SANDBOX: mockUseSandbox
        ])
        
        // test
        let result = sharedState.pushPlatform
        
        // verify
        XCTAssertEqual(MessagingConstants.XDM.Push.Value.APNS, result)
    }
    
    func testPushPlatformSandbox() throws {
        // setup
        let mockUseSandbox = true
        let sharedState = SharedStateResult(status: .set, value: [
            MessagingConstants.SharedState.Configuration.USE_SANDBOX: mockUseSandbox
        ])
        
        // test
        let result = sharedState.pushPlatform
        
        // verify
        XCTAssertEqual(MessagingConstants.XDM.Push.Value.APNS_SANDBOX, result)
    }
    
    func testPushPlatformNoConfigValue() throws {
        // setup
        let sharedState = SharedStateResult(status: .set, value: [:])
        
        // test
        let result = sharedState.pushPlatform
        
        // verify
        XCTAssertEqual(MessagingConstants.XDM.Push.Value.APNS, result)
    }
}
