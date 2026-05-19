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

import os.log

/// Internal logger for the AEPMessagingNotification package.
///
/// Uses `os.log` — a system framework with no external dependencies, safe to use
/// inside `UNNotificationServiceExtension` targets where AEPServices is unavailable.
///
/// Mirrors the `Log.debug / .warning / .error` call style used across the AEP SDK.
enum MessagingLog {

    private static let subsystem = "com.adobe.messaging.notification"

    /// Logs a verbose message useful during development and debugging.
    static func debug(label: String, _ message: String) {
        if #available(iOS 14.0, *) {
            Logger(subsystem: subsystem, category: label).debug("\(message, privacy: .public)")
        } else {
            os_log(.debug, log: OSLog(subsystem: subsystem, category: label), "%@", message)
        }
    }

    /// Logs a non-fatal issue that may affect behaviour but allows execution to continue.
    static func warning(label: String, _ message: String) {
        if #available(iOS 14.0, *) {
            Logger(subsystem: subsystem, category: label).warning("\(message, privacy: .public)")
        } else {
            os_log(.default, log: OSLog(subsystem: subsystem, category: label), "%@", message)
        }
    }

    /// Logs a failure that prevented an operation from completing.
    static func error(label: String, _ message: String) {
        if #available(iOS 14.0, *) {
            Logger(subsystem: subsystem, category: label).error("\(message, privacy: .public)")
        } else {
            os_log(.error, log: OSLog(subsystem: subsystem, category: label), "%@", message)
        }
    }
}
