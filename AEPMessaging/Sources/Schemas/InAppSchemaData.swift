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

/// represents the schema data object for an in-app schema
@objc(AEPInAppSchemaData)
@objcMembers
public class InAppSchemaData: NSObject, Codable {
    /// Represents the content of the InAppSchemaData object.  Its value's type is determined by `contentType`.
    public let content: Any

    /// Determines the value type of `content`.
    public let contentType: ContentType

    /// Date and time this in-app campaign was published represented as epoch seconds
    public let publishedDate: Int?

    /// Date and time this in-app campaign will expire represented as epoch seconds
    public let expiryDate: Int?

    /// Dictionary containing any additional meta data for this content card
    public let meta: [String: Any]?

    /// Dictionary containing parameters that help control display and behavior of the in-app message on mobile
    public let mobileParameters: [String: Any]?

    /// Dictionary containing parameters that help control display and behavior of the in-app message on web
    public let webParameters: [String: Any]?

    /// Array of remote assets to be downloaded and cached for future use with the in-app message
    public let remoteAssets: [String]?

    enum CodingKeys: String, CodingKey {
        case content
        case contentType
        case publishedDate
        case expiryDate
        case meta
        case mobileParameters
        case webParameters
        case remoteAssets
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        contentType = try ContentType(from: values.decode(String.self, forKey: .contentType))

        if contentType == .applicationJson {
            if let _ = try? values.decode([AnyCodable].self, forKey: .content) {
                let codableAny = try values.decode(AnyCodable.self, forKey: .content)
                content = codableAny.arrayValue ?? []
            } else {
                let codableDictionary = try values.decode([String: AnyCodable].self, forKey: .content)
                content = AnyCodable.toAnyDictionary(dictionary: codableDictionary) ?? [:]
            }
        } else {
            content = try values.decode(String.self, forKey: .content)
        }

        publishedDate = try? values.decode(Int.self, forKey: .publishedDate)
        expiryDate = try? values.decode(Int.self, forKey: .expiryDate)
        let codableMeta = try? values.decode([String: AnyCodable].self, forKey: .meta)
        meta = AnyCodable.toAnyDictionary(dictionary: codableMeta)
        let codableMobileParams = try? values.decode([String: AnyCodable].self, forKey: .mobileParameters)
        mobileParameters = AnyCodable.toAnyDictionary(dictionary: codableMobileParams)
        let codableWebParams = try? values.decode([String: AnyCodable].self, forKey: .webParameters)
        webParameters = AnyCodable.toAnyDictionary(dictionary: codableWebParams)
        remoteAssets = try? values.decode([String].self, forKey: .remoteAssets)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(contentType.toString(), forKey: .contentType)
        if contentType == .applicationJson {
            if let arrayValue = getArrayValue {
                try container.encode(AnyCodable(arrayValue), forKey: .content)
            } else if let dictionaryValue = getDictionaryValue {
                try container.encode(AnyCodable.from(dictionary: dictionaryValue), forKey: .content)
            }
        } else {
            try container.encode(content as? String, forKey: .content)
        }
        try container.encode(publishedDate, forKey: .publishedDate)
        try container.encode(expiryDate, forKey: .expiryDate)
        try container.encode(AnyCodable.from(dictionary: meta), forKey: .meta)
        try container.encode(AnyCodable.from(dictionary: mobileParameters), forKey: .mobileParameters)
        try container.encode(AnyCodable.from(dictionary: webParameters), forKey: .webParameters)
        try container.encode(remoteAssets, forKey: .remoteAssets)
    }
}

extension InAppSchemaData {
    var getArrayValue: [Any]? {
        content as? [Any]
    }

    var getDictionaryValue: [String: Any]? {
        content as? [String: Any]
    }
}

extension InAppSchemaData {
    func getMessageSettings(with parent: Any?) -> MessageSettings {
        guard let mobileParameters = mobileParameters else {
            return MessageSettings(parent: parent)
        }

        let vAlign = mobileParameters[MessagingConstants.Event.Data.Key.IAM.VERTICAL_ALIGN] as? String
        let hAlign = mobileParameters[MessagingConstants.Event.Data.Key.IAM.HORIZONTAL_ALIGN] as? String
        var opacity: CGFloat?
        if let opacityDouble = mobileParameters[MessagingConstants.Event.Data.Key.IAM.BACKDROP_OPACITY] as? Double {
            opacity = CGFloat(opacityDouble)
        }
        var cornerRadius: CGFloat?
        if let cornerRadiusInt = mobileParameters[MessagingConstants.Event.Data.Key.IAM.CORNER_RADIUS] as? Int {
            cornerRadius = CGFloat(cornerRadiusInt)
        }
        let displayAnimation = mobileParameters[MessagingConstants.Event.Data.Key.IAM.DISPLAY_ANIMATION] as? String
        let dismissAnimation = mobileParameters[MessagingConstants.Event.Data.Key.IAM.DISMISS_ANIMATION] as? String
        var gestures: [MessageGesture: URL]?
        if let gesturesMap = mobileParameters[MessagingConstants.Event.Data.Key.IAM.GESTURES] as? [String: String] {
            gestures = [:]
            for gesture in gesturesMap {
                if let gestureEnum = MessageGesture.fromString(gesture.key), let url = URL(string: gesture.value) {
                    gestures?[gestureEnum] = url
                }
            }
        }

        let settings = MessageSettings(parent: parent)
            .setWidth(mobileParameters[MessagingConstants.Event.Data.Key.IAM.WIDTH] as? Int)
            .setMaxWidth(mobileParameters[MessagingConstants.Event.Data.Key.IAM.MAX_WIDTH] as? Int)
            .setHeight(mobileParameters[MessagingConstants.Event.Data.Key.IAM.HEIGHT] as? Int)
            .setVerticalAlign(MessageAlignment.fromString(vAlign ?? "center"))
            .setVerticalInset(mobileParameters[MessagingConstants.Event.Data.Key.IAM.VERTICAL_INSET] as? Int)
            .setHorizontalAlign(MessageAlignment.fromString(hAlign ?? "center"))
            .setHorizontalInset(mobileParameters[MessagingConstants.Event.Data.Key.IAM.HORIZONTAL_INSET] as? Int)
            .setUiTakeover(mobileParameters[MessagingConstants.Event.Data.Key.IAM.UI_TAKEOVER] as? Bool ?? true)
            .setFitToContent(mobileParameters[MessagingConstants.Event.Data.Key.IAM.FIT_TO_CONTENT] as? Bool ?? false)
            .setBackdropColor(mobileParameters[MessagingConstants.Event.Data.Key.IAM.BACKDROP_COLOR] as? String)
            .setBackdropOpacity(opacity)
            .setCornerRadius(cornerRadius)
            .setDisplayAnimation(MessageAnimation.fromString(displayAnimation ?? "none"))
            .setDismissAnimation(MessageAnimation.fromString(dismissAnimation ?? "none"))
            .setGestures(gestures)
        return settings
    }
}
