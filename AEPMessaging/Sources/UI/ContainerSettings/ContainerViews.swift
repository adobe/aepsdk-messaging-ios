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

// MARK: - Main Container View

/// SwiftUI view that renders the container based on template type
@available(iOS 15.0, *)
struct ContainerView: View {
    @ObservedObject var container: ContainerSettingsUI
    
    var body: some View {
        Group {
            switch container.state {
            case .loading:
                loadingView
            case .loaded:
                contentView
            case .empty:
                emptyStateView
            case .error(let error):
                errorView(error)
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading content cards...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var contentView: some View {
        Group {
            if let template = container.containerTemplate {
                AnyView(template.view)
            } else {
                // Fallback view in case template creation fails
                Text("Template not available")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            // Use empty state settings from container if available
            if let emptyStateSettings = container.containerSettings.emptyStateSettings {
                if let imageUrl = emptyStateSettings.image?.url {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: 120, maxHeight: 120)
                } else {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
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
                Image(systemName: "tray")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                
                Text("No content cards available")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Button("Refresh") {
                container.refresh()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Error loading content cards")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                container.refresh()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}