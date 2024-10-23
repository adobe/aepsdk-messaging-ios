/*
Copyright 2024 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/

import SwiftUI

struct TabHeader: View {
    var title: String
    var refreshAction: (() -> Void)?
    var redownloadAction: (() -> Void)?
    
    var body: some View {
        ZStack {
            Text("\(title)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.accentColor)
                .padding(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                if let redownloadAction = redownloadAction {
                    Button(action: redownloadAction, label: {
                        VStack {
                            Image(systemName: "arrow.up.arrow.down")
                            Text("Download")
                                .font(.system(size: 12, weight: .light))
                        }
                    })
                }
                if let refreshAction = refreshAction {
                    Button(action: refreshAction, label: {
                        VStack {
                            Image(systemName: "arrow.2.circlepath")
                            Text("Refresh")
                                .font(.system(size: 12, weight: .light))
                        }
                    })
                }
            }
            .padding(.trailing, 5)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .buttonStyle(.borderless)
            
            
            
        }
        .frame(maxWidth: .infinity)
    }
}
