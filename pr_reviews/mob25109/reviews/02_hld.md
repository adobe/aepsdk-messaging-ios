# HLD Review

**Branch:** MOB-25109/offline-content-card-availability
**Review ID:** MOB-25109-offline-content-card-availability
**Reviewer Focus:** API boundary design, module responsibility, origin-table approach soundness, read path design, public API surface correctness, blast radius.

## Summary

Five architectural issues found: the feature's default configuration semantics are inverted (disabled by default despite the spec saying enabled), the network gate central to the offline design is hardcoded to never fire, an in-memory state structure is written but never read, `getPropositions` silently dropped its ordering guarantee with no breaking-change notice, and the offline-fallback API cannot distinguish "feature disabled" from "no cards."

---

## Design Flaws

### CRITICAL Flaws

**[CRITICAL-1]: `isContentCardOfflineAvailable` defaults to `false` — inverts the stated contract**

- **What's Wrong:** `isContentCardOfflineAvailable(for:)` evaluates `?? false` when `messaging.contentCardOfflineAvailable` is absent from the Configuration shared state (Messaging.swift line 1015). The doc comment on that same function says "Defaults to `true` when the key is absent (backwards-compatible: offline availability is on unless the operator explicitly disables it)." The implementation is the exact opposite of the documented intent.
- **Why It's Critical:** The consequence is two-fold and both are silent. (1) Every call to `applyPropositionChangeFor` with an absent config key evaluates `ccOfflineAvailable = false` and calls `clearPersistedContentCardPropositions()`, which wipes `qualifiedContentCardsBySurface`, `contentCardRulesBySurface`, `contentCardOriginByProposition`, `inMemoryContentCardPropositions`, the CC rules engine, and the disk cache. Net result: every network response during a session with no explicit config destroys any previously persisted cards. (2) Any call to `getPropositionsForSurfaces(surfaces:usePersistedContentCards:true:)` with an absent config key hits the `isContentCardOfflineAvailable` guard in `retrieveMessages` and returns an empty proposition list — no error, no signal — silently indistinguishable from "no cards exist." The feature is completely non-functional for any operator who does not explicitly set the key.
- **Evidence:** `Messaging.swift` line 1015 (`?? false`); contradicting doc comment two lines above; `applyPropositionChangeFor` lines 1281-1289 (the `else { clearPersistedContentCardPropositions() }` branch); `retrieveMessages` lines 1478-1488 (the early-return empty-response branch).
- **Fix Required:** Change `?? false` to `?? true` at line 1015. Update the log message at line 1016 from "defaulting to false" to "defaulting to true." Verify the `applyPropositionChangeFor` `else` branch behavior is still correct under the new default: when the feature defaults to on, `clearPersistedContentCardPropositions()` should only be called when the operator explicitly sets the key to `false`, not on absence.
- **Confidence:** 0.97
- **Caveats:** If the intent truly was opt-in (disabled by default), the doc comment is wrong and every other architectural decision in this PR (boot hydration, always-on disk write) becomes inconsistent with the feature being opt-in. One of the two must be corrected.
- **Challenge:** Could argue opt-in is safer to prevent unexpected disk I/O for operators who haven't adopted this feature. But then boot hydration (`hydrateAllPersistedContentCards` called unconditionally in `readyForEvent`) and the unconditional `contentCardOfflineAvailable: true` passed in `hydrateContentCardPropositionsRulesEngine` both bypass the flag — the system is inconsistent regardless of which default is "right."

---

### MAJOR Flaws

**[MAJOR-1]: `isNetworkAvailable()` is permanently hardcoded to `true` — the network gate ships as dead code**

- **What's Wrong:** `isNetworkAvailable()` at Messaging.swift line 1004–1008 returns `true` unconditionally. It carries a `// TODO:` comment acknowledging it should wire to `MobileCore.isNetworkAvailable()`. The function is called in two places: `handleProcessEvent` (guard before `fetchPropositions` on update events) and `fetchPropositions` (guard at line 1038). Both guards can never fire.
- **Impact:** The PR's stated design decision — "New network availability gate: `MobileCore.isNetworkAvailable()` skips Edge on update when offline" — is entirely absent from the shipped feature. When offline, the SDK will still dispatch an Edge request. If the request fails with a non-recoverable error, `nonRecoverableErrorEventIds` protects against eviction, but the completion handler still receives `true` (a separate known issue documented in `endRequestFor`). The offline scenario advertised in the PR title is only partially functional: read-from-disk works, but skip-network-on-write does not. Callers using `updatePropositionsForSurfacesWithCompletionHandler` to drive a "fetch then fallback" pattern receive misleading success/failure signals.
- **Evidence:** Messaging.swift lines 1004–1008 (hardcoded `return true`); `handleProcessEvent` line 416 (`guard isNetworkAvailable()`); `fetchPropositions` line 1038.
- **Recommended Fix:** Either wire the real reachability check before merging, or remove the gate entirely and document the deferred work as a tracked follow-up item. Shipping the guard structure with a hardcoded stub creates a false impression of correctness in the architecture diagram and misleads future contributors about what is actually enforced. If deferring, the guard calls should be removed, not left as dead stubs.
- **Confidence:** 1.0 (literal `return true` in production code with a TODO).
- **Caveats:** The fallback path (error detection via `nonRecoverableErrorEventIds`) partially compensates. But the completion-handler always-`true` issue makes this unreliable for callers.
- **Challenge:** The TODO is explicit and the author is aware. If this is intentional ship-now-fix-later, it needs a tracked ticket and the public API documentation should not describe the network gate as if it exists.

