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

import WidgetKit
import ActivityKit
import SwiftUI
import AEPMessagingLiveActivity

struct FoodDeliveryLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FoodDeliveryLiveActivityAttributes.self) { context in
            
            // Lock Screen / Expanded UI
            let status = context.state.orderStatus
            let minutes = minutesForStatus(status)
            
            /// Steps in your delivery journey
            let steps = [
                DeliveryStep(status: "Ordered",         icon: "bag.fill"),
                DeliveryStep(status: "Order Accepted",  icon: "checkmark.seal.fill"),
                DeliveryStep(status: "Preparing",       icon: "flame.fill"),
                DeliveryStep(status: "On the Way",      icon: "car.fill"),
                DeliveryStep(status: "Delivered",       icon: "house.fill")
            ]
            
            VStack(alignment: .leading, spacing: 12) {
                // 1) Header
                HStack {
                    Image("hungry")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                    
                    Text("Hungry App")
                        .font(.headline)
                }
                
                // 2) Restaurant name + status
                HStack {
                    Text(context.attributes.restaurantName)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(status)
                        .font(.subheadline)
                }
                
                // 3) Step-based progress
                FoodDeliveryProgressView(
                    steps: steps,
                    orderStatus: status
                )
                
                // 4) Current status text
                Text("\(minutes) min until drop off")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding()
            
        } dynamicIsland: { context in
            
            // Dynamic Island Regions
            let status = context.state.orderStatus
            let progress = progressValue(for: status)
            let minutes = minutesForStatus(status)
            let driverName = "John Doe"
            
            return DynamicIsland {
                // MARK: Expanded (Long-Press) Region
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text(context.attributes.restaurantName)
                            .font(.headline)
                        
                        Text("Driver: \(driverName)")
                            .font(.subheadline)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text("\(minutes) min")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text("until drop off")
                            .font(.footnote)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack {
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                            .tint(.orange)
                        
                        Text(status)
                            .font(.footnote)
                    }
                }
                
            } compactLeading: {
                Text("\(minutes)m")
                    .font(.caption2)
                    .foregroundColor(.orange)
            } compactTrailing: {
                Text("ETA")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } minimal: {
                Text("\(minutes)m")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
    }
}

// MARK: - Helper: Progress Calculation
private func progressValue(for status: String) -> Double {
    switch status {
    case "Ordered":
        return 0.0
    case "Order Accepted":
        return 0.25
    case "Preparing":
        return 0.50
    case "On the Way":
        return 0.75
    case "Delivered":
        return 1.0
    default:
        return 0.0
    }
}

// MARK: - Helper: Minutes Calculation (Mocked by Status)
private func minutesForStatus(_ status: String) -> Int {
    switch status {
    case "Ordered":
        return 30
    case "Order Accepted":
        return 25
    case "Preparing":
        return 15
    case "On the Way":
        return 5
    case "Delivered":
        return 0
    default:
        return 0
    }
}

// MARK: - Sample ContentStates (Previews Only)
extension FoodDeliveryLiveActivityAttributes.ContentState {
    static let ordered = Self(orderStatus: "Ordered")
    static let orderAccepted = Self(orderStatus: "Order Accepted")
    static let preparing = Self(orderStatus: "Preparing")
    static let onTheWay = Self(orderStatus: "On the Way")
    static let delivered = Self(orderStatus: "Delivered")
}

// MARK: - Preview
#Preview("Notification", as: .content,
         using: FoodDeliveryLiveActivityAttributes(liveActivityData: LiveActivityData(liveActivityID: "<UNIQUE_ORDER_ID>"),
            restaurantName: "Burger Boss")) {
    FoodDeliveryLiveActivity()
} contentStates: {
    FoodDeliveryLiveActivityAttributes.ContentState.ordered
    FoodDeliveryLiveActivityAttributes.ContentState.orderAccepted
    FoodDeliveryLiveActivityAttributes.ContentState.preparing
    FoodDeliveryLiveActivityAttributes.ContentState.onTheWay
    FoodDeliveryLiveActivityAttributes.ContentState.delivered
}
