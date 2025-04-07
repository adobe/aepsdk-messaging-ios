//
//  FoodDeliveryLiveActivity.swift
//  MobileTestApp
//
//  Created by Pravin Prakash Kumar on 1/3/25.
//

import WidgetKit
import ActivityKit
import SwiftUI

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
         using: FoodDeliveryLiveActivityAttributes(restaurantName: "Habit Burger", liveActivityData: AEPLiveActivityData.create(liveActivityID: "orderID123"))) {
    FoodDeliveryLiveActivity()
} contentStates: {
    FoodDeliveryLiveActivityAttributes.ContentState.ordered
    FoodDeliveryLiveActivityAttributes.ContentState.orderAccepted
    FoodDeliveryLiveActivityAttributes.ContentState.preparing
    FoodDeliveryLiveActivityAttributes.ContentState.onTheWay
    FoodDeliveryLiveActivityAttributes.ContentState.delivered
}
