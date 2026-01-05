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
            if let heading = inbox.inboxSchemaData?.content.heading?.text.content {
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
                ForEach(inbox.contentCards, id: \.id) { card in
                    styledCardView(for: card)
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
                ForEach(inbox.contentCards, id: \.id) { card in
                    styledCardView(for: card)
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
    
    /// Returns a styled card view with optional unread indicators
    /// - Parameter card: The content card to style
    /// - Returns: Card view with unread styling applied if applicable
    private func styledCardView(for card: ContentCardUI) -> some View {
        // Early exit if unread feature is disabled
        guard let inboxSchemaData = inbox.inboxSchemaData,
              inboxSchemaData.content.isUnreadEnabled else {
            return card.view
        }
        
        // Early exit if card is already read
        guard !card.isRead else {
            return card.view
        }
        
        // Card is unread - apply unread styling
        let unreadSettings = inboxSchemaData.content.unreadIndicator
        
        // Apply unread background color if available
        if let unreadBgColor = unreadSettings?.unreadBackground?.color {
            card.template.backgroundColor = Color(aepColor: unreadBgColor)
        }
        
        // Apply unread icon overlay if available
        let unreadIcon = unreadSettings?.unreadIcon
        return card.view
            .if(unreadIcon != nil) { view in
                view.overlay(alignment: unreadIconAlignment(unreadIcon?.placement)) {
                    unreadIcon?.image.view
                        .frame(width: inbox.unreadIconSize, height: inbox.unreadIconSize)
                }
            }
    }
    
    // MARK: - Unread Styling Helpers
    
    /// Returns the SwiftUI alignment for the unread icon based on placement settings
    private func unreadIconAlignment(_ placement: UnreadIndicatorSettings.UnreadIconSettings.IconPlacement?) -> Alignment {
        guard let placement = placement else { return .topLeading }
        
        switch placement {
        case .topLeft:
            return .topLeading
        case .topRight:
            return .topTrailing
        case .bottomLeft:
            return .bottomLeading
        case .bottomRight:
            return .bottomTrailing
        case .unknown:
            return .topLeading
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

// MARK: - View Extensions

@available(iOS 15.0, *)
extension View {
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
}

// MARK: - Color Extensions

@available(iOS 15.0, *)
extension Color {
    /// Creates a Color from AEPColor with light and dark mode support
    /// - Parameter aepColor: The AEPColor containing hex values for light and dark modes
    init(aepColor: AEPColor) {
        self.init(
            light: Color(hex: aepColor.light),
            dark: Color(hex: aepColor.dark)
        )
    }
    
    /// Creates a Color from AEPColor with light and dark mode support
    /// - Parameters:
    ///   - light: Color for light mode
    ///   - dark: Color for dark mode
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #else
        self = light
        #endif
    }
    
    /// Creates a Color from a hex string
    /// Supports formats: "0xRRGGBB", "0xRRGGBBAA", "#RRGGBB", "#RRGGBBAA", "RRGGBB", "RRGGBBAA"
    /// - Parameter hex: The hex string
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "0x", with: "")
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let length = hexSanitized.count
        let r, g, b, a: Double
        
        if length == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double(rgb & 0x000000FF) / 255.0
        } else {
            r = 0
            g = 0
            b = 0
            a = 1
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
