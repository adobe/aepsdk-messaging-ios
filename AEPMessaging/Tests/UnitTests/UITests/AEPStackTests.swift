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

import XCTest
import SwiftUI
@testable import AEPMessaging

@available(iOS 15.0, *)
final class AEPStackTests: XCTestCase {

    let mockModel = AEPText([UIConstants.CardTemplate.UIElement.Text.CONTENT: "Text Content"])!

    func testHStack_Init() {
        // test
        let hStack = AEPHStack()

        // verify
        XCTAssertNotNil(hStack)
        XCTAssertNotNil(hStack.view)
    }

    func testHStack_addModel() {
        // test
        let hStack = AEPHStack()
        hStack.addModel(mockModel)

        // verify
        XCTAssertEqual(hStack.childModels.count, 1)
    }

    func testHStack_addView() {
        // test
        let hStack = AEPHStack()
        hStack.addView(Text("Hello"))

        // verify
        XCTAssertEqual(hStack.childModels.count, 1)

        // test again
        hStack.addView(Text("It's me"))

        // verify
        XCTAssertEqual(hStack.childModels.count, 2)
        XCTAssertNotNil(hStack.view)
    }

    func testHStack_removeView() {
        // setup
        let hStack = AEPHStack()
        hStack.addView(Text("Hello"))
        hStack.addView(Text("Hello Again"))

        // verify
        XCTAssertEqual(hStack.childModels.count, 2)

        // test and verify
        XCTAssertNoThrow(try hStack.removeView(at: 1))
        XCTAssertEqual(hStack.childModels.count, 1)

        // test and verify
        XCTAssertNoThrow(try hStack.removeView(at: 0))
        XCTAssertEqual(hStack.childModels.count, 0)
    }

    func testHStack_removeView_outOfBounds() {
        // setup
        let hStack = AEPHStack()
        hStack.addView(Text("Hello"))

        // verify
        XCTAssertEqual(hStack.childModels.count, 1)

        // test and verify
        XCTAssertThrowsError(try hStack.removeView(at: 1)) { error in
            XCTAssertEqual(error as? AEPStackError, AEPStackError.indexOutOfBounds)
        }
        
        // verify state after attempted removal
        XCTAssertEqual(hStack.childModels.count, 1)
    }

    func testHStack_insertView() {
        // setup
        let hStack = AEPHStack()
        hStack.addView(Text("Hello"))
        hStack.addView(Text("It's me"))

        // verify
        XCTAssertEqual(hStack.childModels.count, 2)

        // test and verify
        XCTAssertNoThrow(try hStack.insertView(Text("I was wondering"), at: 1))
        XCTAssertEqual(hStack.childModels.count, 3)
    }

    func testHStack_insertView_outOfBounds() {
        // setup
        let hStack = AEPHStack()
        hStack.addView(Text("Hello"))

        // verify
        XCTAssertEqual(hStack.childModels.count, 1)

        // test and verify
        XCTAssertThrowsError(try hStack.insertView(Text("It's me"), at: 2)) { error in
            XCTAssertEqual(error as? AEPStackError, AEPStackError.indexOutOfBounds)
        }
        
        // verify state after attempted removal
        XCTAssertEqual(hStack.childModels.count, 1)
    }

    func testVStack_Init() {
        // test
        let vStack = AEPVStack()

        // verify
        XCTAssertNotNil(vStack)
        XCTAssertNotNil(vStack.view)
    }

    func testVStack_addModel() {
        // test
        let vStack = AEPVStack()
        vStack.addModel(mockModel)

        // verify
        XCTAssertEqual(vStack.childModels.count, 1)
    }

    func testVStack_addView() {
        // test
        let vStack = AEPVStack()
        vStack.addView(Text("Hello"))

        // verify
        XCTAssertEqual(vStack.childModels.count, 1)

        // test again
        vStack.addView(Text("It's me"))

        // verify
        XCTAssertEqual(vStack.childModels.count, 2)
        XCTAssertNotNil(vStack.view)
    }

    func testVStack_removeView() {
        // setup
        let vStack = AEPVStack()
        vStack.addView(Text("Hello"))
        vStack.addView(Text("Hello Again"))

        // verify
        XCTAssertEqual(vStack.childModels.count, 2)

        // test and verify
        XCTAssertNoThrow(try vStack.removeView(at: 1))
        
        XCTAssertEqual(vStack.childModels.count, 1)

        // test and verify
        XCTAssertNoThrow(try vStack.removeView(at: 0))
        XCTAssertEqual(vStack.childModels.count, 0)
    }
}
