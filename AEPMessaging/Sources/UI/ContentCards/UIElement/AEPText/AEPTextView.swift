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

#if canImport(SwiftUI)
    import SwiftUI
#endif

/// A view that displays an button based on the provided `AEPText` model.
@available(iOS 15.0, *)
struct AEPTextView: View {
    /// The model containing the data about the text.
    @ObservedObject var model: AEPText

    /// Initializes a new instance of `AEPTextView` with the provided model
    init(model: AEPText) {
        self.model = model
    }

    /// The body of the view
    var body: some View {
        Text(model.content)
            .font(model.font)
            .foregroundColor(model.textColor)
            .applyModifier(model.modifier)
    }
}
