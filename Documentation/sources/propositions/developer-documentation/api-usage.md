# APIs Usage

This document details the Messaging SDK APIs that can be used to implement proposition based experiences in mobile apps.

## Proposition based APIs

- [getPropositionsForSurfaces](#getPropositionsForSurfaces)
- [updatePropositionsForSurfaces](#updatePropositionsForSurfaces)

---

### getPropositionsForSurfaces(\_:\_:)

Retrieves previously fetched `Proposition`s from the SDK's in-memory propositions cache for the requested `Surface`s. The completion handler is invoked with the corresponding `Proposition`s or an `AEPError` if one occurs. 

If a requested `Surface` has not been previously cached by calling `updatePropositionsForSurfaces(_:)`, this API will not return any `Proposition`s for that `Surface`.

#### Swift

##### Syntax

```swift
static func getPropositionsForSurfaces(_ surfaces: [Surface], 
                                       _ completion: @escaping ([Surface: [Proposition]]?, Error?) -> Void)
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
    if let propositionsForSurface1 = propositionsDict[surface1] {
        // read surface1 propositions
    }

    if let propositionsForSurface2 = propositionsDict[surface2] {
        // read surface2 propositions
    }
}
```

#### Objective-C

##### Syntax

```objc
+ (void) getPropositionsForSurfaces: (NSArray<AEPSurface*>* _Nonnull) surfaces 
                         completion: (void (^ _Nonnull)(NSDictionary<AEPSurface*, NSArray<AEPProposition*>*>* _Nullable propositionsDict, 
                                                        NSError* _Nullable error)) completion;
```

##### Example

```objc
AEPSurface* surface1 = [[AEPSurface alloc] initWithPath: @"myView#button"];
AEPSurface* surface2 = [[AEPSurface alloc] initWithPath: @"myViewAttributes"];

[AEPMobileMessaging getPropositionsForSurfaces: @[surface1, surface2] 
                                    completion: ^(NSDictionary<AEPDecisionScope*, NSArray<AEPProposition*>*>* propositionsDict, NSError* error) {
    if (error != nil) {
        // handle error
        return;
    }

    NSArray<AEPProposition*>* propositionsForSurface1 = propositionsDict[surface1];
    // read surface1 propositions

    NSArray<AEPProposition*>* propositionsForSurface2 = propositionsDict[surface2];
    // read surface2 propositions
}];
```

---

### updatePropositionsForSurfaces(_:)

Dispatches an event for the Edge network extension to fetch personalization decisions from the AJO campaigns for the provided `Surface`s array. The returned decision `Proposition`s are cached in-memory by the Messaging extension.

To retrieve previously cached decision `Proposition`s, use the `getPropositionsForSurfaces(_:_:)` API.

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
AEPSurface* surface2 = [[AEPSurface alloc] initWithPath: @"myViewAttributes"];

[AEPMobileMessaging updatePropositions: @[surface1, surface2]]; 
```
