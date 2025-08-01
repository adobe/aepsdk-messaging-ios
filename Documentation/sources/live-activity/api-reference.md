# Live Activity API Reference

This document provides comprehensive API documentation for the Live Activity integration with AEP Messaging SDK.

## Core Protocols

### LiveActivityAttributes

The main protocol that enables Live Activities to integrate with Adobe Experience Platform.

```swift
@available(iOS 16.1, *)
public protocol LiveActivityAttributes: ActivityAttributes {
    /// The Adobe Experience Platform data associated with the Live Activity.
    var liveActivityData: LiveActivityData { get }
}
```

**Requirements:**
- Must conform to `ActivityAttributes` (Apple's protocol)
- Must include `liveActivityData` property of type `LiveActivityData`

### LiveActivityAssuranceDebuggable

Optional protocol for debugging Live Activities in development.

```swift
@available(iOS 16.1, *)
public protocol LiveActivityAssuranceDebuggable: LiveActivityAttributes {
    /// Returns debug information for the Live Activity.
    /// Used by Adobe Assurance for debugging and testing.
    static func getDebugInfo() -> (attributes: Self, state: Self.ContentState)
}
```

## Data Structures

### LiveActivityData

Encapsulates data for Adobe Experience Platform integration with iOS Live Activities.

```swift
@available(iOS 16.1, *)
public struct LiveActivityData: Codable {
    /// Unique identifier for managing and tracking a broadcast Live Activity channel.
    public let channelID: String?
    
    /// Unique identifier for managing and tracking an individual Live Activity.
    public let liveActivityID: String?
    
    /// Defines whether the Live Activity was started locally or remotely.
    public let origin: LiveActivityOrigin
    
    /// Initialize with channel ID for broadcast Live Activities.
    public init(channelID: String)
    
    /// Initialize with Live Activity ID for individual Live Activities.
    public init(liveActivityID: String)
}
```

### LiveActivityOrigin

Defines the origin of a Live Activity.

```swift
@available(iOS 16.1, *)
public enum LiveActivityOrigin: String, Codable {
    case local
    case remote
}
```

## Public API Methods

### registerLiveActivity

Registers a Live Activity type with the Adobe Experience Platform SDK.

```swift
@available(iOS 16.1, *)
static func registerLiveActivity<T: LiveActivityAttributes>(_: T.Type)
```

**Parameters:**
- `type`: The Live Activity type that conforms to `LiveActivityAttributes`

**Behavior:**
- Automatically collects push-to-start tokens (iOS 17.2+)
- Manages complete lifecycle of Live Activities
- Monitors state transitions (start, update, end)
- Tracks events for the registered activity type

**Example:**
```swift
Messaging.registerLiveActivity(FoodDeliveryLiveActivityAttributes.self)
```

## Event Tracking

The SDK automatically tracks the following events for registered Live Activities:

### 1. Push-to-Start Token Event

Dispatched when a push-to-start token is received (iOS 17.2+).

**Event Name:** `com.adobe.eventType.messaging.liveActivity.pushToStart`

**Event Data:**
```swift
[
    "pushToStartToken": true,
    "token": "hexEncodedToken",
    "attributeType": "FoodDeliveryLiveActivityAttributes"
]
```

### 2. Update Token Event

Dispatched when a Live Activity's push token is updated.

**Event Name:** `com.adobe.eventType.messaging.liveActivity.updateToken`

**Event Data:**
```swift
[
    "updateToken": true,
    "token": "hexEncodedToken",
    "attributeType": "FoodDeliveryLiveActivityAttributes",
    "appleId": "activityAppleId",
    "liveActivityId": "yourLiveActivityId"
]
```

### 3. Start Event

Dispatched when a Live Activity starts.

**Event Name:** `com.adobe.eventType.messaging.liveActivity.start`

**Event Data:**
```swift
[
    "trackStart": true,
    "attributeType": "FoodDeliveryLiveActivityAttributes",
    "appleId": "activityAppleId",
    "origin": "local",
    "liveActivityId": "yourLiveActivityId" // or "channelId": "yourChannelId"
]
```

### 4. State Update Event

Dispatched when a Live Activity state changes (dismissed/ended).

**Event Name:** `com.adobe.eventType.messaging.liveActivity.stateUpdate`

**Event Data:**
```swift
[
    "trackState": true,
    "attributeType": "FoodDeliveryLiveActivityAttributes",
    "appleId": "activityAppleId",
    "state": "dismissed", // or "ended"
    "liveActivityId": "yourLiveActivityId" // or "channelId": "yourChannelId"
]
```

### 5. Content State Update Event (Debug Only)

Dispatched when Live Activity content updates (DEBUG mode only, iOS 16.2+).

**Event Name:** `com.adobe.eventType.messaging.liveActivity.contentUpdate`

**Event Data:**
```swift
[
    "contentUpdate": true,
    "attributeType": "FoodDeliveryLiveActivityAttributes",
    "appleId": "activityAppleId",
    "contentState": "updatedStateData"
]
```

## Implementation Examples

### Basic Live Activity Attributes

```swift
@available(iOS 16.1, *)
struct GameScoreLiveActivityAttributes: LiveActivityAttributes {
    var liveActivityData: LiveActivityData
    
    struct ContentState: Codable, Hashable {
        var homeTeamScore: Int
        var awayTeamScore: Int
        var statusText: String
    }
}
```

### Live Activity with Static Attributes

```swift
@available(iOS 16.1, *)
struct FoodDeliveryLiveActivityAttributes: LiveActivityAttributes {
    var liveActivityData: LiveActivityData
    var restaurantName: String
    var orderNumber: String
    
    struct ContentState: Codable, Hashable {
        var orderStatus: String
        var estimatedDeliveryTime: Date?
        var driverLocation: String?
    }
}
```

### Debuggable Live Activity

```swift
@available(iOS 16.1, *)
struct AirplaneTrackingAttributes: LiveActivityAttributes {
    var liveActivityData: LiveActivityData
    let arrivalAirport: String
    let departureAirport: String
    let arrivalTerminal: String
    
    struct ContentState: Codable, Hashable {
        let journeyProgress: Int
    }
}

@available(iOS 16.1, *)
extension AirplaneTrackingAttributes: LiveActivityAssuranceDebuggable {
    static func getDebugInfo() -> (attributes: AirplaneTrackingAttributes, state: ContentState) {
        return (
            AirplaneTrackingAttributes(
                liveActivityData: LiveActivityData(channelID: "channelXYZ"),
                arrivalAirport: "SFO",
                departureAirport: "MIA",
                arrivalTerminal: "Terminal 3"
            ),
            ContentState(journeyProgress: 0)
        )
    }
}
```

## Channel vs Individual Live Activities

### Individual Live Activity

Use `liveActivityID` for targeting specific users:

```swift
let attributes = FoodDeliveryLiveActivityAttributes(
    liveActivityData: LiveActivityData(liveActivityID: "order_12345"),
    restaurantName: "Pizza Hut"
)
```

### Broadcast Channel Live Activity

Use `channelID` for broadcasting to multiple subscribers:

```swift
let attributes = AirplaneTrackingAttributes(
    liveActivityData: LiveActivityData(channelID: "flight_ABC123"),
    arrivalAirport: "SFO",
    departureAirport: "MIA",
    arrivalTerminal: "Terminal 3"
)
```

## Error Handling

The SDK handles various error scenarios:

- **Missing Live Activity ID**: Logs error and skips update token events
- **Invalid Token Data**: Logs warning and continues processing
- **Registration Failures**: Logs error and continues with other functionality

## Platform Compatibility

| Feature | iOS Version | Notes |
|---------|-------------|-------|
| Basic Live Activities | 16.1+ | Core functionality |
| Push-to-Start Tokens | 17.2+ | Remote Live Activity triggering |
| Content Updates | 16.2+ | Debug mode only |
| Dynamic Island | 16.1+ | iPhone 14 Pro+ only |

## Constants

### Event Names

```swift
extension MessagingConstants.Event.Name {
    struct LiveActivity {
        static let PUSH_TO_START = "com.adobe.eventType.messaging.liveActivity.pushToStart"
        static let UPDATE_TOKEN = "com.adobe.eventType.messaging.liveActivity.updateToken"
        static let START = "com.adobe.eventType.messaging.liveActivity.start"
        static let STATE_UPDATE = "com.adobe.eventType.messaging.liveActivity.stateUpdate"
        static let CONTENT_UPDATE = "com.adobe.eventType.messaging.liveActivity.contentUpdate"
    }
}
```

### Event Data Keys

```swift
extension MessagingConstants.Event.Data.Key {
    struct LiveActivity {
        static let PUSH_TO_START_TOKEN = "pushToStartToken"
        static let UPDATE_TOKEN = "updateToken"
        static let TRACK_START = "trackStart"
        static let TRACK_STATE = "trackState"
        static let CONTENT_UPDATE = "contentUpdate"
        static let ATTRIBUTE_TYPE = "attributeType"
        static let APPLE_ID = "appleId"
    }
}
```

### XDM Keys

```swift
extension MessagingConstants.XDM {
    struct LiveActivity {
        static let ID = "liveActivityId"
        static let ORIGIN = "origin"
    }
} 