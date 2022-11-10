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

struct CustomButtonView: View {
    @State var buttonTitle: String = ""
    @State var action: () -> Void
    var body: some View {
        Button(action: self.action) {
            Text(self.buttonTitle)
        }
        .buttonStyle(CustomButtonStyle())
    }
}

struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font.body.weight(.medium))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .foregroundColor(Color.black)
            .cornerRadius(20)
            .shadow(color: configuration.isPressed ? Color.gray: Color.blue, radius: 3, x: 2, y: 2)

    }
}

struct CustomButtonView_Previews: PreviewProvider {
    static var previews: some View {
        CustomButtonView(buttonTitle: "Sample title") {
            // Perform action
        }
    }
}