---

**[MAJOR-2]: `inMemoryContentCardPropositions` is written on every network response but never read — dead state**

- **What's Wrong:** `_inMemoryContentCardPropositions` is populated by `updateContentCardPropositions` in `Messaging+State.swift` (lines 71–87) and cleared by `clearContentCards()`. Its doc comment says "Engine hydration reads from here rather than re-reading disk on every call." But no code in the codebase reads from this property for hydration or retrieval. `hydrateContentCardRulesEngineFromDisk` calls `readContentCardPropositionsFromDisk` (which reads from `cache`, not from `inMemoryContentCardPropositions`). `retrieveMessages` reads from `qualifiedContentCardsBySurface`. `hydrateContentCardPropositionsRulesEngine` takes propositions as a parameter.
- **Impact:** Every network response writes into a dictionary that has no reader. The state must be protected by the dispatch queue, cleared on reset, and kept consistent — all for no benefit. The doc comment describing a behavior that isn't implemented creates false confidence that an optimization exists. Any future contributor implementing a feature that relies on the stated semantics ("reads from here rather than re-reading disk") would build on an incorrect assumption.
- **Evidence:** `Messaging+State.swift` lines 70–88 (write path); no read site for `inMemoryContentCardPropositions` in `Messaging.swift` or `Messaging+State.swift`; `hydrateContentCardRulesEngineFromDisk` line 1441 reads from `readContentCardPropositionsFromDisk` (cache), not this property; `retrieveMessages` line 1530 reads from `qualifiedContentCardsBySurface`.
- **Recommended Fix:** Either (a) implement the stated intent — make `hydrateContentCardRulesEngineFromDisk` read from `inMemoryContentCardPropositions` when it's populated (avoiding a disk round-trip on re-hydration after a network fetch) — or (b) remove the property and its write sites, and correct the doc comment on `hydrateContentCardRulesEngineFromDisk`. Option (a) is the architecturally correct choice since it completes the design.
- **Confidence:** 0.90
- **Caveats:** I did not search integration test or demo app files for reads. However, the property is `internal`, so only SDK sources and same-module tests can access it; no external reader can exist without it being `public`.
- **Challenge:** It's possible the property was scaffolded for a near-future commit. If so, it should be absent from this PR or accompanied by a TODO comment, not a doc comment asserting it's used.

---

**[MAJOR-3]: `getPropositions` silently dropped the ordering guarantee with no API migration path**

- **What's Wrong:** Before this PR, `isGetPropositionsEvent` was queued via `eventsQueue.add(event)` (original `handleProcessEvent`). This guaranteed that a `getPropositions` call immediately following an `updatePropositions` call would return data from the completed update. This PR changes that: `handleProcessEvent` now calls `retrieveMessages` immediately (Messaging.swift line 431) and returns, never adding the event to the queue. The `eventsQueue.setHandler` still has a dead `if event.isGetPropositionsEvent` branch (line 339–341) that can never fire since get-propositions events no longer enter the queue.
- **Impact:** Existing callers who dispatch `updatePropositionsForSurfaces` followed by `getPropositionsForSurfaces` without a completion handler (the old pattern) now get a race: if the Edge response hasn't returned yet, `getPropositionsForSurfaces` returns the pre-update in-memory data. This is a behavioral regression with no deprecation notice, no version bump signal, and no documentation change on the existing `getPropositionsForSurfaces(_ surfaces: _ completion:)` overload (the one without `usePersistedContentCards`). The old overload's doc comment still references being used "to read freshly updated in-memory data" after calling update first — but that pattern is now racy.
- **Evidence:** `handleProcessEvent` line 426–433 (immediate retrieval, no queue); `eventsQueue.setHandler` lines 339–341 (dead branch); original code comment at line 425–427 ("// Queue the get propositions event...") is replaced by a comment justifying immediate processing.
- **Recommended Fix:** The behavioral change is arguably correct for the new design (where `updatePropositionsForSurfacesWithCompletionHandler` + `getPropositionsForSurfaces` is the recommended pattern), but it must be documented as a breaking behavior change. Update the doc comment on the unchanged `getPropositionsForSurfaces(_ surfaces: _ completion:)` overload to state clearly that it no longer serializes after in-flight updates. Remove the dead `isGetPropositionsEvent` branch from `eventsQueue.setHandler`. Consider whether the old "queue on update" behavior should be preserved for callers that pass `usePersistedContentCards: false` (in-memory read), since those callers almost certainly want post-update data.
- **Confidence:** 0.85
- **Caveats:** If all existing callers have already been migrated to use the completion-based update API, this may have no observable impact. This is a self-review branch so no external consumer impact is known.
- **Challenge:** The new API contract is strictly better for most use cases (non-blocking reads). The issue is the silent change in semantics for existing call patterns, not the direction of the change.

