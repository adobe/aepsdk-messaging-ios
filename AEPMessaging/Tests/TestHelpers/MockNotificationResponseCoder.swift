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

import Foundation
import UserNotifications

class MockNotificationResponseCoder: NSCoder {
    private let request: UNNotificationRequest
    private let testIdentifier = "mockIdentifier"
    private enum FieldKey: String {
        case request, originIdentifier, sourceIdentifier, actionIdentifier, notification
    }

    override var allowsKeyedCoding: Bool { true }
    init(with request: UNNotificationRequest) {
        self.request = request
    }

    override func decodeObject(forKey key: String) -> Any? {
        let fieldKey = FieldKey(rawValue: key)
        switch fieldKey {
        case .request:
            return request
        case .sourceIdentifier, .actionIdentifier, .originIdentifier:
            return testIdentifier
        case .notification:
            return UNNotification(coder: self)
        default:
            return nil
        }
    }
}
