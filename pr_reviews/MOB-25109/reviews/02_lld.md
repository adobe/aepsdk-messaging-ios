# LLD Review: MOB-25109/offline-content-card-availability

## Summary

The session-level `networkRefreshedSurfaces` design is structurally sound, but the CC offline persistence write path is entirely broken by a commented-out line in `ParsedPropositions`, and several secondary issues reduce long-term maintainability.

---

## Design Issues

### CRITICAL: Content card disk write is commented out — offline persistence ships broken

**Files:**
- `AEPMessaging/Sources/ParsedPropositions.swift:92-94`

**Problem:**
```swift
case .feed, .contentCard:
    propositionInfoToCache[consequence.id] = PropositionInfo.fromProposition(proposition)
    if contentCardOfflineAvailable {
      //  contentCardPropositionsToPersist.add(proposition, forKey: surface)
    }
    mergeRules(parsedRule, for: surface, with: .contentCard)
```

`contentCardPropositionsToPersist` is declared and the parameter `contentCardOfflineAvailable` is wired up correctly, but the single line that actually populates the dictionary is commented out. As a result, `contentCardPropositionsToPersist` is always `[:]` regardless of the config flag.

In `applyPropositionChangeFor` (Messaging.swift:1300), the call:
```swift
ccWriteOK = cache.updateContentCardPropositions(parsedPropositions.contentCardPropositionsToPersist, removing: surfacesToRemove)
```
always writes an empty map. The CC disk cache is never populated. The entire offline persistence feature for content cards does not work.

**Why it matters:** The PR's stated goal is offline CC availability. The read path (disk hydration at boot) is implemented, but the write path is dead. The feature ships silently broken — apps with `messaging.contentCardOfflineAvailable = true` will hydrate from disk on cold start but never have anything to hydrate.

**Confidence:** 1.0

**Caveats:** None — the code state is unambiguous.

**Challenge:** Could this be intentional scaffolding committed before the write path is ready? The diff shows it was introduced in this PR as a commented placeholder, not as a future-PR deferral. There is no accompanying tracking comment linking to a follow-up ticket.

**Fix:**
```swift
case .feed, .contentCard:
    propositionInfoToCache[consequence.id] = PropositionInfo.fromProposition(proposition)
    if contentCardOfflineAvailable {
        contentCardPropositionsToPersist.add(proposition, forKey: surface)
    }
    mergeRules(parsedRule, for: surface, with: .contentCard)
```

---

### HIGH: `nonRecoverableErrorEventIds` is read twice across a function boundary — fragile ordering dependency

**Files:**
- `AEPMessaging/Sources/Messaging.swift:1257-1266` (`endRequestFor`)
- `AEPMessaging/Sources/Messaging.swift:1282` (`applyPropositionChangeFor`)

**Problem:**
```swift
// endRequestFor
private func endRequestFor(eventId: String) {
    let requestFailed = nonRecoverableErrorEventIds.contains(eventId)  // read #1
    applyPropositionChangeFor(eventId: eventId)                        // reads it again internally
    requestedSurfacesForEventId.removeValue(forKey: eventId)
    nonRecoverableErrorEventIds.remove(eventId)                        // removal happens LAST
    inProgressPropositions.removeAll()
    if let handler = completionHandlerFor(edgeRequestEventId: UUID(uuidString: eventId)) {
        handler.handle?(!requestFailed)                                 // uses read #1
    }
}

// applyPropositionChangeFor
private func applyPropositionChangeFor(eventId: String) {
    ...
    let requestFailed = nonRecoverableErrorEventIds.contains(eventId)  // read #2 — same set, same key
```

The same set is queried twice for the same `eventId`. Both reads are consistent today only because `nonRecoverableErrorEventIds.remove(eventId)` is sequenced after both reads. If someone reorders `endRequestFor` — a tempting refactor — to clean up the error set before calling `applyPropositionChangeFor`, `requestFailed` inside `applyPropositionChangeFor` silently becomes `false`, causing incorrect eviction of disk content on error.

