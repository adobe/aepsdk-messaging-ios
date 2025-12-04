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

// MARK: - Default View Components

/// Default loading view shown while content cards are being fetched
@available(iOS 15.0, *)
private struct DefaultLoadingView: View {
    private enum Constants {
        static let verticalSpacing: CGFloat = 16
        static let message = "Loading..."
    }
    
    var body: some View {
        VStack(spacing: Constants.verticalSpacing) {
            ProgressView()
            Text(Constants.message)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Default empty state view shown when no content cards are available
@available(iOS 15.0, *)
private struct DefaultEmptyStateView: View {
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
            // Use empty state settings from container if available
            if let emptyStateSettings = emptyStateSettings {
                if let imageUrl = emptyStateSettings.image?.url {
                    AsyncImage(url: URL(string: imageUrl)) { image in
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

/// Default error view shown when content cards fail to load
@available(iOS 15.0, *)
private struct DefaultErrorView: View {
    let error: Error
    let onRetry: () -> Void
    
    private enum Constants {
        static let verticalSpacing: CGFloat = 16
        static let iconSize: CGFloat = 48
        static let icon = "exclamationmark.triangle"
        static let title = "Error loading content cards"
        static let buttonTitle = "Try Again"
    }
    
    var body: some View {
        VStack(spacing: Constants.verticalSpacing) {
            Image(systemName: Constants.icon)
                .font(.system(size: Constants.iconSize))
                .foregroundColor(.red)
            
            Text(Constants.title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(Constants.buttonTitle) {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Main Container View

/// SwiftUI view that renders the container based on template type
@available(iOS 15.0, *)
struct ContainerView: View {
    @ObservedObject var container: ContainerUI
    
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
        Group {
            if let customView = container.customLoadingView {
                customView()
            } else {
                DefaultLoadingView()
            }
        }
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
        Group {
            if let customView = container.customEmptyView {
                customView(container.containerSettings.emptyStateSettings)
            } else {
                DefaultEmptyStateView(
                    emptyStateSettings: container.containerSettings.emptyStateSettings,
                    onRefresh: { container.refresh() }
                )
            }
        }
    }
    
    private func errorView(_ error: Error) -> some View {
        Group {
            if let customView = container.customErrorView {
                customView(error)
            } else {
                DefaultErrorView(
                    error: error,
                    onRetry: { container.refresh() }
                )
            }
        }
    }
}
