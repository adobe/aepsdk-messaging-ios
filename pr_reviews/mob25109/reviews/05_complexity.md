# Complexity Analysis: MOB-25109/offline-content-card-availability

### Files Reviewed
- **Deeply reviewed:**
  - `AEPMessaging/Sources/Messaging.swift`
  - `AEPMessaging/Sources/Messaging+State.swift` (diff only)
  - `TestApps/MessagingDemoAppSwiftUI/AppPages/CardsView.swift` (diff only)
- **Lightly reviewed:**
  - `AEPMessaging/Sources/MessagingConstants.swift` (grep only)
- **Not reviewed:**
  - `AEPMessaging/Sources/ParsedPropositions.swift`, `Cache+Messaging.swift`, `Event+Messaging.swift`, test files

### Findings

| # | Severity | Title |
|---|----------|-------|
| 1 | HIGH | `inMemoryContentCardPropositions` is dead state — written but never read |
| 2 | HIGH | `isNetworkAvailable()` stub ships dead guard branches in two production paths |
| 3 | HIGH | `endRequestFor` KNOWN ISSUE: completion handler reports success on non-recoverable Edge error |
| 4 | HIGH | `isContentCardOfflineAvailable` docstring says default `true`, code defaults `false` |
| 5 | MEDIUM | Duplicate `ccOfflineKeyPresent` block copied outside its `if !initialLoadComplete` scope in `readyForEvent` |
| 6 | MEDIUM | Commented-out optimization block left in production code |
| 7 | MEDIUM | `clearPersistedContentCardPropositions` is a one-liner wrapper around `clearContentCards` with no distinct semantics |
| 8 | MEDIUM | `isContentCardOfflineAvailable` called at two dispatch sites purely for its log side-effect |
| 9 | LOW | Assurance event in `retrieveMessages` disk path uses raw string-literal keys |
| 10 | LOW | `completeUpdatePropositionsRequest` is a single-call thin wrapper |
| 11 | LOW | `EdgeNetworkSimulator` in demo app is over-engineered for demo use |

### Unreviewed Risk Areas
- Thread safety of the new `nonRecoverableErrorEventIds` `Set` with async set/sync get: consistent with other properties on the same `queue` — appears safe but not deeply verified.
- `hydrateContentCardPropositionsRulesEngine` writing directly to `qualifiedContentCardsBySurface` without going through `addOrReplaceContentCards` (intentional per comment, but the implication that this skips `.trigger` events is not verified against the rules engine path).

---

## Review Inputs Used
- `MOB-25109-offline-content-card-availability_template.md` — commit list and file inventory
- Per-file diffs: `Messaging.swift.diff`, `Messaging+State.swift.diff`, `CardsView.swift.diff`
- Live source: `AEPMessaging/Sources/Messaging.swift`

## Exploration Coverage
- Entry points checked: `readyForEvent`, `handleProcessEvent`, `applyPropositionChangeFor`, `endRequestFor`, `retrieveMessages`, `handleEdgeErrorResponse`
- Callers/callees traced: `clearContentCards` → `clearPersistedContentCardPropositions`, `updateContentCardPropositions` → origin map, `hydrateAllPersistedContentCards` → `hydrateContentCardRulesEngineFromDisk` → `readContentCardPropositionsFromDisk` + `hydrateContentCardPropositionsRulesEngine`
- Blast radius checked: `isNetworkAvailable()` guard in `fetchPropositions` and `handleProcessEvent`; `inMemoryContentCardPropositions` write in `updateContentCardPropositions` and clear in `clearContentCards`
- Runtime/data flow followed: disk path in `retrieveMessages`; origin-table lifecycle from write → prune → filter in in-memory path

## Summary

The `CardOrigin`/origin-table approach is reasonable and appropriately scoped. The main complexity burden comes from four shipping defects — a dead variable, an always-true network stub with dead guards, a completion handler that misreports success on failure, and a docstring that contradicts its implementation — plus two development artifacts that were not cleaned before review (duplicate log block, commented-out code).

---

## Research Findings

**Problem researched:** Per-proposition provenance tracking for offline vs. network content cards in an SDK that cannot modify the public `Proposition` type.

