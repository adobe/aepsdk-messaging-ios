# Completeness Validation: MOB-25109/offline-content-card-availability

## Summary
The offline content card feature has a failing test that tests an unimplemented stub, a stale listener-count assertion, two P0 open items (dismiss eviction, real connectivity signal) with no test coverage, no tests for the 400-error shield, a doc/code comment contradiction on `isContentCardOfflineAvailable`, and a KNOWN ISSUE in the completion handler path that has no tracking ticket.

---

## Missing / Incomplete Requirements

**HIGH: P0 dismiss eviction (Option B) is not implemented**
- **What's missing:** `removePropositionFromQualifiedCards` (Messaging.swift:994–1001) removes the dismissed card only from `qualifiedContentCardsBySurface` (in-memory). It does NOT write the updated state back to the disk cache. The raw CC proposition that originally qualified the card remains on disk untouched.
- **Impact:** On the next cold start, `hydrateAllPersistedContentCards()` re-reads the disk, re-evaluates the content-card rules engine, and the dismissed card re-qualifies and reappears. This is the "cold-start flash" AGENTS.md marks as **P0 Open**.
- **Action:** After removing the card from `qualifiedContentCardsBySurface`, rewrite the CC disk cache via `cache.updateContentCardPropositions(qualifiedContentCardsBySurface, removing: [])` or, per AGENTS.md Option B, evict the specific proposition from the raw disk propositions when `track(.dismiss)` fires.

**HIGH: P0 real connectivity signal not wired — `isNetworkAvailable()` hardcodes `return true`**
- **What's missing:** `isNetworkAvailable()` (Messaging.swift:1004–1008) contains an explicit TODO and always returns `true`. The `ServiceProvider.shared.networkAvailabilityService` mock is set in tests but is never queried by the implementation.
- **Impact:** The entire offline gate for `updatePropositions` and `fetchPropositions` is disabled. The feature headline ("skip Edge on offline") cannot be tested or relied on in production until this is wired.
- **Action:** Replace `return true` with a real connectivity check, e.g. `ServiceProvider.shared.networkConnectivityService?.isNetworkAvailable() ?? true`. This also unblocks the failing unit test.

---

## Incomplete / Missing Operational Aspects

### CRITICAL: `testHandleProcessEvent_updatePropositions_skipsEdgeWhenOffline` tests a stub and will FAIL
- **What's missing:** The test (MessagingTests.swift:1686–1714) sets `mockNetworkConnectivityService.isAvailable = false` and asserts (1) completion handler returns `false` and (2) no Edge events are dispatched. But `isNetworkAvailable()` hardcodes `return true` and never queries the mock service. `fetchPropositions` IS called, Edge events ARE dispatched, and both assertions fail.
- **Impact:** The test is giving false confidence in the offline gate and will fail in CI.
- **Action:** Wire `isNetworkAvailable()` to the real service first (see above), then the test will pass as written.

### HIGH: `testOnRegistered_nineListenersAreRegistered` is stale — 10 listeners now registered
- **What's missing:** `Messaging.onRegistered()` now registers 10 listeners (lines 287–334 of Messaging.swift): the new `EDGE_ERROR_RESPONSE` listener (lines 317–319) was added in this PR. The test at MessagingTests.swift:87–89 still asserts `mockRuntime.listeners.count == 9`.
- **Impact:** This test will fail in CI every time it runs.
- **Action:** Update assertion to `XCTAssertEqual(mockRuntime.listeners.count, 10)`.

### HIGH: No unit tests for `handleEdgeErrorResponse` (400-error shield)
- **What's missing:** The new `handleEdgeErrorResponse` listener (Messaging.swift:1579–1607) is the key mechanism for preserving disk/memory on non-recoverable Edge errors. No unit test covers:
  - A non-recoverable error (e.g. status 400) populates `nonRecoverableErrorEventIds`
  - A recoverable error (408, 429, 502 etc.) does NOT populate `nonRecoverableErrorEventIds`
  - `applyPropositionChangeFor` preserves existing disk/memory when the flag is set
- The existing `test_handleProcessCompletedEvent_noDecisions_preservesContentCardDiskCache` (MessagingProcessCompletedEventTests.swift:611–629) simulates zero decisions but does NOT exercise the Edge-error code path. It does not set `nonRecoverableErrorEventIds`, so it is testing a different branch.
- **Impact:** The 400-error shield is completely untested at the unit level. A regression in `handleEdgeErrorResponse` or `applyPropositionChangeFor`'s error-gate branch would go undetected.
- **Action:** Add tests simulating `handleEdgeErrorResponse` called with non-recoverable vs. recoverable status codes, verify `nonRecoverableErrorEventIds` set/cleared correctly, and verify disk not evicted when the flag is set.

