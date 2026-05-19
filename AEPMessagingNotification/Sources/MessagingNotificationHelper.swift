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

import Foundation
import UserNotifications

/// Lightweight helper for processing rich media in Notification Service Extensions.
/// This class is designed to be used in app extensions and has no dependencies on AEPCore or AEPServices.
@objc(AEPMessagingNotificationHelper)
public final class MessagingNotificationHelper: NSObject {

    /// The key used to look up the media URL in the notification's userInfo dictionary.
    @objc public static let mediaKey = "adb_media"

    // Overridable in unit tests to avoid real network calls.
    static var urlSession: URLSession = .shared

    /// Processes a mutable notification content object by downloading and attaching any media
    /// specified in the AEP payload's `adb_media` field.
    ///
    /// Create the mutable content from `request.content.mutableCopy()` before calling this method.
    /// If the `adb_media` key is absent, the URL is invalid, or the download fails, the content
    /// handler is still called — the notification delivers without a media attachment.
    ///
    /// - Parameters:
    ///   - content: A mutable copy of the notification content.
    ///   - contentHandler: Called with the (possibly enriched) content once the download completes.
    ///
    /// ## Usage
    /// **Swift**
    /// ```swift
    /// MessagingNotificationHelper.processNotificationRequest(with: content, contentHandler: contentHandler)
    /// ```
    ///
    /// **Objective-C**
    /// ```objc
    /// [AEPMessagingNotificationHelper processContent:content withContentHandler:contentHandler];
    /// ```
    @objc(processContent:withContentHandler:)
    public static func processNotificationRequest(
        with content: UNMutableNotificationContent,
        contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        downloadAndAttachMedia(to: content) {
            contentHandler(content)
        }
    }

    // MARK: - Private

    private static let label = "MessagingNotificationHelper"

    private static func downloadAndAttachMedia(to content: UNMutableNotificationContent,
                                               completion: @escaping () -> Void) {
        guard let mediaURLString = content.userInfo[mediaKey] as? String else {
            MessagingLog.debug(label: label, "No media URL found in notification payload — skipping media attachment.")
            completion()
            return
        }

        guard let mediaURL = URL(string: mediaURLString) else {
            MessagingLog.warning(label: label, "Invalid media URL string: \(mediaURLString)")
            completion()
            return
        }

        guard mediaURL.scheme?.lowercased() == "https" else {
            MessagingLog.warning(label: label, "Media URL must use HTTPS. Received scheme: \(mediaURL.scheme ?? "none")")
            completion()
            return
        }

        urlSession.downloadTask(with: mediaURL) { tempURL, response, error in
            defer { completion() }

            if let error = error {
                MessagingLog.error(label: label, "Media download failed: \(error.localizedDescription)")
                return
            }

            guard let tempURL = tempURL else {
                MessagingLog.error(label: label, "Download completed but no file URL was returned.")
                return
            }

            if let httpResponse = response as? HTTPURLResponse,
               !(200 ... 299).contains(httpResponse.statusCode) {
                MessagingLog.warning(label: label, "Media download failed with HTTP status: \(httpResponse.statusCode)")
                return
            }

            let fileExtension = determineFileExtension(from: mediaURL, response: response)
            let destinationURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("aep-media-\(UUID().uuidString).\(fileExtension)")

            do {
                try FileManager.default.copyItem(at: tempURL, to: destinationURL)
                if let attachment = try? UNNotificationAttachment(identifier: "aep-media",
                                                                   url: destinationURL,
                                                                   options: nil) {
                    content.attachments = [attachment]
                    MessagingLog.debug(label: label, "Media attachment added successfully.")
                } else {
                    MessagingLog.error(label: label, "Failed to create UNNotificationAttachment from: \(destinationURL.lastPathComponent)")
                }
            } catch {
                MessagingLog.error(label: label, "Failed to copy downloaded media to destination: \(error.localizedDescription)")
            }
        }.resume()
    }

    private static func determineFileExtension(from url: URL, response: URLResponse?) -> String {
        // Try to get extension from URL path — only accept known supported types
        let pathExtension = (url.path as NSString).pathExtension.lowercased()
        if supportedExtensions.contains(pathExtension) {
            return pathExtension
        }

        // Try to determine from Content-Type header
        if let httpResponse = response as? HTTPURLResponse,
           let contentType = httpResponse.allHeaderFields["Content-Type"] as? String {
            let mimeType = contentType.lowercased().split(separator: ";").first.map(String.init) ?? ""
            if let mapped = mimeTypeToExtension[mimeType] {
                return mapped
            }
        }

        // Default to jpg
        return "jpg"
    }

    // Supported attachment types per Apple documentation:
    // https://developer.apple.com/documentation/usernotifications/unnotificationattachment
    private static let supportedExtensions: Set<String> = [
        "jpg", "jpeg", "png", "gif",
        "mp4", "mpeg4",
        "aif", "aiff", "mp3", "mpeg", "mpg", "wav", "m4a"
    ]

    private static let mimeTypeToExtension: [String: String] = [
        "image/jpeg": "jpg",
        "image/jpg": "jpg",
        "image/png": "png",
        "image/gif": "gif",
        "video/mp4": "mp4",
        "audio/mpeg": "mp3",
        "audio/wav": "wav",
        "audio/aiff": "aiff",
        "audio/x-aiff": "aiff",
        "audio/mp4": "m4a"
    ]
}
