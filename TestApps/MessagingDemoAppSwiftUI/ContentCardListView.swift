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
import SwiftUI

struct ContentCardListView: View {
    @State var contentCard: ContentCard
    
    var body: some View {
        HStack(spacing: 10) {
            CustomImageView(url: contentCard.imageUrl ?? "")
                .frame(width: 100, height: 100)
            VStack(alignment: .leading) {
                Text(contentCard.title)
                    .font(.headline)
                Text(contentCard.body)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer()
        }
    }
}

struct ContentCardListView_Previews: PreviewProvider {
    static var previews: some View {
        ContentCardListView(contentCard: ContentCard(
                        title: "Flash spring sale!",
                        body: "All hiking gear is now up to 30% off at checkout.",
                        imageUrl: "https://d14dq8eoa1si34.cloudfront.net/2a6ef2f0-1167-11eb-88c6-b512a5ef09a7/urn:aaid:aem:cd6f726b-ea5a-4308-b1ee-7a8dd1488020/oak:1.0::ci:4363a82474f25c79f2588786cd82e3b2/dd2c2c8e-bd5c-3116-8a7a-e85c2c54549f",
                        actionUrl: "https://luma.com/springsale",
                        actionTitle: "Shop the sale!"))
    }
}
