# Proposition

Represents the decision propositions received from the remote, upon a personalization query request to the Experience Edge network.

```swift
@objc(AEPProposition)
@objcMembers
public class Proposition: NSObject, Codable {
    /// Unique proposition identifier
    public let uniqueId: String

    /// Scope string
    public let scope: String

    /// Array containing proposition decision items
    public lazy var items: [PropositionItem] = {...}()

    ...
}
```