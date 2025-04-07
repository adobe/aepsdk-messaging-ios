//
//  FlightTrackingAttributes.swift
//  MobileTestApp
//
//  Created by Pravin Prakash Kumar on 1/4/25.
//


import ActivityKit
import Foundation
import AEPMessaging

@available(iOS 16.1, *)
struct AirplaneTrackingAttributes: LiveActivityAttributes {
    // static attributes
    var liveActivityData: LiveActivityData
    let arrivalAirport: String
    let departureAirport: String
    let arrivalTerminal: String
    
    
    // dynamic attributes
    public struct ContentState: Codable, Hashable {
        let journeyProgress: Int
    }
}
