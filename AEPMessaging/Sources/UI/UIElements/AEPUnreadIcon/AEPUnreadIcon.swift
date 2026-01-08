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
    import Combine
    import SwiftUI
#endif

import AEPServices

@available(iOS 15.0, *)
public class AEPUnreadIcon: ObservableObject, AEPViewModel {
    /// custom view modifier that can be applied to the unread icon view.
    @Published public var modifier: AEPViewModifier?

    /// The image for the unread icon
    @Published public var image: AEPImage

    /// Alignment for the unread icon rendered as an overlay on the card's template
    @Published public var alignment: Alignment
    
    /// SwiftUI view that represents the unread icon
    lazy var view: some View = image.view
    
    /// Initializes an AEPUnreadIcon with the given settings
    /// - Parameters:
    ///   - settings: Settings for the unread icon from Inbox schema
    init(settings: UnreadIndicatorSettings.UnreadIconSettings) {
        self.image = settings.image
        self.alignment = settings.placement.alignment
    }
}

@available(iOS 15.0, *)
extension UnreadIndicatorSettings.UnreadIconSettings.IconPlacement {
    var alignment: Alignment {
        switch self {
        case .topLeft: return .topLeading
        case .topRight: return .topTrailing
        case .bottomLeft: return .bottomLeading
        case .bottomRight: return .bottomTrailing
        case .unknown: return .topTrailing // Default fallback
        }
    }
}
