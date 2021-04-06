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
    let MOCK_DCCS_URL = "https://dcs.adobedc.net/collection/"
    let MOCK_ECID = "mock_ecid"
    let MOCK_PROFILE_DATASET = "mock_profile_dataset"
    let MOCK_EVENT_DATASET = "mock_event_dataset"
    let MOCK_PRIVACY_STATUS_OPTED_IN = "optedin"
    let MOCK_PRIVACY_STATUS_OPTED_OUT = "optedout"
    let MOCK_EXP_ORG_ID = "mock_exp_org_id"
    let MOCK_PUSH_TOKEN = "mock_pushToken"

    let MOCK_APNSSANDBOX_JSON = "{\n    \"header\" : {\n        \"imsOrgId\": \"mock_exp_org_id\",\n        \"source\": {\n            \"name\": \"mobile\"\n        },\n        \"datasetId\": \"mock_profile_dataset\"\n    },\n    \"body\": {\n        \"xdmEntity\": {\n            \"identityMap\": {\n                \"ECID\": [\n                    {\n                        \"id\" : \"mock_ecid\"\n                    }\n                ]\n            },\n            \"pushNotificationDetails\": [\n                {\n                    \"appID\": \"com.apple.dt.xctest.tool\",\n                    \"platform\": \"apnsSandbox\",\n                    \"token\": \"mock_pushToken\",\n                    \"denylisted\": false,\n                    \"identity\": {\n                        \"namespace\": {\n                            \"code\": \"ECID\"\n                        },\n                        \"id\": \"mock_ecid\"\n                    }\n                }\n            ]\n        }\n    }\n}"

    let MOCK_APNS_JSON = "{\n    \"header\" : {\n        \"imsOrgId\": \"mock_exp_org_id\",\n        \"source\": {\n            \"name\": \"mobile\"\n        },\n        \"datasetId\": \"mock_profile_dataset\"\n    },\n    \"body\": {\n        \"xdmEntity\": {\n            \"identityMap\": {\n                \"ECID\": [\n                    {\n                        \"id\" : \"mock_ecid\"\n                    }\n                ]\n            },\n            \"pushNotificationDetails\": [\n                {\n                    \"appID\": \"com.apple.dt.xctest.tool\",\n                    \"platform\": \"apns\",\n                    \"token\": \"mock_pushToken\",\n                    \"denylisted\": false,\n                    \"identity\": {\n                        \"namespace\": {\n                            \"code\": \"ECID\"\n                        },\n                        \"id\": \"mock_ecid\"\n                    }\n                }\n            ]\n        }\n    }\n}"

    // before each
    override func setUp() {
        mockRuntime = TestableExtensionRuntime()
        messaging = Messaging(runtime: mockRuntime)
        messaging.onRegistered()

        self.mockNetworkService = MockNetworkService()
        ServiceProvider.shared.networkService = self.mockNetworkService!
    }

    /// validate the extension is registered without any error
    func testregisterExtension_registersWithoutAnyErrorOrCrash() {
        XCTAssertNoThrow(MobileCore.registerExtensions([Messaging.self]))
    }

    /// validate that 6 listeners are registered onRegister
    func testOnRegistered_sixListenersAreRegistered() {
        XCTAssertEqual(mockRuntime.listeners.count, 6)
    }

    /// validating handleConfigurationResponse does not throw error with nil data and
    func testhandleConfigurationResponse_withNilData() {
        let event: Event = Event(name: "configurationresponseEvent",
                                 type: EventType.configuration,
                                 source: EventSource.responseContent,
                                 data: nil)
        XCTAssertNoThrow(messaging.handleConfigurationResponse(event))
        XCTAssertFalse(mockRuntime.isStarted)
        XCTAssertFalse(mockRuntime.isStopped)
    }

    /// validating handleConfigurationResponse when privacy is optedout
    func testhandleConfigurationResponse_withPrivacyOptedOut() {
        let eventData: [String: Any] = [MessagingConstants.SharedState.Configuration.privacyStatus: "optedout"]
        let event: Event = Event(name: "configurationresponseEvent",
                                 type: EventType.configuration,
                                 source: EventSource.responseContent,
                                 data: eventData)
        XCTAssertNoThrow(messaging.handleConfigurationResponse(event))
        XCTAssertFalse(mockRuntime.isStarted)
        XCTAssertTrue(mockRuntime.isStopped)
    }

    /// validating handleConfigurationResponse when privacy is optedIn
    func testhandleConfigurationResponse_withPrivacyOptedIn() {
        let eventData: [String: Any] = [MessagingConstants.SharedState.Configuration.privacyStatus: "optedin"]
        let event: Event = Event(name: "configurationresponseEvent",
                                 type: EventType.configuration,
                                 source: EventSource.responseContent,
                                 data: eventData)
        XCTAssertNoThrow(messaging.handleConfigurationResponse(event))
        XCTAssertTrue(mockRuntime.isStarted)
        XCTAssertFalse(mockRuntime.isStopped)
    }

    /// validating handleProcessEvent withNilData
    func testhandleProcessEvent_withNilEventData() {
        let event: Event = Event(name: "handleProcessEvent",
                                 type: EventType.genericIdentity,
                                 source: EventSource.requestContent,
                                 data: nil)
        XCTAssertNoThrow(messaging.handleProcessEvent(event))
    }

    /// validating handleProcessEvent with no shared state
    func testhandleProcessEvent_NoSharedState() {
        let eventData: [String: Any] = [MessagingConstants.SharedState.Configuration.privacyStatus: "optedin"]
        let event: Event = Event(name: "handleProcessEvent",
                                 type: EventType.genericIdentity,
                                 source: EventSource.requestContent,
                                 data: eventData)

        //test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))

        //verify
        XCTAssertNotEqual("https://dcs.adobedc.net/collection/", self.mockNetworkService?.actualNetworkRequest?.url.absoluteString)
    }

    /// validating handleProcessEvent with empty shared state
    func testhandleProcessEvent_withEmptySharedState() {
        let eventData: [String: Any] = [MessagingConstants.SharedState.Configuration.privacyStatus: "optedin"]
        let event: Event = Event(name: "handleProcessEvent",
                                 type: EventType.genericIdentity,
                                 source: EventSource.requestContent,
                                 data: eventData)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.name, data: (value: nil, status: SharedStateStatus.set))
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Identity.name, data: (value: nil, status: SharedStateStatus.set))

        //test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))

        //verify
        XCTAssertNotEqual("https://dcs.adobedc.net/collection/", self.mockNetworkService?.actualNetworkRequest?.url.absoluteString)
    }

    /// validating handleProcessEvent with invalid config
    func testhandleProcessEvent_withInvalidConfig() {
        let mockConfig = [MessagingConstants.SharedState.Configuration.privacyStatus: MOCK_PRIVACY_STATUS_OPTED_IN]

        let mockIdentity = [MessagingConstants.SharedState.Identity.ecid: MOCK_ECID]

        let eventData: [String: Any] = [MessagingConstants.SharedState.Configuration.privacyStatus: MOCK_PRIVACY_STATUS_OPTED_IN]
        let event: Event = Event(name: "handleProcessEvent",
                                 type: EventType.genericIdentity,
                                 source: EventSource.requestContent,
                                 data: eventData)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.name, data: (value: mockConfig, status: SharedStateStatus.set))
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Identity.name, data: (value: mockIdentity, status: SharedStateStatus.set))

        //test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))

        //verify
        XCTAssertNotEqual(MOCK_DCCS_URL, self.mockNetworkService?.actualNetworkRequest?.url.absoluteString)
    }

    /// validating handleProcessEvent with privacy opted out
    func testhandleProcessEvent_withPrivacyOptedOut() {
        let mockConfig = [MessagingConstants.SharedState.Configuration.privacyStatus: MOCK_PRIVACY_STATUS_OPTED_OUT]

        let mockIdentity = [MessagingConstants.SharedState.Identity.ecid: MOCK_ECID]

        let eventData: [String: Any] = [MessagingConstants.SharedState.Configuration.privacyStatus: MOCK_PRIVACY_STATUS_OPTED_OUT]
        let event: Event = Event(name: "handleProcessEvent",
                                 type: EventType.genericIdentity,
                                 source: EventSource.requestContent,
                                 data: eventData)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.name, data: (value: mockConfig, status: SharedStateStatus.set))
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Identity.name, data: (value: mockIdentity, status: SharedStateStatus.set))

        //test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))

        //verify
        XCTAssertNotEqual(MOCK_DCCS_URL, self.mockNetworkService?.actualNetworkRequest?.url.absoluteString)
    }

    /// validating handleProcessEvent with empty token
    func testhandleProcessEvent_withEmptyToken() {
        let mockConfig = [MessagingConstants.SharedState.Configuration.privacyStatus: MOCK_PRIVACY_STATUS_OPTED_OUT,
                          MessagingConstants.EventDataKeys.PUSH_IDENTIFIER: ""]

        let mockIdentity = [MessagingConstants.SharedState.Identity.ecid: MOCK_ECID]

        let eventData: [String: Any] = [MessagingConstants.SharedState.Configuration.privacyStatus: MOCK_PRIVACY_STATUS_OPTED_OUT]
        let event: Event = Event(name: "handleProcessEvent",
                                 type: EventType.genericIdentity,
                                 source: EventSource.requestContent,
                                 data: eventData)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.name, data: (value: mockConfig, status: SharedStateStatus.set))
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Identity.name, data: (value: mockIdentity, status: SharedStateStatus.set))

        //test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))

        //verify
        XCTAssertNotEqual(MOCK_DCCS_URL, self.mockNetworkService?.actualNetworkRequest?.url.absoluteString)
    }

    /// validating handleProcessEvent with working shared state and data
    func testhandleProcessEvent_withConfigAndIdentityData() {
        let mockConfig = [MessagingConstants.SharedState.Configuration.dccsEndpoint: MOCK_DCCS_URL, MessagingConstants.SharedState.Configuration.profileDatasetId: MOCK_PROFILE_DATASET,
                          MessagingConstants.SharedState.Configuration.privacyStatus: MOCK_PRIVACY_STATUS_OPTED_IN,
                          MessagingConstants.SharedState.Configuration.experienceCloudOrgId: MOCK_EXP_ORG_ID]

        let mockIdentity = [MessagingConstants.SharedState.Identity.ecid: MOCK_ECID]

        let eventData: [String: Any] = [MessagingConstants.SharedState.Configuration.privacyStatus: MOCK_PRIVACY_STATUS_OPTED_IN,
                                        MessagingConstants.EventDataKeys.PUSH_IDENTIFIER: MOCK_PUSH_TOKEN]

        let event: Event = Event(name: "handleProcessEvent",
                                 type: EventType.genericIdentity,
                                 source: EventSource.requestContent,
                                 data: eventData)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.name, data: (value: mockConfig, status: SharedStateStatus.set))
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Identity.name, data: (value: mockIdentity, status: SharedStateStatus.set))

        //test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))

        //verify
        XCTAssertEqual(MOCK_DCCS_URL, self.mockNetworkService?.actualNetworkRequest?.url.absoluteString)
        XCTAssertEqual(MOCK_APNS_JSON, self.mockNetworkService?.actualNetworkRequest?.connectPayload)
    }

    /// validating handleProcessEvent with working apns sandbox
    func testhandleProcessEvent_withApnsSandbox() {
        let mockConfig = [MessagingConstants.SharedState.Configuration.dccsEndpoint: MOCK_DCCS_URL, MessagingConstants.SharedState.Configuration.profileDatasetId: MOCK_PROFILE_DATASET,
                          MessagingConstants.SharedState.Configuration.privacyStatus: MOCK_PRIVACY_STATUS_OPTED_IN,
                          MessagingConstants.SharedState.Configuration.experienceCloudOrgId: MOCK_EXP_ORG_ID,
                          MessagingConstants.SharedState.Configuration.useSandbox: true] as [String: Any]

        let mockIdentity = [MessagingConstants.SharedState.Identity.ecid: MOCK_ECID]

        let eventData: [String: Any] = [MessagingConstants.SharedState.Configuration.privacyStatus: MOCK_PRIVACY_STATUS_OPTED_IN,
                                        MessagingConstants.EventDataKeys.PUSH_IDENTIFIER: MOCK_PUSH_TOKEN]

        let event: Event = Event(name: "handleProcessEvent",
                                 type: EventType.genericIdentity,
                                 source: EventSource.requestContent,
                                 data: eventData)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.name, data: (value: mockConfig, status: SharedStateStatus.set))
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Identity.name, data: (value: mockIdentity, status: SharedStateStatus.set))

        //test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))

        //verify
        XCTAssertEqual(MOCK_DCCS_URL, self.mockNetworkService?.actualNetworkRequest?.url.absoluteString)
        XCTAssertEqual(MOCK_APNSSANDBOX_JSON, self.mockNetworkService?.actualNetworkRequest?.connectPayload)
    }

    /// validating handleProcessEvent with working apns sandbox
    func testhandleProcessEvent_withApns() {
        let mockConfig = [MessagingConstants.SharedState.Configuration.dccsEndpoint: MOCK_DCCS_URL, MessagingConstants.SharedState.Configuration.profileDatasetId: MOCK_PROFILE_DATASET,
                          MessagingConstants.SharedState.Configuration.privacyStatus: MOCK_PRIVACY_STATUS_OPTED_IN,
                          MessagingConstants.SharedState.Configuration.experienceCloudOrgId: MOCK_EXP_ORG_ID,
                          MessagingConstants.SharedState.Configuration.useSandbox: false] as [String: Any]

        let mockIdentity = [MessagingConstants.SharedState.Identity.ecid: MOCK_ECID]

        let eventData: [String: Any] = [MessagingConstants.SharedState.Configuration.privacyStatus: MOCK_PRIVACY_STATUS_OPTED_IN,
                                        MessagingConstants.EventDataKeys.PUSH_IDENTIFIER: MOCK_PUSH_TOKEN]

        let event: Event = Event(name: "handleProcessEvent",
                                 type: EventType.genericIdentity,
                                 source: EventSource.requestContent,
                                 data: eventData)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.name, data: (value: mockConfig, status: SharedStateStatus.set))
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Identity.name, data: (value: mockIdentity, status: SharedStateStatus.set))

        //test
        XCTAssertNoThrow(messaging.handleProcessEvent(event))

        //verify
        XCTAssertEqual(MOCK_DCCS_URL, self.mockNetworkService?.actualNetworkRequest?.url.absoluteString)
        XCTAssertEqual(MOCK_APNS_JSON, self.mockNetworkService?.actualNetworkRequest?.connectPayload)
    }

    /// validating handleProcessEvent with Tracking info event when event data is empty
    func testhandleProcessEvent_withTrackingInfoEvent() {
        let mockConfig = [MessagingConstants.SharedState.Configuration.experienceEventDatasetId: MOCK_EVENT_DATASET] as [String: Any]
        let mockIdentity = [MessagingConstants.SharedState.Identity.ecid: MOCK_ECID]

        let eventData: [String: Any]? = nil

        let event: Event = Event(name: "trackingInfo",
                                 type: MessagingConstants.EventType.MESSAGING,
                                 source: EventSource.requestContent,
                                 data: eventData)
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Configuration.name, data: (value: mockConfig, status: SharedStateStatus.set))
        mockRuntime.simulateSharedState(for: MessagingConstants.SharedState.Identity.name, data: (value: mockIdentity, status: SharedStateStatus.set))

        //test
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
