# APIs Usage

This document details how to use the APIs provided by the AEPMessaging framework.

## Code-based experiences APIs

- [updatePropositionsForSurfaces](#updatePropositionsForSurfaces)
- [getPropositionsForSurfaces](#getPropositionsForSurfaces)

---

### updatePropositionsForSurfaces

This API dispatches an event for the Edge network extension to fetch personalization decisions, for the provided surfaces array, from the AJO campaigns via the Experience Edge. The returned decision propositions are cached in-memory in the SDK and can be retrieved using `getPropositionsForSurfaces(_:_:)` API.

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

### getPropositionsForSurfaces

This API retrieves the previously fetched propositions, for the provided surfaces, from the SDK in-memory propositions cache. The completion handler is invoked with the decision propositions corresponding to the given surfaces or AEPError, if it occurs. If a certain surface has not already been fetched prior to this API call using `updatePropositionsForSurfaces(_:)` API, it will not be contained in the returned propositions.

#### Swift

##### Syntax

```swift
static func getPropositionsForSurfaces(_ surfacePaths: [Surface], _ completion: @escaping ([Surface: [Proposition]]?, Error?) -> Void)
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
              completion: (void (^ _Nonnull)(NSDictionary<AEPSurface*, NSArray<AEPProposition*>*>* _Nullable propositionsDict, NSError* _Nullable error)) completion;
```

##### Example

```objc
AEPSurface* surface1 = [[AEPSurface alloc] initWithPath: @"myView#button"];
AEPSurface* surface2 = [[AEPSurface alloc] initWithPath: @"myView#button"];

[AEPMobileMessaging getPropositionsForSurfaces: @[surface1, surface2] 
                        completion: ^(NSDictionary<AEPDecisionScope*, NSArray<AEPProposition*>*>* propositionsDict, NSError* error) {
  if (error != nil) {
    // handle error   
    return;
  }

  NSArray<AEPProposition*>* proposition1 = propositionsDict[surface1];
  // read surface1 propositions

  NSArray<AEPProposition*>* proposition2 = propositionsDict[surface2];
  // read surface2 propositions
}];
```

---

## Public Classes

| Type | Swift | Objective-C |
| ---- | ----- | ----------- |
| class | `Surface` | `AEPSurface` |
| class | `Proposition` | `AEPProposition` |
| class | `PropositionItem` | `AEPPropositionItem` |

### Surface

This class represents the decision scope which is used to fetch the decision propositions from the Edge decisioning services. The encapsulated scope name can also represent the Base64 encoded JSON string created using the provided activityId, placementId and itemCount.

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

    /// Creates a new surface by providing the full mobile app surface URI.
    ///
    /// - Parameter uri: string representation for the surface URI.
    init(uri: String) {
        self.uri = uri
    }

    /// Creates a new base surface URI (containing mobileapp:// prefixed to app bundle identifier), without any path suffix.
    override convenience init() {
        self.init(uri: Bundle.main.mobileappSurface)
    }

    /// Verifies that the surface URI string is a valid URL.
    var isValid: Bool {
        guard URL(string: uri) != nil else {
            Log.warning(label: MessagingConstants.LOG_TAG,
                        "Invalid surface URI found \(uri).")
            return false
        }
        return true
    }
    ...
}
```

### Proposition

This class represents the decision propositions received from the remote, upon a personalization query request to the Experience Edge network.

```swift
@objc(AEPProposition)
@objcMembers
public class Proposition: NSObject, Codable {
    /// Unique proposition identifier
    public let uniqueId: String

    /// Scope string
    public let scope: String

    /// Scope details dictionary
    var scopeDetails: [String: Any]

    /// Array containing proposition decision items
    private let propositionItems: [PropositionItem]

    public lazy var items: [PropositionItem] = {...}()

    init(uniqueId: String, scope: String, scopeDetails: [String: Any], items: [PropositionItem]) {
        self.uniqueId = uniqueId
        self.scope = scope
        self.scopeDetails = scopeDetails
        propositionItems = items
    }
    ...
}
```

### PropositionItem

This class represents the decision proposition item received from the remote, upon a personalization query to the Experience Edge network.

```swift
@objc(AEPPropositionItem)
@objcMembers
public class PropositionItem: NSObject, Codable {
    /// Unique PropositionItem identifier
    public let uniqueId: String

    /// PropositionItem schema string
    public let schema: String

    /// PropositionItem content string
    public let content: String

    /// Weak reference to Proposition instance
    weak var proposition: Proposition?

    init(uniqueId: String, schema: String, content: String) {
        self.uniqueId = uniqueId
        self.schema = schema
        self.content = content
    }
    ...
}
```