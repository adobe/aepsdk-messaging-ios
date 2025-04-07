//
//  FoodDeliveryLiveActivityAttributes.swift
//  MobileTestApp
//
//  Created by Pravin Prakash Kumar on 1/3/25.
//

import ActivityKit
import AEPMessaging

@available(iOS 16.1, *)
struct FoodDeliveryLiveActivityAttributes: LiveActivityAttributes {
      
    // Static Attributes
    var restaurantName: String
    var liveActivityData: LiveActivityData  // adobe attribute
    
    // Dynamic Attributes
    struct ContentState: Codable, Hashable {
        /// Possible values: "Ordered", "Order Accepted", "Preparing", "On the Way", "Delivered"
        var orderStatus: String
    }
}