**Searches performed:**
- "offline-first mobile SDK cache provenance pattern" → Industry pattern: maintain a side-table keyed by item ID mapping to source enum. Used by Apollo Client (`.cache` / `.network` fetch policy), SWR/React Query (stale-while-revalidate with `dataUpdatedAt`), and Firebase offline persistence.
- "two-collection vs side-table for online/offline content" → Two-collection approach (separate `networkCards` and `diskCards` dicts) avoids the pruning problem but doubles the surface-management bookkeeping when a network response must evict disk entries.
- "iOS SDK offline caching patterns" → Standard approach in AEP Core-adjacent SDKs: write to a named `Cache`, hydrate at boot, tag in-memory entries with provenance.

**Industry standard approach:** Side-table keyed by item ID → provenance enum is the standard pattern when the item type is sealed (cannot add a `source` property). The alternative — wrapping `Proposition` in a `TaggedProposition<Source>` struct — is cleaner but requires changing public API surface.

**Simpler alternatives identified:**
1. Two separate dicts (`networkQualifiedCards`, `diskQualifiedCards`) — eliminates the origin table and `pruneContentCardOrigins` call, but requires merging at read time and managing eviction in both.
2. Add `origin: CardOrigin?` directly to `qualifiedContentCardsBySurface` values by using a wrapper tuple `(proposition: Proposition, origin: CardOrigin?)` — eliminates the side-table but changes the type of `qualifiedContentCardsBySurface`.
3. Keep current approach, but collapse `inMemoryContentCardPropositions` (dead state) to eliminate the misleading parallel data structure.

**Assessment:** The origin-table approach is standard practice and appropriate given the sealed `Proposition` type. The complexity concerns are in the implementation details (dead state, stubs, documentation drift), not the core design.

---

## Complexity Issues

### HIGH: `inMemoryContentCardPropositions` is dead state — written, never read

**Issue:** `inMemoryContentCardPropositions` is declared with `internal` visibility, written in `updateContentCardPropositions` (every live network response) and cleared in `clearContentCards` (identity reset), but never read in any live code path. The docstring claims "Engine hydration reads from here rather than re-reading disk on every call" — but `hydrateContentCardRulesEngineFromDisk` calls `readContentCardPropositionsFromDisk` which reads `cache.contentCardPropositions` from disk directly. `retrieveMessages` reads `qualifiedContentCardsBySurface`, not `inMemoryContentCardPropositions`. The only reference to this variable outside of writes and clears is a commented-out optimization guard.

**Evidence:**
- File: `AEPMessaging/Sources/Messaging.swift:158-162` — property declaration
- File: `AEPMessaging/Sources/Messaging+State.swift` diff lines 13-18 — writes in `updateContentCardPropositions`
- File: `AEPMessaging/Sources/Messaging.swift:707` — cleared in `clearContentCards`
- File: `AEPMessaging/Sources/Messaging.swift:1286` — only other reference: `// if !inMemoryContentCardPropositions.isEmpty {` (commented out)
- `hydrateContentCardRulesEngineFromDisk` at line ~1437: "Disk data is never written to `inMemoryContentCardPropositions`" — doc confirms disk path bypasses this variable; but the network write path also has no reader

**Why It's a Problem:** The variable misleads future maintainers into believing there is a populated in-memory CC proposition cache parallel to `inMemoryPropositions` (IAM/CBE). The `internal` access level exists specifically to let `Messaging+State` write to it — widening the access modifier for a write that has no consumer. The docstring is false.

**Simpler Alternative:** Remove `inMemoryContentCardPropositions` entirely. The origin-tag write in `updateContentCardPropositions` is the actual useful work. If the optimization (skip disk clear when memory is empty) is needed, track a simple `Bool hasNetworkContentCards` flag instead.

**Confidence:** 0.95

**Caveats:** I did not read every test file; a test could be reading this property to assert write behavior. But test-only reads do not justify the misleading docstring or `internal` access.

**Challenge:** The variable could be a scaffolding for a planned future optimization (memory-first-disk-fallback) that was not yet implemented. If so, the docstring should say "reserved for future use" rather than claiming current behavior.

---

### HIGH: `isNetworkAvailable()` stub ships dead guard branches in two production paths

