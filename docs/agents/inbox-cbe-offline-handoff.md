# Inbox + CBE Offline Persistence — Handoff Guide

**Branch:** `MOB-25109/offline-content-card-availability`  
**Last updated:** 2026-07-14  
**Scope:** Extended offline persistence to cover Code-Based Experiences (CBE) and Inbox container-items, on top of the already-shipped Content Card persistence. Also adds simulation machinery to validate partial-persistence scenarios.

Read `content-card-offline-implementation.md` first — this document assumes that context and only records the delta.

---

## 1. What was done in this session

### 1.1 Extended persistence to CBE and Inbox

`ParsedPropositions.swift` already routed `.feed`/`.contentCard` ruleset consequences to `contentCardPropositionsToPersist`. The same pattern was applied to the two remaining surface types:

| Schema | In-memory store | Disk store |
|--------|----------------|-----------|
| `.jsonContent`, `.htmlContent`, `.defaultContent` | `propositionsToCache` | `codeBasedPropositionsToPersist` (new) |
| `.inbox` (container-item) | `inboxPropositionsToCache` (new) | `inboxPropositionsToPersist` (new) |

**New constants** added in `MessagingConstants.swift`:
```swift
static let CODE_BASED_PROPOSITIONS = "codeBasedPropositions"
static let INBOX_PROPOSITIONS = "inboxPropositions"
```

**New cache getter/setter pairs** added in `Cache+Messaging.swift`:
```swift
var codeBasedPropositions: [Surface: [Proposition]]?       // reads CODE_BASED_PROPOSITIONS key
func updateCodeBasedPropositions(_ propositions:...) -> Bool

var inboxPropositions: [Surface: [Proposition]]?           // reads INBOX_PROPOSITIONS key
func updateInboxPropositions(_ propositions:...) -> Bool
```

Both delegate to the shared `updatePropositionsByKey` helper (same as CC and IAM).

### 1.2 Write path — `applyPropositionChangeFor` in `Messaging.swift`

Four disk writes now happen on every successful update:
```swift
let iamWriteOK  = cache.updatePropositions(parsedPropositions.propositionsToPersist, removing: surfacesToRemove)
let ccWriteOK   = cache.updateContentCardPropositions(parsedPropositions.contentCardPropositionsToPersist, removing: surfacesToRemove)
let cbeWriteOK  = cache.updateCodeBasedPropositions(parsedPropositions.codeBasedPropositionsToPersist, removing: surfacesToRemove)
let inboxWriteOK = cache.updateInboxPropositions(parsedPropositions.inboxPropositionsToPersist, removing: surfacesToRemove)
if !iamWriteOK || !ccWriteOK || !cbeWriteOK || !inboxWriteOK { Log.warning(...) }
```

The failed-fetch guard in `endRequestFor` already protects all four writes — unchanged.

### 1.3 Read path — `retrieveMessages` in `Messaging.swift`

Three hydration blocks (in addition to the existing IAM `loadCachedPropositions`):
```swift
// CC
let surfacesWithoutCCInMemory = requestedSurfaces.filter { qualifiedContentCardsBySurface[$0] == nil }
if !surfacesWithoutCCInMemory.isEmpty { hydrateContentCardRulesEngineFromDisk(for: surfacesWithoutCCInMemory) }

// CBE
let surfacesWithoutCBEInMemory = requestedSurfaces.filter { inMemoryPropositions[$0] == nil }
if !surfacesWithoutCBEInMemory.isEmpty { hydrateCodeBasedPropositionsFromDisk(for: surfacesWithoutCBEInMemory) }

// Inbox
let surfacesWithoutInboxInMemory = requestedSurfaces.filter { inboxPropositionsBySurface[$0] == nil }
if !surfacesWithoutInboxInMemory.isEmpty { hydrateInboxPropositionsFromDisk(for: surfacesWithoutInboxInMemory) }
```

Each `hydrateXFromDisk` follows the same pattern as `hydrateContentCardRulesEngineFromDisk`: read cache → decode → update in-memory map / rules engine.

### 1.4 `offlineAvailable` flag added to CC and CBE

CBE already had the gate. Content cards were unconditionally persisted before — now gated on `proposition.offlineAvailable`:
```swift
case .feed, .contentCard:
    propositionInfoToCache[consequence.id] = PropositionInfo.fromProposition(proposition)
    if proposition.offlineAvailable {
        contentCardPropositionsToPersist.add(proposition, forKey: surface)
    }
    mergeRules(parsedRule, for: surface, with: .contentCard)
```

