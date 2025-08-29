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

// MARK: - Carousel Container Template

/// Template for carousel-style container with horizontal scrolling and no unread indicators
@available(iOS 15.0, *)
struct CarouselContainerTemplate: View {
    @ObservedObject var container: ContainerSettingsUI
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header if available
            if let heading = container.containerSettings.heading?.content {
                headerView(heading)
            }
            
            // Horizontal scrolling carousel
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(container.contentCards, id: \.id) { card in
                        card.view
                            .frame(width: 280) // Fixed width for carousel
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
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
}