**Issue:** `isNetworkAvailable()` always returns `true`. It is used as a guard in two production paths: `handleProcessEvent` (line 416) and `fetchPropositions` (line 1038). Both `guard isNetworkAvailable() else { ... }` branches are permanently unreachable. The TODO comment says "wire up to a real reachability signal once available."

**Evidence:**
- File: `AEPMessaging/Sources/Messaging.swift:1004-1008` — stub
- File: `AEPMessaging/Sources/Messaging.swift:416-420` — unreachable guard in `handleProcessEvent`
- File: `AEPMessaging/Sources/Messaging.swift:1038-1042` — unreachable guard in `fetchPropositions`
- `completeUpdatePropositionsRequest` (line 1020) was added to serve the unreachable branch at line 418

**Why It's a Problem:** Shipping unreachable guard branches with a TODO adds dead code surface that a reader must evaluate as if it were live. The `completeUpdatePropositionsRequest` helper was introduced solely to serve the unreachable path, creating a second piece of dead infrastructure. If a future engineer wires up the real reachability signal, they must also verify that `completeUpdatePropositionsRequest` correctly handles the success=false case for the `updatePropositions` public API.

**Simpler Alternative:** Remove both guards (and `completeUpdatePropositionsRequest`) now. Add a single `// TODO(MOB-XXXXX): add isNetworkAvailable() gate here before returning` comment at the two call sites. Re-add the gate with real logic when `MobileCore.isNetworkAvailable()` is available. This preserves the intent without shipping dead paths.

**Confidence:** 0.98

**Caveats:** None — the stub returns a literal `true` with no conditional logic.

**Challenge:** The guards may be retained intentionally to minimize diff when the real implementation lands. That's a valid workflow choice but creates production dead code in the meantime.

---

### HIGH: `endRequestFor` KNOWN ISSUE — completion handler reports success on non-recoverable Edge error

**Issue:** `endRequestFor` calls `handler.handle?(true)` unconditionally at line 1246, even when `nonRecoverableErrorEventIds.contains(eventId)` was true. The KNOWN ISSUE comment (lines 1223-1231) accurately describes the bug: a caller of `updatePropositionsForSurfacesWithCompletionHandler` cannot distinguish a genuine success from a failed request that preserved stale data.

**Evidence:**
- File: `AEPMessaging/Sources/Messaging.swift:1222-1248` — `endRequestFor` full body
- The fix is described exactly in the comment: capture `nonRecoverableErrorEventIds.contains(eventId)` before line 1239 clears the entry, pass `!requestFailed` to `handler.handle?(...)`

**Why It's a Problem:** This is a shipped correctness bug in the public completion handler API. Any caller using the success boolean to decide "should I fall back to `usePersistedContentCards: true`?" will always get `true` and never fall back, even when the network request silently failed and stale data was preserved. The KNOWN ISSUE comment makes the bug visible, but ships it.

**Simpler Fix:**
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

**Confidence:** 0.97

**Caveats:** Changing the completion handler semantics is a behavior change. Callers who rely on the current (broken) "always true" behavior would see different behavior. However, the current behavior is documented as wrong, and the fix is the stated intent.

**Challenge:** Could be intentionally deferred to keep this PR focused on the offline-read path. The comment suggests it is a known deferral, not an oversight.

---

### HIGH: `isContentCardOfflineAvailable` docstring says default `true`, code defaults `false`

**Issue:** The docstring states "Defaults to `true` when the key is absent (backwards-compatible: offline availability is on unless the operator explicitly disables it)." The implementation uses `?? false`. The inline log string confirms the code behavior: "absent from config — defaulting to false."

**Evidence:**
- File: `AEPMessaging/Sources/Messaging.swift:1010-1018`
- Docstring line 1012: "Defaults to `true` when the key is absent"
- Code line 1015: `let value = config?.value?[...] as? Bool ?? false`

**Why It's a Problem:** The docstring is the contract for operators reading this code. An operator who reads the docstring would believe the feature is opt-out; the actual behavior is opt-in. Any operator who does not set the key will get offline availability disabled, contrary to the stated "backwards-compatible" claim.

**Simpler Fix:** Either (a) change `?? false` to `?? true` to match the docstring and the "backwards-compatible" intent, or (b) update the docstring to say "Defaults to `false` (opt-in: offline availability requires explicit operator configuration)." The correct choice depends on the product decision — but the two must agree.

