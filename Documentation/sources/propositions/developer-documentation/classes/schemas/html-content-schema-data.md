# HtmlContentSchemaData

Represents the schema data object for an HTML content schema.

```swift
@objc(AEPHtmlContentSchemaData)
@objcMembers
public class HtmlContentSchemaData: NSObject, Codable {
    /// Represents the content of the HtmlContentSchemaData object.
    public let content: String
    
    /// Determines the value type of `content`.  For HtmlContentSchemaData objects, this value is always `.textHtml`.
    public let format: ContentType?

    ...
}
```
