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

struct HeaderView: View {
    var text: String
    var body: some View {
        VStack {
            Text(text)
                .font(Font.title2.weight(.bold))
                .frame(height: 100)
                .padding(.top, 30)
            Divider()
        }
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.accentColor, Color.white]), startPoint: .top, endPoint: .bottom)
        )
        .edgesIgnoringSafeArea([.top])
        .frame(maxHeight: 100)

    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView(text: "Sample Text")
    }
}
