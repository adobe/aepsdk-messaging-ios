# Code Validation: MOB-25109/offline-content-card-availability

## Summary

Nine code-level bugs found across correctness, state management, and dead code — two of which silently destroy the disk cache in normal operation and misreport errors to callers.

---

## Code Issues

### CRITICAL-1: `isContentCardOfflineAvailable` defaults to `false` but doc comment says `true` — causes disk cache to be cleared on every network response when config key is absent

**File:** `AEPMessaging/Sources/Messaging.swift:1013–1018`

**Problem:**
```swift
/// Defaults to `true` when the key is absent (backwards-compatible: offline availability is on
/// unless the operator explicitly disables it).
private func isContentCardOfflineAvailable(for event: Event? = nil) -> Bool {
    let config = getSharedState(...)
    let value = config?.value?[MessagingConstants.SharedState.Configuration.CONTENT_CARD_OFFLINE_AVAILABLE] as? Bool ?? false
    // ...
    return value
}
```

The doc comment says the function defaults to `true` when the config key is absent. The code defaults to `false`. This is not a doc drift concern — the divergence produces destructive behavior: in `applyPropositionChangeFor` (line 1281–1290), when `ccOfflineAvailable` is `false`, the code calls `clearPersistedContentCardPropositions()`, which wipes the entire CC disk cache. So for any app that does not explicitly set `messaging.contentCardOfflineAvailable = true` in its config, every successful network personalization response destroys the disk cache. The boot-time hydration (`hydrateAllPersistedContentCards`, called unconditionally) will read data that was persisted in a prior session, but the first successful network refresh after launch will immediately clear it.

**Fix:**
```swift
let value = config?.value?[MessagingConstants.SharedState.Configuration.CONTENT_CARD_OFFLINE_AVAILABLE] as? Bool ?? true
// Update log: "absent from config — defaulting to true"
```

---

### CRITICAL-2: `endRequestFor` always reports success to the completion handler even when the request had a non-recoverable Edge error

**File:** `AEPMessaging/Sources/Messaging.swift:1222–1247`

**Problem:**
```swift
private func endRequestFor(eventId: String) {
    // KNOWN ISSUE: ... `handler.handle?(true)` further down still unconditionally reports
    // success. A caller using `updatePropositionsForSurfacesWithCompletionHandler` to decide
    // "did this call return fresh data, or should I fall back to a persisted-disk read"
    // cannot currently distinguish this case from a genuine success.
    applyPropositionChangeFor(eventId: eventId)

    requestedSurfacesForEventId.removeValue(forKey: eventId)
    nonRecoverableErrorEventIds.remove(eventId)   // <-- cleared here, below the fix point
    inProgressPropositions.removeAll()

    if let handler = completionHandlerFor(edgeRequestEventId: UUID(uuidString: eventId)) {
        handler.handle?(true)   // <-- always true
    }
}
```

The `nonRecoverableErrorEventIds` set correctly tracks request failures, but it is cleared _before_ the result is used to inform the completion handler. A caller using `updatePropositionsForSurfacesWithCompletionHandler` to fall back to disk on failure always receives `true` and therefore never falls back. The code itself identifies the fix in the comment: capture the failure flag before clearing it, then pass `!requestFailed` to the handler.

**Fix:**
```swift
private func endRequestFor(eventId: String) {
    applyPropositionChangeFor(eventId: eventId)

    requestedSurfacesForEventId.removeValue(forKey: eventId)

    let requestFailed = nonRecoverableErrorEventIds.contains(eventId)
    nonRecoverableErrorEventIds.remove(eventId)

    inProgressPropositions.removeAll()

    if let handler = completionHandlerFor(edgeRequestEventId: UUID(uuidString: eventId)) {
        handler.handle?(!requestFailed)
    }
}
```

---

### HIGH-1: `applyPropositionChangeFor` CC-disabled path ignores `requestFailed` and clears disk cache for failed requests

**File:** `AEPMessaging/Sources/Messaging.swift:1280–1290`

**Problem:**
```swift
let requestFailed = nonRecoverableErrorEventIds.contains(eventId)
// ... surfacesToRemove is correctly [] when requestFailed ...

let ccWriteOK: Bool
if ccOfflineAvailable {
    ccWriteOK = cache.updateContentCardPropositions(..., removing: surfacesToRemove)
} else {
    clearPersistedContentCardPropositions()   // always executed, even when requestFailed = true
    ccWriteOK = true
}
```

When `ccOfflineAvailable = false` AND `requestFailed = true`, the code still calls `clearPersistedContentCardPropositions()`. The IAM path correctly passes `surfacesToRemove = []` on failure so nothing is evicted. The CC path has no equivalent guard. A non-recoverable Edge error while the feature flag is disabled (or absent — see CRITICAL-1) silently wipes the CC disk cache.

