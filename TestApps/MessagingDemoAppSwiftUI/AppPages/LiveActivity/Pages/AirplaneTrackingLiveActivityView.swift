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

// MARK: - AirplaneTrackingLiveActivityView

@available(iOS 16.1, *)
struct AirplaneTrackingLiveActivityView: View {
    // MARK: - Observed / State Properties
    
    @ObservedObject var pushTokenManager = PushTokenCollectionManager.shared
    
    /// Keep track of all running AirplaneTracking activities so we can refresh easily
    @State private var runningActivities: [Activity<AirplaneTrackingAttributes>] = []
    
    /// Whether each activity row is expanded (dropdown shown)
    @State private var expandedActivities: [String: Bool] = [:]
    
    /// Per-activity "Dismiss Immediately" toggle
    @State private var endImmediateToggles: [String: Bool] = [:]
    
    /// Per-activity percentage completion, initially populated from contentState
    @State private var activityValues: [String: Double] = [:]
    
    @State private var channelID: String = ""
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // MARK: - Start Live Activity
                BigHeader(title: "Start Live Activity")
                
                // 1) Push-to-start (iOS 17.2+)
                if #available(iOS 17.2, *) {
                    PushToStartSection<AirplaneTrackingAttributes>(
                        pushToStartToken: $pushTokenManager.airplaneTrackingPushToStartToken
                    )
                } else {
                    Text("Push-to-start not available on < iOS 17.2")
                }
                
                // 2) Start in-app
                startActivitySection
                
                channelActivitySection
                
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
            .navigationTitle("✈️ Airplane Live Activity")
            .padding(.horizontal, 10)
        }
        .onAppear {
            // Refresh on first load
            refreshActivities()
        }
    }
}

// MARK: - Private Extension

@available(iOS 16.1, *)
private extension AirplaneTrackingLiveActivityView {
    