### HIGH: No test for `handleResetIdentitiesEvent` clearing CC disk cache
- **What's missing:** `handleResetIdentitiesEvent` now calls `clearPersistedContentCardPropositions()` which removes the CC disk cache key (diff line 234-235). No unit test verifies that a reset-identities event causes `cache.remove` to be called with `MessagingConstants.Caches.CONTENT_CARD_PROPOSITIONS`.
- **Impact:** A regression that accidentally skips the CC disk clear on identity reset (a privacy/GDPR-sensitive operation) would be undetected.
- **Action:** Add a test that fires a reset-identities event and asserts `mockCache.removeCalls.contains(MessagingConstants.Caches.CONTENT_CARD_PROPOSITIONS)`.

### HIGH: `isContentCardOfflineAvailable()` docstring contradicts implementation
- **What's missing:** The docstring says "Defaults to `true` when the key is absent (backwards-compatible: offline availability is on unless the operator explicitly disables it)." The implementation does `?? false` (defaults to `false`). The debug log also says "defaulting to false".
- **Impact:** An operator reading the docstring will assume offline is on by default. The actual behavior silently disables the feature for apps that do not add the config key. This is a high-impact backwards-compatibility claim that is wrong.
- **Action:** Correct the docstring to say "Defaults to `false` when the key is absent" OR change the implementation to `?? true` if backwards-compat is the real intent. The two must be consistent.
- **File:** Messaging.swift:1010–1018

### MEDIUM: `endRequestFor` KNOWN ISSUE — completion handler always reports `success: true` on non-recoverable errors; no ticket reference
- **What's missing:** A `KNOWN ISSUE` comment at Messaging.swift:1223–1233 documents that `handler.handle?(true)` is called unconditionally even when the request had a non-recoverable Edge error. Callers using `updatePropositionsForSurfacesWithCompletionHandler` to decide "should I fall back to a disk read?" receive `true` and incorrectly believe the fetch succeeded.
- **Impact:** Apps that fall back to offline content only when the completion handler returns `false` will never trigger the offline path on a 400 error. The KNOWN ISSUE is not tracked anywhere (no Jira ticket reference).
- **Action:** File a ticket and add its ID to the comment. Fix: capture `nonRecoverableErrorEventIds.contains(eventId)` before clearing the set, and pass `!requestFailed` to `handler.handle?(...)`.

### MEDIUM: eventsQueue `isGetPropositionsEvent` branch in `onRegistered` is dead code
- **What's missing:** `onRegistered()` (lines 338–345) sets up an `eventsQueue.setHandler` that processes `isGetPropositionsEvent` events from the queue. But `handleProcessEvent` now calls `retrieveMessages` directly (line 431) without adding get-propositions events to `eventsQueue`. The handler branch can never fire.
- **Impact:** No functional regression, but the dead branch misleads readers about the data flow and creates maintenance risk (a future engineer may add back `eventsQueue.add(event)` for get events, causing a double-dispatch).
- **Action:** Remove the `isGetPropositionsEvent` branch from the eventsQueue handler, leaving only the `EventType.edge` ordering logic.

### MEDIUM: P0 functional E2E offline device tests absent
- **What's missing:** AGENTS.md §Open implementation work lists "Functional E2E offline tests on device" as **P0**. The branch adds integration tests using Swift Testing (`@Suite`) that run against a live Event Hub (`GetContentCardUITest.swift`, `BootHydratePersistedContentCardsTest`), but these are not device-level tests verifying full cold-start → dismiss → re-boot offline flows under network interruption.
- **Impact:** The offline persistence path has no verified end-to-end proof on actual device hardware or a simulator with network simulation enabled.
- **Action:** Document this explicitly as deferred to a follow-up ticket with an ID.

---

## Test Quality Risks

- **CRITICAL:** `testHandleProcessEvent_updatePropositions_skipsEdgeWhenOffline` is a false-confidence test. It appears to verify the offline gate but the implementation it is trying to test is a hardcoded stub. The test will fail, not pass.
- **HIGH:** `testOnRegistered_nineListenersAreRegistered` — stale count, will fail.
- **HIGH:** Zero unit tests for `handleEdgeErrorResponse`. The 400 error shield has no test coverage at the unit layer.
- **HIGH:** Zero unit tests for `handleResetIdentitiesEvent` clearing CC disk.
- **MEDIUM:** `test_handleProcessCompletedEvent_noDecisions_preservesContentCardDiskCache` does NOT cover the non-recoverable Edge error path. It simulates zero in-progress propositions, which is structurally different from `nonRecoverableErrorEventIds` being set.
- **MEDIUM:** No unit tests for `retrieveMessages` disk path when `isContentCardOfflineAvailable` returns `false` (should return empty, not fall through to memory path).

---

## Comment & Doc Accuracy

