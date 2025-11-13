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

// MARK: - LiveActivityView

struct LiveActivityView: View {
    
    var body: some View {
        if #available(iOS 16.1, *) {
            // Structure the view to ensure banner only shows on the main page
            NavigationView {
                mainContentView
            }
            .onAppear {}
        } else {
            // Fallback for older versions
            Text("Live Activities are available only on iOS 16.1 or newer.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
    
    // MARK: - Main Content View
    
    @available(iOS 16.1, *)
    private var mainContentView: some View {
        VStack(spacing: 20) {
            Text("Use cases")
                .font(.title)
                .padding(.top)
            
            // Cards in a grid layout
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                // Card 1: Game Live Activity
                NavigationLink(destination: GameScoreLiveActivityView()) {
                    CardView(
                        imageName: "nfl",
                        title: "Game \n Live Activity"
                    )
                }

                // Card 2: Food Delivery Live Activity
                NavigationLink(destination: FoodDeliveryLiveActivityView()) {
                    CardView(
                        imageName: "hungry",
                        title: "Food Delivery \n Live Activity"
                    )
                }

                // Card 3: Airplane Tracking Live Activity
                NavigationLink(destination: AirplaneTrackingLiveActivityView()) {
                    CardView(
                        imageName: "AirplaneLogo",
                        title: "Airplane Tracking \n Live Activity"
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)            
            Spacer(minLength: 80) // Add space at the bottom for the banner
        }
    }
}

// MARK: - CardView (for each card in the grid)
struct CardView: View {
    let imageName: String
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 90, height: 90) // Increased size for images
                .foregroundColor(.blue)

            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 160, height: 180) // Ensures consistent size for all cards
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    LiveActivityView()
}
