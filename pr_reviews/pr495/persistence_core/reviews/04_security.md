# Security Validation: persistence_core (PR #495)

## Summary
The core disk-persistence read/write/clear design does not introduce a new at-rest-encryption gap or an unsafe deserialization path, but `resetIdentities` fails to clear the persisted Inbox cache (cross-identity data leak on shared devices), a per-proposition data-minimization opt-out flag is defined but never enforced (all content is persisted regardless of server-declared intent), and the new failure-preservation logic trusts locally-dispatched Edge events with no provenance check.

---

## Security Issues

### CRITICAL: `resetIdentities` clears the Content Card disk cache but never clears the persisted Inbox cache — cross-identity leak on shared/kiosk devices

**File:** `AEPMessaging/Sources/Messaging.swift:634-669`

**Problem:**
```swift
private func handleResetIdentitiesEvent(_ event: Event) {
    ...
    clearContentCards()               // line ~654 area
    runtime.createSharedState(...)
    ...
}

private func clearContentCards() {
    qualifiedContentCardsBySurface = [:]
    contentCardRulesBySurface = [:]
    contentCardOriginBySurface = [:]
    contentCardRulesEngine.launchRulesEngine.replaceRules(with: [])
    try? cache.remove(key: MessagingConstants.Caches.CONTENT_CARD_PROPOSITIONS)
    ...
}

private func clearPersistedContentCardAndInboxPropositions() {
    clearContentCards()
    inboxPropositionsBySurface = [:]
    try? cache.remove(key: MessagingConstants.Caches.INBOX_PROPOSITIONS)
    ...
}
```
`handleResetIdentitiesEvent` (the handler for `MobileCore.resetIdentities()` / `EventType.genericIdentity` + `requestReset`) calls only `clearContentCards()`. That function never touches `inboxPropositionsBySurface` or the `INBOX_PROPOSITIONS` disk key. The only code path that clears the Inbox disk cache is `clearPersistedContentCardAndInboxPropositions()`, reachable exclusively through the new opt-in public API `clearPersistedPropositions()` — a call the host app must remember to make separately from `resetIdentities()`.

**Impact:**
`resetIdentities()` is the SDK's documented mechanism for guaranteeing no per-user state survives an identity switch (retail POS, kiosk, shared-device, or logout/login flows). With this gap: User A's individually-targeted Inbox content (container-item propositions, which can carry personalized/PII-adjacent copy) is written to `INBOX_PROPOSITIONS` on disk while signed in. User A signs out and the app calls `resetIdentities()`. User B signs in on the same device. If the app then calls `getInboxUI`/`getPropositionsForSurfaces(..., usePersistedContentCards: true)` before User B's own network fetch completes — precisely the offline/cold-start scenario this PR exists to support — **User A's stale Inbox content is served to User B directly from disk**, bypassing the identity boundary the reset was supposed to enforce.

`AGENTS.md`'s own "Content Card offline — agent summary" table documents that `resetIdentities` clears the CC cache ("unlike IAM") but says nothing about Inbox, indicating this asymmetry was not a deliberate decision. No test exercises Inbox-cache state on identity reset (`grep -n "resetIdentities" AEPMessaging/Tests/UnitTests/MessagingTests.swift` only returns push-token/live-activity-store assertions).

**Fix:**
```swift
private func handleResetIdentitiesEvent(_ event: Event) {
    ...
    clearPersistedContentCardAndInboxPropositions()   // clears CC + Inbox symmetrically
    runtime.createSharedState(...)
    ...
}
```
Add a regression test asserting both `CONTENT_CARD_PROPOSITIONS` and `INBOX_PROPOSITIONS` disk keys (and in-memory `inboxPropositionsBySurface`) are cleared on `resetIdentities`.

**Note:** This is the same code path identified by the HLD reviewer's CRITICAL-1 (`02_hld.md`); flagging it here as well because it is, at its core, a security/data-exposure finding (cross-identity disclosure of personalized content) and should carry security severity/tagging in consolidation regardless of which lens surfaced it first.

---

### MEDIUM: Per-proposition offline opt-out signal is defined but never enforced — all content card/inbox propositions are persisted to disk unconditionally

**File:** `AEPMessaging/Sources/Proposition.swift:112-124`, `AEPMessaging/Sources/ParsedPropositions.swift:94-98,121-125`, `AEPMessaging/Sources/MessagingConstants.swift:34`

