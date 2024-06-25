# ContentType

Enum representing content types found within a schema object.

```swift
@objc(AEPContentType)
public enum ContentType: Int, Codable {
    case applicationJson = 0
    case textHtml = 1
    case textXml = 2
    case textPlain = 3
    case unknown = 4

    public func toString() -> String {
        switch self {
        case .applicationJson:
            return MessagingConstants.ContentTypes.APPLICATION_JSON
        case .textHtml:
            return MessagingConstants.ContentTypes.TEXT_HTML
        case .textXml:
            return MessagingConstants.ContentTypes.TEXT_XML
        case .textPlain:
            return MessagingConstants.ContentTypes.TEXT_PLAIN
        default:
            return ""
        }
    }
}
```

#### String values

Below is the table of values returned by calling the `toString` method for each case:

| Case | String value |
| ---- | ------------ |
| `.applicationJson` | `application/json` |
| `.testHtml` | `text/html` |
| `.textXml` | `text/xml` |
| `.textPlain` | `text/plain` |
| `.unknown` | (empty string) |
