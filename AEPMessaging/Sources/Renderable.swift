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

protocol Renderable {
    /// Plain-text title for the feed item
    var title: String { get }

    /// Plain-text body representing the content for the feed item
    var body: String { get }

    /// String representing a URI that contains an image to be used for this feed item
    var imageUrl: String? { get }

    /// Required if `actionUrl` is provided. Text to be used in title of button or link in feed item
    var actionTitle: String? { get }

    /// Contains a URL to be opened if the user interacts with the feed item
    var actionUrl: String? { get }

    /// Represents when this feed item went live. Represented in seconds since January 1, 1970
    var publishedDate: Int { get }

    /// Should SDK render this feed item.
    func shouldRender() -> Bool
}
