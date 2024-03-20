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

/// represents the schema data object for an html content schema
@objc(AEPHtmlContentSchemaData)
@objcMembers
public class HtmlContentSchemaData: NSObject, Codable {
    public let content: String
    public let format: ContentType?

    enum CodingKeys: String, CodingKey {
        case content
        case format
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        if let decodedFormat = try? values.decode(String.self, forKey: .format) {
            format = ContentType(from: decodedFormat)
        } else {
            format = .textHtml
        }
        content = try values.decode(String.self, forKey: .content)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(format?.toString() ?? ContentType.textHtml.toString(), forKey: .format)
        try container.encode(content, forKey: .content)
    }
}
