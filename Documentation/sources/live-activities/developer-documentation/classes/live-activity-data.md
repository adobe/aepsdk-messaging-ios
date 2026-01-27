# LiveActivityData

Encapsulates data for Adobe Experience Platform integration with iOS Live Activities.

This struct provides the necessary identifiers and data for both managing and tracking Live Activities through Adobe Experience Platform. Use this struct when implementing the [`LiveActivityAttributes`](./live-activity-attributes.md) protocol.

## Definition

```swift
@available(iOS 16.1, *)
public struct LiveActivityData: Codable {
    /// Unique identifier for managing and tracking a broadcast Live Activity channel
    public let channelID: String?
    
    /// Unique identifier for managing and tracking an individual Live Activity
    public let liveActivityID: String?
    
    /// Defines whether the Live Activity was started locally or remotely
    public let origin: LiveActivityOrigin?
    
    /// Initializer for broadcast Live Activities
    public init(channelID: String)
    
    /// Initializer for individual Live Activities
    public init(liveActivityID: String)
}
```

## Properties

### channelID

Unique identifier for managing and tracking a broadcast Live Activity channel in Adobe Experience Platform.

Use this when creating Live Activities that are broadcast to multiple subscribers of a channel (available on iOS 18+).

### liveActivityID

Unique identifier for managing and tracking an individual Live Activity in Adobe Experience Platform.

Use this when creating Live Activities targeted at a specific user.

### origin

Defines whether the Live Activity was started locally by the app or remotely via a push-to-start notification.

See [`LiveActivityOrigin`](./live-activity-origin.md) for available values.

## Initializers

### init(channelID:)

Initializes a `LiveActivityData` instance for broadcast Live Activities.

Use this initializer for Live Activities that are broadcast to subscribers of a channel.

```swift
let data = LiveActivityData(channelID: "sports-game-channel")
```

### init(liveActivityID:)

Initializes a `LiveActivityData` instance for individual Live Activities.

Use this initializer for Live Activities targeted at an individual user.

```swift
let data = LiveActivityData(liveActivityID: "order-12345")
```

## Usage examples

### Individual Live Activity

```swift
let attributes = FoodDeliveryLiveActivityAttributes(
    liveActivityData: LiveActivityData(liveActivityID: "order123"),
    restaurantName: "Pizza Palace"
)
```

### Broadcast Live Activity

```swift
let attributes = GameScoreLiveActivityAttributes(
    liveActivityData: LiveActivityData(channelID: "nfl-game-001"),
    homeTeam: "Chiefs",
    awayTeam: "Eagles"
)
```