**Problem:**
```swift
// Proposition.swift — added, but zero call sites outside its own declaration
var offlineAvailable: Bool {
    ...
    if let mobileParams = characteristics?["mobileParameters"] as? [String: Any],
       let flag = mobileParams["offline"] as? Bool {
        return flag
    }
    return true
}

// ParsedPropositions.swift — actual gate used instead
if MessagingConstants.OFFLINE_AVAILABILITY_ENABLED {   // hardcoded `true`, MessagingConstants.swift:34
    contentCardPropositionsToPersist.add(proposition, forKey: surface)
}
...
if MessagingConstants.OFFLINE_AVAILABILITY_ENABLED {
    inboxPropositionsToPersist.add(proposition, forKey: surface)
}
```
`grep -rn "offlineAvailable" AEPMessaging/Sources AEPMessaging/Tests` returns only the property's own declaration — it is never read. Persistence is instead gated on a single hardcoded `true` constant applied uniformly to every proposition.

**Impact (security/privacy framing):** if a campaign author or server-side config explicitly marks a proposition as `mobileParameters.offline = false` (intended to prevent a sensitive, time-limited, or individually-targeted piece of content from surviving on the device after the session ends), that intent is silently ignored — the content is written to the unencrypted on-disk cache (`AEPServices.DiskCacheService`, same mechanism as the existing IAM `propositions` cache) anyway. This widens the data-minimization surface introduced by this PR: every content card and inbox item now persists to disk regardless of server-declared sensitivity, with no working mechanism to opt out short of removing the hardcoded constant.

**Fix:**
```swift
if MessagingConstants.OFFLINE_AVAILABILITY_ENABLED && proposition.offlineAvailable {
    contentCardPropositionsToPersist.add(proposition, forKey: surface)
}
```
Apply the same change to the inbox branch. Add a regression test asserting a proposition with `mobileParameters.offline = false` is excluded from `contentCardPropositionsToPersist`/`inboxPropositionsToPersist`.

**Note:** Already flagged in detail by the LLD reviewer (CRITICAL, confidence 0.9) and HLD reviewer (MAJOR-7) from a design-integrity angle; recorded here specifically for the data-minimization/on-disk-exposure consequence, which is squarely in security scope.

---

### LOW: `handleEdgeErrorResponse` trusts any locally-dispatched Edge error event with a matching `requestEventId` — no provenance/authenticity check

**File:** `AEPMessaging/Sources/Messaging.swift:1435-1452`, `AEPMessaging/Sources/ClassExtensions/Event+Messaging.swift:46-58`

**Problem:**
```swift
private func handleEdgeErrorResponse(_ event: Event) {
    guard event.isEdgeErrorResponseEvent,
          let requestEventId = event.requestEventId,
          requestedSurfacesForEventId.contains(where: { $0.key == requestEventId })
    else {
        return
    }
    if let status = event.edgeErrorStatus, MessagingConstants.RECOVERABLE_EDGE_ERROR_STATUS_CODES.contains(status) {
        ...
        return
    }
    ...
    nonRecoverableErrorEventIds.insert(requestEventId)
}
```
`isEdgeErrorResponseEvent` checks only `type == .edge` and `source == "com.adobe.eventSource.errorResponseContent"` — both are plain string/enum matches on the Event Hub, which any code running in the host app process (e.g. another bundled extension, or a compromised/malicious dependency) can dispatch via `MobileCore.dispatch(event:)`. There is no signature, sender-identity, or origin-extension check tying the event to the real Edge extension.

**Impact:** Before this PR, an `applyPropositionChangeFor` empty response always meant "server says this surface has nothing" and evicted stale content from memory/disk. This PR adds a new trust dependency: if `nonRecoverableErrorEventIds` contains the request's ID, eviction is skipped entirely and the existing (possibly stale/ended-campaign) disk and in-memory content is preserved instead. A forged `errorResponseContent` event with a guessed/observed in-flight `requestEventId` (visible to same-process code) can force this "preserve, don't evict" branch indefinitely, keeping already-superseded personalization content alive on disk past its intended lifetime. This requires existing code-execution inside the host app process to exploit (same trust model as the rest of the AEP Event Hub), so it does not cross a new process/privilege boundary, but it is a new *behavioral* dependency on an unauthenticated in-process signal that did not exist before this PR.

