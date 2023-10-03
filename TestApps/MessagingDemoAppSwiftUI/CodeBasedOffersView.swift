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

struct CodeBasedOffersView: View {
    @State var propositionsDict: [Surface: [MessagingProposition]]? = nil
    @State private var viewDidLoad = false
    var body: some View {
        VStack {
            Text("Code Based Experiences")
                .font(Font.title)
                .padding(.top, 30)
            List {
                if let codePropositions: [MessagingProposition] = propositionsDict?[Surface(path: "<your-surface-path>")], !codePropositions.isEmpty {
                    ForEach(codePropositions.first?.items ?? [], id:\.uniqueId) { item in
                        if item.schema.contains("html-content-item") {
                            CustomHtmlView(htmlString: item.content)
                        } else if item.schema.contains("json-content-item") {
                            CustomTextView(text: item.content)
                        }
                    }
                }
            }
        }
        .onAppear {
            if viewDidLoad == false {
                viewDidLoad = true
                Messaging.updatePropositionsForSurfaces([Surface(path: "<your-surface-path>")])
            }
            Messaging.getPropositionsForSurfaces([Surface(path: "<your-surface-path>")]) { propositionsDict, error in
                guard error == nil else {
                    return
                }
                DispatchQueue.main.async {
                    self.propositionsDict = propositionsDict
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
