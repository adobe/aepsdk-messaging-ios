# Live Activity Channel Broadcasting

Channel broadcasting enables you to send Live Activities to multiple users simultaneously, making it perfect for events, sports, and other shared experiences.

## Overview

Channel broadcasting allows you to:

- **Reach Multiple Users** - Send Live Activities to all subscribers of a channel
- **Real-time Updates** - Update all subscribers simultaneously with new content
- **Efficient Resource Usage** - Use a single channel for multiple users
- **Scalable Architecture** - Handle large numbers of subscribers efficiently

## Channel vs Individual Live Activities

### Individual Live Activities

Target specific users with personalized content:

```swift
let attributes = FoodDeliveryLiveActivityAttributes(
    liveActivityData: LiveActivityData(liveActivityID: "order_12345"),
    restaurantName: "Pizza Hut"
)
```

### Channel Live Activities

Broadcast to multiple subscribers:

```swift
let attributes = AirplaneTrackingAttributes(
    liveActivityData: LiveActivityData(channelID: "flight_ABC123"),
    arrivalAirport: "SFO",
    departureAirport: "MIA",
    arrivalTerminal: "Terminal 3"
)
```

## Implementation

### Step 1: Define Channel Live Activity Attributes

```swift
@available(iOS 16.1, *)
struct AirplaneTrackingAttributes: LiveActivityAttributes {
    var liveActivityData: LiveActivityData
    
    // Static attributes (shared across all subscribers)
    let arrivalAirport: String
    let departureAirport: String
    let arrivalTerminal: String
    
    // Dynamic attributes (can be updated for all subscribers)
    struct ContentState: Codable, Hashable {
        let journeyProgress: Int
        let estimatedArrivalTime: Date?
        let currentLocation: String?
    }
}
```

### Step 2: Register the Channel Live Activity

```swift
@available(iOS 16.1, *)
class LiveActivityManager {
    
    func setupChannelLiveActivities() {
        // Register channel Live Activity type
        Messaging.registerLiveActivity(AirplaneTrackingAttributes.self)
    }
    
    func startFlightTrackingChannel() {
        let attributes = AirplaneTrackingAttributes(
            liveActivityData: LiveActivityData(channelID: "flight_ABC123"),
            arrivalAirport: "San Francisco International Airport",
            departureAirport: "Miami International Airport",
            arrivalTerminal: "Terminal 3"
        )
        
        let contentState = AirplaneTrackingAttributes.ContentState(
            journeyProgress: 0,
            estimatedArrivalTime: Date().addingTimeInterval(2 * 60 * 60), // 2 hours
            currentLocation: "En route"
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            print("Channel Live Activity started: \(activity.id)")
        } catch {
            print("Failed to start channel Live Activity: \(error)")
        }
    }
}
```

### Step 3: Update Channel Content

```swift
@available(iOS 16.1, *)
func updateFlightProgress(activity: Activity<AirplaneTrackingAttributes>, progress: Int) {
    let newContentState = AirplaneTrackingAttributes.ContentState(
        journeyProgress: progress,
        estimatedArrivalTime: Date().addingTimeInterval(1 * 60 * 60), // 1 hour
        currentLocation: "Approaching destination"
    )
    
    Task {
        await activity.update(using: newContentState)
        // All channel subscribers will receive the update
    }
}
```

## Channel Management

### Creating Channels

Channels are created automatically when you start a channel Live Activity:

```swift
// Channel is created when Live Activity starts
let channelID = "flight_ABC123"
let attributes = AirplaneTrackingAttributes(
    liveActivityData: LiveActivityData(channelID: channelID),
    // ... other attributes
)
```

### Subscribing to Channels

Users can subscribe to channels through your app:

