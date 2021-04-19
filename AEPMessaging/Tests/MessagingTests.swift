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
import AEPServices
import XCTest

@testable import AEPMessaging

class MessagingTests: XCTestCase {
    var messaging: Messaging!
    var mockRuntime: TestableExtensionRuntime!
    var mockNetworkService: MockNetworkService?
    
    // Mock constants
    let MOCK_ECID = "mock_ecid"
    let MOCK_EVENT_DATASET = "mock_event_dataset"
    let MOCK_PRIVACY_STATUS_OPTED_IN = "optedin"
    let MOCK_PRIVACY_STATUS_OPTED_OUT = "optedout"
    let MOCK_EXP_ORG_ID = "mock_exp_org_id"
    let MOCK_PUSH_TOKEN = "mock_pushToken"
    
    // before each
    override func setUp() {
        mockRuntime = TestableExtensionRuntime()
        messaging = Messaging(runtime: mockRuntime)
        messaging.onRegistered()
        
        mockNetworkService = MockNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService!
    }
    
    /// validate the extension is registered without any error
    func testregisterExtension_registersWithoutAnyErrorOrCrash() {
        XCTAssertNoThrow(MobileCore.registerExtensions([Messaging.self]))
    }
    
    /// validate that 6 listeners are registered onRegister
    func testonRegistered_sixListenersAreRegistered() {
        XCTAssertEqual(mockRuntime.listeners.count, 6)
    }
    
    /// validating handleConfigurationResponse does not throw error with nil data and
    func testhandleConfigurationResponse_withNilData() {
        let event = Event(name: "configurationresponseEvent", type: EventType.configuration, source: EventSource.responseContent, data: nil)
        XCTAssertNoThrow(messaging.handleConfigurationResponse(event))
        XCTAssertFalse(mockRuntime.isStarted)
        XCTAssertFalse(mockRuntime.isStopped)
    }
    
    /// validating handleConfigurationResponse when privacy is optedout
    func testhandleConfigurationResponse_withPrivacyOptedOut() {
        let eventData: [String: Any] = [MessagingConstants.SharedState.Configuration.GLOBAL_PRIVACY: "optedout"]
        let event = Event(name: "configurationresponseEvent", type: EventType.configuration, source: EventSource.responseContent, data: eventData)
        XCTAssertNoThrow(messaging.handleConfigurationResponse(event))
        XCTAssertFalse(mockRuntime.isStarted)
        XCTAssertTrue(mockRuntime.isStopped)
    }
    
    /// validating handleConfigurationResponse when privacy is optedIn
    func testhandleConfigurationResponse_withPrivacyOptedIn() {
        let eventData: [String: Any] = [MessagingConstants.SharedState.Configuration.GLOBAL_PRIVACY: "optedin"]
        let event = Event(name: "configurationresponseEvent", type: EventType.configuration, source: EventSource.responseContent, data: eventData)
        XCTAssertNoThrow(messaging.handleConfigurationResponse(event))
        XCTAssertTrue(mockRuntime.isStarted)
        XCTAssertFalse(mockRuntime.isStopped)
    }
    
    /// validating handleProcessEvent withNilData
    func testhandleProcessEvent_withNilEventData() {
        let event = Event(name: "handleProcessEvent", type: EventType.genericIdentity, source: EventSource.requestContent, data: nil)
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
    }
    
    /// validating handleProcessEvent with no shared state
    func testhandleProcessEvent_NoSharedState() {
        let eventData: [String: Any] = [MessagingConstants.SharedState.Configuration.GLOBAL_PRIVACY: "optedin"]
        let event = Event(name: "handleProcessEvent", type: EventType.genericIdentity, source: EventSource.requestContent, data: eventData)
        
        // test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
    }
    
