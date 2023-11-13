# APIs Usage

This document details the Messaging SDK APIs that can be used to implement code-based experiences in mobile apps.

## Code-based experiences APIs

- [updatePropositionsForSurfaces](#updatePropositionsForSurfaces)
- [getPropositionsForSurfaces](#getPropositionsForSurfaces)

---

### updatePropositionsForSurfaces(_:)

Dispatches an event for the Edge network extension to fetch personalization decisions from the AJO campaigns for the provided surfaces array. The returned decision propositions are cached in-memory by the Messaging extension.

To retrieve previously cached decision propositions, use `getPropositionsForSurfaces(_:_:)` API.

#### Swift

##### Syntax
```swift
static func updatePropositionsForSurfaces(_ surfaces: [Surface])
```

##### Example
```swift
let surface1 = Surface(path: "myView#button")
let surface2 = Surface(path: "myViewAttributes")

Messaging.updatePropositionsForSurfaces([surface1, surface2])
```

#### Objective-C

##### Syntax
```objc
+ (void) updatePropositionsForSurfaces: (NSArray<AEPSurface*>* _Nonnull) surfaces;
```

##### Example
```objc
AEPSurface* surface1 = [[AEPSurface alloc] initWithPath: @"myView#button"];
AEPSurface* surface2 = [[AEPSurface alloc] initWithPath: @"myView#button"];

[AEPMobileMessaging updatePropositions: @[surface1, surface2]]; 
```

---

### getPropositionsForSurfaces(_:_:)

Retrieves the previously fetched propositions from the SDK's in-memory propositions cache for the provided surfaces. The completion handler is invoked with the decision propositions corresponding to the given surfaces or AEPError, if it occurs. 

If a requested surface was not previously cached prior to calling `getPropositionsForSurfaces(_:_:)` (using the `updatePropositionsForSurfaces(_:)` API), no propositions will be returned for that surface.

#### Swift

##### Syntax

```swift
static func getPropositionsForSurfaces(_ surfacePaths: [Surface], _ completion: @escaping ([Surface: [MessagingProposition]]?, Error?) -> Void)
```

##### Example

```swift
let surface1 = Surface(path: "myView#button")
let surface2 = Surface(path: "myViewAttributes")

Messaging.getPropositionsForSurfaces([surface1, surface2]) { propositionsDict, error in
    guard error == nil else {
        // handle error
        return
    }

    guard let propositionsDict = propositionsDict else {
        // bail early if no propositions
        return
    }
    
    // get the propositions for the given surfaces
    if let propositions1 = propositionsDict[surface1] {
        // read surface1 propositions
    }

    if let propositions2 = propositionsDict[surface2] {
        // read surface2 propositions
    }
}
```

#### Objective-C

##### Syntax

```objc
+ (void) getPropositionsForSurfaces: (NSArray<AEPSurface*>* _Nonnull) surfaces 
              completion: (void (^ _Nonnull)(NSDictionary<AEPSurface*, NSArray<AEPMessagingProposition*>*>* _Nullable propositionsDict, NSError* _Nullable error)) completion;
```

##### Example

```objc
AEPSurface* surface1 = [[AEPSurface alloc] initWithPath: @"myView#button"];
AEPSurface* surface2 = [[AEPSurface alloc] initWithPath: @"myView#button"];

[AEPMobileMessaging getPropositionsForSurfaces: @[surface1, surface2] 
                        completion: ^(NSDictionary<AEPDecisionScope*, NSArray<AEPMessagingProposition*>*>* propositionsDict, NSError* error) {
  if (error != nil) {
    // handle error   
    return;
  }

  NSArray<AEPMessagingProposition*>* proposition1 = propositionsDict[surface1];
  // read surface1 propositions

  NSArray<AEPMessagingProposition*>* proposition2 = propositionsDict[surface2];
  // read surface2 propositions
}];
```

---

## Public Classes

| Type | Swift | Objective-C |
| ---- | ----- | ----------- |
| class | `Surface` | `AEPSurface` |
| class | `MessagingProposition` | `AEPMessagingProposition` |
| class | `MessagingPropositionItem` | `AEPMessagingPropositionItem` |

### class Surface

Represents an entity for user or system interaction. It is identified by a self-describing URI and is used to fetch the decision propositions from the AJO campaigns. For example, all mobile application surface URIs start with `mobileapp://`, followed by app bundle identifier and an optional path. 

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

### class MessagingProposition

Represents the decision propositions received from the remote, upon a personalization query request to the Experience Edge network.

```swift
@objc(AEPMessagingProposition)
@objcMembers
public class MessagingProposition: NSObject, Codable {
    /// Unique proposition identifier
    public let uniqueId: String

    /// Scope string
    public let scope: String

    /// Scope details dictionary
    var scopeDetails: [String: Any]

    /// Array containing proposition decision items
    public lazy var items: [MessagingPropositionItem] = {...}()

    ...
}
```

### class MessagingPropositionItem

Represents the decision proposition item received from the remote, upon a personalization query to the Experience Edge network.

```swift
@objc(AEPMessagingPropositionItem)
@objcMembers
public class MessagingPropositionItem: NSObject, Codable {
    /// Unique proposition item identifier
    public let uniqueId: String

    /// Proposition item schema string
    public let schema: String

    /// Proposition item content string
    public let content: String

    ...
}
```