**Why it matters:** The ordering dependency is invisible. The computed value (`requestFailed`) should be computed once and passed as a parameter to `applyPropositionChangeFor`. The current design scatters the failure-detection logic across two call frames with a shared-state dependency.

**Confidence:** 0.9

**Caveats:** The current execution is correct; this is a future-regression risk, not a current bug.

**Challenge:** Could argue that both callers need independent reads since `applyPropositionChangeFor` might be called from other paths. But it is only called from `endRequestFor`, making the double-read redundant.

**Fix:**
```swift
private func endRequestFor(eventId: String) {
    let requestFailed = nonRecoverableErrorEventIds.contains(eventId)
    applyPropositionChangeFor(eventId: eventId, requestFailed: requestFailed)
    requestedSurfacesForEventId.removeValue(forKey: eventId)
    nonRecoverableErrorEventIds.remove(eventId)
    inProgressPropositions.removeAll()
    if let handler = completionHandlerFor(edgeRequestEventId: UUID(uuidString: eventId)) {
        handler.handle?(!requestFailed)
    }
}

private func applyPropositionChangeFor(eventId: String, requestFailed: Bool) {
    guard let requestedSurfaces = requestedSurfacesForEventId[eventId] else { return }
    // remove the `let requestFailed = nonRecoverableErrorEventIds.contains(eventId)` line
    ...
}
```

**Change impact analysis:**
To add another caller of `applyPropositionChangeFor` (e.g., a timeout path):
- `Messaging.swift` — needs to compute `requestFailed` before calling (currently implicit)
- This is 1 file; GOOD EXTENSIBILITY once the parameter is explicit.

---

### HIGH: `ServiceProvider.shared` direct coupling bypasses extension API boundary

**Files:**
- `AEPMessaging/Sources/Messaging.swift:994-996`

**Problem:**
```swift
// TODO: Replace with MobileCore.isNetworkAvailable() once AEPCore exposes it as a public API.
// Reaching into ServiceProvider.shared is an internal coupling that extensions should not need.
private func isNetworkAvailable() -> Bool {
    ServiceProvider.shared.networkService.isNetworkAvailable()
}
```

An AEP extension reaching directly into `ServiceProvider.shared` crosses the intended API boundary. `ServiceProvider` is the AEP internal service container — extensions are expected to interact with `MobileCore` or `runtime` only. The test workaround (`MockNetworkConnectivityService`) also has to replace the underlying service provider entry, which is brittle and depends on AEP internals.

Additionally, `isNetworkAvailable()` is called in `onRegistered()` (line 339) solely to warm up `NWPathMonitor`. This is a side-effectful call disguised as a query — the return value is discarded with `_ =`. The warm-up intent should be explicit, not buried in a query call.

**Why it matters:** If AEP Core changes how `ServiceProvider.shared.networkService` is structured, or the method signature changes, this breaks silently at runtime. The warm-up pattern also leaks the concern that `NWPathMonitor` needs pre-warming into the `Messaging` extension.

**Confidence:** 0.85

**Caveats:** The TODO comment acknowledges this; the coupling may be intentional until AEPCore exposes the API publicly. The impact is bounded to the `isNetworkAvailable()` wrapper.

**Challenge:** There may be no better option until AEPCore ships the public API. The wrapper at least isolates the coupling to one place.

**Fix (when AEPCore ships the API):** Replace with `MobileCore.isNetworkAvailable()`. For the warm-up concern, add an explicit method:
```swift
private func warmUpNetworkMonitor() {
    // NWPathMonitor requires time to report its first status reading.
    // This call initializes the singleton early so the first user-triggered
    // fetch has a stable reading.
    ServiceProvider.shared.networkService.isNetworkAvailable()
}
```
Call `warmUpNetworkMonitor()` in `onRegistered()` for clarity.

---

