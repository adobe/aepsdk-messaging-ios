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
import AEPServices
import Foundation
import XCTest

/// Struct defining the event specifications - contains the event type and source
struct EventSpec {
    let type: String
    let source: String
}

/// Hashable `EventSpec`, to be used as key in Dictionaries
extension EventSpec: Hashable & Equatable {

    static func == (lhs: EventSpec, rhs: EventSpec) -> Bool {
        return lhs.source.lowercased() == rhs.source.lowercased() && lhs.type.lowercased() == rhs.type.lowercased()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(source)
    }
}

class FunctionalTestBase: XCTestCase {
    
    /// Use this property to execute code logic in the first run in this test class; this value changes to False after the parent tearDown is executed
    private(set) static var isFirstRun: Bool = true
    /// Use this setting to enable debug mode logging in the `FunctionalTestBase`
    static var debugEnabled = false
    
    static let WAIT_EVENT_TIMEOUT: TimeInterval = 2
    static let WAIT_SHARED_STATE_TIMEOUT: TimeInterval = 3
    static let WAIT_NETWORK_REQUEST_TIMEOUT: TimeInterval = 2
    static let WAIT_TIMEOUT: UInt32 = 1 // used when no expectation is set
    
    private enum EventType {
        static let INSTRUMENTED_EXTENSION = "com.adobe.eventType.instrumentedExtension"
    }
    
    private enum EventSource {
        static let SHARED_STATE_REQUEST = "com.adobe.eventSource.requestState"
        static let UNREGISTER_EXTENSION = "com.adobe.eventSource.unregisterExtension"
    }

    public class override func setUp() {
        super.setUp()
        UserDefaults.clearAll()
        FileManager.default.clearCache()
        MobileCore.setLogLevel(LogLevel.trace)
    }

    public override func setUp() {
        super.setUp()
        continueAfterFailure = false
        MobileCore.registerExtension(InstrumentedExtension.self)
    }

    public override func tearDown() {
        super.tearDown()

        // to revisit when AMSDK-10169 is available
        // wait .2 seconds in case there are unexpected events that were in the dispatch process during cleanup
        usleep(200000)
        resetTestExpectations()
        FunctionalTestBase.isFirstRun = false
        EventHub.reset()
        UserDefaults.clearAll()
        FileManager.default.clearCache()
    }

    /// Reset event and network request expectations and drop the items received until this point
    func resetTestExpectations() {
        log("Resetting functional test expectations for events and network requests")
        InstrumentedExtension.reset()
    }

    /// Unregisters the `InstrumentedExtension` from the Event Hub. This method executes asynchronous.
    func unregisterInstrumentedExtension() {
        let event = Event(name: "Unregister Instrumented Extension",
                          type: EventType.INSTRUMENTED_EXTENSION,
                          source: EventSource.UNREGISTER_EXTENSION,
                          data: nil)

        MobileCore.dispatch(event: event)
    }

    // MARK: Expected/Unexpected events assertions

    /// Sets an expectation for a specific event type and source and how many times the event should be dispatched
    /// - Parameters:
    ///   - type: the event type as a `String`, should not be empty
    ///   - source: the event source as a `String`, should not be empty
    ///   - count: the number of times this event should be dispatched, but default it is set to 1
    /// - See also:
    ///   - assertExpectedEvents(ignoreUnexpectedEvents:)
    func setExpectationEvent(type: String, source: String, expectedCount: Int32 = 1) {
        guard expectedCount > 0 else {
            assertionFailure("Expected event count should be greater than 0")
            return
        }
        guard !type.isEmpty, !source.isEmpty else {
            assertionFailure("Expected event type and source should be non-empty trings")
            return
        }

        InstrumentedExtension.expectedEvents[EventSpec(type: type, source: source)] = CountDownLatch(expectedCount)
    }

    /// Asserts if all the expected events were received and fails if an unexpected event was seen
    /// - Parameters:
    ///   - ignoreUnexpectedEvents: if set on false, an assertion is made on unexpected events, otherwise the unexpected events are ignored
    /// - See also:
    ///   - setExpectationEvent(type: source: count:)
    ///   - assertUnexpectedEvents()
    func assertExpectedEvents(ignoreUnexpectedEvents: Bool = false, file: StaticString = #file, line: UInt = #line) {
        guard InstrumentedExtension.expectedEvents.count > 0 else { // swiftlint:disable:this empty_count
            assertionFailure("There are no event expectations set, use this API after calling setExpectationEvent", file: file, line: line)
            return
        }

        let currentExpectedEvents = InstrumentedExtension.expectedEvents.shallowCopy
        for expectedEvent in currentExpectedEvents {
            let waitResult = expectedEvent.value.await(timeout: FunctionalTestBase.WAIT_EVENT_TIMEOUT)
            let expectedCount: Int32 = expectedEvent.value.getInitialCount()
            let receivedCount: Int32 = expectedEvent.value.getInitialCount() - expectedEvent.value.getCurrentCount()
            XCTAssertFalse(waitResult == DispatchTimeoutResult.timedOut, "Timed out waiting for event type \(expectedEvent.key.type) and source \(expectedEvent.key.source), expected \(expectedCount), but received \(receivedCount)", file: (file), line: line)
            XCTAssertEqual(expectedCount, receivedCount, "Expected \(expectedCount) event(s) of type \(expectedEvent.key.type) and source \(expectedEvent.key.source), but received \(receivedCount)", file: (file), line: line)
        }

        guard ignoreUnexpectedEvents == false else { return }
        assertUnexpectedEvents(file: file, line: line)
    }

