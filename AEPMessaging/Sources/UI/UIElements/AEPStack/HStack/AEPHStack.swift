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
    import Combine
    import SwiftUI
#endif
import Foundation

/// A model class representing a horizontal stack used for Content Cards
@available(iOS 15.0, *)
public class AEPHStack: AEPStack, AEPViewModel {
    /// The vertical alignment of child views in the horizontal stack.
    @Published public var alignment: VerticalAlignment = UIConstants.CardTemplate.DefaultStyle.Stack.VERTICAL_ALIGNMENT

    /// The SwiftUI view representing the horizontal stack.
    lazy var view: some View = AEPHStackView(model: self)
}
