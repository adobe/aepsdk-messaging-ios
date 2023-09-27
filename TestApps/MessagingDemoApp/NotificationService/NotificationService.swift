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

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        // defer this block to be executed to call the callback
        defer {
            contentHandler(bestAttemptContent ?? request.content)
        }
        
        guard let attachment = request.adobeAttachment else { return }
        bestAttemptContent?.attachments = [attachment]
        
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}


extension UNNotificationRequest {
    var adobeAttachment: UNNotificationAttachment? {
        // return nil if the notification does not contain a valid value for adb_media key
        guard let attachmentString = content.userInfo["adb_media"] as? String else {
            return nil
        }
        
        // do not attach anything if its not a valid URL
        guard let attachmentURL = URL(string: attachmentString) else {
            return nil
        }
        
        // do not attach anything if the url does not contain downloadable data
        guard let attachmentData = try? Data(contentsOf: attachmentURL) else {
            return nil
        }
        
        return try? UNNotificationAttachment(data: attachmentData, options: nil, attachmentURL: attachmentURL)
    }
}


extension UNNotificationAttachment {
    /// convenience initializer to create a UNNotificationAttachment from a URL
    /// - Parameters:
    ///  - data: the data to be displayed in the notification
    ///  - options : options for the attachment
    ///  - attachmentURL : the URL of the rich media to be displayed in the notification
    convenience init(data: Data, options: [NSObject: AnyObject]?, attachmentURL: URL) throws {
        let fileManager = FileManager.default
        let temporaryFolderURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString,
                                                                                                     isDirectory: true)
        try fileManager.createDirectory(at: temporaryFolderURL, withIntermediateDirectories: true, attributes: nil)
        var attachmentType : String
        
        // determine the attachment type from the url
        // common format are png, jpg, gif, mp3,  mpeg4, avi, mp4
        // Reference Apple documentation for supported file types and maximum size : https://developer.apple.com/documentation/usernotifications/unnotificationattachment
        // sample urls used for testing
        /// jpg : https://picsum.photos/600
        /// gif  : https://media.giphy.com/media/MeJgB3yMMwIaHmKD4z/giphy.gif
        ///
        /// NOTE : Please edit the below code according to the type of rich media notification that your app needs to support
        if ((attachmentURL.host?.contains("media.giphy.com")) != nil) {
            attachmentType = ".gif"
        } else {
            attachmentType = ".jpg"
        }
        
        let attachmentName = UUID().uuidString + attachmentType
        let fileURL = temporaryFolderURL.appendingPathComponent(attachmentName)
        try data.write(to: fileURL)
        try self.init(identifier: attachmentName, url: fileURL, options: options)
    }
    
}
