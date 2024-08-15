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
    @State var contentCardSchemaData: ContentCardSchemaData
    
    var body: some View {
        HStack(spacing: 10) {
            CustomImageView(url: contentCardSchemaData.imageUrl ?? "")
                .frame(width: 100, height: 100)
            VStack(alignment: .leading) {
                Text(contentCardSchemaData.title)
                    .font(.headline)
                Text(contentCardSchemaData.body)
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
        ContentCardListView(contentCardSchemaData: ContentCardSchemaData.getDefaultContentCard()!)
    }
}