    /// Section: Start a new Live Activity in-app
    var startActivitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionHeader(title: "Using Application")
                Spacer()
                SectionSubHeader(title: "iOS 16.1+")
            }
            SectionDescription(text: "Manually start an AirplaneTracking Live Activity from the app. After starting, a unique push token is generated. Use it to send push-based updates to this Live Activity.")
            
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
    
    /// Section: Start a new Live Activity using Channel
    var channelActivitySection: some View {
           VStack(alignment: .leading, spacing: 8) {
               HStack {
                   SectionHeader(title: "Using Channel")
                   Spacer()
               }
               SectionDescription(text: "This will use channel to provide updates to the live activity.")
               
               // Text field for channel ID
               TextField("Enter Channel ID", text: $channelID)
                   .textFieldStyle(RoundedBorderTextFieldStyle())
                   .padding(.vertical, 4)
               
               // Button to start the Live Activity (push type: .channel)
               Button(action: startChannelActivity) {
                   Text("Subscribe and Start Activity")
                       .fontWeight(.medium)
                       .padding(.all, 10)
                       .background(Color.green.opacity(0.15))
                       .cornerRadius(8)
               }
               .foregroundColor(.green)
               .padding(.top, 10)
           }
           .padding(.horizontal, 10)
       }
    
    /// Row for each running activity
    func activityRow(activity: Activity<AirplaneTrackingAttributes>, index: Int) -> some View {
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
            Text("Percentage Completion: \(Int(contentState.journeyProgress))%\nArrival Terminal: \(activity.attributes.arrivalTerminal)")
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
                    
                    // Percentage Completion field
                    AirplaneTrackingActivityUpdateView(
                        journeyProgress: Binding(
                            get: { activityValues[activity.id] ?? 0.0 },
                            set: { activityValues[activity.id] = $0 }
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
                activityValues[activity.id] = Double(cs.journeyProgress) / 100.0
            }
        }
    }
    
    // MARK: - Methods
    
    /// Refresh the running activities list
    func refreshActivities() {
        let current = pushTokenManager.getRunningAirplaneTrackingActivities()
        runningActivities = current
        
        // Also refresh the content states in `activityValues`
        for activity in current {
           let cs = activity.contentState
            activityValues[activity.id] = Double(cs.journeyProgress) / 100.0
        }
    }
    
    /// Start a new Live Activity
    func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are disabled on this device.")
            return
        }
        
        // Example attribute + initial content state
        let attributes = AirplaneTrackingAttributes(liveActivityData: LiveActivityData.create(liveActivityID: "<unique_ID_for_airplane_tracking>"), arrivalAirport: "SFO", departureAirport: "MIA", arrivalTerminal: "Terminal 2")
        let initialContentState = AirplaneTrackingAttributes.ContentState(journeyProgress: 0)
        
        do {
            let newActivity = try Activity<AirplaneTrackingAttributes>.request(
                attributes: attributes,
                contentState: initialContentState,
                pushType: .token // to receive push updates
            )
            
            print("AirplaneTracking Live Activity requested. ID: \(newActivity.id)")
            
            // Refresh to include newly started activity
            refreshActivities()
        } catch {
            print("Error requesting live activity: \(error.localizedDescription)")
        }
    }
    
    /// Start a new Live Activity using pushType: .channel
     func startChannelActivity() {
         guard ActivityAuthorizationInfo().areActivitiesEnabled else {
             print("Live Activities are disabled on this device.")
             return
         }
         
         // Example attribute + initial content state
         let attributes = AirplaneTrackingAttributes(liveActivityData: LiveActivityData.create(channelID: "<Apple Push Channel ID>"), arrivalAirport: "SFO", departureAirport: "MIA", arrivalTerminal: "Terminal 2")
         let initialContentState = AirplaneTrackingAttributes.ContentState(journeyProgress: 0)
         
         // The channelID is taken from the text field
         let id = channelID.trimmingCharacters(in: .whitespacesAndNewlines)
         guard !id.isEmpty else {
             print("Channel ID cannot be empty.")
             return
         }
         
         do {
             if #available(iOS 18.0, *) {
                 let newActivity = try Activity<AirplaneTrackingAttributes>.request(
                    attributes: attributes,
                    contentState: initialContentState,
                    pushType: .channel(id)
                 )
                 print("AirplaneTracking Live Activity (CHANNEL: \(id)) requested. ID: \(newActivity.id)")
             } else {
                 // Fallback on earlier versions
             }
    
             // Refresh to include newly started activity
             refreshActivities()
         } catch {
             print("Error requesting live activity: \(error.localizedDescription)")
         }
     }
    /// Update percentage completion on a specific activity
    func updateActivity(_ activity: Activity<AirplaneTrackingAttributes>) {
        guard let sliderValue = activityValues[activity.id] else { return }
        let intPercentage = Int(sliderValue * 100)
        
        Task {
            let updatedState = AirplaneTrackingAttributes.ContentState(
                journeyProgress: intPercentage
            )
            
            await activity.update(using: updatedState)
            print("Updated \(activity.id) with: \(updatedState)")
        }
    }
    
    /// End a specific activity
    func endSelectedActivity(activity: Activity<AirplaneTrackingAttributes>, immediate: Bool) {
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
struct AirplaneTrackingActivityUpdateView: View {
    @Binding var journeyProgress: Double
    let onUpdate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Flight Progress:")
                .font(.footnote)
                .foregroundColor(.secondary)
            
            HStack {
                Text("0%")
                Slider(value: $journeyProgress, in: 0...1, step: 0.01)
                Text("100%")
            }
            
            Text("Current: \(Int(journeyProgress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Spacer()
                Button("Update Progress") {
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

// MARK: - Preview

#Preview {
    if #available(iOS 16.1, *) {
        AirplaneTrackingLiveActivityView()
    } else {
        Text("Requires iOS 16.1 or later")
    }
}

// MARK: - Helpers