**Fix:** No practical remediation exists purely within `AEPMessaging` (the Event Hub does not currently support sender authentication), so treat this as accepted risk consistent with the rest of the SDK's extension-trust model. If Edge's `errorResponseContent` contract is ever extended with a signed/attributed sender field, prefer validating against it here.

---

### LOW: Stale test assertions describe "automatic" disk hydration that contradicts the shipped explicit opt-in gate — reduces assurance that the opt-in boundary is actually enforced by CI

**File:** `AEPMessaging/Tests/UnitTests/Messaging+StateTests.swift` (`testGetPropositionsAutoHydratesFromDiskWhenMemoryIsEmpty`), `AEPMessaging/Tests/UnitTests/Messaging+PublicApiTest.swift` (`testGetPropositionsForSurfacesDoesNotSetPersistedFlag`)

**Problem:** The shipped `retrieveMessages` (`Messaging.swift:1374-1377`) only reads content card/inbox data from disk when `event.usePersistedContentCards == true`:
```swift
if event.usePersistedContentCards {
    hydrateContentCardRulesEngineFromDisk(for: requestedSurfaces)
    hydrateInboxPropositionsFromDisk(for: requestedSurfaces)
}
```
This is the only call site for both hydrate functions, and matches the PR's own design docs (`docs/agents/write-read-clear-flow.md:150`: *"No automatic fallback. Memory-empty does NOT trigger a disk read on its own anymore."*; `AGENTS.md`: *"Cold start: No auto-hydrate; opt-in `usePersistedContentCards: true` on get"*).

However, `testGetPropositionsAutoHydratesFromDiskWhenMemoryIsEmpty` builds a `GET_PROPOSITIONS` event **without** setting `USE_PERSISTED_CONTENT_CARDS`, with the comment "No USE_PERSISTED_CONTENT_CARDS flag needed — disk hydration is automatic," then asserts the content card rules engine was hydrated from disk. A sibling test's comment similarly states "the persisted-flag approach has been removed; offline hydration is automatic." Both directly contradict the shipped, documented, explicit-opt-in gate.

**Why this matters for security:** the explicit-opt-in requirement is the mechanism that keeps disk reads from happening implicitly (relevant to the data-minimization/consent-adjacent design intent of this feature). A test suite that asserts (and appears to expect as correct) automatic disk hydration either (a) currently fails in CI — meaning it's inert as regression protection for the opt-in boundary, or (b) passes for an unrelated reason (e.g., some other rules-engine wiring already sets the tracked flag), which would mean the "explicit-only" guarantee is not actually verified by CI, so a future refactor could silently reintroduce implicit disk reads without a test catching it.

**Caveat:** I attempted to run this test directly (`xcodebuild test -only-testing:...testGetPropositionsAutoHydratesFromDiskWhenMemoryIsEmpty`) to get a definitive pass/fail result, but the environment's `-destination 'platform=iOS Simulator,name=iPhone 16'` resolved ambiguously (multiple installed runtimes/duplicate simulator UDIDs) and the run did not execute the test; I could not obtain a live pass/fail signal. Static trace of the only call site (`if event.usePersistedContentCards`) makes an unconditional pass surprising, but I cannot rule it out without a clean run.

**Fix:** Set `USE_PERSISTED_CONTENT_CARDS: true` in the test's event data (matching the documented explicit-opt-in contract) and correct the misleading comments in both tests; or, if genuinely automatic hydration is desired product behavior, that would be a design reversal requiring explicit reconciliation with `AGENTS.md` and the PR's own `write-read-clear-flow.md`.

**Note:** Also flagged by the LLD reviewer with the same caveat about being unable to confirm CI pass/fail in this environment; recorded here for the security-boundary framing specifically.

---

