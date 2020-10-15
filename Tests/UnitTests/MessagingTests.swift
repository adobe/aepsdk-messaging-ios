//
// Copyright 2020 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import AEPCore
import XCTest

@testable import AEPMessaging

class MessagingTests: XCTestCase {
    var messaging: Messaging!
    var mockRuntime: TestableExtensionRuntime!

    // before each
    override func setUp() {
        mockRuntime = TestableExtensionRuntime()
        messaging = Messaging(runtime: mockRuntime)
        messaging.onRegistered()
    }

    /// validate the extension is registered without any error
    func testregisterExtension_registersWithoutAnyErrorOrCrash() {
        XCTAssertNoThrow(MobileCore.registerExtensions([Messaging.self]))
    }

    /// validate that 3 listeners are registered onRegister
    func testonRegistered_threeListenersAreRegistered() {
        XCTAssertEqual(mockRuntime.listeners.count, 3)
    }

    /// validating handleConfigurationResponse does not throw error with nil data and
    func testhandleConfigurationResponse_withNilData() {
        let event: Event = Event(name: "configurationresponseEvent", type: MessagingConstants.EventTypes.configuration, source: MessagingConstants.EventSources.responseContent, data: nil)
        XCTAssertNoThrow(messaging.handleConfigurationResponse(event))
        XCTAssertFalse(mockRuntime.isStarted)
        XCTAssertFalse(mockRuntime.isStopped)
    }

    /// validating handleConfigurationResponse when privacy is optedout
    func testhandleConfigurationResponse_withPrivacyOptedOut() {
        let eventData: [String: Any] = [MessagingConstants.SharedState.Configuration.privacyStatus: "optedout"]
        let event: Event = Event(name: "configurationresponseEvent", type: MessagingConstants.EventTypes.configuration, source: MessagingConstants.EventSources.responseContent, data: eventData)
        XCTAssertNoThrow(messaging.handleConfigurationResponse(event))
        XCTAssertFalse(mockRuntime.isStarted)
        XCTAssertTrue(mockRuntime.isStopped)
    }

    /// validating handleConfigurationResponse when privacy is optedIn
    func testhandleConfigurationResponse_withPrivacyOptedIn() {
        let eventData: [String: Any] = [MessagingConstants.SharedState.Configuration.privacyStatus: "optedin"]
        let event: Event = Event(name: "configurationresponseEvent", type: MessagingConstants.EventTypes.configuration, source: MessagingConstants.EventSources.responseContent, data: eventData)
        XCTAssertNoThrow(messaging.handleConfigurationResponse(event))
        XCTAssertTrue(mockRuntime.isStarted)
        XCTAssertFalse(mockRuntime.isStopped)
    }

    // validating handleProcessEvent withNilData
    func testhandleProcessEvent_withNilEventData() {
        let event: Event = Event(name: "handleProcessEvent", type: MessagingConstants.EventTypes.genericIdentity, source: MessagingConstants.EventSources.requestContent, data: nil)
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
    }

    // validating handleProcessEvent
    func testhandleProcessEvent() {
        let eventData: [String: Any] = [MessagingConstants.SharedState.Configuration.privacyStatus: "optedin"]
        let event: Event = Event(name: "handleProcessEvent", type: MessagingConstants.EventTypes.genericIdentity, source: MessagingConstants.EventSources.requestContent, data: eventData)
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
    }
}
