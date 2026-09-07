# Code Validation: MOB-25109/offline-content-card-availability

## Summary

The offline content card persistence feature has a critical commented-out write that makes the entire disk cache non-functional, plus a `clearContentCards` incomplete cleanup that leaves stale event-history rules in the shared rules engine and a dismiss path that never evicts from disk.

---

## Code Issues

### CRITICAL: `contentCardPropositionsToPersist` is never populated — disk persistence is a no-op

**File:** `AEPMessaging/Sources/ParsedPropositions.swift:92-94`

**Problem:**
```swift
case .feed, .contentCard:
    propositionInfoToCache[consequence.id] = PropositionInfo.fromProposition(proposition)
    if contentCardOfflineAvailable {
      //  contentCardPropositionsToPersist.add(proposition, forKey: surface)
    }
    mergeRules(parsedRule, for: surface, with: .contentCard)
```

The line that populates `contentCardPropositionsToPersist` is commented out. `contentCardPropositionsToPersist` is therefore always `[:]` on every parse. In `applyPropositionChangeFor` (Messaging.swift:1300):

```swift
ccWriteOK = cache.updateContentCardPropositions(parsedPropositions.contentCardPropositionsToPersist, removing: surfacesToRemove)
```

`updateContentCardPropositions` receives `[:]` as `newPropositions`. Inside `updatePropositionsByKey`, this merges the empty new set with whatever is already on disk and writes that back — no current-session propositions are ever added to disk. On a fresh install the disk is always empty and stays empty. On a returning session, only old disk data (minus removed surfaces) gets written back.

The entire `messaging.contentCardOfflineAvailable = true` code path is silently inert: `hydrateAllPersistedContentCards` finds nothing on a fresh install, and any existing disk data is never updated.

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

### HIGH: `clearContentCards` leaves stale event-history rules in the shared `rulesEngine`

**File:** `AEPMessaging/Sources/Messaging.swift:682-689`

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
```

`clearContentCards` clears `contentCardRulesBySurface` and replaces the CC engine's rules with `[]`. But it does not:
1. Clear `eventHistoryRulesBySurface`
2. Call `rebuildMainRulesEngine()`

`rebuildMainRulesEngine` (line 1393) combines `inAppRulesBySurface` and `eventHistoryRulesBySurface` into the shared `rulesEngine`. Without calling it here, the shared `rulesEngine` still contains the stale event-history operation rules (dismiss/disqualify rules) for cleared content cards. These rules evaluate on every wildcard event; if their conditions match ambient events, they dispatch spurious Event History writes for cards that no longer exist.

This affects both `handleResetIdentitiesEvent` (which calls `clearCachedContentCardPropositions` → `clearContentCards`) and the public `clearCachedPropositions()` API.

**Fix:**
```swift
private func clearContentCards() {
    qualifiedContentCardsBySurface = [:]
    contentCardRulesBySurface = [:]
    eventHistoryRulesBySurface = [:]        // ADD: clear stale dismiss rules
    networkRefreshedSurfaces = []
    contentCardRulesEngine.launchRulesEngine.replaceRules(with: [])
    rebuildMainRulesEngine()                // ADD: remove them from the shared engine
    try? cache.remove(key: MessagingConstants.Caches.CONTENT_CARD_PROPOSITIONS)
    Log.debug(label: MessagingConstants.LOG_TAG, "Content card state cleared.")
}
```

Note: clearing `eventHistoryRulesBySurface` is safe here because these rules are tied to the content card propositions being cleared. IAM rules are in `inAppRulesBySurface` (separate dictionary) and are untouched.

---

### HIGH: `removePropositionFromQualifiedCards` only clears in-memory — dismissed cards reappear on cold start

**File:** `AEPMessaging/Sources/Messaging.swift:982-989`

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
}
```

This removes the dismissed card from `qualifiedContentCardsBySurface` (in-memory) but does not update the disk cache (`contentCardPropositions`). On the next cold start with `messaging.contentCardOfflineAvailable = true`, `hydrateAllPersistedContentCards` re-qualifies the dismissed card from disk. The user sees a card they dismissed reappear after relaunching the app.

