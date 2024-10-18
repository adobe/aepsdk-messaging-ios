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
import Foundation
import SwiftUI

/// A model class representing a vertical stack used for Content Cards
@available(iOS 15.0, *)
public class AEPVStack: AEPStack, AEPViewModel {
    /// The horizontal alignment of child views in the vertical stack.
    @Published public var alignment: HorizontalAlignment = Constants.CardTemplate.DefaultStyle.Stack.HORIZONTAL_ALIGNMENT

    /// The SwiftUI view representing the vertical stack.
    lazy var view: some View = AEPVStackView(model: self)
}
#endif
