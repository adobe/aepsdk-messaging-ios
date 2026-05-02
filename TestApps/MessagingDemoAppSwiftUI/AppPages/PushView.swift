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
import AEPCore
import AEPEdgeIdentity
import AEPMessaging

struct PushView: View {
    @State private var ECID: String?
    @State private var devicePushToken: String?
    @State private var resetStatus: String?

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
            
            Divider().frame(height: 30)

            VStack(spacing: 12) {
                Text("Identity Reset")
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    resetAndReregister()
                } label: {
                    Text("Reset Identity")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if let status = resetStatus {
                    Text(status)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .onAppear(perform: fetchInfo)
    }

    private func fetchInfo() {
        Identity.getExperienceCloudId { (ecid, error) in
            if let error = error {
                ECID = "Error Reading ECID: \(error.localizedDescription)"
            } else {
                ECID = ecid
            }
        }
        
        devicePushToken = UserDefaults.standard.string(forKey: "devicePushToken")
    }

    private func resetAndReregister() {
        let oldEcid = ECID ?? "unknown"
        resetStatus = "Resetting identities..."

        MobileCore.resetIdentities()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Re-register for remote notifications so the APNs callback
            // fires and setPushIdentifier is called with the device token.
            // Live Activity tokens are automatically re-synced by the SDK.
            UIApplication.shared.registerForRemoteNotifications()

            Identity.getExperienceCloudId { (ecid, error) in
                ECID = ecid
                resetStatus = "Done. ECID changed: \(oldEcid.prefix(8))... -> \(ecid?.prefix(8) ?? "nil")..."
            }
        }
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