- **HIGH:** `isContentCardOfflineAvailable` docstring says "Defaults to `true`" but code does `?? false`. Messaging.swift:1010–1018.
- **HIGH:** `endRequestFor` KNOWN ISSUE comment has no tracking ticket. Messaging.swift:1223–1233.
- **MEDIUM:** Duplicate `ccOfflineKeyPresent` variable declaration in `readyForEvent` (Messaging.swift:371–377): the same value is computed and logged twice — once outside and once inside the `if !initialLoadComplete` guard. The inner block also contains stale comment text ("once we have valid configuration, fetch message definitions from offers if we haven't already") which duplicates the outer comment. These are dev-time debug leftovers that should be removed before merge.
- **MEDIUM:** `removePropositionFromQualifiedCards` docstring says "Removes the Proposition matching `activityId` from both the live and disk qualified caches" (Messaging.swift:991–993). The implementation only removes from in-memory; disk is NOT touched. The docstring overstates what the function does.

---

## Hygiene & Communication Checklist

- [NEEDS FIX] `testOnRegistered_nineListenersAreRegistered` — stale assertion, will fail in CI
- [NEEDS FIX] `testHandleProcessEvent_updatePropositions_skipsEdgeWhenOffline` — tests an unimplemented stub
- [NEEDS FIX] Duplicate debug log block in `readyForEvent` — dev-time noise in production code
- [NEEDS FIX] `removePropositionFromQualifiedCards` docstring — claims disk is updated, implementation does not
- [OPEN] KNOWN ISSUE in `endRequestFor` has no tracking ticket
- [DEFERRED OK] P1 `clearCachedContentCardPropositions()` name in AGENTS.md vs `clearPersistedPropositions()` in code — different name but same functional intent; acceptable if AGENTS.md is updated
- [DEFERRED OK] PLATIR-64717 empty items[] — `ParsedPropositions.init` already guards `items.first` at line 55 which skips empty-items propositions; this P1 appears already addressed by the existing guard, but AGENTS.md still marks it open — update the table

---

## Review Inputs Used
- `MOB-25109-offline-content-card-availability_template.md` — commit history, file list
- `Messaging.swift.diff` — full source diff
- `MessagingProcessCompletedEventTests.swift.diff` and live file — test coverage for process-completed path
- `MessagingTests.swift.diff` and live file — offline gate and listener count tests
- `Messaging+PublicApiTest.swift.diff` — public API test updates
- `Cache+MessagingTests.swift.diff` — CC cache unit tests
- `AEPMessaging/Sources/Messaging+State.swift` — updateContentCardPropositions, readContentCardPropositionsFromDisk
- `AEPMessaging/Sources/ParsedPropositions.swift` — empty items guard, contentCardPropositionsToPersist
- `AEPMessaging/Sources/Messaging+PublicAPI.swift` — clearPersistedPropositions public API
- `AEPMessaging/Tests/IntegrationTests/GetContentCardUITest.swift` — boot hydration integration test
- `AEPMessaging/Tests/TestHelpers/MockNetworkConnectivityService.swift` — mock network service
- AGENTS.md — open P0/P1 items

---

## Exploration Coverage

- Entry points checked: `handleProcessEvent`, `readyForEvent`, `onRegistered`, `handleEdgeErrorResponse`, `handleResetIdentitiesEvent`, `clearPersistedPropositions` public API, `removePropositionFromQualifiedCards`
- Callers/callees traced: `isNetworkAvailable()` → `fetchPropositions` → Edge dispatch; `removePropositionFromQualifiedCards` → `handleRulesResponse`; `hydrateAllPersistedContentCards` → `hydrateContentCardRulesEngineFromDisk` → `hydrateContentCardPropositionsRulesEngine`
- Blast radius checked: CC disk cache write path, resetIdentities path, cold-start hydration, event-history disqualify rules, test listener count
- Runtime/data flow followed: cold-start boot → disk hydration → rules evaluation → qualified cards tagged `.disk`; dismiss → `removePropositionFromQualifiedCards` → (disk gap identified)

---

## Summary

**Feature Completeness:**
- P0 real connectivity signal: NOT IMPLEMENTED (hardcoded stub, broken test)
- P0 dismiss eviction to disk: NOT IMPLEMENTED (memory-only removal)
- P1 public clear API: IMPLEMENTED (`clearPersistedPropositions()`)
- P1 empty items[] skip: ALREADY HANDLED by existing `items.first` guard
- Boot cold-start hydration: IMPLEMENTED
- 400-error shield: IMPLEMENTED but untested at unit level
- `resetIdentities` CC disk clear: IMPLEMENTED but untested

**Operational Completeness:**
- Critical gaps: 1 (failing test on unimplemented stub)
- High priority: 5 (stale listener test, missing 400-error tests, missing resetIdentities test, dismissal disk gap, isContentCardOfflineAvailable doc/code mismatch)
- Medium priority: 3 (endRequestFor completion handler KNOWN ISSUE, dead eventsQueue branch, E2E offline tests deferred)

**Recommendation:** BLOCK — Two tests will fail in CI (listener count, offline guard stub). The dismiss eviction gap means dismissed cards re-appear on cold start. The `isContentCardOfflineAvailable` default of `false` silently disables the feature for apps that don't add the config key, contradicting the stated backwards-compatibility intent.