## Review Inputs Used
- `pr_reviews/pr495/persistence_core/files.md` — module scope (Messaging.swift, Messaging+PublicAPI.swift, MessagingConstants.swift, ParsedPropositions.swift, Cache+Messaging.swift, Event+Messaging.swift, Proposition.swift, + listed tests)
- `pr_reviews/pr495/pr495_unresolved_comments.md` — 0 unresolved comments; nothing to avoid duplicating
- `pr_reviews/pr495/pr495_template.md` — PR description/commit list
- `pr_reviews/pr495/pr495_diff/AEPMessaging/Sources/**` and `.../Tests/**` — per-file diffs for all in-scope files
- `AGENTS.md` / `docs/agents/content-card-offline-implementation.md`, `docs/agents/write-read-clear-flow.md`, `docs/agents/content-card-offline-known-gaps.md`, `docs/agents/inbox-cbe-offline-handoff.md` — design intent used to confirm/contradict shipped behavior
- `.build/checkouts/aepsdk-core-ios/AEPServices/Sources/cache/DiskCacheService.swift` — verified actual disk-write mechanism (plain `FileManager.createFile`, no encryption, pre-existing for the `propositions` key) to confirm this PR introduces no *new* at-rest-encryption gap
- `pr_reviews/pr495/persistence_core/reviews/02_hld.md`, `03_lld.md` — cross-checked to avoid pure duplication; several findings below are corroborations with an explicit security framing added, not fresh discoveries

---

## Exploration Coverage
- **Entry points checked:** `Messaging+PublicAPI.swift` public surface (`getPropositionsForSurfaces(_:usePersistedContentCards:_:)`, `clearPersistedPropositions()`, `updatePropositionsForSurfacesWithCompletionHandler`); `Messaging.swift` event handlers (`handleProcessEvent` get/update/clear branches, `handleResetIdentitiesEvent`, `handleEdgeErrorResponse`, `handleEdgePersonalizationNotification`).
- **Callers/callees traced:** `clearPersistedPropositions()` → `isClearPersistedPropositionsEvent` → `clearPersistedContentCardAndInboxPropositions()` → `clearContentCards()` + inbox clear + disk `remove(key:)`, confirmed it does **not** touch IAM (`PROPOSITIONS`) or CBE (`inMemoryPropositions`) — scoping claim in the doc comment holds. `handleResetIdentitiesEvent` → `clearContentCards()` only, confirmed it does **not** reach the inbox-clearing path (see CRITICAL finding).
- **Blast radius checked:** confirmed the CBE revert left no orphaned `CODE_BASED_PROPOSITIONS`/`codeBasedPropositions` key or reference anywhere in `AEPMessaging/Sources` or `AEPMessaging/Tests` (`grep` returned zero hits outside historical git log / this PR's own docs describing the reverted design) — no stale disk key or dead trust surface from the revert. Confirmed `DiskCacheService` (shared by `PROPOSITIONS`, `CONTENT_CARD_PROPOSITIONS`, `INBOX_PROPOSITIONS`) applies identical (non-)encryption semantics to all three keys — no new at-rest gap specific to the two new keys.
- **Runtime/data flow followed:** disk decode path (`Cache+Messaging.swift` `propositionsByKey` → `JSONDecoder().decode` wrapped in `try?`) confirmed to fail closed (returns `nil`, no crash, no unsafe deserialization) on malformed/tampered cache data; `handleEdgeErrorResponse` log statements confirmed to emit only the request ID and an `Int?` status code, never a raw error body/headers/tokens.

---

## Summary
- Critical: 1
- High: 0
- Medium: 1
- Low: 2

**Recommendation:** REQUEST CHANGES

**Note:** The CRITICAL cross-identity Inbox-cache leak on `resetIdentities` MUST be fixed before merge — it is a real, reachable data-exposure path on the exact shared/kiosk-device scenario `resetIdentities()` exists to protect, and is a direct consequence of code shipped in this PR (the Inbox disk-persistence path is new).

---

## Structured Findings Summary
- Total findings: 4 (1 CRITICAL, 0 HIGH, 1 MEDIUM, 2 LOW)
- Overall confidence in this review: 0.75
- Areas I could NOT adequately assess:
  - Whether `testGetPropositionsAutoHydratesFromDiskWhenMemoryIsEmpty` currently passes or fails in CI — blocked by an ambiguous simulator destination in this environment (`xcodebuild` returned the full device list instead of running the test); would require a clean simulator environment or CI logs.
  - Whether Edge's `errorResponseContent` event contract could be extended with sender attribution to close the trust-boundary gap noted in the LOW finding above — would require inspecting the `aepsdk-edge-ios` repo, not available here.
  - Whether product/security explicitly accepted the residual on-disk exposure of content marked non-cacheable by campaign authors as an interim state (vs. an oversight) — no sign-off artifact found in this diff.