**Confidence:** 0.99

**Caveats:** The boot-time hydration call (`hydrateAllPersistedContentCards`) ignores `isContentCardOfflineAvailable` entirely ("Always hydrate from disk at boot" comment at line 381), so the default value affects only `applyPropositionChangeFor` (disk write decision) and `retrieveMessages` (disk-read gate). The discrepancy still matters for the disk-write path.

**Challenge:** If `?? false` is correct (opt-in), the docstring is simply wrong and should be updated. If `?? true` is correct (opt-out), the code has a bug that disables offline availability by default.

---

## Simplification Opportunities

### MEDIUM: Duplicate `ccOfflineKeyPresent` declarations in `readyForEvent`

**Issue:** Lines 371-372 compute `ccOfflineKeyPresent` and log it outside the `if !initialLoadComplete` guard. Lines 376-377 compute the same `ccOfflineKeyPresent` with a different log message label ("initial code") inside the guard. The outer pair runs on every call to `readyForEvent` (which AEP Core calls repeatedly until it returns `true`). The inner pair was presumably the original debug instrumentation; the outer pair appears to be a copy-paste artifact from development.

**Evidence:**
- File: `AEPMessaging/Sources/Messaging.swift:371-377`

**Why It Matters:** The outer log fires on every event until `initialLoadComplete = true`, spamming the log with a key-presence check that serves no routing purpose. The inner duplicate is also unnecessary since `isContentCardOfflineAvailable` already logs on every call.

**How to Simplify:** Remove lines 371-372 (the outer pair) entirely. Remove lines 376-377 (the inner pair). The `isContentCardOfflineAvailable` function already logs the key value; additional key-presence logs at the call site are noise.

**Confidence:** 0.95

---

### MEDIUM: Commented-out optimization block left in production code

**Issue:** Lines 1285-1288 in `applyPropositionChangeFor` contain a commented-out conditional:
```swift
// Optimization disabled: always clear explicitly for now.
// if !inMemoryContentCardPropositions.isEmpty {
clearPersistedContentCardPropositions()
// }
```
The optimization guard was removed (leaving only the body), but the surrounding commented-out lines were not cleaned up.

**Evidence:**
- File: `AEPMessaging/Sources/Messaging.swift:1284-1289`