### MEDIUM: `clearCachedContentCardPropositions()` is a vacuous wrapper over `clearContentCards()`

**Files:**
- `AEPMessaging/Sources/Messaging.swift:682-696`

**Problem:**
```swift
private func clearContentCards() {
    qualifiedContentCardsBySurface = [:]
    contentCardRulesBySurface = [:]
    networkRefreshedSurfaces = []
    contentCardRulesEngine.launchRulesEngine.replaceRules(with: [])
    try? cache.remove(key: MessagingConstants.Caches.CONTENT_CARD_PROPOSITIONS)
    Log.debug(label: MessagingConstants.LOG_TAG, "Content card state cleared.")
}

private func clearCachedContentCardPropositions() {
    clearContentCards()
    Log.debug(label: MessagingConstants.LOG_TAG, "Persisted content card propositions cleared.")
}
```

`clearCachedContentCardPropositions` does exactly what `clearContentCards` does, plus logs a second message. The two names suggest different scopes ("in-memory + disk" vs "disk only"), but the implementations are identical. Call sites (`handleResetIdentitiesEvent`, `handleProcessEvent` for `isClearCachedPropositionsEvent`, `applyPropositionChangeFor`, `retrieveMessages`) use them interchangeably.

Call sites for both functions:
- `Messaging.swift:417` — `clearCachedContentCardPropositions()`
- `Messaging.swift:672` — `clearCachedContentCardPropositions()`
- `Messaging.swift:1304` — `clearCachedContentCardPropositions()`
- `Messaging.swift:1480` — `clearCachedContentCardPropositions()`

All four call the wrapper. `clearContentCards` is only called by `clearCachedContentCardPropositions`. The wrapper adds nothing.

**Why it matters:** A reader trying to understand why two functions exist with similar names will search for behavioral difference and find none. If a future developer adds behavior to one but not the other (e.g., clearing `networkRefreshedSurfaces` only in the wrapper), it creates a silent divergence.

**Confidence:** 1.0

**Fix:** Eliminate `clearContentCards()` and consolidate everything into `clearCachedContentCardPropositions()`, or eliminate the wrapper and call `clearContentCards()` directly everywhere.

---

### MEDIUM: `enrichWithContentCardOrigin` uses a raw string literal `"data"` — inconsistent with all other keys in the same function

**Files:**
- `AEPMessaging/Sources/Messaging.swift:192-196`

**Problem:**
```swift
let enrichedItems: [[String: Any]] = items.map { item in
    var updatedItem = item
    var data = updatedItem["data"] as? [String: Any] ?? [:]         // raw string
    var characteristics = data[MessagingConstants.XDM.Inbound.Key.CHARACTERISTICS] as? [String: Any] ?? [:]
    characteristics[MessagingConstants.XDM.Inbound.Key.SERVED_FROM_PERSISTENT_CACHE] = servedFromCache
    data[MessagingConstants.XDM.Inbound.Key.CHARACTERISTICS] = characteristics
    updatedItem["data"] = data                                       // raw string again
    return updatedItem
}
```

Every other key accessed in this function uses a `MessagingConstants` reference. The `"data"` key is the only bare string literal. If the XDM schema for proposition item data changes the key name, the constant would be updated centrally but this line would silently break.

**Why it matters:** The XDM schema key `"data"` is used in at least two places here (read and write) and is not covered by the constant system that protects every other key in the function.

**Confidence:** 0.95

**Caveats:** Could not verify whether a constant for this specific key already exists elsewhere in `MessagingConstants`. If it does, this is a clear omission. If it does not, the fix is to add one.

**Fix:**
```swift
// In MessagingConstants.XDM.Inbound.Key (or appropriate nested scope):
static let DATA = "data"

// In enrichWithContentCardOrigin:
var data = updatedItem[MessagingConstants.XDM.Inbound.Key.DATA] as? [String: Any] ?? [:]
updatedItem[MessagingConstants.XDM.Inbound.Key.DATA] = data
```

