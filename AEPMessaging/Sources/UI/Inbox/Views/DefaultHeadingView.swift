/*
 Copyright 2025 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

#if canImport(SwiftUI)
    import SwiftUI
#endif
import Foundation

/// Default heading view for the Inbox
@available(iOS 15.0, *)
struct DefaultHeadingView: View {
    let heading: Heading
    
    var body: some View {
        HStack {
            Spacer()
            heading.text.view
            Spacer()
        }
        .padding(.horizontal, UIConstants.Inbox.DefaultStyle.Heading.HORIZONTAL_PADDING)
        .padding(.vertical, UIConstants.Inbox.DefaultStyle.Heading.VERTICAL_PADDING)
        .background(UIConstants.Inbox.DefaultStyle.Heading.BACKGROUND_COLOR)
        .onAppear {
            applyDefaultStyling()
        }
    }
    
    /// Applies default styling to the heading text if not already customized
    private func applyDefaultStyling() {
        heading.text.font = UIConstants.Inbox.DefaultStyle.Heading.FONT
        heading.text.textColor = UIConstants.Inbox.DefaultStyle.Heading.COLOR
    }
}

