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

import Foundation
import XCTest

@testable import AEPMessaging
import AEPServices

class SurfaceTests: XCTestCase {
    
    let mockAppSurface = "mobileapp://com.apple.dt.xctest.tool"
    
    func testSurfaceHappy() {
        // test
        let surface = Surface(path: "myTestView")
        
        // verify
        XCTAssertEqual("\(mockAppSurface)/myTestView", surface.uri)
        XCTAssertTrue(surface.isValid)
    }
    
    func testSurfaceUriHappy() {
        let myAppSurface = "myProtocol://com.my.bundle.id/myView"
        
        // test
        let surface = Surface(uri: myAppSurface)
        
        // verify
        XCTAssertEqual(myAppSurface, surface.uri)
        XCTAssertTrue(surface.isValid)
    }
    
    func testSurfaceEmptyPath() {
        // test
        let surface = Surface(path: "")
        
        // verify
        XCTAssertEqual(mockAppSurface, surface.uri)
    }
    
    func testSurfaceIsEqual() {
        // test
        let surface1 = Surface()
        let surface2 = Surface()
        
        // verify
        XCTAssertTrue(surface1.isEqual(surface2))
        XCTAssertEqual(surface1, surface2)
    }
    
    func testSurfaceIsEqualDifferentSurfaces() {
        // test
        let surface1 = Surface(path: "myTestView")
        let surface2 = Surface()
        
        // verify
        XCTAssertFalse(surface1.isEqual(surface2))
        XCTAssertNotEqual(surface1, surface2)
    }
    
    func testSurfaceIsEqualNotValidSurface() {
        // test
        let surface = Surface()
        let notASurface = ["path": "myTestView"] as? Any
        
        // verify
        XCTAssertFalse(surface.isEqual(notASurface))
    }
}
