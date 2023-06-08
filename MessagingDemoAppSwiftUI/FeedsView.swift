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
    @State private var viewDidLoad = false
    var body: some View {
        VStack {
            VStack {
                Text("Feeds")
                    .font(Font.title2.weight(.bold))
                    .frame(height: 70)
                    .padding(.top, 30)
                Divider()
            }
            Grid(alignment: .leading, horizontalSpacing: 70, verticalSpacing: 30) {
                GridRow {
                    Button("update feeds") {
                        Messaging.updateFeedsForSurfacePaths(["feeds/promos", "feeds/events"])
                    }
                }
                GridRow {
                    Button("get feeds") {
                        Messaging.getFeedsForSurfacePaths(["feeds/promos", "feeds/events"]) { feedsDict, error in
                            
                            guard error == nil,
                                  let feedsDict = feedsDict else {
                                return
                            }

                            for (_, feed) in feedsDict.enumerated() {
                                print("\(feed)")
                            }
                        }
                    }
                }
            }
            Spacer()
        }
        .onAppear {
            if viewDidLoad == false {
                viewDidLoad = true
                
                Messaging.setFeedsHandler { feedsDict in
                    for (_, feed) in feedsDict.enumerated() {
                        print("\(feed)")
                    }
                }
            }
        }
    }
}

struct FeedsView_Previews: PreviewProvider {
    static var previews: some View {
        FeedsView()
    }
}