`offlineAvailable` is computed on `Proposition` from `scopeDetails.characteristics.mobileParameters.offline` and defaults to `true`, so existing server payloads without the flag persist by default.

---

## 2. AJO Inbox surface model (important — do not assume)

This was clarified via wiki research and is non-obvious:

- AJO authors assign content cards a **primary surface** (`s1`, `s2`) AND an **inbox surface** (`i1`) via `inboxSurfaces`.
- IDS (Interaction Decision Service) uses the `inboxSurfaces` field to **remap the response scope** to `i1` when returning to the SDK.
- The SDK **only ever sees scope `i1`** — it never sees `s1`/`s2`.
- `getInboxUI(for: i1)` issues a single `updatePropositionsForSurfaces([i1])` request. Edge returns the inbox container-item AND all linked content cards, all scoped to `i1`.
- `ParsedPropositions` routes:
  - Proposition with `.inbox` first item → `inboxPropositionsToCache` / `inboxPropositionsToPersist`
  - Propositions with `.contentCard`/`.feed` first item → `contentCardPropositionsToPersist`

**Bottom line:** You do NOT need separate surface requests for cards and inbox. One call with the inbox surface returns everything.

---

## 3. InboxUI.processInboxPropositions dependency

`InboxUI.processInboxPropositions` requires **both**:
1. A proposition whose first item schema is `.inbox` (the container-item / `InboxSchemaData`)
2. Content card propositions (the individual cards)

If the container-item is missing from the propositions returned by `getPropositionsForSurfaces`, `extractInboxSchemaData` returns `nil` → `handleError(InboxError.inboxSchemaDataNotFound)` → `.error` state shown — regardless of whether cards are in cache.

This is the core behavioral fact the simulation below is designed to validate.

---

## 4. Current simulation in effect (IMPORTANT — revert when done)

### 4.1 What the simulation does

To validate the claim in §3, we forced the inbox container-item to never persist to disk while leaving content card persistence active. Two files are modified:

**`AEPMessaging/Sources/ParsedPropositions.swift` — line ~124:**
```swift
case .inbox:
    inboxPropositionsToCache.add(proposition, forKey: surface)
    // SIMULATION: inbox offlineAvailable forced false — container-item never written to disk.
    // Expected cold-start result: error screen even though content cards ARE cached.
    // if proposition.offlineAvailable {
    //     inboxPropositionsToPersist.add(proposition, forKey: surface)
    // }
```

**`AEPMessaging/Tests/UnitTests/ParsedPropositionsTests.swift` — lines ~482 and ~541:**
```swift
// SIMULATION: inbox offlineAvailable forced false — expect 0
// XCTAssertEqual(1, result.inboxPropositionsToPersist.count, ...)
XCTAssertEqual(0, result.inboxPropositionsToPersist.count, "simulation: inbox must not persist to disk")
```

### 4.2 Expected behavior when testing

| Scenario | Expected |
|----------|----------|
| Online first launch | Inbox loads normally; cards written to disk; container-item NOT written to disk |
| Kill app → go offline → cold start → open Inbox | Error screen ("An error occurred") even though card data is in cache |
| Online relaunch | Normal inbox load again (container-item fetched fresh from network) |

### 4.3 Revert checklist (do this after simulation validated)

1. `ParsedPropositions.swift` — uncomment the `if proposition.offlineAvailable { inboxPropositionsToPersist.add(...) }` block; remove the simulation comment lines.
2. `ParsedPropositionsTests.swift` — uncomment the `count == 1` assertions; remove the `count == 0` simulation assertions.
3. Run `make unit-test` to confirm green.

---

## 5. Demo app

**`TestApps/MessagingDemoAppSwiftUI/Constants.swift`:**
```swift
static let INBOX = "shwetansh_inbox_mda"
```

This is the inbox surface used by the demo app's InboxUI tab.

**`TestApps/MessagingDemoAppSwiftUI/AppPages/CardsView.swift`** — has Offline / Log Props buttons for manually testing content card offline flows (not inbox-specific).

---

## 6. MockCache changes (test infrastructure)

`AEPMessaging/Tests/TestHelpers/MockCache.swift` has a new `internalStorage: [String: CacheEntry]` dictionary so multi-step tests work correctly:

