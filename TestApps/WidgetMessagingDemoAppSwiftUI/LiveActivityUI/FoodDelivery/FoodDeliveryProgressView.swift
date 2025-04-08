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

import SwiftUI

struct DeliveryStep: Identifiable {
    let id = UUID()
    let status: String
    let icon: String
}

struct FoodDeliveryProgressView: View {
    let steps: [DeliveryStep]
    let orderStatus: String
    
    // Base icon size, can adjust to taste
    private let baseIconSize: CGFloat = 25
    
    var body: some View {
        // Which step is currently active?
        let currentIndex = steps.firstIndex(where: { $0.status == orderStatus }) ?? 0
        let totalSteps   = steps.count
        
        ZStack(alignment: .center) {
            
            // MARK: 1) The “unfilled” gray track, centered vertically
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(height: 4)  // or 4 if you want it a bit thicker
                .overlay(
                    GeometryReader { geo in
                        // The total width of the track
                        let totalWidth   = geo.size.width
                        // Each segment’s width is totalWidth / (totalSteps - 1)
                        let segmentCount = max(totalSteps - 1, 1)
                        let segmentWidth = totalWidth / CGFloat(segmentCount)
                        
                        // MARK: 2) The “filled” (orange) portion
                        Rectangle()
                            .fill(Color.orange)
                            // Multiply segmentWidth by currentIndex to fill up to that step
                            .frame(width: segmentWidth * CGFloat(currentIndex), height: 4)
                            .animation(.easeInOut, value: currentIndex)
                    }
                )
            
            // MARK: 3) Icons, placed in a horizontal stack above the track
            HStack(spacing: 0) {
                ForEach(steps.indices, id: \.self) { i in
                    let isActive = i <= currentIndex
                    // Enlarge active/past icons slightly
                    let iconSize = isActive ? baseIconSize + 15 : baseIconSize
                    let iconColor: Color = isActive ? .orange : .gray
                    
                    ZStack {
                        // Optional circle behind icon, if you want a background
                        Circle()
                            .fill(Color(.systemBackground))
                            .frame(width: iconSize, height: iconSize)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        
                        Image(systemName: steps[i].icon)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(iconColor)
                            .frame(width: iconSize * 0.6, height: iconSize * 0.6)
                    }
                    
                    if i < totalSteps - 1 {
                        Spacer() // Distribute icons evenly
                    }
                }
            }
        }
        // Give enough height so the icons don’t clip.
        .frame(height: max(baseIconSize + 12, 30))
    }
}