---

### MEDIUM: `hydrateContentCardPropositionsRulesEngine` hardcodes `contentCardOfflineAvailable: true`, bypassing the config flag

**Files:**
- `AEPMessaging/Sources/Messaging.swift:1407-1408`

**Problem:**
```swift
func hydrateContentCardPropositionsRulesEngine(for surfaces: [Surface], from propositions: [Surface: [Proposition]]) {
    ...
    let parsedPropositions = ParsedPropositions(with: filtered, requestedSurfaces: surfaces, runtime: runtime,
                                                contentCardOfflineAvailable: true)  // hardcoded
```

The disk hydration path always passes `contentCardOfflineAvailable: true` to `ParsedPropositions`, regardless of the app's `messaging.contentCardOfflineAvailable` configuration. This creates an asymmetry: the network path (in `applyPropositionChangeFor`) reads the actual config flag, while the disk hydration path always behaves as if the flag is `true`.

The rationale (we're already reading from disk, so the feature is implicitly enabled) is logical, but the `contentCardOfflineAvailable` parameter on `ParsedPropositions` is now semantically different depending on who calls it. To a future reader, it's unclear why one call site reads the config and the other does not.

Since the disk write (`contentCardPropositionsToPersist.add(...)`) is currently commented out (see CRITICAL finding above), this is moot in practice. But once the write path is activated, the inconsistency matters: if the app disables the flag mid-session, a subsequent `applyPropositionChangeFor` will stop writing, but `hydrateContentCardPropositionsRulesEngine` will behave as if the feature is still enabled.

**Why it matters:** The parameter's semantics diverge depending on call site. This makes `ParsedPropositions` harder to reason about in isolation.

**Confidence:** 0.75

**Caveats:** The intent may be correct — disk hydration should always try to persist regardless of the runtime flag because the data is already on disk. But the parameter name does not communicate this distinction.

**Fix:** Either rename the parameter to `shouldPopulateContentCardsToPersist` to clarify its purpose, or — preferably — remove the `contentCardOfflineAvailable` parameter from `ParsedPropositions` entirely and always populate `contentCardPropositionsToPersist`. Let callers (in `applyPropositionChangeFor`) decide whether to call `cache.updateContentCardPropositions` based on the config flag. This moves the policy decision out of the data-parsing layer.

---

### MEDIUM: `isContentCardOfflineAvailable()` reads the config value twice in the same call — once for logic, once for the log message

**Files:**
- `AEPMessaging/Sources/Messaging.swift:1002-1006`

**Problem:**
```swift
private func isContentCardOfflineAvailable(for event: Event? = nil) -> Bool {
    let config = getSharedState(extensionName: MessagingConstants.SharedState.Configuration.NAME, event: event)
    let value = config?.value?[MessagingConstants.SharedState.Configuration.CONTENT_CARD_OFFLINE_AVAILABLE] as? Bool ?? false
    Log.debug(label: MessagingConstants.LOG_TAG, "isContentCardOfflineAvailable: \(value) (key '\(MessagingConstants.SharedState.Configuration.CONTENT_CARD_OFFLINE_AVAILABLE)' \(config?.value?[MessagingConstants.SharedState.Configuration.CONTENT_CARD_OFFLINE_AVAILABLE] == nil ? "absent from config — defaulting to false" : "found in config"))")
    return value
}
```

`config?.value?[MessagingConstants.SharedState.Configuration.CONTENT_CARD_OFFLINE_AVAILABLE]` is evaluated twice: once to extract `value` (with `as? Bool ?? false`) and once again inside the log string interpolation for the nil-check conditional. The second evaluation does a separate dictionary lookup and conditional expression inside a debug interpolation that is evaluated on every call.

`isContentCardOfflineAvailable()` is called at least 3 times per request cycle (`applyPropositionChangeFor` calls it once, `retrieveMessages` calls it once, and potentially `hydrateContentCardPropositionsRulesEngine` bypasses it). Each call triggers two dictionary lookups on the shared state, plus the string interpolation work.

**Why it matters:** Minor performance overhead, but the doubled lookup also means the log message could theoretically differ from the returned value if the shared state is mutable between the two reads (unlikely in practice since shared state is event-pinned, but it's still imprecise code).

**Confidence:** 0.9

**Fix:**
```swift
private func isContentCardOfflineAvailable(for event: Event? = nil) -> Bool {
    let config = getSharedState(extensionName: MessagingConstants.SharedState.Configuration.NAME, event: event)
    let rawValue = config?.value?[MessagingConstants.SharedState.Configuration.CONTENT_CARD_OFFLINE_AVAILABLE]
    let value = rawValue as? Bool ?? false
    let source = rawValue == nil ? "absent from config — defaulting to false" : "found in config"
    Log.debug(label: MessagingConstants.LOG_TAG,
              "isContentCardOfflineAvailable: \(value) (key '\(MessagingConstants.SharedState.Configuration.CONTENT_CARD_OFFLINE_AVAILABLE)' \(source))")
    return value
}
```

---

### LOW: Change impact for adding a second provenance-tracked proposition type

**Context:** The PR replaces per-`Proposition` `CardOrigin` with a session-level `networkRefreshedSurfaces: Set<Surface>`. This is the right direction — per-proposition tagging would have required persisting the flag on the `Proposition` type itself, complicating serialization. However, the pattern for a second tracked type (e.g., if CBE or IAM ever needed a `servedFromPersistentCache` flag) is not abstracted.

To add provenance tracking for a second proposition type:
- `Messaging.swift` — add a new session `Set<Surface>` for the new type (private + queue-protected)
- `Messaging.swift:clearContentCards` — clear the new set
- `Messaging.swift:removeOrReplaceContentCards` (or its equivalent for the new type) — maintain the new set
- `Messaging.swift:enrichWithContentCardOrigin` — extend the function or add a parallel function for the new type
- `ParsedPropositions.swift` — add a new `*ToPersist` property
- `Cache+Messaging.swift` — add a new persistence method for the new type

VERDICT: 6 files need changes = POOR EXTENSIBILITY for new provenance types. The pattern is not parameterized or protocol-driven.

**Confidence:** 0.7

**Caveats:** CBE and IAM provenance tracking is not in scope for the current release. This is a speculative future concern, not a current bug.

**Challenge:** This could be YAGNI — the design is correct for the current scope and adding abstraction prematurely would increase complexity without immediate benefit.

**Suggested mitigation (deferred):** If a second provenance-tracked type is planned, extract `networkRefreshedSurfaces` maintenance into a small `ProvenanceTracker` type that maps `SchemaType → Set<Surface>`. This avoids duplicating the queue-protection and clear/insert/remove logic per type.

---

## Structured Output

**Findings by severity:**
- CRITICAL: 1
- HIGH: 2
- MEDIUM: 4
- LOW: 1

**Overall confidence in this review:** 0.90

**Areas I could not adequately assess:**
- Whether `contentCardPropositionsToPersist.add(...)` being commented out is a known, tracked deferral (no ticket reference is present in the code). If this is intentional scaffolding for a follow-up commit, the CRITICAL severity should be reclassified as a merge-blocking TODO rather than a design defect.
- The exact AEP Core internal API surface for `ServiceProvider.shared.networkService.isNetworkAvailable()` — I cannot verify whether the method signature has changed since the TODO was written, or whether the AEPCore public API is available in the version this project targets.
- Thread-safety between the two separate `queue.sync` reads in `enrichWithContentCardOrigin` under true concurrent load — the event processing model serializes most calls, but an external network callback could theoretically slip a `queue.async` write between the two reads.

**Recommendation:** BLOCK — the commented-out disk write (CRITICAL finding) means the feature does not function as described in the PR. All other findings are request-changes level but do not justify blocking on their own.