**Fix:**
```swift
if ccOfflineAvailable {
    ccWriteOK = cache.updateContentCardPropositions(..., removing: surfacesToRemove)
} else {
    if !requestFailed {
        clearPersistedContentCardPropositions()
    }
    ccWriteOK = true
}
```

---

### HIGH-2: `removePropositionFromQualifiedCards` does not prune `contentCardOriginByProposition` — dismissed card origins accumulate

**File:** `AEPMessaging/Sources/Messaging.swift:994–1002`

**Problem:**
```swift
private func removePropositionFromQualifiedCards(for activityId: String) {
    for (surface, propositions) in qualifiedContentCardsBySurface {
        if let matchedProposition = propositions.first(where: { $0.activityId == activityId }),
           let index = propositions.firstIndex(of: matchedProposition) {
            qualifiedContentCardsBySurface[surface]?.remove(at: index)
            break
        }
    }
    // contentCardOriginByProposition entry for matchedProposition.uniqueId is NOT removed
}
```

When a card is dismissed (via `eventHistoryOperation` consequence), its entry is removed from `qualifiedContentCardsBySurface` but the corresponding entry in `contentCardOriginByProposition` remains. `pruneContentCardOrigins()` is only called from `updateRulesEngines` (the network-response path) and from `hydrateContentCardPropositionsRulesEngine`. In a session with no network refreshes, dismissed cards' origin entries accumulate. `enrichWithContentCardOrigin` reads from this map on every `trackPropositions` call, so stale entries can cause incorrect `servedFromPersistentCache` tagging if a proposition ID is recycled.

**Fix:** Add a prune call after removal, or remove the specific entry inline:
```swift
private func removePropositionFromQualifiedCards(for activityId: String) {
    for (surface, propositions) in qualifiedContentCardsBySurface {
        if let matchedProposition = propositions.first(where: { $0.activityId == activityId }),
           let index = propositions.firstIndex(of: matchedProposition) {
            qualifiedContentCardsBySurface[surface]?.remove(at: index)
            var origins = contentCardOriginByProposition
            origins.removeValue(forKey: matchedProposition.uniqueId)
            contentCardOriginByProposition = origins
            break
        }
    }
}
```

---

### HIGH-3: `hydrateAllPersistedContentCards` reads the CC disk cache twice — once for the guard, once inside the call chain

**File:** `AEPMessaging/Sources/Messaging.swift:1452–1458` and `AEPMessaging/Sources/Messaging+State.swift:94–97`

**Problem:**
```swift
// Messaging.swift:1452
func hydrateAllPersistedContentCards() {
    guard let persisted = cache.contentCardPropositions, !persisted.isEmpty else { ... }
    // persisted is read from disk and decoded here
    hydrateContentCardRulesEngineFromDisk(for: Array(persisted.keys))
    // hydrateContentCardRulesEngineFromDisk → readContentCardPropositionsFromDisk:
    //   guard let cached = cache.contentCardPropositions, !cached.isEmpty  <-- reads disk AGAIN
}
```

`cache.contentCardPropositions` is a computed property that reads and JSON-decodes the file on every access. The boot path calls it twice: once in `hydrateAllPersistedContentCards` to enumerate keys, and again inside `readContentCardPropositionsFromDisk` to filter by surface. This is avoidable I/O on every cold start that has persisted data.

**Fix:** Pass the already-read `persisted` dictionary through to the hydration function rather than re-reading:
```swift
func hydrateAllPersistedContentCards() {
    guard let persisted = cache.contentCardPropositions, !persisted.isEmpty else { ... }
    hydrateContentCardPropositionsRulesEngine(for: Array(persisted.keys), from: persisted)
}
```

---

### HIGH-4: `readyForEvent` defines `ccOfflineKeyPresent` twice — inner variable shadows outer, both are debug-only dead code

**File:** `AEPMessaging/Sources/Messaging.swift:371–378`

**Problem:**
```swift
// outer — line 371 (outside if block)
let ccOfflineKeyPresent = configurationSharedState.value?[...CONTENT_CARD_OFFLINE_AVAILABLE] != nil
Log.debug(..., "readyForEvent — key ... \(ccOfflineKeyPresent ? "PRESENT" : "ABSENT") ...")
if !initialLoadComplete {
    // inner — line 376 (shadows outer)
    let ccOfflineKeyPresent = configurationSharedState.value?[...CONTENT_CARD_OFFLINE_AVAILABLE] != nil
    Log.debug(..., "initial code — key ... \(ccOfflineKeyPresent ? "PRESENT" : "ABSENT") ...")
```

Neither variable drives any logic — both are used only for `Log.debug` output. The inner variable re-computes the identical expression and shadows the outer. The repeated comment `// once we have valid configuration, fetch message definitions...` is a copy-paste of the function's existing top-level comment. This is leftover development scaffolding.

