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

/// A protocol that defines a model capable of providing a SwiftUI view.
///
/// Types conforming to `AEPModel` must  provide a `view` property that returns an instance of `Content` that conforms to `View`
///
/// This protocol is useful for creating a uniform interface for different view models that can generate SwiftUI views.
/// All the UI elements `AEPText`, `AEPButton`, `AEPImage`, `AEPHStack`, and `AEPVStack`
/// must conform to the `AEPModel` protocol.
@available(iOS 15.0, *)
protocol AEPViewModel {
    /// The type of view associated with this model.
    associatedtype Content: View

    /// A SwiftUI view that represents the content of this model.
    var view: Content { get }
}

/// Adapts any SwiftUI View to conform to the `AEPViewModel` protocol.
///
/// This struct acts as a bridge, allowing you to  integrate any existing SwiftUI view into a
/// system that expects view models adhering to the `AEPViewModel` protocol.
/// Used in AEPStack to accept SwiftUI view's from public API and store them as `AEPViewModel`
@available(iOS 15.0, *)
struct AnyViewModel<Content: View>: AEPViewModel {
    /// The underlying SwiftUI view being adapted.
    let wrappedView: Content

    /// Provides the adapted view, fulfilling the `AEPViewModel` requirement
    var view: some View {
        wrappedView
    }
}
