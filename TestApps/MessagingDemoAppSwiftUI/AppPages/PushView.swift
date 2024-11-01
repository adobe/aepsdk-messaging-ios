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

import SwiftUI
import AEPEdgeIdentity

struct PushView: View {
    @State private var ECID: String?
    @State private var devicePushToken: String?

    var body: some View {
        VStack {
            TabHeader(title: "Push Notification")
            
            Spacer()
            
            InfoSection(title: "Experience Cloud ID", value: ECID ?? "Not Available") {
                UIPasteboard.general.string = ECID
            }
            
            Divider().frame(height: 30)
            
            InfoSection(title: "Push Token", value: devicePushToken ?? "Not Available") {
                UIPasteboard.general.string = devicePushToken
            }
            
            Spacer()
        }
        .padding()
        .onAppear(perform: fetchInfo)
    }

    // Function to fetch ECID and Push Token
    private func fetchInfo() {
        Identity.getExperienceCloudId { (ecid, error) in
            if let error = error {
                ECID = "Error Reading ECID: \(error.localizedDescription)"
            } else {
                ECID = ecid
            }
        }
        
        // Retrieve the device push token from UserDefaults
        devicePushToken = UserDefaults.standard.string(forKey: "devicePushToken")
    }
}

// Reusable view for displaying information with a copy button
struct InfoSection: View {
    var title: String
    var value: String
    var copyAction: () -> Void

    var body: some View {
        HStack() {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                Text(value)
                    .font(.footnote)
            }
            Spacer()
            Button(action: copyAction) {
                Image(systemName: "doc.on.doc")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

#Preview {
    PushView()
}
