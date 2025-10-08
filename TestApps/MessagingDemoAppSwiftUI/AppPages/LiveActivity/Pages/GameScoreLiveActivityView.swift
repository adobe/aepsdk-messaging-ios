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
import AEPMessagingLiveActivity

@available(iOS 16.1, *)
struct GameScoreLiveActivityView: View {
    // MARK: - Observed / State Properties
    
    /// Keep track of all running GameScore activities so we can refresh easily
    @State private var runningActivities: [Activity<GameScoreLiveActivityAttributes>] = []
    
    /// Whether each activity row is expanded (dropdown shown)
    @State private var expandedActivities: [String: Bool] = [:]
    
    /// Per-activity "Dismiss Immediately" toggle
    @State private var endImmediateToggles: [String: Bool] = [:]
    
    /// Per-activity Score & Status, initially populated from contentState
    @State private var activityValues: [String: (homeTeamScore: Int, awayTeamScore: Int, statusText: String)] = [:]

    /// State to hold the liveActivityID input
    @State private var liveActivityID: String = ""
    
    /// State to control alert visibility
    @State private var showAlert: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // MARK: - Start Live Activity
                BigHeader(title: "Start Live Activity")
                
                // 1) Push-to-start (iOS 17.2+)
                if #available(iOS 17.2, *) {
                    PushToStartSection<GameScoreLiveActivityAttributes>(
                        pushToStartToken: TokenCollector.gameScorePushToStartToken
                                       )
                } else {
                    Text("Push-to-start not available on < iOS 17.2")
                }
                
                // 2) Start in-app
                startActivitySection
                
                // MARK: - Live Activity in Progress
                HStack {
                    BigHeader(title: "Live Activity in Progress")
                    Spacer()
                    
                    // Refresh Button
                    Button {
                        refreshActivities()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                    .padding(.trailing, 10)
                }
                
                // If no activities are running, display placeholder
                if runningActivities.isEmpty {
                    Text("No live activities in progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                } else {
                    // Otherwise, list each running activity
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(runningActivities.indices, id: \.self) { index in
                            let activity = runningActivities[index]
                            activityRow(activity: activity, index: index)
                            Divider()
                        }
                    }
                    .padding(.horizontal, 10)
                }
            }
            .navigationTitle("🏈 Game Live Activity")
            .padding(.horizontal, 10)
            .alert("Live Activity ID Required", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter a Live Activity ID to start the activity.")
            }
        }
        .onAppear {
            // Refresh on first load
            refreshActivities()
        }
    }
}

