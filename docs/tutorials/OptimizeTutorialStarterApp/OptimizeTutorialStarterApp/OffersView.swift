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
import AEPCore
import AEPEdgeIdentity
import AEPOptimize
import SwiftUI

import Foundation

struct OffersView: View {
    @EnvironmentObject var targetSettings: TargetSettings
    @ObservedObject var propositions: Propositions
    
    @State private var errorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack {
            HeaderView(text: "Welcome to AEPOptimize Demo")
            List {
                Section(header: Text("Target Offers")) {
                    if let targetProposition = propositions.targetProposition,
                       !targetProposition.offers.isEmpty {
/* Optimize Tutorial: CODE SECTION 9/10 BEGINS
                        ForEach(targetProposition.offers, id: \.self) { offer in
                            if offer.type == OfferType.html {
                                HtmlOfferView(htmlString: offer.content,
                                              displayAction: { offer.displayed() },
                                              tapAction: { offer.tapped() })
                            } else {
                                TextOfferView(text: offer.content,
                                              displayAction: { offer.displayed() },
                                              tapAction: { offer.tapped() })
                            }
                        }
// Optimize Tutorial: CODE SECTION 9 ENDS */
                    } else {
                        TextOfferView(text: "Placeholder Target Text")
                    }
                }
            }
            Divider()
            HStack {
                CustomButtonView(buttonTitle: "Update Propositions") {
/* Optimize Tutorial: CODE SECTION 6/10 BEGINS
                    let targetScope = DecisionScope(name: targetSettings.targetMbox)
                    
                    var data: [String: Any] = [:]
                    var targetParams: [String: String] = [:]
                    if !targetScope.name.isEmpty {
                        if !targetSettings.mboxParameters.isEmpty {
                            targetParams.merge(targetSettings.mboxParameters) { _, new in new }
                        }
                        
                        if !targetSettings.profileParameters.isEmpty {
                            targetParams.merge(targetSettings.profileParameters) { _, new in new }
                        }
                        
                        if targetSettings.order.isValid() {
                            targetParams["orderId"] = targetSettings.order.orderId
                            targetParams["orderTotal"] = targetSettings.order.orderTotal
                            targetParams["purchasedProductIds"] = targetSettings.order.purchasedProductIds
                        }
                        
                        if targetSettings.product.isValid() {
                            targetParams["productId"] = targetSettings.product.productId
                            targetParams["categoryId"] = targetSettings.product.categoryId
                        }
                        
                        if !targetParams.isEmpty {
                            data["__adobe"] = [
                                "target": targetParams
                            ]
                        }
                    }

                    Optimize.updatePropositions(for: [
                        targetScope
                    ], withXdm: nil,
                       andData: data)
// Optimize Tutorial: CODE SECTION 6 ENDS */
                }

                
                CustomButtonView(buttonTitle: "Get Propositions") {
/* Optimize Tutorial: CODE SECTION 7/10 BEGINS
                    let targetScope = DecisionScope(name: targetSettings.targetMbox)
                    Optimize.getPropositions(for: [
                        targetScope
                    ]) {
                            propositionsDict, error in
    
                            if let error = error {
                                errorAlert = true
                                errorMessage = error.localizedDescription
                            } else {
                                
                                guard let propositionsDict = propositionsDict else {
                                    return
                                }
                                
                                DispatchQueue.main.async {
                                    
                                    if propositionsDict.isEmpty {
                                        propositions.targetProposition = nil
                                        return
                                    }
                                    
                                    if let targetProposition = propositionsDict[targetScope] {
                                        propositions.targetProposition = targetProposition
                                    }
                                }
                            }
                    }
// Optimize Tutorial: CODE SECTION 7 ENDS */
                }
                .alert(isPresented: $errorAlert) {
                    Alert(title: Text("Error: Get Propositions"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
                }
                
                CustomButtonView(buttonTitle: "Clear Propositions") {
/* Optimize Tutorial: CODE SECTION 8/10 BEGINS
                    Optimize.clearCachedPropositions()
// Optimize Tutorial: CODE SECTION 8 ENDS */
                }
            }
            .padding(15)
        }
    }
}

struct OffersView_Previews: PreviewProvider {
    static var previews: some View {
        OffersView(propositions: Propositions())
    }
}