```swift
@available(iOS 16.1, *)
class ChannelSubscriptionManager {
    
    func subscribeToFlightChannel(flightNumber: String) {
        let channelID = "flight_\(flightNumber)"
        
        // Start the channel Live Activity for this user
        let attributes = AirplaneTrackingAttributes(
            liveActivityData: LiveActivityData(channelID: channelID),
            arrivalAirport: "SFO",
            departureAirport: "MIA",
            arrivalTerminal: "Terminal 3"
        )
        
        let contentState = AirplaneTrackingAttributes.ContentState(
            journeyProgress: 0,
            estimatedArrivalTime: nil,
            currentLocation: "Subscribed to flight tracking"
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            print("Subscribed to flight channel: \(channelID)")
        } catch {
            print("Failed to subscribe to channel: \(error)")
        }
    }
    
    func unsubscribeFromChannel(activity: Activity<AirplaneTrackingAttributes>) {
        let finalContentState = AirplaneTrackingAttributes.ContentState(
            journeyProgress: 100,
            estimatedArrivalTime: Date(),
            currentLocation: "Flight completed"
        )
        
        Task {
            await activity.end(using: finalContentState, dismissalPolicy: .immediate)
            print("Unsubscribed from channel")
        }
    }
}
```

## Use Cases

### Sports Events

```swift
@available(iOS 16.1, *)
struct GameScoreLiveActivityAttributes: LiveActivityAttributes {
    var liveActivityData: LiveActivityData
    
    struct ContentState: Codable, Hashable {
        var homeTeamScore: Int
        var awayTeamScore: Int
        var statusText: String
        var timeRemaining: String?
    }
}

// Start channel for all fans
let attributes = GameScoreLiveActivityAttributes(
    liveActivityData: LiveActivityData(channelID: "game_LAKERS_WARRIORS_2024"),
    // ... game details
)

let contentState = GameScoreLiveActivityAttributes.ContentState(
    homeTeamScore: 0,
    awayTeamScore: 0,
    statusText: "Game starting soon",
    timeRemaining: "Tip-off in 5 minutes"
)
```

### News Updates

```swift
@available(iOS 16.1, *)
struct NewsUpdateLiveActivityAttributes: LiveActivityAttributes {
    var liveActivityData: LiveActivityData
    let newsCategory: String
    
    struct ContentState: Codable, Hashable {
        var headline: String
        var summary: String
        var updateTime: Date
        var priority: String // "breaking", "urgent", "normal"
    }
}

// Broadcast breaking news to all subscribers
let attributes = NewsUpdateLiveActivityAttributes(
    liveActivityData: LiveActivityData(channelID: "news_breaking_2024"),
    newsCategory: "Breaking News"
)

let contentState = NewsUpdateLiveActivityAttributes.ContentState(
    headline: "Breaking: Major announcement",
    summary: "Important news update for all subscribers",
    updateTime: Date(),
    priority: "breaking"
)
```

### Weather Alerts

```swift
@available(iOS 16.1, *)
struct WeatherAlertLiveActivityAttributes: LiveActivityAttributes {
    var liveActivityData: LiveActivityData
    let region: String
    
    struct ContentState: Codable, Hashable {
        var alertType: String
        var severity: String
        var description: String
        var validUntil: Date
    }
}

// Alert all users in a region
let attributes = WeatherAlertLiveActivityAttributes(
    liveActivityData: LiveActivityData(channelID: "weather_alert_california"),
    region: "California"
)

let contentState = WeatherAlertLiveActivityAttributes.ContentState(
    alertType: "Severe Weather",
    severity: "High",
    description: "Heavy rain and wind expected",
    validUntil: Date().addingTimeInterval(6 * 60 * 60) // 6 hours
)
```

## Event Tracking for Channels

### Channel Start Event

```swift
// Event data for channel Live Activity start
[
    "trackStart": true,
    "attributeType": "AirplaneTrackingAttributes",
    "appleId": "activityAppleId",
    "origin": "local",
    "channelId": "flight_ABC123"
]
```

### Channel Update Event

```swift
// Event data for channel Live Activity updates
[
    "trackState": true,
    "attributeType": "AirplaneTrackingAttributes",
    "appleId": "activityAppleId",
    "state": "updated",
    "channelId": "flight_ABC123"
]
```

## Best Practices

### Channel Design

1. **Meaningful Channel IDs**: Use descriptive, unique channel identifiers
2. **Consistent Naming**: Follow a consistent naming convention for channels
3. **Category Organization**: Group related channels by category
4. **Version Management**: Include version information in channel IDs if needed

### Content Management

1. **Relevant Updates**: Only send updates that are relevant to all subscribers
2. **Frequency Control**: Avoid overwhelming subscribers with too many updates
3. **Content Validation**: Ensure content is appropriate for all subscribers
4. **Error Handling**: Handle cases where channel updates fail

### Performance Optimization

