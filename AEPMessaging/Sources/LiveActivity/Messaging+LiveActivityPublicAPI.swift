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

import AEPCore
import AEPServices

// Extension for Messaging class for Live Activity public APIs
@available(iOS 16.1, *)
public extension Messaging {
    // MARK: - Shared Storage

    /// Actor that manages and stores Live Activity push-to-start tokens in a thread-safe way.
    private actor LiveActivityStore {
        /// A dictionary storing push tokens associated with their corresponding keys.
        private var tokens: [String: String] = [:]

        /// Updates the token for the given key.
        ///
        /// - Parameters:
        ///   - key: The key associated with the token.
        ///   - token: The new push token to store.
        /// - Returns: `true` if the token was updated, `false` if the token was already set to the given value.
        func updatePushToken(for key: String, token: String) -> Bool {
            if tokens[key] == token { return false }
            tokens[key] = token
            return true
        }

        /// Retrieves the push token associated with the given key.
        ///
        /// - Parameter key: The key associated with the desired token.
        /// - Returns: The push token if it exists, or `nil` if not found.
        func pushToken(for key: String) -> String? {
            tokens[key]
        }

        /// Clears all stored push tokens.
        func clear() {
            tokens.removeAll()
        }
    }

    /// An actor that stores and manages `Task`s associated with Live Activity types in a thread-safe way.
    private actor ActivityTaskStore<Key: Hashable> {
        private var tasks: [Key: Task<Void, Never>] = [:]

        /// Sets or replaces the task for the given key.
        ///
        /// If `task` is `nil`, any existing task for the key will be removed.
        ///
        /// - Parameters:
        ///   - key: A `Hashable` key representing the Live Activity type or instance.
        ///   - task: The `Task` to associate with the key, or `nil` to remove the task.
        func setTask(for key: Key, task: Task<Void, Never>?) {
            tasks[key] = task
        }

        /// Retrieves the task associated with the given key.
        ///
        /// - Parameter key: The key identifying the task.
        /// - Returns: The associated `Task` if one exists, or `nil` if not found.
        func task(for key: Key) -> Task<Void, Never>? {
            tasks[key]
        }

        /// Removes the task associated with the given key.
        ///
        /// - Parameter key: The key representing the task to be removed.
        func removeTask(for key: Key) {
            tasks[key] = nil
        }

        /// Clears all stored tasks.
        func clear() {
            tasks.removeAll()
        }
    }

    /// A shared store used to manage push tokens across the application.
    private static let liveActivityStore = LiveActivityStore()

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
    /// - Parameter type: The Live Activity type that conforms to the `LiveActivityAttributes` protocol.
    ///                   This type defines the structure and content of your Live Activity.
    static func registerLiveActivity<T: LiveActivityAttributes>(_: T.Type) {
        let typeKey = T.typeKey

        if #available(iOS 17.2, *) {
            let newPushTask = createPushToStartTokenTask(type: T.self)
            Task {
                await pushToStartTaskStore.setTask(for: typeKey, task: newPushTask)
            }
        } else {
            Log.debug(
                label: MessagingConstants.LOG_TAG,
                "Not creating a Live Activity push-to-start token handler task for " +
                "LiveActivityAttributes type \(typeKey). " +
                "iOS 17.2 or later is required to start a Live Activity with a push-to-start token."
            )
        }

