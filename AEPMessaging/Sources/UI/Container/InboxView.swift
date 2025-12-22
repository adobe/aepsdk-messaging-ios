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

// MARK: - Main Inbox View

/// SwiftUI view that renders the inbox directly from schema data
@available(iOS 15.0, *)
struct InboxView: View {
    @ObservedObject var inbox: InboxUI
    
    var body: some View {
        Group {
            switch inbox.state {
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
            if let customView = inbox.customLoadingView {
                customView()
            } else {
                DefaultLoadingView()
            }
        }
    }
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header if available
            if let heading = inbox.inboxSchemaData?.heading?.text.content {
                headerView(heading)
            }
            
            // Render based on layout orientation (default to vertical if nil)
            let orientation = inbox.inboxSchemaData?.layout.orientation ?? .vertical
            if orientation == .horizontal {
                horizontalLayout
            } else {
                verticalLayout
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            // Track inbox display event
            inbox.inboxSchemaData?.track(withEdgeEventType: .display)
        }
    }
    
    private var verticalLayout: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 16) {
                ForEach(inbox.contentCards, id: \.id) { card in
                    cardRow(card)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    private var horizontalLayout: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 20) {
                ForEach(inbox.contentCards, id: \.id) { card in
                    cardRow(card)
                        .frame(width: 280) // Fixed width for horizontal cards
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    private func headerView(_ heading: String) -> some View {
        HStack {
            Text(heading)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        )
    }
    
    private func cardRow(_ card: ContentCardUI) -> some View {
        let isHorizontal = inbox.inboxSchemaData?.layout.orientation == .horizontal
        let isUnreadEnabled = inbox.inboxSchemaData?.isUnreadEnabled ?? false
        
        return card.view
            .padding(.all, 12)
            .padding(.top, isHorizontal ? 20 : 0) // Extra top padding for horizontal layout dismiss button
            .overlay(alignment: .topLeading) {
                // Show unread indicator if enabled and card is unread
                if isUnreadEnabled && card.isRead != true {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .offset(x: 4, y: 4)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: isHorizontal ? 12 : 8))
    }
    
    private var emptyStateView: some View {
        Group {
            if let customView = inbox.customEmptyView {
                customView(inbox.inboxSchemaData?.emptyStateSettings)
            } else {
                DefaultEmptyStateView(
                    emptyStateSettings: inbox.inboxSchemaData?.emptyStateSettings,
                    onRefresh: { inbox.refresh() }
                )
            }
        }
    }
    
    private func errorView(_ error: Error) -> some View {
        Group {
            if let customView = inbox.customErrorView {
                customView(error)
            } else {
                DefaultErrorView(
                    error: error,
                    onRetry: { inbox.refresh() }
                )
            }
        }
    }
}
