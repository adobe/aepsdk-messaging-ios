# JsonContentSchemaData

Represents the schema data object for a json content schema.

```swift
@objc(AEPJsonContentSchemaData)
@objcMembers
public class JsonContentSchemaData: NSObject, Codable {
    /// Represents the content of the JsonContentSchemaData object.  Its value's type is determined by `format`.
    public let content: Any
    
    /// Determines the value type of `content`.
    public let format: ContentType?

    ...
}
```