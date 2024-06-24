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

struct CodeBasedOffersView: View {
    @StateObject var propositions = Propositions()
    @State private var viewDidLoad = false
    
    let surfaces: [Surface] = [
        // prod surfaces
        // Surface(path: "codeBasedView#customHtmlOffer")
        // Surface(path: "sb/cbe-json-object")
        // Surface(path: "sb/cbe-json")
        
        // staging surfaces
        // Surface(path: "cbeoffers3")
        Surface(path: "cbeJsonArray"),
        Surface(path: "cbeHtml")
    ]
    
    var body: some View {
        VStack {
            Text("Code Based Experiences")
                .font(Font.title)
                .padding(.top, 30)
            if viewDidLoad {
                // Display a loading indicator or some placeholder content
                Text("Loading...")
            } else {
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
            }
        }
        .onAppear {
            viewDidLoad = true
            Messaging.updatePropositionsForSurfaces(surfaces)
            Messaging.getPropositionsForSurfaces(surfaces) { propositionsDict, error in
                if let error = error {
                    return
                }
                DispatchQueue.main.async {
                    self.propositions.propositionsDict = propositionsDict
                    self.viewDidLoad = false
                }
            }
        }
    }
}

struct CodeBasedOffersView_Previews: PreviewProvider {
    static var previews: some View {
        CodeBasedOffersView()
    }
}
