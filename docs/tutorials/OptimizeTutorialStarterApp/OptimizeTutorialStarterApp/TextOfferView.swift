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

struct TextOfferView: View {
    var text = ""
    var displayAction: (() -> Void)? = nil
    var tapAction: (() -> Void)? = nil

    var body: some View {
        Text(text)
            .multilineTextAlignment(.center)
            .frame(height: 150)
            .frame(maxWidth: .infinity)
            .onAppear {
                if self.displayAction != nil {
                    self.displayAction!()
                }
            }
            .onTapGesture {
                if self.tapAction != nil {
                    self.tapAction!()
                }
            }
    }
}

struct TextOfferView_Previews: PreviewProvider {
    static var previews: some View {
        TextOfferView(text: "Sample Text")
    }
}
