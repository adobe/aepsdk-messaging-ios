# LiveActivityAssuranceDebuggable

A protocol that enables debugging of Live Activity schemas in Adobe Assurance.

Conforming to this protocol allows developers to debug and validate their Live Activity attribute structure and content state in Adobe Assurance sessions.

## Definition

```swift
@available(iOS 16.1, *)
public protocol LiveActivityAssuranceDebuggable: LiveActivityAttributes {
    /// Provides debug information for the Live Activity
    /// - Returns: A tuple containing sample attributes and content state for debugging
    static func getDebugInfo() -> (attributes: Self, state: Self.ContentState)
}
```

## Requirements

### getDebugInfo()

A static method that returns sample data for debugging purposes.

This method should return a tuple containing:
- `attributes`: A sample instance of your Live Activity attributes with mock data
- `state`: A sample content state with mock data

The returned data will be used in Adobe Assurance to validate and debug your Live Activity schema.

## Usage

### Basic implementation

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

### Example with more complex attributes

```swift
@available(iOS 16.1, *)
extension GameScoreLiveActivityAttributes: LiveActivityAssuranceDebuggable {
    static func getDebugInfo() -> (attributes: GameScoreLiveActivityAttributes, state: ContentState) {
        return (
            GameScoreLiveActivityAttributes(
                liveActivityData: LiveActivityData(channelID: "debug-game-channel"),
                homeTeam: "Chiefs",
                awayTeam: "Eagles",
                gameTime: Date()
            ),
            ContentState(
                homeScore: 21,
                awayScore: 17,
                quarter: "Q3",
                timeRemaining: "5:30"
            )
        )
    }
}
```

## Notes

- This protocol is optional and only needed when debugging Live Activities in Adobe Assurance
- The mock data provided should represent a typical instance of your Live Activity
- Assurance will use this data to validate your schema structure without requiring an active Live Activity

