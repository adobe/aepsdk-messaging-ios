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

import AEPServices
import SwiftUI

@available(iOS 15.0, *)
class ImageCache {
    private static let cache = Cache(name: MessagingConstants.Caches.UI_CACHE_NAME)

    static subscript(url: URL) -> UIImage? {
        get {
            guard let cacheEntry = cache.get(key: url.absoluteString) else { return nil }
            return UIImage(data: cacheEntry.data)
        }
        set {
            guard let image = newValue, let data = image.pngData() else { return }
            let cacheEntry = CacheEntry(
                data: data,
                expiry: .seconds(MessagingConstants.THIRTY_DAYS_IN_SECONDS),
                metadata: nil
            )
            try? cache.set(key: url.absoluteString, entry: cacheEntry)
        }
    }
}
