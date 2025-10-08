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
import ActivityKit
import Combine
import AEPCore

/// Main manager class for push tokens (regular and Live Activity) collection and management.
/// This class serves as a parent class that coordinates TokenReminder, TokenSendingPreference,
/// and GoogleSheetUploader functionality.
class TokenCollector: NSObject ,ObservableObject, Extension {
    
    // MARK: - Extension Properties
    static var extensionVersion = "5.0.0"
    var metadata: [String : String]?
    public var name = "com.adobe.sharedstateReader"
    public var friendlyName = "Share State Reader"
    public var runtime: ExtensionRuntime
    
    // MARK: - Push Token Properties
    // Static properties to store push tokens for different Live Activities
    static var gameScorePushToStartToken: String = ""
    static var foodDeliveryPushToStartToken: String = ""
    static var airplaneTrackingPushToStartToken: String = ""

    
    public required init?(runtime: ExtensionRuntime) {
        self.runtime = runtime
    }
    
    // MARK: - Extension Methods
    public func onRegistered() {
        registerListener(type: EventType.hub, source: EventSource.sharedState, listener: handleSharedStateEvent)
    }
    
    func onUnregistered() {}
    
    func readyForEvent(_ event: Event) -> Bool {
        true
    }
    
    // MARK: - Shared State Handler
    private func handleSharedStateEvent(event: Event) {
        if (event.data?["stateowner"] as! String == "com.adobe.messaging") {
            let messagingState = runtime.getSharedState(extensionName: "com.adobe.messaging", event: nil, barrier: false)?.value
            
            // Extract push-to-start tokens from the new messaging state structure
            if let sharedState = messagingState,
               let liveActivity = sharedState["liveActivity"] as? [String: Any],
               let pushToStartTokens = liveActivity["pushToStartTokens"] as? [String: Any] {
                
                // Extract GameScore token
                if let gameScoreToken = pushToStartTokens["GameScoreLiveActivityAttributes"] as? [String: Any],
                   let token = gameScoreToken["token"] as? String {
                    DispatchQueue.main.async {
                        TokenCollector.gameScorePushToStartToken = token
                        NSLog("Peaks LA : Updated GameScore push-to-start token: \(token)")
                    }
                }
                
                // Extract AirplaneTracking token
                if let airplaneToken = pushToStartTokens["AirplaneTrackingAttributes"] as? [String: Any],
                   let token = airplaneToken["token"] as? String {
                    DispatchQueue.main.async {
                        TokenCollector.airplaneTrackingPushToStartToken = token
                        NSLog("Peaks LA : Updated AirplaneTracking push-to-start token: \(token)")
                    }
                }
                
                // Extract FoodDelivery token
                if let foodDeliveryToken = pushToStartTokens["FoodDeliveryLiveActivityAttributes"] as? [String: Any],
                   let token = foodDeliveryToken["token"] as? String {
                    DispatchQueue.main.async {
                        TokenCollector.foodDeliveryPushToStartToken = token
                        NSLog("Peaks LA : Updated FoodDelivery push-to-start token: \(token)")
                    }
                }
            }
        }
    }
}
