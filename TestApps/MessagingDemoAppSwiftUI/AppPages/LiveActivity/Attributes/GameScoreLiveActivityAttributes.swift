//
//  GameScoreLiveActivityAttributes.swift
//  MobileTestApp
//
//  Created by Pravin Prakash Kumar on 1/3/25.
//

import ActivityKit
import AEPMessaging

@available(iOS 16.1, *)
struct GameScoreLiveActivityAttributes: LiveActivityAttributes {
    
    // static attribute
    var liveActivityData: LiveActivityData // Adobe attributes
    
    // Dynamic Attributes
    struct ContentState: Codable, Hashable {
        var ninersScore: Int
        var lionsScore: Int
        var statusText: String
    }
}
