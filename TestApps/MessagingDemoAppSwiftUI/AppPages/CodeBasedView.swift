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

class Propositions: ObservableObject {
    @Published var propositionsDict: [Surface: [Proposition]]? = nil
}

struct CodeBasedView: View {
    @StateObject var propositions = Propositions()
    @State private var showLoadingIndicator = false
    @State private var viewLoaded = false
    private let surfaces: [Surface] = [
        Surface(path: Constants.SurfaceName.CBE_JSON),
        Surface(path: Constants.SurfaceName.CBE_HTML)
    ]
    
    var body: some View {
        VStack {
            TabHeader(title: "Code Based", refreshAction: {
                fetchExperience()
            }, redownloadAction: {
                downloadExperience()
                fetchExperience()
            })
            ZStack {
                List {
                    if let propositionsDict = propositions.propositionsDict, !propositionsDict.isEmpty {
                        let surfacesArray = Array(propositionsDict.keys)
                        ForEach(surfacesArray, id: \.self) { surface in
                            if let codePropositions: [Proposition] = propositions.propositionsDict?[surface], !codePropositions.isEmpty,
                               let propItems = codePropositions.first?.items as? [PropositionItem] {
                                ForEach(propItems, id:\.itemId) { item in
                                    if item.schema == .htmlContent {
                                        CustomHtmlView(htmlString: item.htmlContent ?? "",
                                                       trackAction: item.track(_:withEdgeEventType:forTokens:))
                                    } else if item.schema == .jsonContent {
                                        if let jsonArray = item.jsonContentArray {
                                            CustomTextView(text: jsonArray.description,
                                                           trackAction: item.track(_:withEdgeEventType:forTokens:))
                                        } else {
                                            CustomTextView(text: item.jsonContentDictionary?.description ?? "",
                                                           trackAction: item.track(_:withEdgeEventType:forTokens:))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                if showLoadingIndicator {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
            
        }
        .onAppear {
            if !viewLoaded {
                viewLoaded = true
                fetchExperience()
            }
        }
    }
    
    private func downloadExperience() {
        showLoadingIndicator = true
        Messaging.updatePropositionsForSurfaces(surfaces)
    }
            
    private func fetchExperience() {
        Messaging.getPropositionsForSurfaces(surfaces) { propositionsDict, error in
            showLoadingIndicator = false
            if error != nil {
                return
            }
            DispatchQueue.main.async {
                self.propositions.propositionsDict = propositionsDict
            }
        }
    }
}

#Preview {
    CodeBasedView()
}