1. **Efficient Updates**: Batch updates when possible
2. **Resource Management**: Monitor channel resource usage
3. **Scalability**: Design channels to handle large numbers of subscribers
4. **Cleanup**: Properly end channels when no longer needed

## Implementation Examples

### Multi-Channel Manager

```swift
@available(iOS 16.1, *)
class MultiChannelManager {
    
    private var activeChannels: [String: Activity<AirplaneTrackingAttributes>] = [:]
    
    func startChannel(channelID: String, flightInfo: FlightInfo) {
        let attributes = AirplaneTrackingAttributes(
            liveActivityData: LiveActivityData(channelID: channelID),
            arrivalAirport: flightInfo.arrivalAirport,
            departureAirport: flightInfo.departureAirport,
            arrivalTerminal: flightInfo.arrivalTerminal
        )
        
        let contentState = AirplaneTrackingAttributes.ContentState(
            journeyProgress: 0,
            estimatedArrivalTime: flightInfo.estimatedArrival,
            currentLocation: "Flight scheduled"
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            activeChannels[channelID] = activity
            print("Started channel: \(channelID)")
        } catch {
            print("Failed to start channel \(channelID): \(error)")
        }
    }
    
    func updateChannel(channelID: String, progress: Int, location: String) {
        guard let activity = activeChannels[channelID] else {
            print("Channel \(channelID) not found")
            return
        }
        
        let newContentState = AirplaneTrackingAttributes.ContentState(
            journeyProgress: progress,
            estimatedArrivalTime: activity.contentState.estimatedArrivalTime,
            currentLocation: location
        )
        
        Task {
            await activity.update(using: newContentState)
            print("Updated channel \(channelID) with progress: \(progress)%")
        }
    }
    
    func endChannel(channelID: String) {
        guard let activity = activeChannels[channelID] else {
            print("Channel \(channelID) not found")
            return
        }
        
        let finalContentState = AirplaneTrackingAttributes.ContentState(
            journeyProgress: 100,
            estimatedArrivalTime: Date(),
            currentLocation: "Flight completed"
        )
        
        Task {
            await activity.end(using: finalContentState, dismissalPolicy: .immediate)
            activeChannels.removeValue(forKey: channelID)
            print("Ended channel: \(channelID)")
        }
    }
    
    func listActiveChannels() -> [String] {
        return Array(activeChannels.keys)
    }
}
```

### Channel Analytics

```swift
class ChannelAnalytics {
    
    static func trackChannelStart(channelID: String, attributeType: String) {
        Analytics.track("channel_live_activity_started", properties: [
            "channel_id": channelID,
            "attribute_type": attributeType,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    static func trackChannelUpdate(channelID: String, updateType: String) {
        Analytics.track("channel_live_activity_updated", properties: [
            "channel_id": channelID,
            "update_type": updateType,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    static func trackChannelEnd(channelID: String, reason: String) {
        Analytics.track("channel_live_activity_ended", properties: [
            "channel_id": channelID,
            "reason": reason,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
}
```

## Troubleshooting

### Common Channel Issues

1. **Channel Not Starting**
   - Verify channel ID is unique
   - Check that Live Activity type is registered
   - Ensure proper permissions

2. **Updates Not Reaching Subscribers**
   - Verify channel is active
   - Check network connectivity
   - Validate content state format

3. **High Resource Usage**
   - Monitor channel count
   - End unused channels
   - Implement channel cleanup

### Debug Information

```swift
// Enable debug logging for channels
MobileCore.setLogLevel(.trace)

// Look for these log messages:
// "Started channel: flight_ABC123"
// "Updated channel flight_ABC123 with progress: 50%"
// "Ended channel: flight_ABC123"
```

## Platform Compatibility

| Feature | iOS Version | Description |
|---------|-------------|-------------|
| Channel Live Activities | 16.1+ | Basic channel functionality |
| Channel Updates | 16.1+ | Real-time channel updates |
| Channel Analytics | 16.1+ | Track channel performance |
| Channel Management | 16.1+ | Create and manage channels |

## Integration with Adobe Experience Platform

Channel Live Activities integrate with AEP for:

- **Audience Management**: Target specific channel subscribers
- **Campaign Orchestration**: Coordinate channel campaigns
- **Analytics**: Track channel engagement and performance
- **Personalization**: Customize channel content based on subscriber data 