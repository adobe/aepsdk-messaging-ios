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

    private let htmlSurface = Surface(path: Constants.SurfaceName.CBE_HTML)
    private let jsonSurface = Surface(path: Constants.SurfaceName.CBE_JSON)

    private var surfaces: [Surface] { [jsonSurface, htmlSurface] }

    var body: some View {
        VStack(spacing: 0) {
            TabHeader(title: "Code Based", refreshAction: {
                fetchExperience(surfaces)
            }, redownloadAction: {
                downloadAndFetch(surfaces)
            })

            // Dedicated per-surface CBE buttons: each does updatePropositions -> getPropositions -> track on render
            HStack(spacing: 12) {
                Button(action: { downloadAndFetch([htmlSurface]) }) {
                    Label("CBE HTML", systemImage: "chevron.left.forwardslash.chevron.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(action: { downloadAndFetch([jsonSurface]) }) {
                    Label("CBE JSON", systemImage: "curlybraces")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            ZStack {
                List {
                    if let propositionsDict = propositions.propositionsDict, !propositionsDict.isEmpty {
                        let surfacesArray = Array(propositionsDict.keys)
                        ForEach(surfacesArray, id: \.self) { surface in
                            if let codePropositions: [Proposition] = propositions.propositionsDict?[surface], !codePropositions.isEmpty,
                               let propItems = codePropositions.first?.items as? [PropositionItem] {
                                Section(header: Text(surface.uri)) {
                                    ForEach(propItems, id: \.itemId) { item in
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
                fetchExperience(surfaces)
            }
        }
    }

    /// Fetches the given surfaces from the remote, and once that completes, retrieves and renders them.
    /// Uses the `updatePropositionsForSurfaces` completion handler so `getPropositionsForSurfaces`
    /// only runs after the network fetch has finished (avoids retrieving stale/empty cached content).
    private func downloadAndFetch(_ surfaces: [Surface]) {
        showLoadingIndicator = true
        Messaging.updatePropositionsForSurfaces(surfaces) { success in
            if !success {
                DispatchQueue.main.async { showLoadingIndicator = false }
            }
            fetchExperience(surfaces)
        }
    }

    /// Retrieves the already-downloaded propositions for the given surfaces and merges them into the view state.
    private func fetchExperience(_ surfaces: [Surface]) {
        Messaging.getPropositionsForSurfaces(surfaces) { propositionsDict, error in
            DispatchQueue.main.async {
                showLoadingIndicator = false
                guard error == nil, let propositionsDict = propositionsDict else {
                    return
                }
                // Merge so fetching a single surface doesn't wipe out the other's results.
                var merged = self.propositions.propositionsDict ?? [:]
                for (surface, props) in propositionsDict {
                    merged[surface] = props
                }
                self.propositions.propositionsDict = merged
            }
        }
    }
}

#Preview {
    CodeBasedView()
}