**Why It Matters:** Commented-out code in production files signals incomplete cleanup. This fragment is doubly misleading because `inMemoryContentCardPropositions` is itself dead state (see finding #1).

**How to Simplify:** Remove the two comment lines. The `clearPersistedContentCardPropositions()` call is sufficient.

**Confidence:** 0.99

---

### MEDIUM: `clearPersistedContentCardPropositions` wraps `clearContentCards` with no distinct semantics

**Issue:** `clearPersistedContentCardPropositions` contains exactly one statement: `clearContentCards()`, plus a log line. The two functions have the same behavior. Two call sites call `clearPersistedContentCardPropositions` (public API event handler, `resetIdentities`); one call site calls `clearContentCards` directly. There is no semantic reason to distinguish them.

**Evidence:**
- File: `AEPMessaging/Sources/Messaging.swift:702-718`
- `clearContentCards` callers: none (it's only called by `clearPersistedContentCardPropositions`)
- `clearPersistedContentCardPropositions` callers: `applyPropositionChangeFor` line 1287, `handleResetIdentitiesEvent` line 693

**Why It Matters:** Having two names for one operation creates cognitive load: a reader must inspect both to confirm they do the same thing. The distinction implies a semantic difference that doesn't exist.

**How to Simplify:** Collapse into one function. Keep `clearContentCards` (internal name), delete `clearPersistedContentCardPropositions`, and call `clearContentCards()` directly at both call sites. The log message can be the same one.

**Confidence:** 0.90

**Challenge:** The separation may be intentional: `clearContentCards` could eventually grow additional logic for identity reset (e.g., notifying observers) while `clearPersistedContentCardPropositions` remains a public-API-only clear. If that's the plan, add a code comment explaining the intended divergence.

---

### MEDIUM: `isContentCardOfflineAvailable` called at two dispatch sites purely for its log side-effect

**Issue:** In `handleProcessEvent`, lines 415 and 428 call `isContentCardOfflineAvailable(for: event)` and discard the return value. The calls exist solely to produce a log line. `isContentCardOfflineAvailable` reads the config shared state, performs a key lookup, and calls `Log.debug` on every call.

**Evidence:**
- File: `AEPMessaging/Sources/Messaging.swift:415` — return value discarded
- File: `AEPMessaging/Sources/Messaging.swift:428` — return value discarded

**Why It Matters:** The function is called on every `updatePropositions` and `getPropositions` event for logging only. Calling a config-reading function purely for side-effects is a code smell; the intent is invisible to a reader who sees the function call but no use of its return value.

**How to Simplify:** Remove both log lines. The `isContentCardOfflineAvailable` function already logs the flag value with full context when it is called by `applyPropositionChangeFor` and `retrieveMessages` (where the return value actually drives logic).

**Confidence:** 0.92

---

### LOW: Assurance event in `retrieveMessages` disk path uses raw string-literal keys

**Issue:** The Assurance-visible event dispatched at line 1500-1507 uses string literals `"source"`, `"surfaces"`, `"cardCount"` as event data keys.

**Evidence:**
- File: `AEPMessaging/Sources/Messaging.swift:1503-1506`

**Why It Matters:** All other event data keys in this file use `MessagingConstants` references. String literals are invisible to grep and typo-prone.

**How to Simplify:** Add constants to `MessagingConstants.Event.Data.Key` for `source`, `surfaces`, `cardCount`, or use an existing `surfaces` key if one already exists.

**Confidence:** 0.85

**Caveats:** This event is Assurance-only and not part of the public API contract, so the impact is low.

---

### LOW: `completeUpdatePropositionsRequest` is a single-use thin wrapper created for a dead path

**Issue:** `completeUpdatePropositionsRequest(for:success:)` contains two lines: `completionHandlerFor(originatingEventId: event.id)` + `handler.handle?(success)`. It is called exactly once (line 418), in the unreachable `guard isNetworkAvailable()` branch.

**Evidence:**
- File: `AEPMessaging/Sources/Messaging.swift:1020-1024` — declaration
- File: `AEPMessaging/Sources/Messaging.swift:418` — sole call site (in dead guard branch)

**Why It Matters:** The wrapper was introduced to serve a dead code path (see finding #2). Once `isNetworkAvailable()` is removed, this function has no caller.

**How to Simplify:** Remove together with the `isNetworkAvailable()` guards.

**Confidence:** 0.97

---

### LOW: `EdgeNetworkSimulator` in demo app is over-engineered for its use case

**Issue:** The demo app's `CardsView.swift` introduces a 100-line singleton `EdgeNetworkSimulator` with: `Simulation` enum with `isRecoverable` and `behaviorNote` computed properties, `onIntercepted` callback, `install()` static factory + `_instance` backing store, `configure`/`clear` methods, and async dispatch for simulated responses.

**Evidence:**
- File: `TestApps/MessagingDemoAppSwiftUI/AppPages/CardsView.swift` (diff lines 12-92)

**Why It Matters:** For a demo app, simulating network errors requires: intercept Edge requests, return a fixed response. A 15-line mock class with a flag would accomplish this. The production-quality abstraction adds ~85 lines of demo-only code with patterns (singleton, callbacks, enum with derived properties) that a reader might mistake for SDK infrastructure.

**Simpler Alternative:**
```swift
private class OfflineNetworkMock: Networking {
    var simulatedStatus: Int? = nil
    func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)?) {
        if let status = simulatedStatus, networkRequest.url.host?.contains("adobedc.net") == true {
            let response = HTTPURLResponse(url: networkRequest.url, statusCode: status, httpVersion: nil, headerFields: nil)!
            completionHandler?(HttpConnection(data: nil, response: response, error: nil))
        } else {
            // pass through — but demo app has no real "pass through" reference
        }
    }
}
```

**Confidence:** 0.75

**Caveats:** The current implementation intentionally mirrors the mechanism used by the Edge SDK's own functional tests (the comment says "this mirrors the exact mechanism used by aepsdk-edge-ios functional tests"). That mirroring may be intentional for SDK developer education. The `behaviorNote` labels showing which errors are recoverable vs. non-recoverable are genuinely useful for SDK developers testing this feature.

**Challenge:** If the demo app is intended to be used by SDK developers validating edge-case behavior (not just end users), the extra complexity is justifiable as a teaching tool. If it's for end-user demonstrations, it's over-built.

---

## UX Assessment

**Intended users:** SDK developers and AEP operator teams testing offline content card behavior.

**What they're trying to do:** Verify that cards appear offline (from disk), that network errors don't wipe the cache, and that fresh network data replaces stale disk data.

**Cognitive load and usability:**
- The new 4-button action panel (`Download`, `Fetch Content Cards`, `Fetch Offline Content Cards`, `Clear Cache`) is clear and well-labeled. Each action maps to one distinct SDK behavior.
- The expandable error simulation panel with per-button labels ("Recoverable · SDK retries" vs "Non-recoverable · hit dropped") gives SDK developers the context they need without requiring them to understand the SDK internals.
- The `statusMessage` feedback line ("Armed: HTTP 400 (non-recoverable). Now tap Download...") provides clear guidance on what to do next.
- **Issue:** `fetchOfflineContentCards` sets `showLoadingIndicator = true` but the function calls `getContentCardsUI(usePersistedContentCards:)` which reads from the already-qualified in-memory cache (via `qualifiedContentCardsBySurface`). This is a fast in-process lookup — the loading spinner will appear and disappear so quickly that users may not see it, creating confusion about whether the action ran. This is a minor UX inconsistency.
- **Issue:** The `onAppear` block removes the `refreshCards()` auto-fetch that existed in the original code. On first open, the cards list will be empty until the user taps a button. This may confuse users who expect cards to load automatically. However, since `hydrateAllPersistedContentCards` now runs at boot, disk-seeded cards will be available in `qualifiedContentCardsBySurface` as soon as `readyForEvent` fires.

**No dangerous actions without safeguards:** The "Clear Cache" button clears immediately without confirmation. For a demo app used to test offline behavior, accidentally clearing the cache during a test would invalidate the test run. A simple alert confirmation would prevent accidental taps.

**Consistency:** The `downloadCards` function no longer sets `showLoadingIndicator = true` (unlike `fetchContentCards` and `fetchOfflineContentCards`). This is inconsistent — users get a loading indicator for some fetches but not others.

---

## Summary
- Complexity issues found: 4 (HIGH), 4 (MEDIUM), 3 (LOW)
- Over-engineering patterns: `inMemoryContentCardPropositions` dead state, `isNetworkAvailable()` stub with dead guards, one-liner wrapper functions
- UX friction issues: 3 (missing auto-load on first open, loading spinner on fast in-process lookup, no confirmation on destructive Clear Cache)
- Simplification opportunities: 7

**Recommendation:** REQUEST CHANGES

**Rationale:** Two of the four HIGH issues are shipping bugs (completion handler misreports success; docstring contradicts implementation) rather than complexity observations. The `inMemoryContentCardPropositions` dead state and `isNetworkAvailable()` stub are both real complexity additions that add maintenance surface for future engineers without providing current value. The other findings are cleanup items that are straightforward to address.

---

## Confidence Assessment

**Overall review confidence:** 0.88

**What I could adequately assess:**
- `isNetworkAvailable()` stub and dead guard branches — fully confirmed, code returns a literal
- `inMemoryContentCardPropositions` write vs. read — verified all usages via grep
- `endRequestFor` KNOWN ISSUE — fully confirmed, the fix is described in the comment
- `isContentCardOfflineAvailable` docstring vs. code — confirmed, one-line discrepancy
- Duplicate `ccOfflineKeyPresent` block — confirmed, identical declarations at lines 371 and 376
- `clearPersistedContentCardPropositions` vs. `clearContentCards` — confirmed, one-liner wrapper

**What I could NOT adequately assess:**
- Whether any test file reads `inMemoryContentCardPropositions` (would require reading all test files)
- Whether `hydrateContentCardPropositionsRulesEngine` writing directly to `qualifiedContentCardsBySurface` is thread-safe in all paths (deep queue/sync analysis needed)
- Product decision on `isContentCardOfflineAvailable` default value — cannot determine from code alone whether opt-in or opt-out is correct

**Mitigations applied:**
- Graded confidence per finding to reflect verification depth
- Noted the single test caveat on `inMemoryContentCardPropositions`
- Flagged docstring discrepancy as requiring product decision confirmation
