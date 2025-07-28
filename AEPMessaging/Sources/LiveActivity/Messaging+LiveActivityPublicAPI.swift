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

    /// A shared task store for tasks that handle push-to-start token updates.
    private static let pushToStartTaskStore = ActivityTaskStore<String>()

    /// A shared task store for tasks that handle Live Activity update tokens and state transitions.
    private static let activityUpdateTaskStore = ActivityTaskStore<String>()

    /// Represents the registration state of a Live Activity type.
    private enum RegistrationState {
        case registered
        case unregistered
        case partiallyRegistered(updateTaskRegistered: Bool, pushStartTaskRegistered: Bool)
    }

    /// Determines the current registration state for a given Live Activity type.
    ///
    /// - Parameter type: The Live Activity type to check.
    /// - Returns: The current registration state indicating whether the type is fully registered,
    ///           not registered, or in a partially registered state.
    private static func getRegistrationState<T: LiveActivityAttributes>(for _: T.Type) async -> RegistrationState {
        let attributeType = T.attributeType
        let updateTaskRegistered = await activityUpdateTaskStore.task(for: attributeType) != nil

        if #available(iOS 17.2, *) {
            let pushStartTaskRegistered = await pushToStartTaskStore.task(for: attributeType) != nil

            if updateTaskRegistered && pushStartTaskRegistered {
                return .registered
            } else if !updateTaskRegistered && !pushStartTaskRegistered {
                return .unregistered
            } else {
                return .partiallyRegistered(updateTaskRegistered: updateTaskRegistered, pushStartTaskRegistered: pushStartTaskRegistered)
            }
        } else {
            return updateTaskRegistered ? .registered : .unregistered
        }
    }

    /// Cleans up any existing tasks for the given attribute type.
    ///
    /// - Parameter attributeType: The string identifier for the Live Activity type.
    private static func cleanupExistingTasks(for attributeType: String) async {
        // Cancel and remove activity updates task
        if let existingUpdateTask = await activityUpdateTaskStore.task(for: attributeType) {
            existingUpdateTask.cancel()
            await activityUpdateTaskStore.removeTask(for: attributeType)
        }

        // Cancel and remove push-to-start task (iOS 17.2+ only)
        if #available(iOS 17.2, *) {
            if let existingPushStartTask = await pushToStartTaskStore.task(for: attributeType) {
                existingPushStartTask.cancel()
                await pushToStartTaskStore.removeTask(for: attributeType)
            }
        }
    }

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
        let attributeType = T.attributeType

        Task {
            let registrationState = await getRegistrationState(for: T.self)

            switch registrationState {
            case .unregistered:
                // Proceed with normal registration. This is the first time the type is being registered.
                break

            case .registered:
                // The type is already registered. Skip duplicate registration.
                Log.debug(label: MessagingConstants.LOG_TAG,
                          "Live Activity type '\(attributeType)' is already fully registered. Skipping duplicate registration.")
                return

            case let .partiallyRegistered(updateTaskRegistered, pushStartTaskRegistered):
                // The type is partially registered. This is unexpected. Clean up and re-create all tasks.
                Log.warning(label: MessagingConstants.LOG_TAG,
                            "Live Activity type '\(attributeType)' is partially registered (update task: \(updateTaskRegistered), push-to-start task: \(pushStartTaskRegistered)). Cleaning up and re-create all tasks.")
                await cleanupExistingTasks(for: attributeType)
            }
            // Fall through to create fresh tasks

            // Dispatch attribute structure event if the type supports debugging
            if let debuggableType = T.self as? any LiveActivityAssuranceDebuggable.Type {
                dispatchAttributeStructureEvent(type: debuggableType)
            }

            // Create and register push-to-start token task for iOS 17.2+
            if #available(iOS 17.2, *) {
                let newPushTask = createPushToStartTokenTask(type: T.self)
                await pushToStartTaskStore.setTask(for: attributeType, task: newPushTask)
                Log.trace(label: MessagingConstants.LOG_TAG,
                          "Registered Live Activity push-to-start token task for type \(attributeType)")
            } else {
                Log.debug(label: MessagingConstants.LOG_TAG,
                          "Not creating a Live Activity push-to-start token handler task for type \(attributeType). " +
                              "iOS 17.2 or later is required to start a Live Activity with a push token.")
            }

            // Create and register activity updates task
            let newActivityUpdatesTask = createActivityUpdatesTask(type: T.self)
            await activityUpdateTaskStore.setTask(for: attributeType, task: newActivityUpdatesTask)
            Log.trace(label: MessagingConstants.LOG_TAG,
                      "Registered Live Activity updates task for type \(attributeType)")
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
            let attributeType = T.attributeType

            // Remove this task from storage when the sequence ends.
            defer {
                Task {
                    await pushToStartTaskStore.removeTask(for: attributeType)
                }
            }

            for await tokenData in Activity<T>.pushToStartTokenUpdates {
                let tokenHex = tokenData.hexEncodedString
                dispatchPushToStartTokenEvent(attributeType: attributeType, token: tokenHex)
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
            let attributeType = T.attributeType

            // Remove this task from storage when the sequence ends.
            defer {
                Task {
                    await activityUpdateTaskStore.removeTask(for: attributeType)
                }
            }

            for await activity in Activity<T>.activityUpdates {
                // Dispatch Live Activity start tracking event
                dispatchStartEvent(activity: activity)

                // Listen for content updates when in DEBUG mode.
                #if DEBUG
                    if #available(iOS 16.2, *) {
                        Task {
                            for await update in activity.contentUpdates {
                                dispatchContentStateUpdateEvent(activity: activity, contentState: update.state)
                            }
                        }
                    } else {
                        Log.debug(label: MessagingConstants.LOG_TAG,
                                  "Not handling Live Activity content updates for type \(attributeType). " +
                                      "iOS 16.2 or later is required.")
                    }
                #endif

                // Listen for state updates.
                Task {
                    for await newState in activity.activityStateUpdates {
                        if newState == .dismissed || newState == .ended {
                            dispatchStateUpdateEvent(activity: activity, state: newState)
                        }
                    }
                }

                // Listen for push token updates for this activity.
                // Live Activities Broadcast via channels do not use this token.
                Task {
                    for await newTokenData in activity.pushTokenUpdates {
                        let newTokenHex = newTokenData.hexEncodedString
                        Log.debug(label: MessagingConstants.LOG_TAG, "Update token received for activity \(activity.id) (\(attributeType)): \(newTokenHex)")
                        dispatchUpdateTokenEvent(activity: activity, token: newTokenHex)
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
    ///   - attributeType: A unique string identifier representing the ``LiveActivityAttributes`` type associated with the Live Activity.
    ///   - token: A `String` representing the push-to-start token for the Live Activity.
    private static func dispatchPushToStartTokenEvent(attributeType: String, token: String) {
        Log.debug(label: MessagingConstants.LOG_TAG,
                  """
                  Dispatching Live Activity push-to-start token event.
                  Token: \(token)
                  Type: \(attributeType)
                  """)

        let eventName = "\(MessagingConstants.Event.Name.LiveActivity.PUSH_TO_START) (\(attributeType))"
        let event = Event(name: eventName,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: [
                              MessagingConstants.Event.Data.Key.LiveActivity.PUSH_TO_START_TOKEN: true,
                              MessagingConstants.XDM.Push.TOKEN: token,
                              MessagingConstants.Event.Data.Key.LiveActivity.ATTRIBUTE_TYPE: attributeType
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
    /// - Note: This method will not dispatch an event if the Live Activity ID is missing.
    private static func dispatchUpdateTokenEvent<T: LiveActivityAttributes>(activity: Activity<T>, token: String) {
        let attributeType = T.attributeType
        guard let liveActivityID = activity.attributes.liveActivityData.liveActivityID else {
            Log.error(label: MessagingConstants.LOG_TAG,
                      """
                      Missing required '\(MessagingConstants.XDM.LiveActivity.ID)'. Update token event will not be sent.
                      Type: \(attributeType)
                      Apple Live Activity ID: \(activity.id)
                      """)
            return
        }

        Log.debug(label: MessagingConstants.LOG_TAG,
                  """
                  Dispatching Live Activity update token event.
                  Type: \(attributeType)
                  Apple Live Activity ID: \(activity.id)
                  LiveActivityID: \(liveActivityID))
                  Token: \(token)
                  """)

        let eventName = "\(MessagingConstants.Event.Name.LiveActivity.UPDATE_TOKEN)"

        let event = Event(name: eventName,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: [
                              MessagingConstants.Event.Data.Key.LiveActivity.UPDATE_TOKEN: true,
                              MessagingConstants.XDM.Push.TOKEN: token,
                              MessagingConstants.Event.Data.Key.LiveActivity.ATTRIBUTE_TYPE: attributeType,
                              MessagingConstants.Event.Data.Key.LiveActivity.APPLE_ID: activity.id,
                              MessagingConstants.XDM.LiveActivity.ID: liveActivityID
                          ])
        MobileCore.dispatch(event: event)
    }

    /// Dispatches an event indicating that a Live Activity has started.
    ///
    /// This method is used to send an event indicating the start of a Live Activity.
    ///
    /// - Parameter activity: The newly started `Activity` instance. The activity must conform to ``LiveActivityAttributes``.
    /// - Note: This method includes the Live Activity's origin and identifier data in the event.
    private static func dispatchStartEvent<T: LiveActivityAttributes>(activity: Activity<T>) {
        let attributeType = T.attributeType
        let liveActivityIdentifierData = activity.attributes.liveActivityIdentifierData

        Log.debug(label: MessagingConstants.LOG_TAG,
                  """
                  Dispatching Live Activity start event.
                  Type: \(attributeType)
                  Apple Live Activity ID: \(activity.id)
                  Identifier: \(liveActivityIdentifierData)
                  """)

        var data: [String: Any] = [
            MessagingConstants.Event.Data.Key.LiveActivity.TRACK_START: true,
            MessagingConstants.Event.Data.Key.LiveActivity.ATTRIBUTE_TYPE: attributeType,
            MessagingConstants.Event.Data.Key.LiveActivity.APPLE_ID: activity.id,
            MessagingConstants.XDM.LiveActivity.ORIGIN: activity.attributes.liveActivityData.origin
        ]

        // Merge in the single identifier (liveActivityID or channelID)
        data.merge(liveActivityIdentifierData) { current, _ in current }

        let eventName = "\(MessagingConstants.Event.Name.LiveActivity.START)"
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
    /// - Note: This method includes the Live Activity's identifier data in the event.
    private static func dispatchStateUpdateEvent<T: LiveActivityAttributes>(
        activity: Activity<T>,
        state: ActivityState
    ) {
        let attributeType = T.attributeType
        let liveActivityIdentifierData = activity.attributes.liveActivityIdentifierData

        Log.debug(label: MessagingConstants.LOG_TAG,
                  """
                  Dispatching Live Activity \(state) event.
                  Type: \(attributeType)
                  Apple Live Activity ID: \(activity.id)
                  Identifier: \(liveActivityIdentifierData)
                  """)

        var data: [String: Any] = [
            MessagingConstants.Event.Data.Key.LiveActivity.TRACK_STATE: true,
            MessagingConstants.Event.Data.Key.LiveActivity.ATTRIBUTE_TYPE: attributeType,
            MessagingConstants.Event.Data.Key.LiveActivity.APPLE_ID: activity.id,
            MessagingConstants.Event.Data.Key.LiveActivity.STATE: "\(state)"
        ]

        // Merge in the single identifier (liveActivityID or channelID)
        data.merge(liveActivityIdentifierData) { current, _ in current }

        let eventName = "\(MessagingConstants.Event.Name.LIVE_ACTIVITY) \(state)"
        let event = Event(name: eventName,
                          type: EventType.messaging,
                          source: EventSource.requestContent,
                          data: data)
        MobileCore.dispatch(event: event)
    }

    /// Dispatches an event to track a Live Activity content state update.
    ///
    /// - Parameters:
    ///   - activity: The Live Activity instance whose content state has changed. The activity must conform to ``LiveActivityAttributes``.
    ///   - contentState: The new content state for the activity, conforming to `T.ContentState`.
    /// - Note: If the content state cannot be encoded as a dictionary, the event will not be dispatched. This method also includes
    ///   the Live Activity's identifier data in the event.
    private static func dispatchContentStateUpdateEvent<T: LiveActivityAttributes>(
        activity: Activity<T>,
        contentState: T.ContentState
    ) {
        let attributeType = T.attributeType
        let liveActivityIdentifierData = activity.attributes.liveActivityIdentifierData

        guard let contentStateData = contentState.asDictionary() else {
            Log.debug(
                label: MessagingConstants.LOG_TAG,
                "Failed to encode content state for Live Activity type \(attributeType); skipping event dispatch."
            )
            return
        }

        Log.debug(
            label: MessagingConstants.LOG_TAG,
            """
            Dispatching Live Activity content-state update.
            Type: \(attributeType)
            Apple Live Activity ID: \(activity.id)
            Identifier: \(liveActivityIdentifierData)
            ContentState: \(contentStateData)
            """
        )

        var data: [String: Any] = [
            MessagingConstants.Event.Data.Key.LiveActivity.TRACK_STATE: true,
            MessagingConstants.Event.Data.Key.LiveActivity.ATTRIBUTE_TYPE: attributeType,
            MessagingConstants.Event.Data.Key.LiveActivity.APPLE_ID: activity.id,
            MessagingConstants.Event.Data.Key.LiveActivity.CONTENT_STATE: contentStateData
        ]

        // Merge in the single identifier (liveActivityID or channelID)
        data.merge(liveActivityIdentifierData) { current, _ in current }

        let eventName = MessagingConstants.Event.Name.LiveActivity.CONTENT_STATE
        let event = Event(
            name: eventName,
            type: EventType.genericData,
            source: EventSource.debug,
            data: data
        )
        MobileCore.dispatch(event: event)
    }

    private static func dispatchAttributeStructureEvent<T: LiveActivityAssuranceDebuggable>(
        type _: T.Type) {
        let debugInfo = T.getDebugInfo()
        let attributes = debugInfo.attributes
        let contentState = debugInfo.state

        let attributeTypeName = String(describing: T.self)

        // Use JSONSchemaBuilder to create the event data
        let eventData = LiveActivityDebugSchemaBuilder.buildEventData(
            attributeTypeName: attributeTypeName,
            attributes: attributes,
            contentState: contentState
        )

        // TODO: Define this event name in MessagingConstants
        let eventName = "Live Activity Schema (\(attributeTypeName))"
        let event = Event(name: eventName,
                          type: EventType.genericData,
                          source: EventSource.debug,
                          data: eventData)
        MobileCore.dispatch(event: event)
    }
}
