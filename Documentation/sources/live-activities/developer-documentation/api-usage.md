# Live Activities

The Adobe Experience Platform Mobile SDK provides built-in support for Apple's Live Activities. This allows your app to display real-time, dynamic updates directly on the Lock Screen and Dynamic Island without opening the app.

## Prerequisites

Ensure the following minimum versions are installed for correct configuration and compatibility:

- **iOS**: 16.1 or later for basic Live Activity functionality
  - iOS 17.2+ for push-to-start support
  - iOS 18+ for broadcast channel support
- **Xcode**: 14.0 or later
- **Swift**: 5.7 or later
- **Dependencies**: AEPCore, AEPMessaging, AEPMessagingLiveActivity, ActivityKit

## Implementation steps

### Step 1: Import required modules

Import the necessary modules in your Swift files:

```swift
import AEPMessaging
import AEPMessagingLiveActivity
import ActivityKit
```

### Step 2: Define Live Activity attributes

Create a struct that conforms to the [`LiveActivityAttributes`](./classes/live-activity-attributes.md) protocol. This defines both the static data and dynamic content state for your Live Activity.

The key components include:

- **`liveActivityData`** (required): Contains Adobe Experience Platform-specific data
  - For individual users: `LiveActivityData(liveActivityID: "unique-id")`
  - For broadcast channels: `LiveActivityData(channelID: "channel-id")`
- **Static attributes**: Custom properties specific to your use case that do not change during the Live Activity lifecycle
- **`ContentState`**: Defines dynamic data that can be updated during the Live Activity lifecycle (must conform to `Codable` and `Hashable`)

#### Example

```swift
@available(iOS 16.1, *)
struct FoodDeliveryLiveActivityAttributes: LiveActivityAttributes {
    // Required: AEP Integration Data
    var liveActivityData: LiveActivityData
    
    // Static attributes: Custom properties that do not change
    var restaurantName: String
    
    // Dynamic content state: Data that can be updated
    struct ContentState: Codable, Hashable {
        var orderStatus: String
    }
}
```

### Step 3: Register Live Activity types

Register your Live Activity types in your `AppDelegate` after SDK initialization. This enables:

- Automatic push-to-start token collection (iOS 17.2+)
- Automatic collection of Live Activity update tokens
- Lifecycle management and event tracking

#### Registering a single Live Activity type

```swift
if #available(iOS 16.1, *) {
    Messaging.registerLiveActivities([FoodDeliveryLiveActivityAttributes.self])
}
```

#### Registering multiple Live Activity types

You can register multiple Live Activity types at once by passing an array:

```swift
if #available(iOS 16.1, *) {
    Messaging.registerLiveActivities([
        AirplaneTrackingAttributes.self,
        FoodDeliveryLiveActivityAttributes.self,
        GameScoreLiveActivityAttributes.self
    ])
}
```

> **Note**: The `registerLiveActivities` method accepts an array of Live Activity types. When registering multiple types, their push-to-start tokens are automatically batched together and dispatched in a single event, improving efficiency.

### Step 4: Create Live Activity widgets

Live Activities are displayed through widgets. Create a widget bundle and configuration using `ActivityConfiguration`:

```swift
@main
struct FoodDeliveryWidgetBundle: WidgetBundle {
    var body: some Widget {
        FoodDeliveryLiveActivityWidget()
    }
}

@available(iOS 16.1, *)
struct FoodDeliveryLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FoodDeliveryLiveActivityAttributes.self) { context in
            // Lock Screen UI
            VStack {
                Text("Order from \(context.attributes.restaurantName)")
                Text("Status: \(context.state.orderStatus)")
            }
        } dynamicIsland: { context in
            // Dynamic Island UI
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Text("Order")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.orderStatus)
                }
            } compactLeading: {
                // Compact leading UI
                Image(systemName: "takeoutbag.and.cup.and.straw")
            } compactTrailing: {
                // Compact trailing UI
                Text(context.state.orderStatus)
            } minimal: {
                // Minimal UI
                Image(systemName: "takeoutbag.and.cup.and.straw")
            }
        }
    }
}
```

### Step 5: Start a Live Activity locally (optional)

While Adobe Journey Optimizer can remotely start Live Activities, you can also start them locally within your app:

