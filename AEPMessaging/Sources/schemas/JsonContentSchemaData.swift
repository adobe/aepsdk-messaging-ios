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

import AEPServices
import Foundation

/// represents the schema data object for a json content schema
@objc(AEPJsonContentSchemaData)
@objcMembers
public class JsonContentSchemaData: NSObject, Codable {
    public let content: Any
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
            format = .applicationJson
        }

        // TODO: core team is adding support for converting [AnyCodable] to [Any]
        // we'll need to update this condition to be less awkward when that's released
        if let _ = try? values.decode([AnyCodable].self, forKey: .content) {
            let codableAny = try values.decode(AnyCodable.self, forKey: .content)
            content = codableAny.arrayValue ?? []
        } else if let codableDictionary = try? values.decode([String: AnyCodable].self, forKey: .content) {
            content = AnyCodable.toAnyDictionary(dictionary: codableDictionary) ?? [:]
        } else {
            content = [:]
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(format?.toString() ?? ContentType.applicationJson.toString(), forKey: .format)

        if isArray {
            try container.encode(AnyCodable(getArrayValue), forKey: .content)
        } else if isDictionary {
            try container.encode(AnyCodable.from(dictionary: getDictionaryValue), forKey: .content)
        }
    }
}

public extension JsonContentSchemaData {
    var isArray: Bool {
        content as? [Any] != nil
    }

    var isDictionary: Bool {
        content as? [String: Any] != nil
    }

    var getArrayValue: [Any]? {
        content as? [Any]
    }

    var getDictionaryValue: [String: Any]? {
        content as? [String: Any]
    }
}