---

**[MAJOR-4]: `usePersistedContentCards: true` returns silent empty response when feature is disabled — undistinguishable from "no cards"**

- **What's Wrong:** In `retrieveMessages`, when `event.usePersistedContentCards == true` and `isContentCardOfflineAvailable(for: event)` returns `false`, the function dispatches a success response event with an empty propositions array (lines 1479–1488). No error code, no error event, no flag in the response data indicating the feature is disabled.
- **Impact:** A caller implementing an offline-first pattern — "try network, fall back to persisted cards" — calls `getPropositionsForSurfaces(surfaces: [s], usePersistedContentCards: true)` and gets a success callback with `[:]`. This is indistinguishable from the case where the feature is enabled but no cards are persisted, or where the requested surface genuinely has no cards. The caller cannot determine whether it should show a "no content" empty state or "feature unavailable" empty state, or whether it should retry with network. In combination with CRITICAL-1 (the feature defaults to disabled), this means every app that hasn't explicitly configured the key gets silent empty responses on every offline read attempt.
- **Evidence:** `retrieveMessages` lines 1479–1488; empty `[[String: Any]]()` response with no distinguishing metadata.
- **Recommended Fix:** Either (a) dispatch an error response event using `event.createErrorResponseEvent(AEPError.invalidRequest)` or a more specific error code, so callers can distinguish "feature off" from "no cards"; or (b) add a `featureDisabled: Bool` flag in the response metadata. Option (a) is cleaner. At minimum, document in the `getPropositionsForSurfaces(usePersistedContentCards:)` API doc that the completion returns an empty (not an error) when the feature is disabled by configuration.
- **Confidence:** 0.85
- **Caveats:** If the SDK's contract is that completion errors are reserved for system/infrastructure failures and empty collections represent "no data available for any reason," this is consistent. But it makes offline fallback logic brittle.
- **Challenge:** The AEPCore `createErrorResponseEvent` API may not have a suitable error code for "feature disabled." In that case, a response metadata flag is the right alternative.

---

### MINOR Flaws

**[MINOR-1]: `clearPersistedPropositions()` name over-promises — only clears content cards**

