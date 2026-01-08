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
    import SwiftUI
#endif
import Foundation

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
            case .loaded(let cards):
                if cards.isEmpty {
                    emptyStateViewWithHeading
                } else {
                    contentView
                }
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
            if let heading = inbox.inboxSchemaData?.content.heading {
                headerView(heading)
            }
            
            // Render based on layout orientation (default to vertical if nil)
            let orientation = inbox.inboxSchemaData?.content.layout.orientation ?? .vertical
            if orientation == .horizontal {
                horizontalLayout
            } else {
                verticalLayout
            }
        }
        .background(inbox.background)
        .onAppear {
            // Track inbox display event
            inbox.inboxSchemaData?.track(withEdgeEventType: .display)
        }
    }
    
    private var verticalLayout: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: inbox.cardSpacing) {
                ForEach(inbox.contentCards) { card in
                    card.view
                }
            }
            .padding(inbox.contentPadding)
        }
        .if(inbox.isPullToRefreshEnabled) { view in
            view.refreshable {
                await inbox.refreshAsync()
            }
        }
    }
    
    private var horizontalLayout: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: inbox.cardSpacing) {
                ForEach(inbox.contentCards) { card in
                    card.view
                }
            }
            .padding(inbox.contentPadding)
        }
        .if(inbox.isPullToRefreshEnabled) { view in
            view.refreshable {
                await inbox.refreshAsync()
            }
        }
    }
    
    private func headerView(_ heading: Heading) -> some View {
        Group {
            if let customView = inbox.customHeadingView {
                customView(heading)
            } else {
                DefaultHeadingView(heading: heading)
            }
        }
    }
    
    private var emptyStateView: some View {
        Group {
            if let customView = inbox.customEmptyView {
                customView(inbox.inboxSchemaData?.content.emptyStateSettings)
            } else {
                DefaultEmptyStateView(
                    emptyStateSettings: inbox.inboxSchemaData?.content.emptyStateSettings,
                    onRefresh: { inbox.refresh() }
                )
            }
        }
    }
    
    private var emptyStateViewWithHeading: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header if available
            if let heading = inbox.inboxSchemaData?.content.heading {
                headerView(heading)
            }
            
            // Empty state view
            emptyStateView
        }
        .background(inbox.background)
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