This is noted as "P0 — Option B dismiss eviction" in AGENTS.md (open work). The current code sets incorrect expectations: the in-memory dismissal silently fails to be durable. A log line should at minimum document this gap so on-call can diagnose user reports.

**Minimum fix (logging):**
```swift
private func removePropositionFromQualifiedCards(for activityId: String) {
    for (surface, propositions) in qualifiedContentCardsBySurface {
        if let matchedProposition = propositions.first(where: { $0.activityId == activityId }),
           let index = propositions.firstIndex(of: matchedProposition) {
            qualifiedContentCardsBySurface[surface]?.remove(at: index)
            // NOTE: disk cache is not updated here — dismissed card will re-qualify from
            // disk on the next cold start. Tracked as P0 "Option B dismiss eviction."
            Log.debug(label: MessagingConstants.LOG_TAG,
                      "Removed dismissed card '\(activityId)' from in-memory state. Disk eviction deferred (P0 open work).")
            break
        }
    }
}
```

---

### MEDIUM: Boot unconditionally hydrates disk regardless of the offline availability flag — brief window of incorrect state

**File:** `AEPMessaging/Sources/Messaging.swift:366-373`

**Problem:**
```swift
if !initialLoadComplete {
    initialLoadComplete = true
    Log.debug(label: MessagingConstants.LOG_TAG, "Boot — unconditionally hydrating content cards from disk.")
    hydrateAllPersistedContentCards()
    fetchPropositions(event)
}
```

`hydrateAllPersistedContentCards` runs before `isContentCardOfflineAvailable` is checked. If the app has `messaging.contentCardOfflineAvailable = false`, the boot hydration still loads disk cards into `qualifiedContentCardsBySurface`. The flag is checked later in `retrieveMessages`:

```swift
if !isContentCardOfflineAvailable(), cache.contentCardPropositions != nil {
    clearCachedContentCardPropositions()
}
```

If `getContentCardsUI` or `getPropositionsForSurfaces` is called before any `retrieveMessages` runs (possible on first app open if the UI is fast), the call will return disk-hydrated cards to an app that explicitly opted out of offline caching. The comment explains this is due to a config race, but the consequence is an observable invariant violation.

The `retrieveMessages` guard on the offline flag is the intended cleanup, but it only fires on the read path. If the caller uses `updatePropositionsForSurfaces` with a fast response (no network latency), `applyPropositionChangeFor` is the first path that clears stale disk data — not `retrieveMessages`. The existing guard in `retrieveMessages` only fires on GET calls, not on the UPDATE → apply path when the flag is false:

```swift
// applyPropositionChangeFor (line 1302):
if !requestFailed {
    clearCachedContentCardPropositions()
}
```

This does clear correctly on the UPDATE path. But the window between boot hydration and either a GET or UPDATE completing is a correctness gap for apps with offline caching disabled.

**Fix:** Log a diagnostic message and document the limitation explicitly:
```swift
if !initialLoadComplete {
    initialLoadComplete = true
    // Hydrate unconditionally — isContentCardOfflineAvailable() races with config settle at boot.
    // If the flag is false, the stale data is evicted on the first GET (retrieveMessages) or
    // successful UPDATE (applyPropositionChangeFor). See: MOB-25109 boot-window note.
    hydrateAllPersistedContentCards()
    fetchPropositions(event)
}
```

The deeper fix (Option B from AGENTS.md deferred work) would gate the boot hydration, but that requires resolving the config race.

---

### MEDIUM: `endRequestFor` computes `requestFailed` before `applyPropositionChangeFor`, which re-computes it independently

**File:** `AEPMessaging/Sources/Messaging.swift:1257-1265`

**Problem:**
```swift
private func endRequestFor(eventId: String) {
    let requestFailed = nonRecoverableErrorEventIds.contains(eventId)   // Read #1
    applyPropositionChangeFor(eventId: eventId)                          // Read #2 inside
    requestedSurfacesForEventId.removeValue(forKey: eventId)
    nonRecoverableErrorEventIds.remove(eventId)
    inProgressPropositions.removeAll()
    if let handler = completionHandlerFor(edgeRequestEventId: UUID(uuidString: eventId)) {
        handler.handle?(!requestFailed)
    }
}
```

