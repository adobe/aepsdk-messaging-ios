# MessagingEdgeEventType

Provides mapping to XDM EventType strings needed for Experience Event requests.

This enum is used in conjunction with the [`track(_:withEdgeEventType:)`](./class-message.md#track_withedgeeventtype) method of a `Message` object.

## Definition

```swift
@objc(AEPMessagingEdgeEventType)
public enum MessagingEdgeEventType: Int {
    case inappDismiss = 0
    case inappInteract = 1
    case inappTrigger = 2
    case inappDisplay = 3
    case pushApplicationOpened = 4
    case pushCustomAction = 5

    public func toString() -> String {
        switch self {
        case .inappDismiss:
            return MessagingConstants.XDM.IAM.EventType.DISMISS
        case .inappTrigger:
            return MessagingConstants.XDM.IAM.EventType.TRIGGER
        case .inappInteract:
            return MessagingConstants.XDM.IAM.EventType.INTERACT
        case .inappDisplay:
            return MessagingConstants.XDM.IAM.EventType.DISPLAY
        case .pushCustomAction:
            return MessagingConstants.XDM.Push.EventType.CUSTOM_ACTION
        case .pushApplicationOpened:
            return MessagingConstants.XDM.Push.EventType.APPLICATION_OPENED
        }
    }
}
```

### String values

Below is the table of values returned by calling the `toString` method for each case:

| Case                  | String value                     |
|-----------------------|----------------------------------|
| inappDismiss          | `inapp.dismiss`                  |
| inappInteract         | `inapp.interact`                 |
| inappTrigger          | `inapp.trigger`                  |
| inappDisplay          | `inapp.display`                  |
| pushApplicationOpened | `pushTracking.applicationOpened` |
| pushCustomAction      | `pushTracking.customAction`      |
