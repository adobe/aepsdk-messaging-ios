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

/// The ImageSourceType enum is used to identify the source type of an image in the AEPImage model.
@available(iOS 15.0, *)
enum ImageSourceType {
    /// Indicates that the image is sourced from a URL.
    case url

    /// Indicates that the image is sourced from a bundled resource within the app
    case bundle

    /// Indicates that the image is sourced from SF Symbols
    case icon
}
