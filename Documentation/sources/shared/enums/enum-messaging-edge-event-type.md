# MessagingEdgeEventType

Provides mapping to XDM EventType strings needed for Experience Event requests.

This enum is used in the following APIs: 

  - [`track(_:withEdgeEventType:)`](./../../inapp-messaging/developer-documentation/message.md#track_withedgeeventtype) for `Message` objects.
  - [`track(_:withEdgeEventType:forTokens:)`](./../../propositions/developer-documentation/classes/proposition-item.md#track_withedgeeventtypefortokens) for `PropositionItem` objects.
  - [`track(_:withEdgeEventType:)`](./../../propositions/developer-documentation/classes/schemas/content-card-schema-data.md#track_withedgeeventtype) for `ContentCardSchemaData` objects.
  - [`track(_:withEdgeEventType:)`](./../../propositions/developer-documentation/classes/content-card.md#track_withedgeeventtype) for `ContentCard` objects.

## Definition

```swift
@objc(AEPMessagingEdgeEventType)
public enum MessagingEdgeEventType: Int {
    case pushApplicationOpened = 4
    case pushCustomAction = 5
    case dismiss = 6
    case interact = 7
    case trigger = 8
    case display = 9
    case disqualify = 10
    case suppressDisplay = 11

    public func toString() -> String {
        switch self {
        case .dismiss:
            return MessagingConstants.XDM.IAM.EventType.DISMISS
        case .trigger:
            return MessagingConstants.XDM.IAM.EventType.TRIGGER
        case .interact:
            return MessagingConstants.XDM.IAM.EventType.INTERACT
        case .display:
            return MessagingConstants.XDM.IAM.EventType.DISPLAY
        case .disqualify:
            return MessagingConstants.XDM.Inbound.EventType.DISQUALIFY
        case .suppressDisplay:
            return MessagingConstants.XDM.Inbound.EventType.SUPPRESSED_DISPLAY
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

| Case                  | String value                             |
|-----------------------|------------------------------------------|
| dismiss               | `decisioning.propositionDismiss`         |
| interact              | `decisioning.propositionInteract`        |
| trigger               | `decisioning.propositionTrigger`         |
| display               | `decisioning.propositionDisplay`         |
| disqualify            | `decisioning.propositionDisqualify`      |
| suppressDisplay       | `decisioning.propositionSuppressDisplay` |
| pushApplicationOpened | `pushTracking.applicationOpened`         |
| pushCustomAction      | `pushTracking.customAction`              |
