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

import AEPCore
import AEPServices
import XCTest
import AEPTestUtils

/// Instrumented extension that registers a wildcard listener for intercepting events in current session. Use it along with `FunctionalTestBase`
class InstrumentedExtension: NSObject, Extension {
    private static let logTag = "InstrumentedExtension"
    var name = "com.adobe.InstrumentedExtension"
    var friendlyName = "InstrumentedExtension"
    static var extensionVersion = "1.0.0"
    var metadata: [String: String]?
    var runtime: ExtensionRuntime
    
    enum TestEventType {
        static let INSTRUMENTED_EXTENSION = "com.adobe.eventType.instrumentedExtension"
    }
    
    enum TestEventSource {
        static let SHARED_STATE = "com.adobe.eventSource.sharedState"
        static let SHARED_STATE_REQUEST = "com.adobe.eventSource.requestState"
        static let SHARED_STATE_RESPONSE = "com.adobe.eventSource.responseState"
        static let UNREGISTER_EXTENSION = "com.adobe.eventSource.unregisterExtension"
    }
    
    enum EventDataKey {
        static let STATE_OWNER = "stateowner"
        static let STATE = "state"
    }

    // Expected events Dictionary - key: EventSpec, value: the expected count
    static var expectedEvents = ThreadSafeDictionary<EventSpec, CountDownLatch>()

    // All the events seen by this listener that are not of type instrumentedExtension - key: EventSpec, value: received events with EventSpec type and source
    static var receivedEvents = ThreadSafeDictionary<EventSpec, [Event]>()

    func onRegistered() {
        runtime.registerListener(type: EventType.wildcard, source: EventSource.wildcard, listener: wildcardListenerProcessor)
    }

    func onUnregistered() {}

    public func readyForEvent(_ event: Event) -> Bool {
        return true
    }

    required init?(runtime: ExtensionRuntime) {
        self.runtime = runtime
    }

    // MARK: Event Processors
    func wildcardListenerProcessor(_ event: Event) {
        if event.type.lowercased() == TestEventType.INSTRUMENTED_EXTENSION.lowercased() {
            // process the shared state request event
            if event.source.lowercased() == TestEventSource.SHARED_STATE_REQUEST.lowercased() {
                processSharedStateRequest(event)
            }
            // process the unregister extension event
            else if event.source.lowercased() == TestEventSource.UNREGISTER_EXTENSION.lowercased() {
                unregisterExtension()
            }

            return
        }

        // save this event in the receivedEvents dictionary
        if InstrumentedExtension.receivedEvents[EventSpec(type: event.type, source: event.source)] != nil {
            InstrumentedExtension.receivedEvents[EventSpec(type: event.type, source: event.source)]?.append(event)
        } else {
            InstrumentedExtension.receivedEvents[EventSpec(type: event.type, source: event.source)] = [event]
        }

        // count down if this is an expected event
        if InstrumentedExtension.expectedEvents[EventSpec(type: event.type, source: event.source)] != nil {
            InstrumentedExtension.expectedEvents[EventSpec(type: event.type, source: event.source)]?.countDown()
        }

        if event.source == EventSource.sharedState {
            Log.debug(label: InstrumentedExtension.logTag, "Received event with type \(event.type) and source \(event.source), state owner \(event.data?["stateowner"] ?? "unknown")")
        } else {
            Log.debug(label: InstrumentedExtension.logTag, "Received event with type \(event.type) and source \(event.source)")
        }
    }

    /// Process `getSharedStateFor` requests
    /// - Parameter event: event sent from `getSharedStateFor` which specifies the shared state `stateowner` to retrieve
    func processSharedStateRequest(_ event: Event) {
        guard let eventData = event.data, !eventData.isEmpty  else { return }
        guard let owner = eventData[EventDataKey.STATE_OWNER] as? String else { return }

        var responseData: [String: Any?] = [EventDataKey.STATE_OWNER: owner, EventDataKey.STATE: nil]
        if let state = runtime.getSharedState(extensionName: owner, event: event, barrier: false) {
            responseData[EventDataKey.STATE] = state
        }

        let responseEvent = event.createResponseEvent(name: "Get Shared State Response",
                                                      type: TestEventType.INSTRUMENTED_EXTENSION,
                                                      source: TestEventSource.SHARED_STATE_RESPONSE,
                                                      data: responseData as [String: Any])

        Log.debug(label: InstrumentedExtension.logTag, "ProcessSharedStateRequest Responding with shared state \(String(describing: responseData))")

        // dispatch paired response event with shared state data
        MobileCore.dispatch(event: responseEvent)
    }

    func unregisterExtension() {
        Log.debug(label: InstrumentedExtension.logTag, "Unregistering the Instrumented extension from the Event Hub")
        runtime.unregisterExtension()
    }

    static func reset() {
        receivedEvents = ThreadSafeDictionary<EventSpec, [Event]>()
        expectedEvents = ThreadSafeDictionary<EventSpec, CountDownLatch>()
    }
}
