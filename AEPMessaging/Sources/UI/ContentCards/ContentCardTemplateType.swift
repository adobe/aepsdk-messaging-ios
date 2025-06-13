/*
 Copyright 2024 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

/// An enumeration representing the types of content card templates.
@available(iOS 15.0, *)
public enum ContentCardTemplateType: String {
    case smallImage = "SmallImage"
    case largeImage = "LargeImage"
    case unknown = "Unknown"

    // Initializer to create an enum case from a string
    init(from string: String) {
        self = ContentCardTemplateType(rawValue: string) ?? .unknown
    }
}
