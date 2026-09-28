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

    // Attribute type identifiers for the demo app's Live Activities.
    static let gameScoreType = "GameScoreLiveActivityAttributes"
    static let foodDeliveryType = "FoodDeliveryLiveActivityAttributes"
    static let airplaneTrackingType = "AirplaneTrackingAttributes"

    public required init?(runtime: ExtensionRuntime) {
        self.runtime = runtime
    }

    // MARK: - Extension Methods
    public func onRegistered() {
        // Restore any persisted push-to-start tokens so they can be re-sent after an app relaunch.
        TokenCollector.loadPersistedTokens()
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
                if let gameScoreToken = pushToStartTokens[TokenCollector.gameScoreType] as? [String: Any],
                   let token = gameScoreToken["token"] as? String {
                    DispatchQueue.main.async {
                        TokenCollector.gameScorePushToStartToken = token
                        TokenCollector.persist(token: token, for: TokenCollector.gameScoreType)
                        NSLog("Peaks LA : Updated GameScore push-to-start token: \(token)")
                    }
                }

                // Extract AirplaneTracking token
                if let airplaneToken = pushToStartTokens[TokenCollector.airplaneTrackingType] as? [String: Any],
                   let token = airplaneToken["token"] as? String {
                    DispatchQueue.main.async {
                        TokenCollector.airplaneTrackingPushToStartToken = token
                        TokenCollector.persist(token: token, for: TokenCollector.airplaneTrackingType)
                        NSLog("Peaks LA : Updated AirplaneTracking push-to-start token: \(token)")
                    }
                }

                // Extract FoodDelivery token
                if let foodDeliveryToken = pushToStartTokens[TokenCollector.foodDeliveryType] as? [String: Any],
                   let token = foodDeliveryToken["token"] as? String {
                    DispatchQueue.main.async {
                        TokenCollector.foodDeliveryPushToStartToken = token
                        TokenCollector.persist(token: token, for: TokenCollector.foodDeliveryType)
                        NSLog("Peaks LA : Updated FoodDelivery push-to-start token: \(token)")
                    }
                }
            }
        }
    }

    // MARK: - Persistence & Re-send

    private static func udKey(for attributeType: String) -> String { "la_pts_\(attributeType)" }

    private static func persist(token: String, for attributeType: String) {
        UserDefaults.standard.set(token, forKey: udKey(for: attributeType))
    }

    /// Restores previously persisted push-to-start tokens into memory so they survive an app
    /// relaunch (mirrors how the device push token is stored in UserDefaults).
    static func loadPersistedTokens() {
        let defaults = UserDefaults.standard
        gameScorePushToStartToken = defaults.string(forKey: udKey(for: gameScoreType)) ?? gameScorePushToStartToken
        foodDeliveryPushToStartToken = defaults.string(forKey: udKey(for: foodDeliveryType)) ?? foodDeliveryPushToStartToken
        airplaneTrackingPushToStartToken = defaults.string(forKey: udKey(for: airplaneTrackingType)) ?? airplaneTrackingPushToStartToken
    }

    /// The Live Activity push-to-start tokens currently held (non-empty), keyed by attribute type.
    static var heldPushToStartTokens: [String: String] {
        [
            gameScoreType: gameScorePushToStartToken,
            foodDeliveryType: foodDeliveryPushToStartToken,
            airplaneTrackingType: airplaneTrackingPushToStartToken
        ].filter { !$0.value.isEmpty }
    }

    /// Re-dispatches the held Live Activity push-to-start tokens through the SDK, mirroring the
    /// internal batched push-to-start event so the tokens are re-synced to Edge. Use this after
    /// `Messaging.clearLiveActivities()` to re-register the tokens for testing.
    ///
    /// The event keys mirror AEPMessaging's internal MessagingConstants values.
    /// - Returns: the number of tokens re-sent.
    @discardableResult
    static func resendHeldPushToStartTokens() -> Int {
        let tokensArray = heldPushToStartTokens.map { attributeType, token in
            ["attributeType": attributeType, "token": token]
        }
        guard !tokensArray.isEmpty else { return 0 }

        let event = Event(name: "Live Activity push-to-start token (Batched) Re-send",
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: [
                              "isLiveActivityPushToStartTokenEvent": true,
                              "batchedPushToStartTokens": tokensArray
                          ])
        MobileCore.dispatch(event: event)
        return tokensArray.count
    }
}