        let newActivityUpdatesTask = createActivityUpdatesTask(type: T.self)
        Task {
            await activityUpdateTaskStore.setTask(for: typeKey, task: newActivityUpdatesTask)
        }
    }

    // MARK: - Private Helper Functions

    /// Creates and returns a Task that listens for push-to-start token updates.
    ///
    /// This task observes the `pushToStartTokenUpdates` asynchronous sequence from `ActivityKit`
    /// and converts each received token into a hexadecimal string. If the token is new (not previously stored),
    /// it dispatches a push-to-start event to notify the system. Duplicate tokens are ignored to avoid redundant processing.
    ///
    /// - Parameters:
    ///   - type: The concrete type conforming to `LiveActivityAttributes` used to access the associated `Activity`.
    /// - Returns: A `Task` that runs indefinitely, monitoring and responding to incoming push-to-start tokens.
    ///            The task completes only if the underlying sequence ends or the task is explicitly cancelled.
    @available(iOS 17.2, *)
    private static func createPushToStartTokenTask<T: LiveActivityAttributes>(type: T.Type) -> Task<Void, Never> {
        Task {
            let typeKey = T.typeKey

            // Remove this task from storage when the sequence ends.
            defer {
                Task {
                    await pushToStartTaskStore.removeTask(for: typeKey)
                }
            }

            for await tokenData in Activity<T>.pushToStartTokenUpdates {
                let tokenHex = tokenData.map { String(format: "%02x", $0) }.joined()
                if await liveActivityStore.updatePushToken(for: typeKey, token: tokenHex) {
                    dispatchPushToStartTokenEvent(typeKey: typeKey, token: tokenHex)
                } else {
                    Log.debug(label: MessagingConstants.LOG_TAG, "Duplicate push-to-start token for \(typeKey); skipping event.")
                }
            }
        }
    }
    
    /// Creates and returns a Task that listens for activity updates.
    ///
    /// This task observes the `activityUpdates` asynchronous sequence from `ActivityKit` for the given Live Activity type.
    /// When a new activity starts, it dispatches a start event and creates child tasks to monitor state transitions
    /// and push token updates specific to that activity.
    ///
    /// - Parameters:
    ///   - type: The concrete type conforming to `LiveActivityAttributes` used to observe Live Activity lifecycle updates.
    /// - Returns: A `Task` that runs indefinitely, listening for new Live Activities and setting up listeners
    ///            for their state changes and push token updates. The task completes only if the underlying sequence ends
    ///            or the task is explicitly cancelled.
    private static func createActivityUpdatesTask<T: LiveActivityAttributes>(type: T.Type) -> Task<Void, Never> {
        Task {
            let typeKey = T.typeKey

            // Remove this task from storage when the sequence ends.
            defer {
                Task {
                    await activityUpdateTaskStore.removeTask(for: typeKey)
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
                            Log.debug(label: MessagingConstants.LOG_TAG, "Update token received for activity \(activity.id) (\(typeKey)): \(newTokenHex)")
                            dispatchUpdateTokenEvent(activity: activity, token: newTokenHex)
                        }
                    }
                }
            }
        }
    }

    /// Dispatches a generic event.
    private static func dispatchEvent(name: String, data: [String: Any]) {
        let event = Event(name: name, type: EventType.messaging, source: EventSource.requestContent, data: data)
        MobileCore.dispatch(event: event)
    }

    /// Dispatches an event when a push-to-start token is received.
    /// Dispatches an event indicating that a Live Activity push-to-start token has been received.
    ///
    /// This method constructs and dispatches an event to Messaging extension that represents
    /// the push-to-start token and associated details for a specific Live Activity type.
    ///
    /// - Parameters:
    ///   - typeKey: A unique string identifier representing the `LiveActivityAttributes` type associated with the Live Activity.
    ///   - token: A `String` representing the push-to-start token for the Live Activity.
    private static func dispatchPushToStartTokenEvent(typeKey: String, token: String) {
        Log.debug(label: MessagingConstants.LOG_TAG,
                  "Dispatching Live Activity push-to-start token event for type (\(typeKey)) " +
                  "with token (\(token))")

        dispatchEvent(name: "Live Activity push-to-start token for type (\(typeKey))", data: [
            MessagingConstants.Event.Data.Key.LIVE_ACTIVITY_PUSH_TO_START_TOKEN: true,
            MessagingConstants.XDM.Push.TOKEN: token,
            MessagingConstants.Event.Data.Key.ATTRIBUTE_TYPE: typeKey
        ])
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
        let typeKey = T.typeKey
        Log.debug(label: MessagingConstants.LOG_TAG,
                  "Dispatching Live Activity update token event for type (\(typeKey)) " +
                  "with token (\(token))")

        dispatchEvent(name: "Live Activity update token for type (\(typeKey))", data: [
            MessagingConstants.Event.Data.Key.LIVE_ACTIVITY_UPDATE_TOKEN: true,
            MessagingConstants.XDM.Push.TOKEN: token,
            MessagingConstants.Event.Data.Key.ATTRIBUTE_TYPE: typeKey,
            MessagingConstants.Event.Data.Key.APPLE_LIVE_ACTIVITY_ID: activity.id,
            MessagingConstants.Event.Data.Key.LIVE_ACTIVITY_ID: activity.attributes.liveActivityData.liveActivityID ?? MessagingConstants.Event.Data.Value.UNAVAILABLE
        ])
    }

    /// Dispatches an event indicating that a Live Activity has started.
    ///
    /// This method is used to send an event indicating the start of a Live Activity,
    ///
    /// - Parameter activity: The newly started `Activity` instance. The activity must conform to ``LiveActivityAttributes``.
    private static func dispatchStartEvent<T: LiveActivityAttributes>(activity: Activity<T>) {
        let typeKey = T.typeKey
        Log.debug(label: MessagingConstants.LOG_TAG,
                  "Dispatching start Live Activity event for type (\(typeKey)) " +
                  "with Apple Live Activity ID (\(activity.id)) " +
                  "and Live Activity ID (\(activity.attributes.liveActivityData.liveActivityID ?? "unavailable"))")

        dispatchEvent(name: "Live Activity started (\(typeKey))", data: [
            MessagingConstants.Event.Data.Key.LIVE_ACTIVITY_TRACK_START: true,
            MessagingConstants.Event.Data.Key.ATTRIBUTE_TYPE: typeKey,
            MessagingConstants.Event.Data.Key.APPLE_LIVE_ACTIVITY_ID: activity.id,
            MessagingConstants.Event.Data.Key.LIVE_ACTIVITY_ID: activity.attributes.liveActivityData.liveActivityID ?? MessagingConstants.Event.Data.Value.UNAVAILABLE
        ])
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
        let typeKey = T.typeKey
        Log.debug(label: MessagingConstants.LOG_TAG, "State update for activity \(activity.id) (\(typeKey)): \(state)")
        dispatchEvent(name: "Live Activity \(state) (\(typeKey))", data: [
            MessagingConstants.Event.Data.Key.LIVE_ACTIVITY_TRACK_STATE: true,
            MessagingConstants.Event.Data.Key.APPLE_LIVE_ACTIVITY_ID: activity.id,
            MessagingConstants.Event.Data.Key.STATE: "\(state)",
            MessagingConstants.Event.Data.Key.LIVE_ACTIVITY_ID: activity.attributes.liveActivityData.liveActivityID ?? MessagingConstants.Event.Data.Value.UNAVAILABLE
        ])
    }
}

fileprivate extension Data {
    /// A computed property that returns a hexadecimal string representation of the data.
    var hexEncodedString: String {
        self.map { String(format: "%02x", $0) }.joined()
    }
}

@available(iOS 16.1, *)
fileprivate extension LiveActivityAttributes {
    /// A unique string identifier representing the `LiveActivityAttributes` type.
    ///
    /// This value is derived from the type's name and is used as a key when
    /// registering or dispatching events associated with a specific Live Activity type.
    /// It provides a consistent way to reference the type across token and task management, logging, and event data.
    static var typeKey: String {
        return String(describing: Self.self)
    }
}