**Fix:** Remove both declarations and both log lines (they duplicate no-op information already visible through other means), or collapse to a single line outside the `if` block if the debug output is intentionally needed.

---

### HIGH-5: `clearContentCards` log message hardcodes "on identity reset" but the method is called from both identity reset and the public `clearPersistedPropositions()` API path

**File:** `AEPMessaging/Sources/Messaging.swift:703–711`

**Problem:**
```swift
private func clearContentCards() {
    qualifiedContentCardsBySurface = [:]
    contentCardRulesBySurface = [:]
    contentCardOriginByProposition = [:]
    inMemoryContentCardPropositions = [:]
    contentCardRulesEngine.launchRulesEngine.replaceRules(with: [])
    try? cache.remove(key: MessagingConstants.Caches.CONTENT_CARD_PROPOSITIONS)
    Log.debug(label: MessagingConstants.LOG_TAG, "Content card state cleared on identity reset.")
    // ^^^^ misleading when called from clearPersistedContentCardPropositions()
}
```

`clearContentCards()` is called from both `handleResetIdentitiesEvent` (via `clearPersistedContentCardPropositions`) and from `applyPropositionChangeFor` (CC-disabled path). The hardcoded "on identity reset" message is incorrect for non-reset callers and will confuse log readers debugging API-triggered clears.

**Fix:** Remove the log from `clearContentCards` and let each caller log its own context:
```swift
private func clearContentCards() {
    qualifiedContentCardsBySurface = [:]
    contentCardRulesBySurface = [:]
    contentCardOriginByProposition = [:]
    inMemoryContentCardPropositions = [:]
    contentCardRulesEngine.launchRulesEngine.replaceRules(with: [])
    try? cache.remove(key: MessagingConstants.Caches.CONTENT_CARD_PROPOSITIONS)
}

private func clearPersistedContentCardPropositions() {
    clearContentCards()
    Log.debug(label: MessagingConstants.LOG_TAG, "Content card propositions cleared (public API).")
}

// In handleResetIdentitiesEvent, before the call:
Log.debug(label: MessagingConstants.LOG_TAG, "Content card state cleared on identity reset.")
clearPersistedContentCardPropositions()
```

---

### MEDIUM-1: `cache.updateInboxPropositions` added in `Cache+Messaging.swift` but never called — inbox is never persisted to disk, contradicting `getInboxUI(usePersistedContentCards:)` documentation

**File:** `AEPMessaging/Sources/ClassExtensions/Cache+Messaging.swift:62–70`, `AEPMessaging/Sources/Messaging+State.swift:53–65`, `AEPMessaging/Sources/UI/Messaging+UIPublicAPI.swift`

**Problem:** `Cache+Messaging.swift` adds `updateInboxPropositions` and the `inboxPropositions` computed property. Neither is called from the network path. `Messaging+State.updateInboxPropositions` (the in-memory writer) does not call `cache.updateInboxPropositions`. `applyPropositionChangeFor` calls `updateInboxPropositions` (in-memory only). Searching the codebase confirms `cache.updateInboxPropositions` is never invoked.

The `Messaging+UIPublicAPI.swift` doc comment for `getInboxUI(for:usePersistedContentCards:...)` says: "When `true`, the inbox container-item and its content cards are read directly from the persisted disk cache." This is incorrect — inbox propositions are never written to disk, so the disk path in `retrieveMessages` falls back to the in-memory `inboxPropositionsBySurface` (which is empty at cold start before a network response).

Either the inbox persistence path is unfinished (in which case the added dead code and misleading documentation should be removed or deferred), or the `cache.updateInboxPropositions` call is missing from `applyPropositionChangeFor`.

---

### MEDIUM-2: `retrieveMessages` in-memory path filters on `surfaces` (unfiltered) while the disk path uses `requestedSurfaces` (validated)

**File:** `AEPMessaging/Sources/Messaging.swift:1530–1532, 1539`

**Problem:**
```swift
// Disk path uses requestedSurfaces (valid only):
let diskContentCards = qualifiedContentCardsBySurface.filter { requestedSurfaces.contains($0.key) }

// In-memory path uses surfaces (unfiltered):
let requestedContentCards = qualifiedContentCardsBySurface
    .filter { surfaces.contains($0.key) }   // 'surfaces', not 'requestedSurfaces'
    ...
let requestedInboxPropositions = inboxPropositionsBySurface.filter { surfaces.contains($0.key) }
```

Both paths should use the same `requestedSurfaces = surfaces.filter { $0.isValid }` slice. In practice, invalid surfaces won't exist as keys in the in-memory maps, so there is no functional bug today — but the inconsistency is a maintenance trap. A future caller passing an invalid surface could silently get an empty response from one path and correctly-empty from the other.