@available(iOS 16.1, *)
private extension GameScoreLiveActivityView {
    /// Section: Start a new Live Activity in-app
    var startActivitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionHeader(title: "Local")
                Spacer()
                SectionSubHeader(title: "iOS 16.1+")
            }
            SectionDescription(text: "Manually start a GameScore Live Activity from the app. After starting, a unique push token is generated. Use it to send push-based updates to this Live Activity.")
            
            // Text field for liveActivityID
            TextField("Enter Live Activity ID", text: $liveActivityID)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.vertical, 4)
            
            // Button to start the Live Activity
            Button(action: startLiveActivity) {
                Text("Start Live Activity")
                    .fontWeight(.medium)
                    .padding(.all, 10)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(8)
            }
            .foregroundColor(.blue)
            .padding(.top, 10)
        }
        .padding(.horizontal, 10)
    }
    
    /// Row for each running activity
    func activityRow(activity: Activity<GameScoreLiveActivityAttributes>, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            
            // Top row (title, ID, push token)
            HStack(alignment: .top) {
                // Left side: Activity number and ID
                VStack(alignment: .leading, spacing: 2) {
                    Text("Activity \(index + 1)")
                        .font(.headline)
                    Text(activity.id)
                        .font(.system(size: 7))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Right side: push token
                let pushToken = activity.pushToken
                    .map { $0.map { String(format: "%02x", $0) }.joined() } ?? ""
                let displayToken = pushToken.isEmpty ? "No token" : truncateToken(pushToken)
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(displayToken)
                            .font(.subheadline)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .foregroundColor(.secondary)
                        
                        Button {
                            UIPasteboard.general.string = pushToken
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .foregroundColor(pushToken.isEmpty ? .gray : .blue)
                    }
                }
            }
            
            // Content state summary
            let contentState = activity.contentState
            Text("Wingdom: \(contentState.homeTeamScore), Claws: \(contentState.awayTeamScore), Status: \(contentState.statusText)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Edit button at the bottom-right
            HStack {
                Spacer()
                
                Button {
                    expandedActivities[activity.id]?.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Text("Edit")
                        Image(systemName: expandedActivities[activity.id, default: false]
                              ? "chevron.up"
                              : "chevron.down")
                    }
                }
                .foregroundColor(.gray)
            }
            
            // Expanded section with a different background
            if expandedActivities[activity.id, default: false] {
                VStack(alignment: .leading, spacing: 12) {
                    
                    // Score & Status fields
                    ActivityUpdateView(
                        homeTeamScore: Binding(
                            get: { activityValues[activity.id]?.homeTeamScore ?? 0 },
                            set: { activityValues[activity.id]?.homeTeamScore = $0 }
                        ),
                        awayTeamScore: Binding(
                            get: { activityValues[activity.id]?.awayTeamScore ?? 0 },
                            set: { activityValues[activity.id]?.awayTeamScore = $0 }
                        ),
                        gameStatus: Binding(
                            get: { activityValues[activity.id]?.statusText ?? "" },
                            set: { activityValues[activity.id]?.statusText = $0 }
                        ),
                        onUpdate: { updateActivity(activity) }
                    )
                    
                    // "Dismiss Immediately" toggle + End button
                    Toggle("Dismiss Immediately", isOn: Binding(
                        get: { endImmediateToggles[activity.id, default: false] },
                        set: { endImmediateToggles[activity.id] = $0 }
                    ))
                    .font(.system(size: 13))
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
  
                    
                    HStack {
                        Spacer()
                        Button("End Activity") {
                            endSelectedActivity(
                                activity: activity,
                                immediate: endImmediateToggles[activity.id, default: false]
                            )
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(6)
                        Spacer()
                    }
                    
                }
                .padding(10)
                .background(Color(UIColor.systemGray6))  // Slight depth
                .cornerRadius(8)
            }
        }
        .padding(6)
        .background(Color.clear)
        .cornerRadius(8)
        .onAppear {
            // Initialize the dictionaries if needed
            if expandedActivities[activity.id] == nil {
                expandedActivities[activity.id] = false
            }
            if endImmediateToggles[activity.id] == nil {
                endImmediateToggles[activity.id] = false
            }
            if activityValues[activity.id] == nil {
                // Pull the current content state to start
                let cs = activity.contentState
                activityValues[activity.id] = (cs.homeTeamScore, cs.awayTeamScore, cs.statusText)
            }
        }
    }
    
    // MARK: - Methods
    
    /// Refresh the running activities list
    func refreshActivities() {
        let current = Activity<GameScoreLiveActivityAttributes>.activities
        runningActivities = current
        
        // Also refresh the content states in `activityValues`
        for activity in current {
            let cs = activity.contentState
            activityValues[activity.id] = (cs.homeTeamScore, cs.awayTeamScore, cs.statusText)
        }
    }
    
    /// Start a new Live Activity
    func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are disabled on this device.")
            return
        }
        
        // Validate liveActivityID
        let trimmedLiveActivityID = liveActivityID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLiveActivityID.isEmpty else {
            showAlert = true
            return
        }
        
        let attributes = GameScoreLiveActivityAttributes(liveActivityData: LiveActivityData(liveActivityID: trimmedLiveActivityID))
        let initialContentState = GameScoreLiveActivityAttributes.ContentState(
            homeTeamScore: 0,
            awayTeamScore: 0,
            statusText: "Wingdom won the toss and choose to receive the ball")
        
        do {
            let newActivity = try Activity<GameScoreLiveActivityAttributes>.request(
                attributes: attributes,
                contentState: initialContentState,
                pushType: .token // to receive push updates
            )
            
            print("GameScore Live Activity requested. ID: \(newActivity.id)")
            
            // Refresh to include newly started activity
            refreshActivities()
        } catch {
            print("Error requesting live activity: \(error.localizedDescription)")
        }
    }
    
    /// Update scores/status on a specific activity
    func updateActivity(_ activity: Activity<GameScoreLiveActivityAttributes>) {
        guard let newScores = activityValues[activity.id] else { return }
        
        Task {
            let updatedState = GameScoreLiveActivityAttributes.ContentState(
                homeTeamScore: newScores.homeTeamScore,
                awayTeamScore: newScores.awayTeamScore,
                statusText: newScores.statusText
            )
            
            await activity.update(using: updatedState)
            print("Updated \(activity.id) with: \(updatedState)")
        }
    }
    
    /// End a specific activity
    func endSelectedActivity(activity: Activity<GameScoreLiveActivityAttributes>, immediate: Bool) {
        Task {
            if immediate {
                await activity.end(dismissalPolicy: .immediate)
            } else {
                await activity.end(dismissalPolicy: .default)
            }
            
            print("Live Activity ended: \(activity.id)")
            
            // Refresh the list
            refreshActivities()
        }
    }
}

// MARK: - Smaller Update View for each Activity

@available(iOS 16.1, *)
struct ActivityUpdateView: View {
    @Binding var homeTeamScore: Int
    @Binding var awayTeamScore: Int
    @Binding var gameStatus: String
    
    let onUpdate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Scores side by side
            HStack {
                Spacer()
                Image("wingdomLogo")
                    .resizable()
                    .frame(width: 50, height: 50)
                VStack {
                    Text("Wingdom").font(.footnote).foregroundColor(.secondary)
                    TextField("0", value: $homeTeamScore, format: .number)
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                }
                Spacer()
                VStack {
                    Text("Claws").font(.footnote).foregroundColor(.secondary)
                    TextField("0", value: $awayTeamScore, format: .number)
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                }
                Image("clawsLogo")
                    .resizable()
                    .frame(width: 45, height: 45)
                Spacer()
            }
            
            // Status row
            HStack {
                Text("Status:")
                    .font(.system(size: 13, weight: .light))
                TextField("Game Status", text: $gameStatus)
                    .font(.system(size: 13, weight: .light))
                    .textFieldStyle(.roundedBorder)
            }
            
            // Update button, centered
            HStack {
                Spacer()
                Button("Update Score") {
                    onUpdate()
                }
                .padding(.all, 8)
                .background(Color.blue.opacity(0.15))
                .cornerRadius(8)
                .foregroundColor(.blue)
                Spacer()
            }
        }
    }
}

#Preview {
    if #available(iOS 16.1, *) {
        GameScoreLiveActivityView()
    } else {
        // Fallback on earlier versions
    }
}
