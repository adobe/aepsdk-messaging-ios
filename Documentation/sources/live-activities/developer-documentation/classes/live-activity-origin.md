# LiveActivityOrigin

Indicates the source of the Live Activity's creation.

Use this enum to distinguish whether a Live Activity was started locally by the app or remotely via push-to-start delivered by the server.

## Definition

```swift
@available(iOS 16.1, *)
public enum LiveActivityOrigin: String, Codable {
    /// The Live Activity was initiated locally on the device
    case local
    
    /// The Live Activity was initiated remotely via a push-to-start token
    case remote
}
```

## Cases

### local

The Live Activity was initiated locally on the device by calling `Activity.request()` from within the app.

### remote

The Live Activity was initiated remotely via a push-to-start notification delivered by Adobe Journey Optimizer (requires iOS 17.2+).

## Usage

The `origin` property is automatically set when creating a [`LiveActivityData`](./live-activity-data.md) instance:

```swift
// Local origin is set automatically
let data = LiveActivityData(liveActivityID: "order123")
// data.origin == .local
```

When a Live Activity is started remotely via push-to-start, the SDK automatically sets the origin to `.remote`.

## Notes

- Push-to-start functionality requires iOS 17.2 or later
- The origin value is used by the SDK for event tracking and analytics
- You typically don't need to manually set or check this value unless implementing custom tracking logic

