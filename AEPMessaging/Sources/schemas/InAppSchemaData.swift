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
    public let content: Any
    public let contentType: ContentType
    public let publishedDate: Int?
    public let expiryDate: Int?
    public let meta: [String: Any]?
    public let mobileParameters: [String: Any]?
    public let webParameters: [String: Any]?
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
        
        contentType = ContentType(from: try values.decode(String.self, forKey: .contentType))
        if contentType == .applicationJson {
            let codableContent = try values.decode([String: AnyCodable].self, forKey: .content)
            content = AnyCodable.toAnyDictionary(dictionary: codableContent) ?? [:]
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
            try container.encode(AnyCodable.from(dictionary: content as? [String: Any]), forKey: .content)
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
    func getMessageSettings(with parent: Any?) -> MessageSettings {
        guard let mobileParameters = mobileParameters else {
            return MessageSettings(parent: parent)
        }
        
        let vAlign = mobileParameters[MessagingConstants.Event.Data.Key.IAM.VERTICAL_ALIGN] as? String
        let hAlign = mobileParameters[MessagingConstants.Event.Data.Key.IAM.HORIZONTAL_ALIGN] as? String
        var opacity: CGFloat? = nil
        if let opacityDouble = mobileParameters[MessagingConstants.Event.Data.Key.IAM.BACKDROP_OPACITY] as? Double {
            opacity = CGFloat(opacityDouble)
        }
        var cornerRadius: CGFloat? = nil
        if let cornerRadiusInt = mobileParameters[MessagingConstants.Event.Data.Key.IAM.CORNER_RADIUS] as? Int {
            cornerRadius = CGFloat(cornerRadiusInt)
        }
        let displayAnimation = mobileParameters[MessagingConstants.Event.Data.Key.IAM.DISPLAY_ANIMATION] as? String
        let dismissAnimation = mobileParameters[MessagingConstants.Event.Data.Key.IAM.DISMISS_ANIMATION] as? String
        var gestures: [MessageGesture: URL]? = nil
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
            .setHeight(mobileParameters[MessagingConstants.Event.Data.Key.IAM.HEIGHT] as? Int)
            .setVerticalAlign(MessageAlignment.fromString(vAlign ?? "center"))
            .setVerticalInset(mobileParameters[MessagingConstants.Event.Data.Key.IAM.VERTICAL_INSET] as? Int)
            .setHorizontalAlign(MessageAlignment.fromString(hAlign ?? "center"))
            .setHorizontalInset(mobileParameters[MessagingConstants.Event.Data.Key.IAM.HORIZONTAL_INSET] as? Int)
            .setUiTakeover(mobileParameters[MessagingConstants.Event.Data.Key.IAM.UI_TAKEOVER] as? Bool ?? true)
            .setBackdropColor(mobileParameters[MessagingConstants.Event.Data.Key.IAM.BACKDROP_COLOR] as? String)
            .setBackdropOpacity(opacity)
            .setCornerRadius(cornerRadius)
            .setDisplayAnimation(MessageAnimation.fromString(displayAnimation ?? "none"))
            .setDismissAnimation(MessageAnimation.fromString(dismissAnimation ?? "none"))
            .setGestures(gestures)
        return settings
        
    }
}
