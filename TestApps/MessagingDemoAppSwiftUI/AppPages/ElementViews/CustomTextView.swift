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
import SwiftUI
import AEPMessaging

struct CustomTextView: View {
    @State var text: String
    var trackAction: ((String?, MessagingEdgeEventType, [String]?) -> Void)? = nil

    var body: some View {
        Text(text)
            .multilineTextAlignment(.center)
            .frame(height: 150)
            .frame(maxWidth: .infinity)
            .onAppear {
                self.trackAction?(nil, .display, nil)
            }
            .onTapGesture {
                self.trackAction?(nil, .interact, nil)
            }
    }
}

struct CustomTextView_Previews: PreviewProvider {
    static var previews: some View {
        CustomTextView(text: "Sample text.")
    }
}
