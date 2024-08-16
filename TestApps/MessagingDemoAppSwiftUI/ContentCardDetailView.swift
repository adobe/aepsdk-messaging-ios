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

struct ContentCardDetailView: View {
    @State var contentCardSchemaData: ContentCardSchemaData
    
    var body: some View {
        
        ScrollView {
            VStack {
                Text(contentCardSchemaData.title)
                    .font(.title)
                    .padding(.top, 30)
                CustomImageView(url: contentCardSchemaData.imageUrl ?? "")
                    .frame(width: 350, height: 170)
                    .frame(maxWidth: .infinity)
                Text(contentCardSchemaData.body)
                    .multilineTextAlignment(.center)
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                Button(action: {                    
                    if
                        let actionUrl = contentCardSchemaData.actionUrl,
                        let url = URL(string: actionUrl) {
                        contentCardSchemaData.track("cta clicked", withEdgeEventType: .interact)
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        if let customTitle = contentCardSchemaData.actionTitle, !customTitle.isEmpty {
                            Text(customTitle)
                                .font(.title3)
                        } else {
                            Text("OK")
                                .font(.title3)
                        }
                        
                    }
                    .frame(maxWidth: 150)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.black)
                    .clipShape(Capsule())
                }
            }
        }
    }
}

struct ContentCardDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ContentCardDetailView(contentCardSchemaData: ContentCardSchemaData.getDefaultContentCard()!)
    }
}
