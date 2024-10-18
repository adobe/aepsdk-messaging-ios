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

import Foundation

/// A custom view modifier that wraps and applies other SwiftUI view modifiers.
///
/// AEPViewModifier provides a way to encapsulate and store view modifiers,
/// allowing for dynamic application of modifiers to views.
@available(iOS 15.0, *)
public struct AEPViewModifier: ViewModifier {
    private let _body: (Content) -> any View

    /// Initializes a new `AEPViewModifier` with the given SwiftUI view modifier.
    public init<M: ViewModifier>(_ modifier: M) {
        _body = { content in
            content.modifier(modifier)
        }
    }

    /// Applies the wrapped modifier to the given content.
    /// This method is called by SwiftUI when the modifier is applied to a view.
    public func body(content: Content) -> some View {
        AnyView(_body(content))
    }
}