**Fix:** Replace `surfaces` with `requestedSurfaces` in the three in-memory path filter calls.

---

### LOW-1: `clearContentCards` does not clear `eventHistoryRulesBySurface` — stale CC event-history rules remain active in the main rules engine after a content card clear

**File:** `AEPMessaging/Sources/Messaging.swift:703–711`

**Problem:** `clearContentCards` resets `contentCardRulesBySurface`, `contentCardRulesEngine`, and the disk cache, but does not clear `eventHistoryRulesBySurface` or call `rebuildMainRulesEngine`. After a public `clearPersistedPropositions()` call (which invokes `clearContentCards`), event-history rules for dismissed/disqualified content cards remain loaded in the main `rulesEngine`. If these fire (e.g., the same user event that triggered a disqualify rule before the clear), `removePropositionFromQualifiedCards` finds nothing to remove — harmless but wasteful. These stale rules are cleared only when the next successful network response calls `processRulesForSchemaType(.eventHistoryOperation, ...)`.

**Fix:** Either call `rebuildMainRulesEngine()` after clearing `contentCardRulesBySurface` in `clearContentCards`, or explicitly clear `eventHistoryRulesBySurface` entries associated with content cards. The simpler approach is:
```swift
private func clearContentCards() {
    qualifiedContentCardsBySurface = [:]
    contentCardRulesBySurface = [:]
    contentCardOriginByProposition = [:]
    inMemoryContentCardPropositions = [:]
    contentCardRulesEngine.launchRulesEngine.replaceRules(with: [])
    try? cache.remove(key: MessagingConstants.Caches.CONTENT_CARD_PROPOSITIONS)
    // Stale event-history rules for cleared cards must not linger in the main engine.
    eventHistoryRulesBySurface = [:]
    rebuildMainRulesEngine()
}
```

---

## Review Inputs Used
- Template and commit list from `pr_reviews/mob25109/MOB-25109-offline-content-card-availability_template.md`
- Per-file diffs: `Messaging.swift`, `Cache+Messaging.swift`, `Event+Messaging.swift`, `Messaging+PublicAPI.swift`, `Messaging+UIPublicAPI.swift`
- Live source files: `AEPMessaging/Sources/Messaging.swift`, `Cache+Messaging.swift`, `ParsedPropositions.swift`, `Messaging+State.swift`

---

## Exploration Coverage
- Entry points checked: `readyForEvent`, `handleProcessEvent`, `applyPropositionChangeFor`, `endRequestFor`, `handleEdgeErrorResponse`, `retrieveMessages`, `hydrateAllPersistedContentCards`, `clearContentCards`
- Callers traced: `clearPersistedContentCardPropositions` ← `handleResetIdentitiesEvent` + `applyPropositionChangeFor`; `updateContentCardPropositions` ← `applyPropositionChangeFor` + `Messaging+State`; `pruneContentCardOrigins` ← `updateRulesEngines` + `hydrateContentCardPropositionsRulesEngine`
- Blast radius checked: `cache.updateInboxPropositions` — searched codebase, confirmed zero call sites
- Runtime flow followed: `updatePropositionsForSurfacesWithCompletionHandler` → `handleProcessEvent` → `fetchPropositions` → `handleProcessCompletedEvent` → `endRequestFor` → `applyPropositionChangeFor`

---

## Invariants & Type Boundaries
- **Key invariants reviewed:** `contentCardOriginByProposition` must stay a subset of `qualifiedContentCardsBySurface` proposition IDs; `inMemoryContentCardPropositions` must not contain disk-hydrated propositions; `nonRecoverableErrorEventIds` must be cleared in sync with `requestedSurfacesForEventId`
- **Illegal / ambiguous states found:** (1) Disk cache wiped when config key absent (CRITICAL-1). (2) Completion handler reports success on known-failed request (CRITICAL-2). (3) After `removePropositionFromQualifiedCards`, `contentCardOriginByProposition` has a stale entry not reflected in `qualifiedContentCardsBySurface` (HIGH-2).
- **Boundary validation / serialized contract risks:** `isContentCardOfflineAvailable` default mismatch means the disk persistence contract is broken for un-configured apps. `cache.updateInboxPropositions` added but never called — the disk persistence contract for inbox is documented but not implemented (MEDIUM-1).

---

## Summary
- Critical: 2
- High: 5
- Medium: 2
- Low: 1

**Recommendation:** BLOCK — CRITICAL-1 (default `false` clears disk on every network response for un-configured apps) and CRITICAL-2 (success reported on failed requests) are both correctness bugs that silently corrupt the feature's core invariants. CRITICAL-1 in particular would make the offline feature non-functional in any deployment that doesn't set the explicit config key.