`applyPropositionChangeFor` (line 1282) does its own `nonRecoverableErrorEventIds.contains(eventId)`. These are two independent `queue.sync` reads of the same set at two different points in the call stack. Currently they agree because the removal is scheduled `queue.async` after both reads, but this is a latent ordering assumption. If `applyPropositionChangeFor` is ever called independently (e.g., in a future refactor), the two reads diverge.

**Fix:** Pass `requestFailed` explicitly:
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
    // use passed-in requestFailed rather than re-reading nonRecoverableErrorEventIds
    ...
}
```

---

### LOW: `clearCachedContentCardPropositions` is a trivial wrapper with a duplicate log message

**File:** `AEPMessaging/Sources/Messaging.swift:693-696`

**Problem:**
```swift
private func clearContentCards() {
    // ...
    Log.debug(label: MessagingConstants.LOG_TAG, "Content card state cleared.")
}

private func clearCachedContentCardPropositions() {
    clearContentCards()
    Log.debug(label: MessagingConstants.LOG_TAG, "Persisted content card propositions cleared.")
}
```

`clearCachedContentCardPropositions` adds nothing beyond `clearContentCards` except a second consecutive log message that is nearly identical. Log analysis shows two messages for one logical operation. The wrapper adds naming ambiguity — callers must look up which one to call.

**Fix:** Collapse into one function, or remove the second log:
```swift
private func clearContentCards() {
    qualifiedContentCardsBySurface = [:]
    contentCardRulesBySurface = [:]
    networkRefreshedSurfaces = []
    contentCardRulesEngine.launchRulesEngine.replaceRules(with: [])
    try? cache.remove(key: MessagingConstants.Caches.CONTENT_CARD_PROPOSITIONS)
    Log.debug(label: MessagingConstants.LOG_TAG, "Content card state and persisted cache cleared.")
}
```

And replace all `clearCachedContentCardPropositions()` call sites with `clearContentCards()`.

---

### LOW: `parentID?.uuidString as? String` — redundant cast always succeeds

**File:** `AEPMessaging/Sources/ClassExtensions/Event+Messaging.swift:59`

**Problem:**
```swift
var requestEventId: String? {
    parentID?.uuidString as? String ?? data?[MessagingConstants.Event.Data.Key.REQUEST_EVENT_ID] as? String
}
```

`parentID` is `UUID?`. `parentID?.uuidString` is `String?` (Swift optional chaining). Casting `String?` to `String` via `as?` always succeeds when non-nil (String is-a String), so the `as? String` is redundant and can mislead readers into thinking a type narrowing is happening. If `parentID` is nil, both expressions produce nil identically.

**Fix:**
```swift
var requestEventId: String? {
    parentID?.uuidString ?? data?[MessagingConstants.Event.Data.Key.REQUEST_EVENT_ID] as? String
}
```

---

## Review Inputs Used
- `MOB-25109-offline-content-card-availability_diff/AEPMessaging/Sources/Messaging.swift.diff` — primary diff, network path and state management
- `MOB-25109-offline-content-card-availability_diff/AEPMessaging/Sources/Messaging+PublicAPI.swift.diff` — public API additions
- `MOB-25109-offline-content-card-availability_diff/AEPMessaging/Sources/ParsedPropositions.swift.diff` — disk serialization path
- `MOB-25109-offline-content-card-availability_diff/AEPMessaging/Sources/ClassExtensions/Cache+Messaging.swift.diff` — cache read/write helpers
- `MOB-25109-offline-content-card-availability_diff/AEPMessaging/Sources/ClassExtensions/Event+Messaging.swift.diff` — event type predicates
- Full source: `AEPMessaging/Sources/Messaging.swift`, `ParsedPropositions.swift`, `Cache+Messaging.swift`, `Event+Messaging.swift`, `MessagingConstants.swift`, `Messaging+State.swift`

---

## Exploration Coverage
- Entry points checked: `readyForEvent` (boot hydration), `handleProcessEvent` (clear/get/update/track paths), `handleEdgeErrorResponse`, `handleRulesResponse` (dismiss path), `retrieveMessages`, `applyPropositionChangeFor`, `endRequestFor`
- Callers/callees traced: `clearContentCards` → callers (resetIdentities, applyPropositionChangeFor, clearCachedContentCardPropositions); `removeOrReplaceContentCards` → `updateRulesEngines` → `applyPropositionChangeFor`; `enrichWithContentCardOrigin` → `handleProcessEvent` track path
- Blast radius checked: `eventHistoryRulesBySurface` usages in `rebuildMainRulesEngine`, `processRulesForSchemaType`, `hydrateContentCardPropositionsRulesEngine`; `networkRefreshedSurfaces` lifecycle across all write sites
- Runtime/data flow followed: network response → `handleEdgePersonalizationNotification` → `handleProcessCompletedEvent` → `endRequestFor` → `applyPropositionChangeFor` → `cache.updateContentCardPropositions` (broken) → `updateRulesEngines` → `removeOrReplaceContentCards` (networkRefreshedSurfaces maintenance)

---

## Invariants & Type Boundaries

**Key invariants reviewed:**
- `networkRefreshedSurfaces` is insert-only on successful network refresh (in `removeOrReplaceContentCards`), cleared only in `clearContentCards`. Disk hydration must NOT insert. Verified: `hydrateContentCardPropositionsRulesEngine` does not touch `networkRefreshedSurfaces`. Invariant holds.
- `contentCardPropositions` disk key is `"contentCardPropositions"` (separate from IAM `"propositions"`). Verified in `MessagingConstants.Caches`. Invariant holds.
- `requestedSurfacesForEventId` removal in `endRequestFor` is the only place that unblocks `eventsQueue` (via the queue handler check). Removal always happens. Invariant holds.

**Illegal / ambiguous states found:**
- After `clearContentCards`, `eventHistoryRulesBySurface` retains old rules and the shared `rulesEngine` retains stale event-history rules. State is internally inconsistent: CC engine is empty but the main engine still has CC-related dismiss rules.
- After `removePropositionFromQualifiedCards`, disk and in-memory state diverge for dismissed cards. `networkRefreshedSurfaces` is not updated either — a dismissed card's surface remains in `networkRefreshedSurfaces` if it was network-refreshed, meaning future display events for that same surface (from disk re-qualification) will incorrectly report `servedFromPersistentCache = false`.
- `contentCardPropositionsToPersist` is structurally declared and wired into the disk write path but is never populated — the property's existence creates a false impression that the feature works.

**Boundary validation / serialized contract risks:**
- `updatePropositionsByKey` receives `existing` as a parameter (passed as `contentCardPropositions` from the call site) and uses it as the base for the merge. This means each call to `updateContentCardPropositions` performs one disk read at the call site. If called in a tight loop, this multiplies disk reads. Currently called only once per `applyPropositionChangeFor`, so acceptable.
- `propositionPayload` in `retrieveMessages` uses `compactMap { $0.asDictionary() }`. If `asDictionary()` returns nil for any proposition (e.g., encoding failure), that proposition is silently dropped from the response. No warning is logged. Callers cannot distinguish "no propositions" from "propositions that failed to serialize."

---

## Summary

- Critical: 1 (`contentCardPropositionsToPersist` never populated — offline CC feature is entirely non-functional)
- High: 2 (`clearContentCards` misses `eventHistoryRulesBySurface` + `rebuildMainRulesEngine`; dismiss has no disk eviction)
- Medium: 2 (boot unconditional hydration window; double-read of `nonRecoverableErrorEventIds`)
- Low: 2 (`clearCachedContentCardPropositions` trivial wrapper with duplicate log; redundant `as? String` cast)

**Recommendation:** BLOCK — the critical finding renders the primary feature of this PR (offline CC persistence) non-functional. The commented-out code at `ParsedPropositions.swift:93` must be restored before merging.
