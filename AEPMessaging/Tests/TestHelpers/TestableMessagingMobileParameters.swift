/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

@testable import AEPCore
@testable import AEPMessaging
import Foundation

class TestableMobileParameters {
    static let mockWidth = 50
    static let mockHeight = 49
    static let mockVAlign = "bottom"
    static let mockHAlign = "top"
    static let mockVInset = 50
    static let mockHInset = 49
    static let mockUiTakeover = true
    static let mockBackdropColor = "AABBCC"
    static let mockBackdropOpacity = 0.5
    static let mockCornerRadius = 10
    static let mockDisplayAnimation = "left"
    static let mockDismissAnimation = "right"
    static let mockGestures = [
        "swipeDown": "adbinapp://dismiss"
    ]

    static var mobileParameters: [String: Any] {
        [
            MessagingConstants.Event.Data.Key.IAM.WIDTH: mockWidth,
            MessagingConstants.Event.Data.Key.IAM.HEIGHT: mockHeight,
            MessagingConstants.Event.Data.Key.IAM.VERTICAL_ALIGN: mockVAlign,
            MessagingConstants.Event.Data.Key.IAM.VERTICAL_INSET: mockVInset,
            MessagingConstants.Event.Data.Key.IAM.HORIZONTAL_ALIGN: mockHAlign,
            MessagingConstants.Event.Data.Key.IAM.HORIZONTAL_INSET: mockHInset,
            MessagingConstants.Event.Data.Key.IAM.UI_TAKEOVER: mockUiTakeover,
            MessagingConstants.Event.Data.Key.IAM.BACKDROP_COLOR: mockBackdropColor,
            MessagingConstants.Event.Data.Key.IAM.BACKDROP_OPACITY: mockBackdropOpacity,
            MessagingConstants.Event.Data.Key.IAM.CORNER_RADIUS: mockCornerRadius,
            MessagingConstants.Event.Data.Key.IAM.DISPLAY_ANIMATION: mockDisplayAnimation,
            MessagingConstants.Event.Data.Key.IAM.DISMISS_ANIMATION: mockDismissAnimation,
            MessagingConstants.Event.Data.Key.IAM.GESTURES: mockGestures
        ]
    }

    static func getMobileParametersEvent(withData data: [String: Any]? = nil) -> Event {
        var eventData: [String: Any] = [
            MessagingConstants.Event.Data.Key.TRIGGERED_CONSEQUENCE: [
                MessagingConstants.Event.Data.Key.DETAIL: [
                    MessagingConstants.Event.Data.Key.DATA: [
                        "mobileParameters": mobileParameters
                    ]
                ]
            ]
        ]
        if let data = data {
            eventData.merge(data) { _, new in new }
        }

        return Event(name: "Mobile Parameters Event",
                     type: "testType",
                     source: "testSource",
                     data: eventData)
    }
}
