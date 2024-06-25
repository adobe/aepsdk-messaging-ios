# PropositionItem

Represents the decision proposition item received from the remote, upon a personalization query to the Experience Edge network.

```swift
@objc(AEPPropositionItem)
@objcMembers
public class PropositionItem: NSObject, Codable {
    /// Unique identifier for this `PropositionItem`
    /// contains value for `id` in JSON
    public let itemId: String

    /// `PropositionItem` schema string
    /// contains value for `schema` in JSON
    public let schema: SchemaType

    /// `PropositionItem` data as dictionary
    /// contains value for `data` in JSON
    public let itemData: [String: Any]

    ...
}
```

# Public functions

## track(_:withEdgeEventType:forTokens:)

Tracks an interaction with the given `PropositionItem`.

```swift
public func track(_ interaction: String? = nil, withEdgeEventType eventType: MessagingEdgeEventType, forTokens tokens: [String]? = nil)
```

#### Parameters

- _interaction_ - a custom `String` value to be recorded in the interaction
- _eventType_ - the [`MessagingEdgeEventType`](./../../../shared/enums/enum-messaging-edge-event-type.md) to be used for the ensuing Edge Event
- _tokens_ - an array containing the sub-item tokens for recording the interaction

#### Example

```swift
var propositionItem: PropositionItem

// tracking a display
propositionItem.track(withEdgeEventType: .display)

// tracking a user interaction
propositionItem.track("userAccept", withEdgeEventType: .interact)

// Extract the tokens from the PropositionItem's itemData map
propositionItem.track("click", withEdgeEventType: .interact, forTokens: [dataItemToken1, dataItemToken2])
```

# Public calculated variables

## contentCardSchemaData

Tries to retrieve a `ContentCardSchemaData` object from this `PropositionItem`'s `content` property in `itemData`.

Returns a `ContentCardSchemaData` object if the schema for this `PropositionItem` is `.contentCard` or `.feed` and it is properly formed - `nil` otherwise.

```swift
var contentCardSchemaData: ContentCardSchemaData?
```

#### Example

```swift
var propositionItem: PropositionItem
if let contentCardData = propositionItem.contentCardSchemaData {
    // do something with the ContentCardSchemaData object
}
```

## htmlContent

Tries to retrieve `content` from this `PropositionItem`'s `itemData` map as an HTML `String`.

Returns a string if the schema for this `PropositionItem` is `.htmlContent` and it contains string content - `nil` otherwise.

```swift
var htmlContent: String?
```

#### Example

```swift
var propositionItem: PropositionItem
if let htmlContent = propositionItem.htmlContent {
    // do something with the html content
}
```

## inAppSchemaData

Tries to retrieve an `InAppSchemaData` object from this `PropositionItem`'s `content` property in `itemData`.

Returns an `InAppSchemaData` object if the schema for this `PropositionItem` is `.inapp` and it is properly formed - `nil` otherwise.

```swift
var inappSchemaData: InAppSchemaData?
```

#### Example

```swift
var propositionItem: PropositionItem
if let inappData = propositionItem.inappSchemaData {
    // do something with the InAppSchemaData object
}
```

## jsonContentArray

Tries to retrieve `content` from this `PropositionItem`'s `itemData` map as an `[Any]` array.

Returns an array if the schema for this `PropositionItem` is `.jsonContent` and it contains array content - `nil` otherwise.

```swift
var jsonContentArray: [Any]?
```

#### Example

```swift
var propositionItem: PropositionItem
if let contentArray = propositionItem.jsonContentArray {
    // do something with the array content
}
```

## jsonContentDictionary

Tries to retrieve `content` from this `PropositionItem`'s `itemData` map as a `[String: Any]` dictionary.

Returns a dictionary if the schema for this `PropositionItem` is `.jsonContent` and it contains dictionary content - `nil` otherwise.

```swift
var jsonContentDictionary: [String: Any]?
```

#### Example

```swift
var propositionItem: PropositionItem
if let contentDictionary = propositionItem.jsonContentDictionary {
    // do something with the dictionary content
}
```