    /// validating handleProcessEvent with empty shared state
    func testhandleProcessEvent_withEmptySharedState() {
        let eventData: [String: Any] = [MessagingConstants.SharedState.Configuration.GLOBAL_PRIVACY: "optedin"]
        let event = Event(name: "handleProcessEvent", type: EventType.genericIdentity, source: EventSource.requestContent, data: eventData)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: nil, status: SharedStateStatus.set))
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: nil, status: SharedStateStatus.set))
        
        // test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
    }
    
    /// validating handleProcessEvent with invalid config
    func testhandleProcessEvent_withInvalidConfig() {
        let mockConfig = [MessagingConstants.SharedState.Configuration.GLOBAL_PRIVACY: MOCK_PRIVACY_STATUS_OPTED_IN]
        
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: MOCK_ECID]]]]
        
        let eventData: [String: Any] = [MessagingConstants.SharedState.Configuration.GLOBAL_PRIVACY: MOCK_PRIVACY_STATUS_OPTED_IN]
        let event = Event(name: "handleProcessEvent", type: EventType.genericIdentity, source: EventSource.requestContent, data: eventData)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: mockConfig, status: SharedStateStatus.set))
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))
        
        // test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
    }
    
    /// validating handleProcessEvent with privacy opted out
    func testhandleProcessEvent_withPrivacyOptedOut() {
        let mockConfig = [MessagingConstants.SharedState.Configuration.GLOBAL_PRIVACY: MOCK_PRIVACY_STATUS_OPTED_OUT]
        
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: MOCK_ECID]]]]
        
        let eventData: [String: Any] = [MessagingConstants.SharedState.Configuration.GLOBAL_PRIVACY: MOCK_PRIVACY_STATUS_OPTED_OUT]
        let event = Event(name: "handleProcessEvent", type: EventType.genericIdentity, source: EventSource.requestContent, data: eventData)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: mockConfig, status: SharedStateStatus.set))
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))
        
        // test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
    }
    
    /// validating handleProcessEvent with empty token
    func testhandleProcessEvent_withEmptyToken() {
        let mockConfig = [MessagingConstants.SharedState.Configuration.GLOBAL_PRIVACY: MOCK_PRIVACY_STATUS_OPTED_OUT,
                          MessagingConstants.EventDataKeys.PUSH_IDENTIFIER: ""]
        
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: MOCK_ECID]]]]
        
        let eventData: [String: Any] = [MessagingConstants.SharedState.Configuration.GLOBAL_PRIVACY: MOCK_PRIVACY_STATUS_OPTED_OUT]
        let event = Event(name: "handleProcessEvent", type: EventType.genericIdentity, source: EventSource.requestContent, data: eventData)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: mockConfig, status: SharedStateStatus.set))
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))
        
        // test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
    }
    
    /// validating handleProcessEvent with working shared state and data
    func testhandleProcessEvent_withConfigAndIdentityData() {
        let mockConfig = [MessagingConstants.SharedState.Configuration.GLOBAL_PRIVACY: MOCK_PRIVACY_STATUS_OPTED_IN,
                          MessagingConstants.SharedState.Configuration.EXPERIENCE_CLOUD_ORG: MOCK_EXP_ORG_ID]
        
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: MOCK_ECID]]]]
        
        let eventData: [String: Any] = [MessagingConstants.SharedState.Configuration.GLOBAL_PRIVACY: MOCK_PRIVACY_STATUS_OPTED_IN,
                                        MessagingConstants.EventDataKeys.PUSH_IDENTIFIER: MOCK_PUSH_TOKEN]
        
        let event = Event(name: "handleProcessEvent", type: EventType.genericIdentity, source: EventSource.requestContent, data: eventData)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: mockConfig, status: SharedStateStatus.set))
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))
        
        // test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
    }
    
    /// validating handleProcessEvent with working apns sandbox
    func testhandleProcessEvent_withApnsSandbox() {
        let mockConfig = [MessagingConstants.SharedState.Configuration.GLOBAL_PRIVACY: MOCK_PRIVACY_STATUS_OPTED_IN,
                          MessagingConstants.SharedState.Configuration.EXPERIENCE_CLOUD_ORG: MOCK_EXP_ORG_ID,
                          MessagingConstants.SharedState.Configuration.USE_SANDBOX: true] as [String: Any]
        
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: MOCK_ECID]]]]
        
        let eventData: [String: Any] = [MessagingConstants.SharedState.Configuration.GLOBAL_PRIVACY: MOCK_PRIVACY_STATUS_OPTED_IN,
                                        MessagingConstants.EventDataKeys.PUSH_IDENTIFIER: MOCK_PUSH_TOKEN]
        
        let event = Event(name: "handleProcessEvent", type: EventType.genericIdentity, source: EventSource.requestContent, data: eventData)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: mockConfig, status: SharedStateStatus.set))
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))
        
        // test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
    }
    
    /// validating handleProcessEvent with working apns sandbox
    func testhandleProcessEvent_withApns() {
        let mockConfig = [MessagingConstants.SharedState.Configuration.GLOBAL_PRIVACY: MOCK_PRIVACY_STATUS_OPTED_IN,
                          MessagingConstants.SharedState.Configuration.EXPERIENCE_CLOUD_ORG: MOCK_EXP_ORG_ID,
                          MessagingConstants.SharedState.Configuration.USE_SANDBOX: false] as [String: Any]
        
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: MOCK_ECID]]]]
        
        let eventData: [String: Any] = [MessagingConstants.SharedState.Configuration.GLOBAL_PRIVACY: MOCK_PRIVACY_STATUS_OPTED_IN,
                                        MessagingConstants.EventDataKeys.PUSH_IDENTIFIER: MOCK_PUSH_TOKEN]
        
        let event = Event(name: "handleProcessEvent", type: EventType.genericIdentity, source: EventSource.requestContent, data: eventData)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: mockConfig, status: SharedStateStatus.set))
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))
        
        // test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
    }
    
    /// validating handleProcessEvent with Tracking info event when event data is empty
    func testhandleProcessEvent_withTrackingInfoEvent() {
        let mockConfig = [MessagingConstants.SharedState.Configuration.EXPERIENCE_EVENT_DATASET: MOCK_EVENT_DATASET] as [String: Any]
        let mockEdgeIdentity = [MessagingConstants.SharedState.EdgeIdentity.IDENTITY_MAP: [MessagingConstants.SharedState.EdgeIdentity.ECID: [[MessagingConstants.SharedState.EdgeIdentity.ID: MOCK_ECID]]]]
        
        let eventData: [String: Any]? = nil
        
        let event = Event(name: "trackingInfo", type: MessagingConstants.EventType.MESSAGING, source: EventSource.requestContent, data: eventData)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.NAME, data: (value: mockConfig, status: SharedStateStatus.set))
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.EdgeIdentity.NAME, data: (value: mockEdgeIdentity, status: SharedStateStatus.set))
        
        // test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
    }
    
    // HELPER
    func readJSONFromFile(fileName: String) -> [String: Any]? {
        var json: Any?
        
        guard let pathString = Bundle(for: type(of: self)).path(forResource: fileName, ofType: "json") else {
            print("\(fileName).json not found")
            return [:]
        }
        let fileUrl = URL(fileURLWithPath: pathString)
        // Getting data from JSON file using the file URL
        do {
            let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
            json = try? JSONSerialization.jsonObject(with: data)
        } catch {
            print("Error while getting data from json")
        }
        return json as? [String: Any]
    }
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}
