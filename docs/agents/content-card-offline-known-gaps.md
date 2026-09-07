# Content Card Offline — Known Gaps & Deferred Test Scenarios

**Branch context:** `MOB-25109/offline-content-card-availability`  
**Last updated:** 2026-07-13

This file tracks real-device/simulator test scenarios that expose known gaps in the current
offline persistence implementation. These are **not covered by unit tests** and should be
validated manually once the underlying bugs are fixed.

---

## Scenario 1 — Stale CC cards persist on disk when CC campaign ends but IAM campaign stays live on the same surface

### Background

`applyPropositionChangeFor` computes which surfaces to remove from disk using
`inProgressPropositions.keys` — all proposition types combined. If a surface returns IAM
propositions but zero CC propositions, the surface is still present in that set, so it is
**not** added to `surfacesToRemove`. The CC disk entry for that surface is therefore never
cleared.

File: `Messaging.swift` — `applyPropositionChangeFor`, specifically:

```swift
let returnedSurfaces = Array(inProgressPropositions.keys) as [Surface]
let surfacesToRemove = requestedSurfaces.minus(returnedSurfaces)
cache.updateContentCardPropositions(parsedPropositions.contentCardPropositionsToPersist, removing: surfacesToRemove)
```

### Why it matters

A user who goes offline after this update will still see the old, ended CC cards when
`getPropositions(usePersistedContentCards: true)` is called — cards that should no longer
exist.

### Why it is low risk today

In standard AJO deployments:
- IAM campaigns target the root app surface: `mobileapp://com.example.myapp`
- CC campaigns target sub-path surfaces: `mobileapp://com.example.myapp/feeds/homeCards`

These are different surfaces, so the overlap does not occur by default. The bug only
manifests when a customer deliberately creates both an IAM and a CC campaign on the
**exact same surface URI**.

### Pre-conditions for the test

| Step | Action |
|------|--------|
| 1 | In AJO, create an **IAM campaign** targeting surface `mobileapp://<bundleId>/shared` |
| 2 | In AJO, create a **CC campaign** targeting the **same** surface `mobileapp://<bundleId>/shared` |
| 3 | Publish both campaigns |

> Use a non-standard sub-path surface for IAM so both campaign types can coexist on it.
> The demo app's `Constants.SurfaceName` may need a new entry for this shared surface.

### Test steps

1. **Online seed**
   - Launch the app with network enabled.
   - Call `updatePropositionsForSurfaces([sharedSurface])` and wait for `completion(true)`.
   - Confirm the SDK debug log shows:
     - `"Content card propositions saved to persisted disk successfully"`
   - Confirm the IAM triggers correctly on a qualifying event.

2. **End the CC campaign server-side**
   - In AJO, deactivate or delete the CC campaign. Leave the IAM campaign active.

3. **Online refresh**
   - Without restarting the app, call `updatePropositionsForSurfaces([sharedSurface])` again.
   - Wait for `completion(true)`.
   - The server response now contains IAM propositions for `sharedSurface` but **zero** CC propositions.

4. **Kill the app and disable network**

5. **Offline read**
   - Relaunch the app (network off).
   - Call `getPropositionsForSurfaces([sharedSurface], usePersistedContentCards: true)`.

6. **Observe (expected vs actual)**

   | | Expected (correct) | Actual (current bug) |
   |-|--------------------|----------------------|
   | CC propositions returned | `[]` — CC campaign is gone | Old CC propositions still returned from disk |
   | Error | `nil` | `nil` |

### Acceptance criteria (for the fix)

- After step 3, the CC disk entry for `sharedSurface` is cleared (no `set` call for
  `contentCardPropositions` key with `sharedSurface` data; a `remove` or an empty write
  occurs instead).
- After step 5, the returned propositions contain only the IAM proposition (if applicable
  to that API) or an empty CC list — **not** the stale CC cards.

### Suggested unit test name

```
test_handleProcessCompletedEvent_ccClearedWhenSurfaceReturnsIAMOnlyAfterHavingCC
```

Test shape:
1. First response: IAM + CC propositions both on the **same** surface.
2. Second response: IAM propositions only on that same surface (CC campaign removed).
3. Assert: `mockCache.setCalls` for `CONTENT_CARD_PROPOSITIONS` does **not** contain the
   shared surface, or `mockCache.removeCalls` contains `CONTENT_CARD_PROPOSITIONS`.

### Root cause fix (not yet implemented)

Replace the shared `surfacesToRemove` for CC with a CC-specific removal set:

```swift
// Current (wrong for CC):
let returnedSurfaces = Array(inProgressPropositions.keys) as [Surface]
let surfacesToRemove = requestedSurfaces.minus(returnedSurfaces)
cache.updateContentCardPropositions(parsedPropositions.contentCardPropositionsToPersist, removing: surfacesToRemove)

// Correct:
let ccReturnedSurfaces = Array(parsedPropositions.contentCardPropositionsToPersist.keys)
let ccSurfacesToRemove = requestedSurfaces.minus(ccReturnedSurfaces)
cache.updateContentCardPropositions(parsedPropositions.contentCardPropositionsToPersist, removing: ccSurfacesToRemove)
```

---

## Scenario 2 — Distinguishing empty payload vs no response (RESOLVED)

### Status: Fixed

`decisionsReceivedForEventId: Set<String>` was added to `Messaging.swift` to track whether
Edge sent at least one `personalization:decisions` event for a given request — even when
the payload is `[]` (zero campaigns).

The guard in `endRequestFor` now reads:

```swift
let decisionsArrived = decisionsReceivedForEventId.contains(eventId)
guard decisionsArrived || !inProgressPropositions.isEmpty else {
    // skip — Edge never responded (offline / timeout)
}
```

This correctly distinguishes:

| Scenario | `decisionsArrived` | `inProgressPropositions` | Outcome |
|----------|--------------------|--------------------------|---------|
| Online, Adobe has campaigns | true | non-empty | `applyPropositionChangeFor` runs, disk updated ✅ |
| Online, Adobe responds with zero campaigns (empty `[]`) | true | empty | `applyPropositionChangeFor` runs, surface cleared from disk ✅ |
| Offline / timeout, no response at all | false | empty | guard fires, disk unchanged ✅ |

### Manual validation still recommended

Confirm on-device that Case 2 (empty payload) actually clears the CC disk cache:

1. Seed disk with CC cards for `homeCards` surface.
2. Remove the CC campaign in AJO. Leave the surface active.
3. Call `updatePropositionsForSurfaces([homeCards])` — Adobe responds with empty `[]`.
4. Kill app, disable network.
5. Call `getPropositions(usePersistedContentCards: true)`.
6. Expected: empty result — the surface was cleared from disk.
