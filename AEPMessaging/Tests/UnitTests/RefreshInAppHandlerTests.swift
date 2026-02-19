/*
 Copyright 2026 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

@testable import AEPMessaging
import XCTest

class RefreshInAppHandlerTests: XCTestCase {
    
    var handler: RefreshInAppHandler!
    
    override func setUp() {
        super.setUp()
        RefreshInAppHandler.shared.reset()
        handler = RefreshInAppHandler.shared
    }
    
    override func tearDown() {
        RefreshInAppHandler.shared.reset()
        handler = nil
        super.tearDown()
    }
    
    // MARK: - Single Request Tests
    
    func testRefresh_singleRequest_completionCalledOnSuccess() {
        // Setup
        let expectation = self.expectation(description: "Completion called")
        var receivedSuccess: Bool?
        
        // Test - call refresh then simulate completion from Messaging extension
        handler.refresh { success in
            receivedSuccess = success
            expectation.fulfill()
        }
        
        // Simulate Messaging extension completing the refresh
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            self.handler.handleRefreshComplete(success: true)
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Verify
        XCTAssertEqual(receivedSuccess, true, "Should receive success")
    }
    
    func testRefresh_singleRequest_completionCalledOnFailure() {
        // Setup
        let expectation = self.expectation(description: "Completion called")
        var receivedSuccess: Bool?
        
        // Test
        handler.refresh { success in
            receivedSuccess = success
            expectation.fulfill()
        }
        
        // Simulate failure
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            self.handler.handleRefreshComplete(success: false)
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Verify
        XCTAssertEqual(receivedSuccess, false, "Should receive failure")
    }
    
    // MARK: - Multiple Concurrent Requests Tests
    
    func testRefresh_multipleConcurrentRequests_allReceiveSameResult() {
        // Setup
        let expectation1 = self.expectation(description: "Completion 1 called")
        let expectation2 = self.expectation(description: "Completion 2 called")
        let expectation3 = self.expectation(description: "Completion 3 called")
        
        var results: [Bool] = []
        let resultsLock = NSLock()
        
        // Test - fire 3 requests in quick succession
        handler.refresh { success in
            resultsLock.lock()
            results.append(success)
            resultsLock.unlock()
            expectation1.fulfill()
        }
        
        handler.refresh { success in
            resultsLock.lock()
            results.append(success)
            resultsLock.unlock()
            expectation2.fulfill()
        }
        
        handler.refresh { success in
            resultsLock.lock()
            results.append(success)
            resultsLock.unlock()
            expectation3.fulfill()
        }
        
        // Simulate single completion from Messaging extension
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
            self.handler.handleRefreshComplete(success: true)
        }
        
        wait(for: [expectation1, expectation2, expectation3], timeout: 2.0)
        
        // Verify - all 3 completions should receive the same result
        XCTAssertEqual(results.count, 3, "All 3 completions should be called")
        XCTAssertTrue(results.allSatisfy { $0 == true }, "All completions should receive success")
    }
    
    func testRefresh_multipleConcurrentRequests_allReceiveFailureOnFailure() {
        // Setup
        let expectation1 = self.expectation(description: "Completion 1 called")
        let expectation2 = self.expectation(description: "Completion 2 called")
        
        var results: [Bool] = []
        let resultsLock = NSLock()
        
        // Test
        handler.refresh { success in
            resultsLock.lock()
            results.append(success)
            resultsLock.unlock()
            expectation1.fulfill()
        }
        
        handler.refresh { success in
            resultsLock.lock()
            results.append(success)
            resultsLock.unlock()
            expectation2.fulfill()
        }
        
        // Simulate failure
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
            self.handler.handleRefreshComplete(success: false)
        }
        
        wait(for: [expectation1, expectation2], timeout: 2.0)
        
        // Verify
        XCTAssertEqual(results.count, 2, "Both completions should be called")
        XCTAssertTrue(results.allSatisfy { $0 == false }, "All completions should receive failure")
    }
    
    // MARK: - Sequential Requests Tests
    
    func testRefresh_sequentialRequests_eachCompletesIndependently() {
        // Setup
        let expectation1 = self.expectation(description: "First request completed")
        let expectation2 = self.expectation(description: "Second request completed")
        
        // Test - first request
        handler.refresh { _ in
            expectation1.fulfill()
        }
        
        // Complete first request
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            self.handler.handleRefreshComplete(success: true)
        }
        
        wait(for: [expectation1], timeout: 1.0)
        
        // Second request after first completes
        handler.refresh { _ in
            expectation2.fulfill()
        }
        
        // Complete second request
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            self.handler.handleRefreshComplete(success: true)
        }
        
        wait(for: [expectation2], timeout: 1.0)
    }
    
    // MARK: - Thread Safety Tests
    
    func testRefresh_concurrentRequestsFromMultipleThreads_noDataRace() {
        // Setup
        let expectations = (0..<10).map { self.expectation(description: "Completion \($0) called") }
        
        // Test - fire requests from multiple threads
        for i in 0..<10 {
            DispatchQueue.global().async {
                self.handler.refresh { _ in
                    expectations[i].fulfill()
                }
            }
        }
        
        // Wait a bit for all requests to be queued, then complete
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
            self.handler.handleRefreshComplete(success: true)
        }
        
        wait(for: expectations, timeout: 2.0)
        // Test passes if no crashes - validates thread safety
    }
    
    // MARK: - No Completion Handler Tests
    
    func testRefresh_noCompletionHandler_doesNotCrash() {
        // Test - call refresh without completion
        handler.refresh()
        
        // Simulate completion
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            self.handler.handleRefreshComplete(success: true)
        }
        
        // Wait to ensure no crash
        let expectation = self.expectation(description: "No crash")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}