- **What's Wrong:** The public API method is named `clearPersistedPropositions()` (`Messaging+PublicAPI.swift` line 77). Its implementation calls `clearPersistedContentCardPropositions()` which calls `clearContentCards()`. IAM propositions (persisted under `MessagingConstants.Caches.PROPOSITIONS`), CBE propositions, and inbox propositions are not affected. The doc comment discloses "Code-based experience (CBE) persisted propositions are not affected" but doesn't mention IAM or inbox.
- **Impact:** Future callers expecting a full cache flush will be surprised. The name is inconsistent with the SDK's existing naming pattern where "propositions" refers to all proposition types.
- **Suggestion:** Rename to `clearPersistedContentCardPropositions()` to match the implementation scope, or expand the implementation to cover all persisted types (if that's the intent).
- **Confidence:** 0.90
- **Challenge:** The scoped behavior may be intentional (content cards have user-specific cache that should be reset separately from IAM rules).

---

**[MINOR-2]: Dismiss path doesn't call `pruneContentCardOrigins()` — stale origin entries accumulate**

- **What's Wrong:** `removePropositionFromQualifiedCards(for:)` (Messaging.swift line 994) removes a proposition from `qualifiedContentCardsBySurface` but does not call `pruneContentCardOrigins()`. The prop's `uniqueId` key remains in `contentCardOriginByProposition` until the next `updateRulesEngines` call.
- **Impact:** Low: the stale entry doesn't affect `retrieveMessages` (the dismissed card is gone from `qualifiedContentCardsBySurface`). It does mean `contentCardOriginByProposition` is momentarily inconsistent with `qualifiedContentCardsBySurface` after a dismiss. If a new proposition is served with the same `uniqueId` (unlikely but possible), it would inherit the wrong origin tag until a network response cleans it up.
- **Suggestion:** Call `pruneContentCardOrigins()` at the end of `removePropositionFromQualifiedCards(for:)`.
- **Confidence:** 0.80
- **Challenge:** uniqueId collisions are unlikely in practice.

---

**[MINOR-3]: `CardOrigin` enum defined at file scope in `Messaging.swift` — wrong home for a type used across extension files**

- **What's Wrong:** `CardOrigin` (Messaging.swift lines 23–29) is a module-level type defined inside the largest source file in the module. It's used in `Messaging.swift`, `Messaging+State.swift`, and would be referenced by any new extension that needs to inspect card provenance.
- **Impact:** Minor discoverability issue. `CardOrigin` does not appear in any logical grouping with other enum types (like `SchemaType` or `PropositionEventType`). Its doc comment describes it as a "provenance signal" — this suggests it belongs in a types or enums file, not as a file-level prefix to a 1700-line implementation file.
- **Suggestion:** Move `CardOrigin` to `MessagingConstants.swift` or a dedicated `MessagingTypes.swift`.
- **Confidence:** 0.75
- **Challenge:** Swift file placement has no runtime impact; this is purely organizational.

---

**[MINOR-4]: Dead `isGetPropositionsEvent` branch in `eventsQueue.setHandler` after queue bypass**

- **What's Wrong:** `eventsQueue.setHandler` in `onRegistered()` (Messaging.swift lines 338–345) retains an `if event.isGetPropositionsEvent` branch. Since `handleProcessEvent` now intercepts and processes get-propositions events immediately without adding them to the queue, this branch can never execute.
- **Impact:** Future contributors reading `onRegistered()` will incorrectly infer that get-propositions events are queue-processed, leading to incorrect mental models of event ordering.
- **Suggestion:** Remove the dead `isGetPropositionsEvent` branch from the queue handler.
- **Confidence:** 0.95
- **Challenge:** None — the code path is unreachable.

---

**[MINOR-5]: Duplicate debug-log block and redundant variable in `readyForEvent`**

- **What's Wrong:** In `readyForEvent` (Messaging.swift lines 371–387), `ccOfflineKeyPresent` is computed and logged twice: once before the `if !initialLoadComplete` guard (line 371–372) and again inside the guard (lines 374–377). The outer log is redundant since the same variable and value are logged on line 375.
- **Impact:** Noisy debug logs, potential confusion during Assurance debugging. Indicates leftover dev-time scaffolding that wasn't cleaned up.
- **Suggestion:** Remove the outer (pre-guard) duplicate.
- **Confidence:** 1.0
- **Challenge:** None.

---

## Verdict

**Recommendation:** REQUEST CHANGES

| Severity | Count | Action |
|----------|-------|--------|
| Critical | 1 | Must fix before merge |
| Major | 4 | Should fix before merge |
| Minor | 5 | Track for follow-up |

**Summary:** The feature's offline read path (boot hydration, `usePersistedContentCards` flag, origin-table tagging) is architecturally sound and the `nonRecoverableErrorEventIds` eviction-protection design is well-reasoned. However, the inverted default for `isContentCardOfflineAvailable` (CRITICAL-1) means the feature is broken for every operator who doesn't explicitly configure the key — the disk cache is cleared on every network response, not written. The network gate shipping as hardcoded `true` (MAJOR-1) and `inMemoryContentCardPropositions` being written-but-never-read (MAJOR-2) indicate incomplete implementation. The silent-empty vs. feature-disabled response (MAJOR-4) and the ordering-guarantee regression (MAJOR-3) are API contract issues that need documentation or behavioral fixes before external consumption.

---

## Review Metadata

- **Total findings by severity:** Critical: 1, Major: 4, Minor: 5
- **Overall review confidence:** 0.88
- **Areas not adequately assessed:**
  - `ParsedPropositions.contentCardPropositionsToPersist` behavior was not read in full — could not verify the complete set of what gets written to disk vs. only to memory.
  - `InboxUI.swift` and the persistence mode change were not reviewed — the HLD of the inbox offline path may have its own issues outside scope of this review.
  - The recoverable error status code set (`RECOVERABLE_EDGE_ERROR_STATUS_CODES`) was not cross-validated against the actual Edge extension's retry list — the assumption that 408/429/502/503/504/507 match Edge's `PersistentHitQueue` thresholds was taken from the diff comments.
