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

import ActivityKit
import WidgetKit
import SwiftUI
import AEPMessagingLiveActivity

// MARK: - GameScoreLiveActivity
struct GameScoreLiveActivity: Widget {
    
    // Helper to get quarter string based on total score
    func quarterString(from totalScore: Int) -> String {
        switch totalScore {
        case 0...15:   return "Q1"
        case 16...30:  return "Q2"
        case 31...45:  return "Q3"
        default:       return "Q4"
        }
    }
    
    // Helper to generate a random time between 00:00 and 15:00
    func randomTimeString() -> String {
        let randomSeconds = Int.random(in: 0...900) // 0 to 900
        let minutes = randomSeconds / 60
        let seconds = randomSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: GameScoreLiveActivityAttributes.self) { context in
            
            let totalScore = context.state.homeTeamScore + context.state.awayTeamScore
            let quarter = quarterString(from: totalScore)
            let timeString = randomTimeString()
            
            VStack(spacing: 4) {
                // Top row: Logos, Team Names, and Scores
                HStack(alignment: .center) {
                    Spacer()
                    // Left Team
                    VStack {
                        Image("wingdomLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 55, height: 55)   // Larger logo
                        Text("Wingdom")
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    // Scores in the middle
                    HStack(spacing: 10) {
                        Text("\(context.state.homeTeamScore)")
                            .font(.system(size: 38, weight: .bold))
                        
                        Text("-")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("\(context.state.awayTeamScore)")
                            .font(.system(size: 38, weight: .bold))
                    }
                    
                    Spacer()
                    
                    // Right Team
                    VStack {
                        Image("clawsLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)   // Larger logo
                        Text("Claws")
                            .font(.caption)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                
                // Quarter & Time (centered below the scores)
                HStack(spacing: 6) {
                    Text("\(quarter)")
                        .font(.system(size: 14, weight: .semibold))
                    Text("—")
                        .font(.system(size: 14))
                    Text("\(timeString)")
                        .font(.system(size: 14, weight: .semibold))
                }
                
                // Game status text with a small red bar on the left
                HStack(alignment: .center, spacing: 6) {
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 3, height: 20) // Thin vertical bar

                    Text(context.state.statusText)
                        .font(.system(size: 14))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        // Make sure it's at least 22 points tall to look bigger
                        .frame(minHeight: 22)
                }
            }
            .padding(.vertical, 8)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded Island Regions
                DynamicIslandExpandedRegion(.leading) { }
                DynamicIslandExpandedRegion(.trailing) { }
                DynamicIslandExpandedRegion(.bottom) {
                    let totalScore = context.state.homeTeamScore + context.state.awayTeamScore
                    let quarter = quarterString(from: totalScore)
                    let timeString = randomTimeString()
                    
                    VStack {
                        // Top row: Teams & Scores
                        HStack(alignment: .center) {
                            // Left team
                            Spacer()
                            VStack {
                                Image("wingdomLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                Text("Wingdom")
                                    .font(.caption2)
                            }
                            
                            Spacer()
                            
                            // Scores
                            HStack(spacing: 8) {
                                Text("\(context.state.homeTeamScore)")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                Text("-")
                                    .font(.largeTitle)
                                Text("\(context.state.awayTeamScore)")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                            
                            // Right team
                            VStack {
                                Image("clawsLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                Text("Claws")
                                    .font(.caption2)
                            }
                            
                            Spacer()
                        }
                        
                        // Quarter & Time
                        HStack(spacing: 6) {
                            Text("\(quarter)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                            Text("—")
                                .font(.caption2)
                            Text("\(timeString)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        
                        // Status text with a small red bar on the left
                        HStack(alignment: .center, spacing: 6) {
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: 3, height: 20)
                            
                            Text(context.state.statusText)
                                .font(.subheadline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(minHeight: 22)
                        }
                    }
                }
            } compactLeading: {
                // Compact leading region
                HStack(spacing: 2) {
                    Image("wingdomLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("\(context.state.homeTeamScore)")
                        .font(.caption2)
                }
            } compactTrailing: {
                // Compact trailing region
                HStack(spacing: 2) {
                    Image("clawsLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("\(context.state.awayTeamScore)")
                        .font(.caption2)
                }
            } minimal: {
                // Minimal region — combined score
                Text("\(context.state.homeTeamScore)-\(context.state.awayTeamScore)")
                    .font(.caption2)
            }
        }
    }
}

// MARK: - Preview States

extension GameScoreLiveActivityAttributes.ContentState {
    static let startOfGame = Self(
        homeTeamScore: 0,
        awayTeamScore: 0,
        statusText: "Kickoff!"
    )
    
    static let midGame = Self(
        homeTeamScore: 14,
        awayTeamScore: 10,
        statusText: "2nd Quarter, 5:43 left"
    )
    
    static let finalScore = Self(
        homeTeamScore: 27,
        awayTeamScore: 24,
        statusText: "Final Score"
    )
}

// MARK: - Preview

#Preview("Notification", as: .content,
         using: GameScoreLiveActivityAttributes(liveActivityData: LiveActivityData(liveActivityID: "<UNIQUE_GAME_ID>"))
) {
    GameScoreLiveActivity()
} contentStates: {
    GameScoreLiveActivityAttributes.ContentState.startOfGame
    GameScoreLiveActivityAttributes.ContentState.midGame
    GameScoreLiveActivityAttributes.ContentState.finalScore
}
