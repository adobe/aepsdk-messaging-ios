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

import Foundation

/// Enum representing content types found within a schema.
@objc(AEPContentType)
public enum ContentType: Int, Codable {
    case applicationJson = 0
    case textHtml = 1
    case textXml = 2
    case textPlain = 3
    case unknown = 4

    /// Initializes ContentType with the provided content type string.
    /// - Parameter contentType: content type string
    init(from contentType: String) {
        switch contentType {
        case MessagingConstants.ContentTypes.APPLICATION_JSON:
            self = .applicationJson

        case MessagingConstants.ContentTypes.TEXT_HTML:
            self = .textHtml

        case MessagingConstants.ContentTypes.TEXT_XML:
            self = .textXml

        case MessagingConstants.ContentTypes.TEXT_PLAIN:
            self = .textPlain

        default:
            self = .unknown
        }
    }

    /// Returns the content schema string of `ContentType`.
    /// - Returns: A string representing the content type.
    public func toString() -> String {
        switch self {
        case .applicationJson:
            return MessagingConstants.ContentTypes.APPLICATION_JSON
        case .textHtml:
            return MessagingConstants.ContentTypes.TEXT_HTML
        case .textXml:
            return MessagingConstants.ContentTypes.TEXT_XML
        case .textPlain:
            return MessagingConstants.ContentTypes.TEXT_PLAIN
        default:
            return ""
        }
    }
}