```swift
let attributes = FoodDeliveryLiveActivityAttributes(
    liveActivityData: LiveActivityData(liveActivityID: "order123"),
    restaurantName: "Pizza Palace"
)

let contentState = FoodDeliveryLiveActivityAttributes.ContentState(
    orderStatus: "Ordered"
)

let activity = try Activity<FoodDeliveryLiveActivityAttributes>.request(
    attributes: attributes,
    contentState: contentState,
    pushType: .token
)
```

#### Update a locally started Live Activity

Once you have a reference to the activity, you can update its content state:

```swift
let updatedContentState = FoodDeliveryLiveActivityAttributes.ContentState(
    orderStatus: "Preparing"
)

Task {
    await activity.update(using: updatedContentState)
}
```

#### End a locally started Live Activity

To end the Live Activity, call the `end` method:

```swift
Task {
    await activity.end(dismissalPolicy: .default)
}
```

> **Note**: Live Activities can be managed remotely regardless of how they were started. A locally started Live Activity can be updated and ended remotely. Similarly, remotely started Live Activities can also be updated and ended remotely.

### Step 6: Add Assurance debug support (optional)

To debug Live Activity schemas in Adobe Assurance, conform to the [`LiveActivityAssuranceDebuggable`](./classes/live-activity-assurance-debuggable.md) protocol:

```swift
@available(iOS 16.1, *)
extension FoodDeliveryLiveActivityAttributes: LiveActivityAssuranceDebuggable {
    static func getDebugInfo() -> (attributes: FoodDeliveryLiveActivityAttributes, state: ContentState) {
        return (
            FoodDeliveryLiveActivityAttributes(
                liveActivityData: LiveActivityData(liveActivityID: "debug-order-123"),
                restaurantName: "Debug Restaurant"
            ),
            ContentState(orderStatus: "Ordered")
        )
    }
}
```

### Step 7: Clear push and Live Activity tokens before resetting identities

Two APIs need to be cleared together whenever an app also calls `MobileCore.resetIdentities()` (for
example, on user sign-out): `MobileCore.setPushIdentifier(_:)` for the standard push token, and
`Messaging.clearLiveActivities()` for Live Activity push-to-start tokens. Both sync their token state
to Edge under the *current* ECID, so both must run, and be given time to reach Edge, before the ECID
changes.

- **`MobileCore.setPushIdentifier(nil)`** clears the device's standard push token by syncing an empty
  (`""`) token to the current profile.
- **`Messaging.clearLiveActivities()`** revokes previously-registered Live Activity tokens and stops
  token collection entirely. It sends an empty (`""`) push-to-start token to Edge for every stored
  token, cancels the SDK's ActivityKit listeners, and clears the local token stores.

```swift
MobileCore.setPushIdentifier(nil)
Messaging.clearLiveActivities()
```

> **Important**: Both calls dispatch their Edge events asynchronously. If also calling
> `MobileCore.resetIdentities()`, call both of the above first and wait for the clears to reach Edge
> before resetting. Calling `resetIdentities()` immediately afterward can race that dispatch: if the
> new ECID is assigned before a clear's request is sent, Edge attaches the *new* ECID to it and the
> clear is applied to the wrong profile. After the reset completes, call
> `MobileCore.setPushIdentifier(_:)` with the current device token and `registerLiveActivities(_:)`
> again so both tokens are re-collected and synced to the new profile.

#### Example: clearing tokens around a `resetIdentities()` call

```swift
// 1. Clear tokens so the empty values are synced to the *current* (old) profile.
MobileCore.setPushIdentifier(nil)
Messaging.clearLiveActivities()

// 2. Wait for both clears' Edge events to be sent before changing identities. Without this delay,
//    resetIdentities() can run first and the clears would be sent under the new ECID instead.
DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
    MobileCore.resetIdentities()

    // 3. Re-sync both tokens to the new profile.
    MobileCore.setPushIdentifier(currentDeviceToken)
    Messaging.registerLiveActivities([FoodDeliveryLiveActivityAttributes.self])
}
```

## Examples

The test app in this repository demonstrates Live Activity implementation with multiple use cases:

- [MessagingDemoAppSwiftUI](./../../../TestApps/MessagingDemoAppSwiftUI/)

## Further reading

- [LiveActivityData](./classes/live-activity-data.md)
- [LiveActivityAttributes](./classes/live-activity-attributes.md)
- [LiveActivityOrigin](./classes/live-activity-origin.md)
- [LiveActivityAssuranceDebuggable](./classes/live-activity-assurance-debuggable.md)

