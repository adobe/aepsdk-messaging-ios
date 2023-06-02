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

@testable import AEPServices
import Foundation
import XCTest

class TestableMessagingDelegate : MessagingDelegate {
    var expectation: XCTestExpectation
    
    init(expectation: XCTestExpectation) {
        self.expectation = expectation
    }
    
    var onShowCalled = false
    var onShowParam: AEPServices.Showable?
    func onShow(message: AEPServices.Showable) {
        onShowCalled = true
        onShowParam = message
        expectation.fulfill()
    }
    
    var onDismissCalled = false
    var onDismissParam: AEPServices.Showable?
    func onDismiss(message: AEPServices.Showable) {
        onDismissCalled = true
        onDismissParam = message
        expectation.fulfill()
    }
    
    var shouldShowMessageCalled = false
    var shouldShowMessageReturnValue = true
    var shouldShowMessageParam: AEPServices.Showable?
    func shouldShowMessage(message: AEPServices.Showable) -> Bool {
        shouldShowMessageCalled = true
        shouldShowMessageParam = message
        expectation.fulfill()
        return shouldShowMessageReturnValue
    }
    
}
