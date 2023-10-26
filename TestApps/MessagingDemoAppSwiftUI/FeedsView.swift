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

struct FeedsView: View {
    @State var propositionsDict: [Surface: [MessagingProposition]]? = nil
    @State private var viewDidLoad = false
    @State private var feedName: String = "API feed"
    var body: some View {
        NavigationView {
            VStack {
                Text(feedName)
                    .font(.title)
                    .padding(.top, 30)
                List {
<<<<<<< HEAD
                    ForEach(propositionsResult.propositionsDict?[Surface(path: "feeds/apifeed")]?.compactMap {
                        $0.items.first } ?? [], id: \.propositionId ) { propositionItem in
                            if let feedItemSchema = propositionItem.feedItemSchemaData, let feedItem = feedItemSchema.getFeedItem() {
                                NavigationLink(destination: FeedItemDetailView(feedItem: feedItem)) {
                                    FeedItemView(feedItem: feedItem)
                                }
=======
                    ForEach(propositionsDict?[Surface(path: "feeds/apifeed")]?
                        .compactMap { $0.items.first?.decodeContent() } ?? [], id: \.uniqueId) { inboundMessage in
                        if let feedItem = inboundMessage.decodeContent(FeedItem.self) {
                            NavigationLink(destination: FeedItemDetailView(feedItem: feedItem)) {
                                FeedItemView(feedItem: feedItem)
>>>>>>> b06a62d1f3eabd945ad8a38ba95bfee75b2a2238
                            }
                        }
                }
                .listStyle(.plain)
                .navigationBarTitle(Text("Back"), displayMode: .inline)
                .onAppear {
                    if viewDidLoad == false {
                        viewDidLoad = true
                        Messaging.updatePropositionsForSurfaces([Surface(path: "feeds/apifeed")])
                    }
                    Messaging.getPropositionsForSurfaces([Surface(path: "feeds/apifeed")]) { propositionsDict, error in
                        guard error == nil else {
                            return
                        }
                        DispatchQueue.main.async {
                            self.propositionsDict = propositionsDict
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct FeedsView_Previews: PreviewProvider {
    static var previews: some View {
        FeedsView()
    }
}
