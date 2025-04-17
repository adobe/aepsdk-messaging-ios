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

#if canImport(ActivityKit)
    import ActivityKit
#endif

import AEPCore
import AEPMessagingLiveActivity
import AEPServices

// Extension for Messaging class for Live Activity public APIs
@available(iOS 16.1, *)
public extension Messaging {
    // MARK: - Shared Storage

    /// A shared store used to manage push tokens across the application.
    private static let liveActivityTokenStore = LiveActivityTokenStore()

    /// A shared task store for tasks that handle push-to-start token updates.
    private static let pushToStartTaskStore = ActivityTaskStore<String>()

    /// A shared task store for tasks that handle Live Activity update tokens and state transitions.
    private static let activityUpdateTaskStore = ActivityTaskStore<String>()

    /// Registers a Live Activity type with the Adobe Experience Platform SDK.
    ///
    /// When called, this method enables the SDK to:
    /// - Automatically collect push-to-start tokens for devices running iOS 17.2 or later
    /// - Manage the complete lifecycle of Live Activities including:
    ///   - Automatically collect the generated Live Activity update token
    ///   - Monitor state transitions (start, update, end)
    ///   - Event tracking for the registered activity type
    ///
    /// - Parameter type: The Live Activity type that conforms to the ``LiveActivityAttributes`` protocol.
    ///                   This type defines the structure and content of your Live Activity.
    static func registerLiveActivity<T: LiveActivityAttributes>(_: T.Type) {
        let attributeTypeName = T.attributeTypeName

        if #available(iOS 17.2, *) {
            let newPushTask = createPushToStartTokenTask(type: T.self)
            Task {
                await pushToStartTaskStore.setTask(for: attributeTypeName, task: newPushTask)
            }
        } else {
            Log.debug(
                label: MessagingConstants.LOG_TAG,
                "Not creating a Live Activity push-to-start token handler task for " +
                    "LiveActivityAttributes type \(attributeTypeName). " +
                    "iOS 17.2 or later is required to start a Live Activity with a push-to-start token."
            )
        }

