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

import AEPMessaging
import Foundation

extension ContentCardSchemaData {
    var title: String {
        contentDictionary["title"] as? String ?? "defaultTitle"
    }
    
    var body: String {
        contentDictionary["body"] as? String ?? "defaultTitle"
    }
    
    var imageUrl: String? {
        contentDictionary["imageUrl"] as? String
    }
    
    var actionUrl: String? {
        contentDictionary["actionUrl"] as? String
    }
    
    var actionTitle: String? {
        contentDictionary["actionTitle"] as? String
    }
    
    class func getDefaultContentCard() -> ContentCardSchemaData? {
        let testCard = #"""
        {
            "expiryDate": 1723163897,
            "meta": {
                "feedName": "testFeed",
                "campaignName": "testCampaign",
                "surface": "mobileapp://com.feeds.testing/feeds/apifeed"
            },
            "content": {
                "title": "Guacamole!",
                "body": "I'm the queen of Nacho Picchu and I'm really glad to meet you. To spice up this big tortilla chip, I command you to find a big dip.",
                "imageUrl": "https://d14dq8eoa1si34.cloudfront.net/2a6ef2f0-1167-11eb-88c6-b512a5ef09a7/urn:aaid:aem:d4b77a01-610a-4c3f-9be6-5ebe1bd13da3/oak:1.0::ci:fa54b394b6f987d974d8619833083519/8933c829-3ab2-38e8-a1ee-00d4f562fff8",
                "actionUrl": "https://luma.com/guacamolethemusical",
                "actionTitle": "guacamole!"
            },
            "contentType": "application/json",
            "publishedDate": 1691541497
        }
        """#
        let decoder = JSONDecoder()
        let contentCardData = testCard.data(using: .utf8)!
        guard let contentCard = try? decoder.decode(ContentCardSchemaData.self, from: contentCardData) else {
            return nil
        }
        return contentCard
    }
    
    private var contentDictionary: [String: Any] {
        content as? [String: Any] ?? [:]
    }
}
