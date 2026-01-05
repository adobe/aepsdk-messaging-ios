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
    
    private enum Constants {
        static let verticalSpacing: CGFloat = 16
        static let iconSize: CGFloat = 48
        static let icon = "tray"
        static let message = "No content cards available"
        static let buttonTitle = "Refresh"
        static let imageMaxSize: CGFloat = 120
    }
    
    var body: some View {
        VStack(spacing: Constants.verticalSpacing) {
            // Use empty state settings from inbox if available
            if let emptyStateSettings = emptyStateSettings {
                if let imageUrl = emptyStateSettings.image?.url {
                    AsyncImage(url: imageUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Image(systemName: Constants.icon)
                            .font(.system(size: Constants.iconSize))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: Constants.imageMaxSize, 
                           maxHeight: Constants.imageMaxSize)
                } else {
                    Image(systemName: Constants.icon)
                        .font(.system(size: Constants.iconSize))
                        .foregroundColor(.secondary)
                }
                
                if let message = emptyStateSettings.message?.content {
                    Text(message)
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                // Default empty state
                Image(systemName: Constants.icon)
                    .font(.system(size: Constants.iconSize))
                    .foregroundColor(.secondary)
                
                Text(Constants.message)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Button(Constants.buttonTitle) {
                onRefresh()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

