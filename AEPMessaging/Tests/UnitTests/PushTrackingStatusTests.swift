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

class PushTrackingStatusTests: XCTestCase {
    
    func test_trackingInitiated() throws {
        // setup
        let status = PushTrackingStatus(fromRawValue: 0)

        // verify
        XCTAssertEqual(status, .trackingInitiated)
        XCTAssertEqual(status.toString(), "Tracking initiated")
    }
    
    func test_noDatasetConfigured() throws {
        // setup
        let status = PushTrackingStatus(fromRawValue: 1)

        // verify
        XCTAssertEqual(status, .noDatasetConfigured)
        XCTAssertEqual(status.toString(), "No dataset configured")
    }
    
    func test_noTrackingData() throws {
        // setup
        let status = PushTrackingStatus(fromRawValue: 2)

        // verify
        XCTAssertEqual(status, .noTrackingData)
        XCTAssertEqual(status.toString(), "Missing tracking data in Notification Response")
    }

    func test_invalidMessageId() throws {
        // setup
        let status = PushTrackingStatus(fromRawValue: 3)

        // verify
        XCTAssertEqual(status, .invalidMessageId)
        XCTAssertEqual(status.toString(), "MessageId provided for tracking is empty/null")
    }
    
    func test_unknownError() throws {
        // setup
        let status = PushTrackingStatus(fromRawValue: 4)

        // verify
        XCTAssertEqual(status, .unknownError)
        XCTAssertEqual(status.toString(), "Unknown error")
    }
    
    func test_invalidRawValue() throws {
        // setup
        let status = PushTrackingStatus(fromRawValue: 5)

        // verify
        XCTAssertEqual(status, .unknownError)
    }

}
