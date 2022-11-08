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
    

import SwiftUI

struct DictionaryRowView: View {
    @Binding var dict: [String : String]
    @Binding var dictRows: UInt
    
    @State private var showMinusButton = false
    @State private var hideView = false
    
    @State private var key = ""
    @State private var val = ""
    var body: some View {
        HStack {
            HStack {
                TextField("Enter key", text: $key, onEditingChanged: { editing in
                    if !editing && !key.isEmpty {
                        dict[key] = val
                    }
                })
                .autocapitalization(.none)
                        
                Text(":")
                TextField("Enter value", text: $val, onEditingChanged: { editing in
                    if !editing {
                        if !key.isEmpty {
                            if !val.isEmpty {
                                dict[self.key] = val
                            } else {
                                dict[self.key] = nil
                            }
                        }
                    }
                })
                .autocapitalization(.none)
            }
            Button(action: {
                if self.showMinusButton == false {
                    self.dictRows += 1
                    self.showMinusButton = true
                } else {
                    dict.removeValue(forKey: self.key)
                    self.hideView = true
                }
            }) {
                Label("", systemImage: self.showMinusButton ? "minus.circle.fill" : "plus.circle.fill")
                    .foregroundColor(self.showMinusButton ? .red : .green)
            }
        }
        .isHidden(self.hideView)
    }
}

extension View {
    @ViewBuilder func isHidden(_ hidden: Bool, shouldRemove: Bool = true) -> some View {
        if !hidden {
             self
        } else {
            if shouldRemove {
                EmptyView()
            } else {
                self.hidden()
            }
        }
    }
}

struct DictionaryRowView_Previews: PreviewProvider {
    static var previews: some View {
        DictionaryRowView(dict: .constant([:]), dictRows: .constant(1))
    }
}
