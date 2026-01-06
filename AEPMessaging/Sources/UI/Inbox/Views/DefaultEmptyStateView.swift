/*
 Copyright 2026 Adobe. All rights reserved.
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

/// Default empty state view shown when no content cards are available
@available(iOS 15.0, *)
struct DefaultEmptyStateView: View {
    let emptyStateSettings: EmptyStateSettings?
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(spacing: UIConstants.Inbox.DefaultStyle.EmptyState.VERTICAL_SPACING) {
            if let emptyStateSettings = emptyStateSettings {
                // Show image from server if available
                if let image = emptyStateSettings.image {
                    image.view
                        .frame(maxWidth: UIConstants.Inbox.DefaultStyle.EmptyState.IMAGE_MAX_SIZE, 
                               maxHeight: UIConstants.Inbox.DefaultStyle.EmptyState.IMAGE_MAX_SIZE)
                }
                
                // Show message from server if available
                if let message = emptyStateSettings.message {
                    message.view
                        .multilineTextAlignment(.center)
                        .onAppear {
                            applyDefaultStyling(to: message)
                        }
                }
            } else {
                // Default empty state message only
                Text(UIConstants.Inbox.DefaultStyle.EmptyState.MESSAGE)
                    .font(UIConstants.Inbox.DefaultStyle.EmptyState.MESSAGE_FONT)
                    .foregroundColor(UIConstants.Inbox.DefaultStyle.EmptyState.MESSAGE_COLOR)
            }
            
            Button(UIConstants.Inbox.DefaultStyle.EmptyState.BUTTON_TITLE) {
                onRefresh()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(UIConstants.Inbox.DefaultStyle.EmptyState.PADDING)
    }
    
    /// Applies default styling to the empty state message if not already customized
    private func applyDefaultStyling(to message: AEPText) {
        if message.font == nil {
            message.font = UIConstants.Inbox.DefaultStyle.EmptyState.MESSAGE_FONT
        }
        if message.textColor == nil {
            message.textColor = UIConstants.Inbox.DefaultStyle.EmptyState.MESSAGE_COLOR
        }
    }
}

