/*
Copyright 2022 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/
    
import AEPAssurance
import AEPOptimize

import SwiftUI

struct SettingsView: View {
    @State private var assuranceSessionURL = ""
    @EnvironmentObject var targetSettings: TargetSettings
    
    @State private var mboxDictRows: UInt = 1
    @State private var profileDictRows: UInt = 1
    
    var body: some View {
        VStack {
            HeaderView(text: "Settings")
            Form {
                Section(header: Text("AEP Assurance Start URL")) {
                    TextField("Enter Assurance start URL", text: $assuranceSessionURL)
                        .onChange(of: assuranceSessionURL) {
                            if let url = URL(string: $0) {
                                Assurance.startSession(url: url)
                            }
                        }
                }
                
                Section(header: Text("AEPOptimize - Target")) {
                    TextField("Enter Target Mbox", text: $targetSettings.targetMbox)
                        .autocapitalization(.none)
                    
                    Group {
                        Text("Target Parameters - Mbox")
                            .frame(maxWidth: .infinity)
                            .padding(7)
                        ForEach(0 ..< mboxDictRows, id: \.self) { _ in
                            DictionaryRowView(dict: $targetSettings.mboxParameters,
                                              dictRows: $mboxDictRows)
                        }
                    }
                    
                    Group {
                        Text("Target Parameters - Profile")
                            .frame(maxWidth: .infinity)
                            .padding(7)
                        ForEach(0 ..< profileDictRows, id: \.self) { _ in
                            DictionaryRowView(dict:$targetSettings.profileParameters,
                                              dictRows: $profileDictRows)
                        }
                    }
                    
                    Group {
                        Text("Target Parameters - Order")
                            .frame(maxWidth: .infinity)
                            .padding(7)
                        TextField("Enter Order Id", text: $targetSettings.order.orderId)
                        TextField("Enter Order Total", text: $targetSettings.order.orderTotal)
                        TextField("Enter Purchased Product Ids (comma-separated)", text: $targetSettings.order.purchasedProductIds)
                    }
                    
                    Group {
                        Text("Target Parameters - Product")
                            .frame(maxWidth: .infinity)
                            .padding(7)
                        TextField("Enter Product Id", text: $targetSettings.product.productId)
                        TextField("Enter Product Category Id", text: $targetSettings.product.categoryId)
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
//* Optimize Tutorial: CODE SECTION 10/10 BEGINS
                        Text(Optimize.extensionVersion)
// Optimize Tutorial: CODE SECTION 10 ENDS */
                    }
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(TargetSettings())
    }
}
