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
struct FoodDeliveryLiveActivityView: View {
    // MARK: - Observed / State Properties
    
    /// An array of all currently running FoodDeliveryLiveActivities
    @State private var runningActivities: [Activity<FoodDeliveryLiveActivityAttributes>] = []
    
    /// Expanded/collapsed states for each activity row (by activity ID)
    @State private var expandedActivities: [String: Bool] = [:]
    
    /// Whether each activity uses `.immediate` or `.default` dismissal
    @State private var endImmediateToggles: [String: Bool] = [:]
    
    /// Current statuses for each activity (stored by activity ID)
    @State private var activityStatuses: [String: String] = [:]
    
    /// State to hold the restaurant name input
    @State private var restaurantName: String = ""
    
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
                    PushToStartSection<FoodDeliveryLiveActivityAttributes>(
                        pushToStartToken: TokenCollector.foodDeliveryPushToStartToken)
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
            .navigationTitle("🍔 Food Delivery Live Activity")
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

// MARK: - Subviews
@available(iOS 16.1, *)
private extension FoodDeliveryLiveActivityView {
    
    
    /// Section: Start a new Live Activity in-app
    var startActivitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionHeader(title: "Local")
                Spacer()
                SectionSubHeader(title: "iOS 16.1+")
            }
            SectionDescription(text: "Manually start a Food Delivery Live Activity from the app. After starting, a unique push token is generated. Use it to send push-based updates to this Live Activity.")
            
            // Text field for restaurant name
            TextField("Enter Restaurant Name", text: $restaurantName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.vertical, 4)
            
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
    
    /// Row for each running FoodDelivery activity
    func activityRow(activity: Activity<FoodDeliveryLiveActivityAttributes>, index: Int) -> some View {
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
            Text("Current Status: \(contentState.orderStatus)")
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
                    
                    // Status picker
                    FoodDeliveryActivityUpdateView(
                        orderStatus: Binding(
                            get: { activityStatuses[activity.id] ?? "Order Accepted" },
                            set: { activityStatuses[activity.id] = $0 }
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
                            endActivity(activity, immediate: endImmediateToggles[activity.id, default: false])
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
            if activityStatuses[activity.id] == nil {
                // Pull the current content state to start
                let cs = activity.contentState
                activityStatuses[activity.id] = cs.orderStatus
            }
        }
    }
    
    // MARK: - Methods
    
    /// Refresh the running activities list
    func refreshActivities() {
        let current = Activity<FoodDeliveryLiveActivityAttributes>.activities
        runningActivities = current
        
        // Also refresh the content states in `activityStatuses`
        for activity in current {
            let cs = activity.contentState
            activityStatuses[activity.id] = cs.orderStatus
        }
    }
    
    /// Start a new Live Activity
    func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are disabled on this device.")
            return
        }
        
        // Validate inputs
        let trimmedLiveActivityID = liveActivityID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLiveActivityID.isEmpty else {
            showAlert = true
            return
        }
        
        // Create attributes using the entered restaurant name and liveActivityID
        let attributes = FoodDeliveryLiveActivityAttributes(liveActivityData: LiveActivityData(liveActivityID: trimmedLiveActivityID), restaurantName: restaurantName)
        let initialContentState = FoodDeliveryLiveActivityAttributes.ContentState(
            orderStatus: "Ordered"
        )
        
        do {
            let newActivity = try Activity<FoodDeliveryLiveActivityAttributes>.request(
                attributes: attributes,
                contentState: initialContentState,
                pushType: .token // to receive push updates
            )
            
            print("FoodDelivery Live Activity requested. ID: \(newActivity.id)")
            
            // Refresh to include newly started activity
            refreshActivities()
        } catch {
            print("Error requesting food delivery live activity: \(error.localizedDescription)")
        }
    }
    
    /// Update a specific Food Delivery Live Activity
    func updateActivity(_ activity: Activity<FoodDeliveryLiveActivityAttributes>) {
        guard let newStatus = activityStatuses[activity.id] else { return }
        
        Task {
            let updatedState = FoodDeliveryLiveActivityAttributes.ContentState(
                orderStatus: newStatus
            )
            await activity.update(using: updatedState)
            print("Updated \(activity.id) with status: \(newStatus)")
        }
    }
    
    /// End a specific Food Delivery Live Activity
    func endActivity(_ activity: Activity<FoodDeliveryLiveActivityAttributes>, immediate: Bool) {
        Task {
            if immediate {
                await activity.end(dismissalPolicy: .immediate)
            } else {
                await activity.end(dismissalPolicy: .default)
            }
            
            print("FoodDelivery Live Activity ended: \(activity.id)")
            refreshActivities()
        }
    }
}

// MARK: - FoodDeliveryActivityUpdateView
/// A subview for selecting a status (via Picker) and updating the activity
@available(iOS 16.1, *)
struct FoodDeliveryActivityUpdateView: View {
    // Predefined statuses
    private let statuses = [
        "Ordered",
        "Order Accepted",
        "Preparing",
        "On the Way",
        "Delivered"
    ]
    
    @Binding var orderStatus: String
    let onUpdate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            SectionDescription(text: "Update the live activity status.")
            
            HStack {
                Image("hungry")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                
                Text("Current Status")
                    .font(.subheadline)
                
                Picker("Select Status", selection: $orderStatus) {
                    ForEach(statuses, id: \.self) { status in
                        Text(status)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // "Update" button (centered)
            HStack {
                Spacer()
                Button("Update") {
                    onUpdate()
                }
                .fontWeight(.medium)
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
        FoodDeliveryLiveActivityView()
    } else {
        // Fallback on earlier versions
    }
}

