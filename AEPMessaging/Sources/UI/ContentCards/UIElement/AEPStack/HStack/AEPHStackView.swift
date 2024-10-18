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

    @available(iOS 15.0, *)
    struct AEPHStackView: View {
        /// The model containing the data about the button.
        @ObservedObject var model = AEPHStack()

        /// The body of the view
        var body: some View {
            HStack(alignment: model.alignment, spacing: model.spacing) {
                ForEach(Array(model.childModels.enumerated()), id: \.offset) { _, model in
                    AnyView(model.view)
                }
            }.applyModifier(model.modifier)
        }
    }
#endif
