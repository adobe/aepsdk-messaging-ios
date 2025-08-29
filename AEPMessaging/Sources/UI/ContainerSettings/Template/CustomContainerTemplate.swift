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

// MARK: - Custom Container Template

/// Template for custom container with configurable scrolling and unread settings
@available(iOS 15.0, *)
struct CustomContainerTemplate: View {
    @ObservedObject var container: ContainerSettingsUI
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header if available
            if let heading = container.containerSettings.heading?.content {
                headerView(heading)
            }
            
            // Custom layout based on orientation
            if container.containerSettings.layout.orientation == .horizontal {
                horizontalLayout
            } else {
                verticalLayout
            }
        }
    }
    
    private func headerView(_ heading: String) -> some View {
        HStack {
            Text(heading)
                .font(.title2)
                .fontWeight(.semibold)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private var verticalLayout: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 12) {
                ForEach(container.contentCards, id: \.id) { card in
                    customCardView(card)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    private var horizontalLayout: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(container.contentCards, id: \.id) { card in
                    customCardView(card)
                        .frame(width: 280)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    private func customCardView(_ card: ContentCardUI) -> some View {
        HStack(alignment: .top, spacing: 8) {
            card.view
            
            // Show unread indicator if enabled and card is unread
            if container.containerSettings.isUnreadEnabled == true,
               let unreadValue = card.meta?["unread"] as? Bool,
               unreadValue {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
            }
        }
    }
}
