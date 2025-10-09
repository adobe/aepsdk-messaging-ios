# Live Activity

Live Activity integration enables your iOS app to display real-time, dynamic content on the Lock Screen and in the Dynamic Island. The AEP Messaging SDK provides comprehensive support for Live Activities, including automatic token management, lifecycle tracking, and seamless integration with Adobe Experience Platform.

## Overview

Live Activities allow users to stay informed about ongoing events, such as:
- **Food delivery tracking** - Real-time order status updates
- **Flight tracking** - Live journey progress and arrival information  
- **Game scores** - Live sports updates and scores
- **Ride sharing** - Driver location and ETA updates
- **Workout sessions** - Exercise progress and metrics

## Key Features

- **Automatic Token Management** - SDK handles push-to-start and update tokens automatically
- **Lifecycle Tracking** - Complete event tracking for start, update, and end states
- **Channel Support** - Broadcast Live Activities to multiple subscribers
- **Individual Targeting** - Target specific users with personalized Live Activities
- **Adobe Experience Platform Integration** - Seamless data flow to AEP for analytics and personalization

## Requirements

- iOS 16.1+ for basic Live Activity functionality
- iOS 17.2+ for push-to-start token support
- Xcode 15+ for development
- ActivityKit framework

## Quick Start

1. **Define your Live Activity attributes**:
```swift
@available(iOS 16.1, *)
struct FoodDeliveryLiveActivityAttributes: LiveActivityAttributes {
    var liveActivityData: LiveActivityData
    var restaurantName: String
    
    struct ContentState: Codable, Hashable {
        var orderStatus: String
    }
}
```

2. **Register with the SDK**:
```swift
Messaging.registerLiveActivity(FoodDeliveryLiveActivityAttributes.self)
```

3. **Start a Live Activity**:
```swift
let attributes = FoodDeliveryLiveActivityAttributes(
    liveActivityData: LiveActivityData(liveActivityID: "order123"),
    restaurantName: "Pizza Hut"
)
let contentState = FoodDeliveryLiveActivityAttributes.ContentState(orderStatus: "Ordered")

do {
    let activity = try Activity.request(
        attributes: attributes,
        contentState: contentState,
        pushType: nil
    )
} catch {
    print("Error starting Live Activity: \(error)")
}
```

## Documentation Sections

- **[Getting Started](getting-started.md)** - Setup and basic implementation
- **[API Reference](api-reference.md)** - Complete API documentation
- **[Token Management](token-management.md)** - Understanding push tokens and lifecycle
- **[Event Tracking](event-tracking.md)** - Tracking Live Activity interactions
- **[Channel Broadcasting](channel-broadcasting.md)** - Broadcasting to multiple users
- **[Best Practices](best-practices.md)** - Implementation guidelines and tips
- **[Troubleshooting](troubleshooting.md)** - Common issues and solutions

## Architecture

The Live Activity integration consists of several key components:

- **LiveActivityAttributes Protocol** - Defines the structure for your Live Activity data
- **LiveActivityData** - Contains Adobe Experience Platform identifiers and metadata
- **Token Management** - Automatic collection and management of push tokens
- **Event Tracking** - Complete lifecycle event tracking to Adobe Experience Platform
- **Persistence Layer** - Local storage for tokens and activity state

## Integration with Other Features

Live Activities work seamlessly with other AEP Messaging features:

- **Push Notifications** - Use push-to-start tokens to trigger Live Activities remotely
- **In-App Messaging** - Coordinate Live Activities with in-app message campaigns
- **Content Cards** - Display related content cards alongside Live Activities
- **Propositions** - Personalize Live Activity content using AEP propositions 