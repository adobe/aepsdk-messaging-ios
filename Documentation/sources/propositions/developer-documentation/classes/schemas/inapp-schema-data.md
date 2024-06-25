# InAppSchemaData

Represents the schema data object for an in-app schema.

```swift
@objc(AEPInAppSchemaData)
@objcMembers
public class InAppSchemaData: NSObject, Codable {
    /// Represents the content of the InAppSchemaData object.  Its value's type is determined by `contentType`.
    public let content: Any
    
    /// Determines the value type of `content`.
    public let contentType: ContentType
    
    /// Date and time this in-app campaign was published represented as epoch seconds
    public let publishedDate: Int?
    
    /// Date and time this in-app campaign will expire represented as epoch seconds
    public let expiryDate: Int?
    
    /// Dictionary containing any additional meta data for this content card
    public let meta: [String: Any]?
    
    /// Dictionary containing parameters that help control display and behavior of the in-app message on mobile
    public let mobileParameters: [String: Any]?
    
    /// Dictionary containing parameters that help control display and behavior of the in-app message on web
    public let webParameters: [String: Any]?
    
    /// Array of remote assets to be downloaded and cached for future use with the in-app message
    public let remoteAssets: [String]?

    ...
}
```
