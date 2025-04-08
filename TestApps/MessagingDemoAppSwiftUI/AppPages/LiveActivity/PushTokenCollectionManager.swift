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

/// Main manager class for push tokens (regular and Live Activity) collection and management.
/// This class serves as a parent class that coordinates TokenReminder, TokenSendingPreference,
/// and GoogleSheetUploader functionality.
class PushTokenCollectionManager: ObservableObject {
    
    // MARK: - Singleton Access
    static let shared = PushTokenCollectionManager()
    
    // MARK: - Push Token Properties
    @Published var gameScorePushToStartToken: String = ""
    @Published var foodDeliveryPushToStartToken: String = ""
    @Published var airplaneTrackingPushToStartToken: String = ""
    
    // MARK: - Initialization
    private init() {
        
        // Initialize token collection
        if #available(iOS 17.2, *) {
            getFoodDeliveryPushToStartToken()
            getGameScorePushToStartToken()
            getAirplaneTrackingPushToStartToken()
        }
    }
    
    // MARK: - Push-to-Start Token (iOS 17.2+)
    
    @available(iOS 17.2, *)
    func getGameScorePushToStartToken() {
        // First check if we already have the token
        if !gameScorePushToStartToken.isEmpty {
            return
        }
        
        // Try to get token directly
        tryGetDirectTokenFor(.gameScore)
    }
    
    @available(iOS 17.2, *)
    func getAirplaneTrackingPushToStartToken() {
        // First check if we already have the token
        if !airplaneTrackingPushToStartToken.isEmpty {
            return
        }
        
        // Try to get token directly
        tryGetDirectTokenFor(.airplaneTracking)
    }
    
    @available(iOS 17.2, *)
    func getFoodDeliveryPushToStartToken() {
        // First check if we already have the token
        if !foodDeliveryPushToStartToken.isEmpty {
            return
        }
        
        // Try to get token directly
        tryGetDirectTokenFor(.foodDelivery)
    }
    
    // MARK: - Push-to-Start Token Retrieval
    
    /// Enum to identify the activity type
    private enum ActivityType {
        case gameScore
        case foodDelivery
        case airplaneTracking
    }
    
    /// Get push-to-start tokens directly from the static property
    @available(iOS 17.2, *)
    private func tryGetDirectTokenFor(_ type: ActivityType) {
        Task {
            do {
                // Push-to-start tokens are accessed via a static property on the Activity class
                switch type {
                case .gameScore:
                    for try await tokenData in Activity<GameScoreLiveActivityAttributes>.pushToStartTokenUpdates {
                        let tokenHex = tokenData.map { String(format: "%02x", $0) }.joined()
                        DispatchQueue.main.async {
                            NSLog("Peaks LA : Got GameScore push-to-start token: \(tokenHex)")
                            self.gameScorePushToStartToken = tokenHex
                        }
                        break // Only need the first token
                    }
                case .foodDelivery:
                    for try await tokenData in Activity<FoodDeliveryLiveActivityAttributes>.pushToStartTokenUpdates {
                        let tokenHex = tokenData.map { String(format: "%02x", $0) }.joined()
                        DispatchQueue.main.async {
                            NSLog("Peaks LA : Got FoodDelivery push-to-start token: \(tokenHex)")
                            self.foodDeliveryPushToStartToken = tokenHex
                        }
                        break // Only need the first token
                    }
                case .airplaneTracking:
                    for try await tokenData in Activity<AirplaneTrackingAttributes>.pushToStartTokenUpdates {
                        let tokenHex = tokenData.map { String(format: "%02x", $0) }.joined()
                        DispatchQueue.main.async {
                            NSLog("Peaks LA : Got AirplaneTracking push-to-start token: \(tokenHex)")
                            self.airplaneTrackingPushToStartToken = tokenHex
                        }
                        break
                    }
                }
            } catch {
                NSLog("Peaks LA : Error in token retrieval for \(type): \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Observe push tokens on a manually started Activity
    
    @available(iOS 16.1, *)
    func getRunningGameScoreActivities() -> [Activity<GameScoreLiveActivityAttributes>] {
        return Activity<GameScoreLiveActivityAttributes>.activities
    }
    
    @available(iOS 16.1, *)
    func getRunningFoodDeliveryActivities() -> [Activity<FoodDeliveryLiveActivityAttributes>] {
        return Activity<FoodDeliveryLiveActivityAttributes>.activities
    }
    
    @available(iOS 16.1, *)
    func getRunningAirplaneTrackingActivities() -> [Activity<AirplaneTrackingAttributes>] {
        return Activity<AirplaneTrackingAttributes>.activities
    }
}