    /// Asserts if any unexpected event was received. Use this method to verify the received events are correct when setting event expectations.
    /// - See also: setExpectationEvent(type: source: count:)
    func assertUnexpectedEvents(file: StaticString = #file, line: UInt = #line) {
        wait()
        var unexpectedEventsReceivedCount = 0
        var unexpectedEventsAsString = ""

        let currentReceivedEvents = InstrumentedExtension.receivedEvents.shallowCopy
        for receivedEvent in currentReceivedEvents {

            // check if event is expected and it is over the expected count
            if let expectedEvent = InstrumentedExtension.expectedEvents[EventSpec(type: receivedEvent.key.type, source: receivedEvent.key.source)] {
                _ = expectedEvent.await(timeout: FunctionalTestBase.WAIT_EVENT_TIMEOUT)
                let expectedCount: Int32 = expectedEvent.getInitialCount()
                let receivedCount: Int32 = expectedEvent.getInitialCount() - expectedEvent.getCurrentCount()
                XCTAssertEqual(expectedCount, receivedCount, "Expected \(expectedCount) events of type \(receivedEvent.key.type) and source \(receivedEvent.key.source), but received \(receivedCount)", file: (file), line: line)
            }
            // check for events that don't have expectations set
            else {
                unexpectedEventsReceivedCount += receivedEvent.value.count
                unexpectedEventsAsString.append("(\(receivedEvent.key.type), \(receivedEvent.key.source), \(receivedEvent.value.count)),")
                log("Received unexpected event with type: \(receivedEvent.key.type) source: \(receivedEvent.key.source)")
            }
        }

        XCTAssertEqual(0, unexpectedEventsReceivedCount, "Received \(unexpectedEventsReceivedCount) unexpected event(s): \(unexpectedEventsAsString)", file: (file), line: line)
    }

    /// To be revisited once AMSDK-10169 is implemented
    /// - Parameters:
    ///   - timeout:how long should this method wait, in seconds; by default it waits up to 1 second
    func wait(_ timeout: UInt32? = WAIT_TIMEOUT) {
        if let timeout = timeout {
            sleep(timeout)
        }
    }

    /// Returns the `ACPExtensionEvent`(s) dispatched through the Event Hub, or empty if none was found.
    /// Use this API after calling `setExpectationEvent(type:source:count:)` to wait for the right amount of time
    /// - Parameters:
    ///   - type: the event type as in the expectation
    ///   - source: the event source as in the expectation
    ///   - timeout: how long should this method wait for the expected event, in seconds; by default it waits up to 1 second
    /// - Returns: list of events with the provided `type` and `source`, or empty if none was dispatched
    func getDispatchedEventsWith(type: String, source: String, timeout: TimeInterval = WAIT_EVENT_TIMEOUT, file: StaticString = #file, line: UInt = #line) -> [Event] {
        if InstrumentedExtension.expectedEvents[EventSpec(type: type, source: source)] != nil {
            let waitResult = InstrumentedExtension.expectedEvents[EventSpec(type: type, source: source)]?.await(timeout: timeout)
            XCTAssertFalse(waitResult == DispatchTimeoutResult.timedOut, "Timed out waiting for event type \(type) and source \(source)", file: file, line: line)
        } else {
            wait(FunctionalTestBase.WAIT_TIMEOUT)
        }
        return InstrumentedExtension.receivedEvents[EventSpec(type: type, source: source)] ?? []
    }

    /// Synchronous call to get the shared state for the specified `stateOwner`. This API throws an assertion failure in case of timeout.
    /// - Parameter ownerExtension: the owner extension of the shared state (typically the name of the extension)
    /// - Parameter timeout: how long should this method wait for the requested shared state, in seconds; by default it waits up to 3 second
    /// - Returns: latest shared state of the given `stateOwner` or nil if no shared state was found
    func getSharedStateFor(_ ownerExtension: String, timeout: TimeInterval = WAIT_SHARED_STATE_TIMEOUT) -> [AnyHashable: Any]? {
        log("GetSharedState for \(ownerExtension)")
        let event = Event(name: "Get Shared State",
                          type: EventType.INSTRUMENTED_EXTENSION,
                          source: EventSource.SHARED_STATE_REQUEST,
                          data: ["stateowner": ownerExtension])

        var returnedState: [AnyHashable: Any]?

        let expectation = XCTestExpectation(description: "Shared state data returned")
        MobileCore.dispatch(event: event, responseCallback: { event in

            if let eventData = event?.data {
                returnedState = eventData["state"] as? [AnyHashable: Any]
            }
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: timeout)
        return returnedState
    }
    
    
    /// Print message to console if `FunctionalTestBase.debug` is true
    /// - Parameter message: message to log to console
    func log(_ message: String) {
        FunctionalTestBase.log(message)
    }

    /// Print message to console if `FunctionalTestBase.debug` is true
    /// - Parameter message: message to log to console
    static func log(_ message: String) {
        guard !message.isEmpty && FunctionalTestBase.debugEnabled else { return }
        print("FunctionalTestBase - \(message)")
    }
}
