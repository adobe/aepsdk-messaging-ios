# Surface

Represents an entity for user or system interaction. It is identified by a self-describing URI and is used to fetch decision propositions from AJO campaigns. 

All mobile application `Surface` URIs start with `mobileapp://`, followed by the app bundle identifier, and finally an optional path. 

#### Swift

##### Syntax

```swift
/// `Surface` class is used to create surfaces for requesting propositions in personalization query requests.
@objc(AEPSurface)
@objcMembers
public class Surface: NSObject, Codable {
    /// Unique surface URI string
    public let uri: String

    /// Creates a new surface by appending the given surface `path` to the mobile app surface prefix.
    ///
    /// - Parameter path: string representation for the surface path.
    public init(path: String) {
        guard !path.isEmpty else {
            uri = ""
            return
        }
        uri = Bundle.main.mobileappSurface + MessagingConstants.PATH_SEPARATOR + path
    }
    ...
}
```

##### Example

```swift
// Creates a surface instance representing a banner within homeView view in my mobile application.
let surface = Surface(path: "homeView#banner")
```