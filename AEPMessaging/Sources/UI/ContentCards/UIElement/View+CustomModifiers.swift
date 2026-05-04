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

@available(iOS 15.0, *)
extension View {
    /// Applies an optional `AEPViewModifier` to the view.
    /// - Parameter modifier: An optional `AEPViewModifier` to apply to the view.
    /// - Returns: A view with the modifier applied if provided, otherwise the original view.
    @ViewBuilder
    func applyModifier(_ modifier: AEPViewModifier?) -> some View {
        applyIf(modifier) { view, mod in
            view.modifier(mod)
        }
    }

    /// Conditionally applies a transformation to the view based on an optional value.
    /// - Parameters:
    ///   - value: An optional value that determines whether the transformation should be applied.
    ///   - apply: A closure that takes the current view and the unwrapped value, and returns a modified view.
    /// - Returns: A view that is either transformed by the `apply` closure if `value` is non-nil,
    ///            or the original view if `value` is nil.
    @ViewBuilder
    private func applyIf<Value>(_ value: Value?, apply: (Self, Value) -> some View) -> some View {
        if let value = value {
            apply(self, value)
        } else {
            self
        }
    }
    
    /// Conditionally applies a modifier to a view.
    /// - Parameters:
    ///   - condition: The condition to evaluate
    ///   - transform: The modifier to apply if condition is true
    /// - Returns: The modified view if condition is true, otherwise the original view
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Applies a Liquid Glass effect with a rounded rectangle shape when enabled and running on iOS 26+.
    /// Falls back to the unmodified view on older OS versions or when disabled.
    /// - Parameters:
    ///   - enabled: Whether the glass effect should be applied.
    ///   - cornerRadius: Corner radius of the glass shape, matching the card's clip shape.
    /// - Returns: The view with a glass material background, or unchanged if unavailable/disabled.
    @ViewBuilder
    func applyGlassEffect(_ enabled: Bool, cornerRadius: CGFloat) -> some View {
        if enabled {
            if #available(iOS 26.0, *) {
                self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                self
            }
        } else {
            self
        }
    }
}
