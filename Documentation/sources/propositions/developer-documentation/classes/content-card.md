# ContentCard - DEPRECATED

> This class is *DEPRECATED* as of `AEPMessaging v5.2.0`. Use [ContentCardSchemaData](./schemas/content-card-schema-data.md) instead.

An object representing the default content card created in the Adobe Journey Optimizer UI. 

Content cards must be rendered by the app developer.  Tracking a content card is done via calls to the [`track(_:withEdgeEventType:)`](#track_withedgeeventtype) API.

```swift
@objc(AEPContentCard)
@objcMembers
public class ContentCard: NSObject, Codable {
    /// Plain-text title for the content card
    public let title: String

    /// Plain-text body representing the content for the content card
    public let body: String

    /// String representing a URI that contains an image to be used for this content card
    public let imageUrl: String?

    /// Contains a URL to be opened if the user interacts with the content card
    public let actionUrl: String?

    /// Required if `actionUrl` is provided. Text to be used in title of button or link in content card
    public let actionTitle: String?

    ...
}
```

# Public functions

## track(_:withEdgeEventType:)

Tracks an interaction with the given `ContentCard`.

```swift
public func track(_ interaction: String? = nil, withEdgeEventType eventType: MessagingEdgeEventType)
```

#### Parameters

- _interaction_ - a custom `String` value to be recorded in the interaction
- _eventType_ - the [`MessagingEdgeEventType`](./../../../shared/enums/enum-messaging-edge-event-type.md) to be used for the ensuing Edge Event

#### Example

```swift
var contentCard: ContentCard

// tracking a display
contentCard.track(withEdgeEventType: .display)

// tracking a user interaction
contentCard.track("itemSelected", withEdgeEventType: .interact)
```