```swift
private var internalStorage: [String: CacheEntry] = [:]

override func get(key: String) -> CacheEntry? {
    getCalled = true
    getParamKey = key
    return internalStorage[key] ?? getReturnValue  // reflects prior set() calls
}

override func set(key: String, entry: CacheEntry) throws {
    // ...
    internalStorage[key] = entry  // persists for subsequent get() calls
}

override func remove(key: String) throws {
    // ...
    internalStorage.removeValue(forKey: key)
}
```

**Why this was needed:** Tests that write in one code path and read in another (e.g., IAMPropositionsNotReturnedInSubsequentResponse) need the mock to behave like a real cache across multiple operations. Without `internalStorage`, `get()` always returned `getReturnValue` regardless of what was `set()`.

---

## 7. Bug fixed: spurious `remove` calls in `updatePropositionsByKey`

**`Cache+Messaging.swift` — `updatePropositionsByKey`:**

Before the fix, `try? remove(key:)` was called whenever the merged result was empty — even when nothing was ever in cache for that key (CBE and Inbox are new keys, no prior data). This caused `mockCache.removeCalled == true` unexpectedly, failing two tests.

**Fix:**
```swift
guard !updatedPropositions.isEmpty else {
    if !existingPropositions.isEmpty {
        try? remove(key: key)  // only remove if something was actually there
    }
    return true
}
```

---

## 8. New tests added

**`Cache+MessagingTests.swift`** — 6 new tests:
- `testCodeBasedPropositionsHappy` — getter returns decoded propositions from cache
- `testCodeBasedPropositionsNoneInCache` — getter returns nil when key absent
- `testUpdateCodeBasedPropositionsHappy` — setter writes to correct key, not IAM or CC key
- `testInboxPropositionsHappy` — same for inbox getter
- `testInboxPropositionsNoneInCache` — same for inbox nil case
- `testUpdateInboxPropositionsHappy` — same for inbox setter with key isolation check

**`Messaging+UIPublicApiTest.swift`** (new file) — covers `getContentCardsUI` forwarding `usePersistedContentCards`.

---

## 9. Open work (post-simulation)

| Priority | Task |
|----------|------|
| P0 | After simulation validated: revert simulation (§4.3) and decide on final Inbox persistence behavior |
| P0 | Option B: evict dismissed CC from memory + disk on `track(.dismiss)` |
| P0 | Functional E2E offline tests on device |
| P1 | Public `clearCachedContentCardPropositions()` API |
| P1 | Skip persist for empty `items[]` shells (PLATIR-64717) |
| P2 | InboxUI.performRefresh — consider not chaining getPropositions inside updatePropositions completion; they are independent (network success ≠ proposition availability) |

### P2 detail — InboxUI refresh coupling

Current `performRefresh`:
```swift
Messaging.updatePropositionsForSurfaces([surface]) { [weak self] _ in
    Messaging.getPropositionsForSurfaces([self.surface]) { ... }
}
```

`getPropositionsForSurfaces` is called inside the `updatePropositions` completion. If offline, Edge fires completion quickly with `false` → then get runs → no data in memory → error shown. This is correct behavior for the current design (no Inbox disk persistence yet). Once Inbox persistence is enabled, the get should hydrate from disk even on offline update. The chained pattern will still work correctly once disk hydration is active.

---

## 10. Key file locations

| File | Role |
|------|------|
| `AEPMessaging/Sources/ParsedPropositions.swift` | Schema routing to persist buckets; simulation comment here |
| `AEPMessaging/Sources/ClassExtensions/Cache+Messaging.swift` | All four cache getter/setter pairs; `updatePropositionsByKey` helper |
| `AEPMessaging/Sources/Messaging.swift` | All hydration methods; `applyPropositionChangeFor` write path; `retrieveMessages` |
| `AEPMessaging/Sources/MessagingConstants.swift` | Cache key constants for all four store types |
| `AEPMessaging/Tests/TestHelpers/MockCache.swift` | `internalStorage`; `setCalls`/`removeCalls` arrays |
| `AEPMessaging/Tests/UnitTests/Cache+MessagingTests.swift` | CBE + Inbox cache tests (new); simulation assertions here |
| `AEPMessaging/Tests/UnitTests/ParsedPropositionsTests.swift` | Simulation assertions here (revert with §4.3) |
| `TestApps/MessagingDemoAppSwiftUI/Constants.swift` | `INBOX = "shwetansh_inbox_mda"` |