        let newActivityUpdatesTask = createActivityUpdatesTask(type: T.self)
        Task {
            await activityUpdateTaskStore.setTask(for: attributeTypeName, task: newActivityUpdatesTask)
        }
    }

    // MARK: - Private Helper Functions

    /// Creates and returns a `Task` that listens for push-to-start token updates.
    ///
    /// This task observes the `pushToStartTokenUpdates` asynchronous sequence from `ActivityKit`
    /// and converts each received token into a hexadecimal string. If the token is new (not previously stored),
    /// it dispatches a push-to-start event to notify the system. Duplicate tokens are ignored to avoid redundant processing.
    ///
    /// - Parameters:
    ///   - type: The concrete type conforming to ``LiveActivityAttributes`` used to access the associated `Activity`.
    /// - Returns: A `Task` that runs indefinitely, monitoring and responding to incoming push-to-start tokens.
    ///            The task completes only if the underlying sequence ends or the task is explicitly cancelled.
    @available(iOS 17.2, *)
    private static func createPushToStartTokenTask<T: LiveActivityAttributes>(type _: T.Type) -> Task<Void, Never> {
        Task {
            let attributeTypeName = T.attributeTypeName

            // Remove this task from storage when the sequence ends.
            defer {
                Task {
                    await pushToStartTaskStore.removeTask(for: attributeTypeName)
                }
            }

            for await tokenData in Activity<T>.pushToStartTokenUpdates {
                let tokenHex = tokenData.hexEncodedString
                if await liveActivityTokenStore.updatePushToken(for: attributeTypeName, token: tokenHex) {
                    dispatchPushToStartTokenEvent(attributeTypeName: attributeTypeName, token: tokenHex)
                } else {
                    Log.debug(label: MessagingConstants.LOG_TAG, "Duplicate push-to-start token for \(attributeTypeName); skipping event.")
                }
            }
        }
    }

    /// Creates and returns a `Task` that listens for activity updates.
    ///
    /// This task observes the `activityUpdates` asynchronous sequence from `ActivityKit` for the given Live Activity type.
    /// When a new activity starts, it dispatches a start event and creates child tasks to monitor state transitions
    /// and push token updates specific to that activity.
    ///
    /// - Parameters:
    ///   - type: The concrete type conforming to ``LiveActivityAttributes`` used to observe Live Activity lifecycle and token updates.
    /// - Returns: A `Task` that runs indefinitely, listening for new Live Activities and setting up listeners
    ///            for their state changes and push token updates. The task completes only if the underlying sequence ends
    ///            or the task is explicitly cancelled.
    private static func createActivityUpdatesTask<T: LiveActivityAttributes>(type _: T.Type) -> Task<Void, Never> {
        Task {
            let attributeTypeName = T.attributeTypeName

            // Remove this task from storage when the sequence ends.
            defer {
                Task {
                    await activityUpdateTaskStore.removeTask(for: attributeTypeName)
                }
            }

            for await activity in Activity<T>.activityUpdates {
                // Dispatch Live Activity start tracking event
                dispatchStartEvent(activity: activity)

                // Use task group to manage state and push token updates concurrently.
                await withTaskGroup(of: Void.self) { group in
                    // Listen for state updates.
                    group.addTask {
                        for await newState in activity.activityStateUpdates {
                            if newState == .dismissed || newState == .ended {
                                dispatchStateUpdateEvent(activity: activity, state: newState)
                            }
                        }
                    }

                    // Listen for push token updates for this activity.
                    // Live Activities Broadcast via channels do not use this token.
                    group.addTask {
                        for await newTokenData in activity.pushTokenUpdates {
                            let newTokenHex = newTokenData.hexEncodedString
                            Log.debug(label: MessagingConstants.LOG_TAG, "Update token received for activity \(activity.id) (\(attributeTypeName)): \(newTokenHex)")
                            dispatchUpdateTokenEvent(activity: activity, token: newTokenHex)
                        }
                    }
                }
            }
        }
    }

    /// Dispatches an event indicating that a Live Activity push-to-start token has been received.
    ///
    /// This method constructs and dispatches an event to Messaging extension that represents
    /// the push-to-start token and associated details for a specific Live Activity type.
    ///
    /// - Parameters:
    ///   - attributeTypeName: A unique string identifier representing the ``LiveActivityAttributes`` type associated with the Live Activity.
    ///   - token: A `String` representing the push-to-start token for the Live Activity.
    private static func dispatchPushToStartTokenEvent(attributeTypeName: String, token: String) {
        Log.debug(label: MessagingConstants.LOG_TAG,
                  """
                  Dispatching Live Activity push-to-start token event.
                  Token: \(token)
                  Type: \(attributeTypeName)
                  """)

        let eventName = "\(MessagingConstants.Event.Name.LIVE_ACTIVITY_PUSH_TO_START) for type (\(attributeTypeName))"
        let event = Event(name: eventName,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: [
                              MessagingConstants.Event.Data.Key.LIVE_ACTIVITY_PUSH_TO_START_TOKEN: true,
                              MessagingConstants.XDM.Push.TOKEN: token,
                              MessagingConstants.Event.Data.Key.ATTRIBUTE_TYPE: attributeTypeName
                          ])
        MobileCore.dispatch(event: event)
    }

    /// Dispatches an event indicating that a Live Activity's push token has been updated.
    ///
    /// This method constructs and dispatches an event to Messaging extension that represents
    /// the update token and associated details for a specific Live Activity.
    ///
    /// - Parameters:
    ///   - activity: The `Activity` instance whose push token was updated. The activity must conform to ``LiveActivityAttributes``.
    ///   - token: A `String` representing the update push token for the Live Activity.
    private static func dispatchUpdateTokenEvent<T: LiveActivityAttributes>(activity: Activity<T>, token: String) {
        let attributeTypeName = T.attributeTypeName
        guard let liveActivityID = activity.attributes.liveActivityData.liveActivityID else {
            Log.error(label: MessagingConstants.LOG_TAG,
                      """
                      Missing required '\(MessagingConstants.XDM.Push.LIVE_ACTIVITY_ID)'. Update token event will not be sent.
                      Type: \(attributeTypeName)
                      Apple Live Activity ID: \(activity.id)
                      """)
            return
        }

        Log.debug(label: MessagingConstants.LOG_TAG,
                  """
                  Dispatching Live Activity update token event.
                  Type: \(attributeTypeName)
                  Apple Live Activity ID: \(activity.id)
                  LiveActivityID: \(liveActivityID))
                  Token: \(token)
                  """)

        let eventName = "\(MessagingConstants.Event.Name.LIVE_ACTIVITY_PUSH_TO_START) for type (\(attributeTypeName))"

        let event = Event(name: eventName,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: [
                              MessagingConstants.Event.Data.Key.LIVE_ACTIVITY_UPDATE_TOKEN: true,
                              MessagingConstants.XDM.Push.TOKEN: token,
                              MessagingConstants.Event.Data.Key.ATTRIBUTE_TYPE: attributeTypeName,
                              MessagingConstants.Event.Data.Key.APPLE_LIVE_ACTIVITY_ID: activity.id,
                              MessagingConstants.XDM.Push.LIVE_ACTIVITY_ID: liveActivityID
                          ])
        MobileCore.dispatch(event: event)
    }

    /// Dispatches an event indicating that a Live Activity has started.
    ///
    /// This method is used to send an event indicating the start of a Live Activity,
    ///
    /// - Parameter activity: The newly started `Activity` instance. The activity must conform to ``LiveActivityAttributes``.
    private static func dispatchStartEvent<T: LiveActivityAttributes>(activity: Activity<T>) {
        let attributeTypeName = T.attributeTypeName
        let liveActivityIdentifierData = activity.attributes.liveActivityIdentifierData

        Log.debug(label: MessagingConstants.LOG_TAG,
                  """
                  Dispatching Live Activity start event.
                  Type: \(attributeTypeName)
                  Apple Live Activity ID: \(activity.id)
                  Identifier: \(liveActivityIdentifierData)
                  """)

        var data: [String: Any] = [
            MessagingConstants.Event.Data.Key.LIVE_ACTIVITY_TRACK_START: true,
            MessagingConstants.Event.Data.Key.ATTRIBUTE_TYPE: attributeTypeName,
            MessagingConstants.Event.Data.Key.APPLE_LIVE_ACTIVITY_ID: activity.id,
            MessagingConstants.XDM.Push.ORIGIN: activity.attributes.liveActivityData.origin
        ]

        // Merge in the single identifier (liveActivityID or channelID)
        data.merge(liveActivityIdentifierData) { current, _ in current }

        let eventName = "\(MessagingConstants.Event.Name.LIVE_ACTIVITY_START) for type (\(attributeTypeName))"
        let event = Event(name: eventName,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: data)
        MobileCore.dispatch(event: event)
    }

    /// Dispatches an event to track a Live Activity state update.
    ///
    /// This method is used to send an event indicating a change in the state of a Live Activity,
    /// such as when it transitions to `.active`, `.ended`, or `.dismissed`.
    ///
    /// - Parameters:
    ///   - activity: The Live Activity instance whose state has changed. The activity must conform to ``LiveActivityAttributes``.
    ///   - state: The new `ActivityState` representing the current lifecycle state of the activity.
    private static func dispatchStateUpdateEvent<T: LiveActivityAttributes>(
        activity: Activity<T>,
        state: ActivityState
    ) {
        let attributeTypeName = T.attributeTypeName
        let liveActivityIdentifierData = activity.attributes.liveActivityIdentifierData

        Log.debug(label: MessagingConstants.LOG_TAG,
                  """
                  Dispatching Live Activity \(state) state update event.
                  Type: \(attributeTypeName)
                  Apple Live Activity ID: \(activity.id)
                  Identifier: \(liveActivityIdentifierData)
                  """)
        
        var data: [String: Any] = [
            MessagingConstants.Event.Data.Key.LIVE_ACTIVITY_TRACK_STATE: true,
            MessagingConstants.Event.Data.Key.APPLE_LIVE_ACTIVITY_ID: activity.id,
            MessagingConstants.Event.Data.Key.STATE: "\(state)"
        ]

        // Merge in the single identifier (liveActivityID or channelID)
        data.merge(liveActivityIdentifierData) { current, _ in current }

        let eventName = "\(MessagingConstants.Event.Name.LIVE_ACTIVITY_STATE): \(state) for type (\(attributeTypeName))"
        let event = Event(name: eventName,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: data)
        MobileCore.dispatch(event: event)
    }
}
