# LiveActivityAttributes

A protocol that enables Live Activities to integrate with Adobe Experience Platform.

Conforming types can associate required Adobe Experience Platform data with iOS Live Activities. Any custom `ActivityAttributes` struct must implement this protocol when registering a Live Activity with the SDK.

## Definition

```swift
@available(iOS 16.1, *)
public protocol LiveActivityAttributes: ActivityAttributes {
    /// The Adobe Experience Platform data associated with the Live Activity
    var liveActivityData: LiveActivityData { get }
}
```

## Requirements

### liveActivityData

The Adobe Experience Platform data associated with the Live Activity.

This property must return a [`LiveActivityData`](./live-activity-data.md) instance containing either a `liveActivityID` for individual Live Activities or a `channelID` for broadcast Live Activities.

## Usage

### Basic implementation

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

### Registration

After defining your attributes, register the Live Activity type with the SDK:

```swift
if #available(iOS 16.1, *) {
    Messaging.registerLiveActivities([FoodDeliveryLiveActivityAttributes.self])
}
```

To register multiple Live Activity types at once:

```swift
if #available(iOS 16.1, *) {
    Messaging.registerLiveActivities([
        FoodDeliveryLiveActivityAttributes.self,
        GameScoreLiveActivityAttributes.self
    ])
}
```

### Creating a Live Activity

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

## Related protocols

- [`LiveActivityAssuranceDebuggable`](./live-activity-assurance-debuggable.md) - For debugging support in Adobe Assurance

