# ContentCardSchemaData

Represents the schema data object for a content-card schema.

```swift
@objc(AEPContentCardSchemaData)
@objcMembers
public class ContentCardSchemaData: NSObject, Codable {
    /// Represents the content of the ContentCardSchemaData object.  Its value's type is determined by `contentType`.
    public let content: Any
    
    /// Determines the value type of `content`.
    public let contentType: ContentType
    
    /// Date and time this content card was published represented as epoch seconds
    public let publishedDate: Int?
    
    /// Date and time this content card will expire represented as epoch seconds
    public let expiryDate: Int?
    
    /// Dictionary containing any additional meta data for this content card
    public let meta: [String: Any]?

    ...
}
```

# Public functions

## getContentCard

Tries to convert the `content` of this `ContentCardSchemaData` into a [`ContentCard`](./../content-card.md) object.

Returns `nil` if the `contentType` is not equal to `.applicationJson` or the data in `content` is not decodable into a `ContentCard`.

#### Syntax

```swift
func getContentCard() -> ContentCard?
```

#### Example

```swift
var propositionItem: PropositionItem
if let contentCardSchemaData = propositionItem.contentCardSchemaData,
   let contentCard = contentCardSchemaData.getContentCard() {
    // do something with the ContentCard object
}
```

## track(_:withEdgeEventType:)

Tracks an interaction with the given `ContentCardSchemaData`.

```swift
public func track(_ interaction: String? = nil, withEdgeEventType eventType: MessagingEdgeEventType)
```

#### Parameters

- _interaction_ - a custom `String` value to be recorded in the interaction
- _eventType_ - the [`MessagingEdgeEventType`](./../../../shared/enums/enum-messaging-edge-event-type.md) to be used for the ensuing Edge Event

#### Example

```swift
var contentCardSchemaData: ContentCardSchemaData

// tracking a display
contentCardSchemaData.track(withEdgeEventType: .display)

// tracking a user interaction
contentCardSchemaData.track("itemSelected", withEdgeEventType: .interact)
```
