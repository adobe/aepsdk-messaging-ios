# Complexity Analysis: MOB-25109/offline-content-card-availability (pr495, module: persistence_core)

### Files Reviewed
- **Deeply reviewed**:
  - `AEPMessaging/Sources/Messaging.swift`
  - `AEPMessaging/Sources/Messaging+PublicAPI.swift`
  - `AEPMessaging/Sources/MessagingConstants.swift`
  - `AEPMessaging/Sources/ParsedPropositions.swift`
  - `AEPMessaging/Sources/ClassExtensions/Cache+Messaging.swift`
  - `AEPMessaging/Sources/ClassExtensions/Event+Messaging.swift`
  - `AEPMessaging/Sources/Proposition.swift`
- **Lightly reviewed** (boilerplate/duplication only, per scope):
  - `AEPMessaging/Tests/UnitTests/Cache+MessagingTests.swift`
  - `AEPMessaging/Tests/UnitTests/Messaging+StateTests.swift`
  - `AEPMessaging/Tests/UnitTests/MessagingTests.swift`
  - `AEPMessaging/Tests/UnitTests/MessagingProcessCompletedEventTests.swift`
  - `AEPMessaging/Tests/UnitTests/ParsedPropositionsTests.swift`
  - `AEPMessaging/Tests/UnitTests/Messaging+PublicApiTest.swift`
  - `AEPMessaging/Tests/TestHelpers/MockCache.swift`
  - `AEPMessaging/Tests/TestHelpers/MockNetworkConnectivityService.swift`
- **Not reviewed** (out of scope): `Messaging+UIPublicAPI.swift`, `InboxUI.swift`, `ContentCardUI.swift`, demo app files, `docs/agents/*.md` prose beyond what's needed to fact-check the in-scope code.

### Findings (ranked)
1. HIGH — Dead code: `Proposition.offlineAvailable` is never called anywhere in the codebase; persist gating uses a hardcoded global flag instead.
2. HIGH — Documentation drift shipped in this same PR: `AGENTS.md` and `docs/agents/content-card-offline-known-gaps.md` reference a guard/symbol (`personalizationDecisionReceivedForEventId` / `decisionsReceivedForEventId`) that does not exist in the shipped `Messaging.swift`.
3. MEDIUM — CBE branch in `ParsedPropositions.swift` is silently asymmetric after the persistence revert, with no comment explaining the omission.
4. MEDIUM — Two parallel per-eventId collections (`requestedSurfacesForEventId`, `nonRecoverableErrorEventIds`) with independently-maintained lifecycles.
5. MEDIUM — Single shared `surfacesToRemove` value applied uniformly to three independent disk stores (IAM/CC/inbox), which the PR's own bundled docs confirm causes a real eviction bug for CC-vs-IAM same-surface overlap.
6. LOW — Trivial forwarding overload for `getPropositionsForSurfaces` could be a default parameter instead, per an existing in-file precedent.
7. LOW — Test boilerplate: 6 new Cache+MessagingTests are a 3x-duplicated structural copy of the existing IAM proposition tests.

### Unreviewed Risk Areas
- I did not review `Messaging+UIPublicAPI.swift`/`InboxUI.swift` bodies (out of scope), so I cannot confirm whether the UI-layer overloads introduce additional duplicated logic beyond simple forwarding — I only confirmed (via grep) that both flagged and unflagged `getPropositionsForSurfaces` variants have live callers there.
- I did not run the test suite; test-file findings are based on structural reading of diffs only.
- I could not verify whether `NetworkAvailabilityProviding`/`ServiceProvider.networkAvailabilityService` (referenced by `MockNetworkConnectivityService.swift`) actually exists in the pinned `AEPServices` pod version, since that type lives in the sibling `aepsdk-core-ios` repo, out of scope for this review.

## Review Inputs Used
- `pr_reviews/pr495/pr495_template.md` — PR description/commit list (description body itself is empty template boilerplate; commit list on the underlying task states: "Add explicit offline-read APIs...", "offline tracking added in events...", "content card availability for offline support", "added offline capability along with tests")
- `pr_reviews/pr495/pr495_unresolved_comments.md` — confirmed 0 unresolved comments, nothing to avoid duplicating
- `pr_reviews/pr495/pr495_diff/_summary.md` and per-file diffs for all in-scope files
- `AGENTS.md`, `docs/agents/content-card-offline-implementation.md`, `docs/agents/network-availability-layer.md`, `docs/agents/inbox-cbe-offline-handoff.md`, `docs/agents/persistence-write-path-and-errors.md`, `docs/agents/write-read-clear-flow.md`, `docs/agents/content-card-offline-known-gaps.md`
- `.swiftlint.yml` — confirmed `cyclomatic_complexity`, `function_body_length`, `type_body_length` are disabled; not used to flag anything here
- Full working-tree contents of all 7 in-scope source files (not diffs alone) for `Messaging.swift`, `Messaging+PublicAPI.swift`, `MessagingConstants.swift`, `ParsedPropositions.swift`, `Cache+Messaging.swift`, `Event+Messaging.swift`, `Proposition.swift`

## Exploration Coverage
- Entry points checked: `Messaging.onRegistered()` listener registrations, `handleProcessEvent`, `fetchPropositions`, `retrieveMessages`, public API surface in `Messaging+PublicAPI.swift`
- Callers/callees traced: grepped all call sites of `getPropositionsForSurfaces`, `updatePropositionsForSurfaces`, `clearPersistedPropositions`, `offlineAvailable`, `OFFLINE_AVAILABILITY_ENABLED`, `codeBasedPropositions*`, `decisionsReceivedForEventId`/`personalizationDecisionReceivedForEventId` across `AEPMessaging/` and `TestApps/`
- Blast radius checked: `applyPropositionChangeFor` → `updateRulesEngines` → `processRulesForSchemaType` / `removeOrReplaceContentCards` (three eviction destinations gated by one `requestFailed` flag); `beginRequestFor`/`endRequestFor`/`fetchPropositions` timeout closure for the two per-eventId collections' lifecycle
- Runtime/data flow followed: write path (`applyPropositionChangeFor` → `cache.update*Propositions`), read path (`retrieveMessages` → `hydrate*FromDisk`), error path (`handleEdgeErrorResponse` → `nonRecoverableErrorEventIds` → `applyPropositionChangeFor` guard)

## Summary
The core new mechanism (Edge `errorResponseContent` listener + `nonRecoverableErrorEventIds`) is justified, well-scoped, and consistent with an existing Optimize precedent, but the PR ships with a dead proposition-level `offlineAvailable` property, a hardcoded gate that supersedes it, a CBE persistence branch left silently asymmetric after a revert, and — most importantly — architecture docs bundled into the very same PR that describe a guard mechanism which does not exist in the shipped code.

---

## Research Findings

**Problem researched:** Whether the PR's specific implementation choices (public API overload pattern, per-event-id Set/Dictionary state tracking, and the hardcoded feature-flag placeholder) match established patterns, or whether they're unnecessarily complex/over-engineered relative to standard practice.

**Searches performed:**
- "Swift default parameter values vs method overloading Objective-C interoperability best practice" → Found: Swift supports default parameter values even on `@objc`-exposed methods; Objective-C simply requires all parameters explicitly (no default-arg concept), so Swift call sites can omit trailing/middle defaulted parameters while ObjC call sites always see the full selector. General guidance favors default parameters over overloads where both are viable, specifically because it avoids redundant near-identical bodies. ([Default Arguments and Label-based Overloading](https://belkadan.com/blog/2022/04/Default-Arguments-and-Label-based-Overloading/), [The Many Faces of Swift Functions · objc.io](https://www.objc.io/issues/16-swift/swift-functions/))
- "stale-if-error cache pattern distinguishing recoverable vs non-recoverable errors CDN eventually consistent" → Found: Industry-standard `stale-if-error` (RFC 5861, implemented by Fastly/Cloudflare/Vercel/Google Cloud CDN) serves cached/stale content when the origin errors, but the *standard* directive does not itself distinguish recoverable vs. non-recoverable error classes — that differentiation is left to application-level logic. ([Fastly: Stale-While-Revalidate, Stale-If-Error](https://www.fastly.com/blog/stale-while-revalidate-stale-if-error-available-today), [MDN Cache-Control](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Cache-Control))
- "feature flag hardcoded true placeholder TODO pattern technical debt tracking" → Found: Feature-flag literature (LaunchDarkly, Unleash, CloudBees) consistently warns that "temporary" hardcoded-true flags without an enforced expiry/removal mechanism are a top source of long-lived tech debt — the majority of flags in open-source projects that lack automated expiry linger far past their intended lifetime. ([LaunchDarkly: Reducing technical debt from feature flags](https://launchdarkly.com/docs/guides/flags/technical-debt), [CloudBees: Technical Debt Management with Feature Flags](https://www.cloudbees.com/blog/technical-debt-management-feature-flags))
- "parallel dictionaries same key anti-pattern refactor into single struct primitive obsession" → Found: Maintaining two or more collections keyed by the same identifier ("parallel collections") is a documented anti-pattern; the fix is to merge them into a single collection of a struct/tuple so add/remove/mutate logic lives in one place instead of being manually kept in sync across multiple call sites. ([Jon Skeet: Anti-pattern: parallel collections](https://codeblog.jonskeet.uk/2014/06/03/anti-pattern-parallel-collections/), [Anti Patterns: Parallel Arrays](https://obdurodon.silvrback.com/anti-patterns-parallel-arrays))

**Industry standard approach:** For Swift/ObjC-bridged SDKs, a single method with a default parameter value is the idiomatic way to add an optional flag without duplicating logic, reserving genuinely distinct overloads for cases needing different ObjC selector names (e.g., a non-optional/`@escaping`-only completion handler variant for ObjC ergonomics). For distinguishing "request failed" from "request succeeded but returned nothing," CDN/cache systems universally use a single failure classification embedded in the response/error path rather than multiple independently-tracked collections. For temporary flags, the standard is either a config-driven value from day one or an enforced expiry (linter rule, calendar reminder, or a tracked ticket referenced directly in the flag name/comment) — a bare `TODO` comment with no ticket reference and no test coverage of the alternate branch is the exact anti-pattern the literature warns rots into permanent scaffolding.

**Simpler alternatives identified:**
1. Collapse `getPropositionsForSurfaces(_:_:)` into a default parameter on `getPropositionsForSurfaces(_:usePersistedContentCards:_:)` (`usePersistedContentCards: Bool = false`), removing one forwarding overload — mirrors the existing `handleNotificationResponse(_:urlHandler:closure:)` pattern already in the same file (`Messaging+PublicAPI.swift:29-32`), which already uses default values on an `@objc`-exposed method.
2. Merge `requestedSurfacesForEventId: [String: [Surface]]` and `nonRecoverableErrorEventIds: Set<String>` into one `[String: RequestState]` where `RequestState` carries `surfaces: [Surface]` and `failed: Bool` — eliminates the need to keep two removal call sites in sync by construction.
3. Either wire `Proposition.offlineAvailable` into the actual gate (`if MessagingConstants.OFFLINE_AVAILABILITY_ENABLED && proposition.offlineAvailable`) or delete the unused property until the shared-state config lands — shipping an unreachable 17-line computed property is worse than shipping nothing.

**Assessment:** The headline new mechanism (non-recoverable-error tracking + Edge error listener) is standard practice, well-justified, and appropriately scoped — it is not over-engineered. However, several secondary design choices (dead `offlineAvailable` property, two parallel per-eventId collections instead of one, hardcoded flag with no wiring to the property it was presumably meant to replace) show signs of an implementation that changed direction mid-flight without a full cleanup pass, which is a maintainability risk more than a "too much engineering" risk.

---

## Focus Questions — Direct Answers

### Q1. Overload duplication — are the 3 overloads simplest, or should defaults have been used?

Not "3 overloads with duplicated logic" — in reality each forwarding overload is a single-line delegation, so there is **no duplicated logic**, only duplicated signatures/doc-comments. Specifically:

- `getPropositionsForSurfaces(_ surfaces:, _ completion:)` (`Messaging+PublicAPI.swift:159-162`) is a 1-line forwarder to `getPropositionsForSurfaces(_:usePersistedContentCards:_:)` (`:171-214`) with `usePersistedContentCards: false`.
- `updatePropositionsForSurfacesWithCompletionHandler(_:completionHandler:)` (`:144-148`, **new** in this PR) is a 1-line forwarder to the pre-existing `updatePropositionsForSurfaces(_:_:)` (`:110-137`, which already defaults its `completion` parameter to `nil` and predates this PR).

Given the file already demonstrates (`handleNotificationResponse(_:urlHandler:closure:)`, `:29-32`) that Swift permits default parameter values on `@objc`-exposed methods, the `getPropositionsForSurfaces(_:_:)` forwarder could have been eliminated by adding `usePersistedContentCards: Bool = false` directly to the single implementation — Swift allows omitting a defaulted middle parameter even when the trailing closure is unlabeled. This would save ~6 lines. This is **low severity**: it's a real, low-risk simplification opportunity, not a duplication problem, since the current code has no duplicated business logic.

`updatePropositionsForSurfacesWithCompletionHandler` is justified as-is: it exists specifically to give Objective-C callers a distinctly-named, non-optional-closure selector, matching the SDK's existing naming convention for ObjC-friendly completion APIs elsewhere in the file. Not over-engineering.

Grep confirms **both** flagged and unflagged `getPropositionsForSurfaces` variants have live callers (`Messaging+UIPublicAPI.swift:51`, `InboxUI.swift:166` use the flagged form; `InboxUI.swift:187`, `TestApps/.../CodeBasedView.swift:87` use the unflagged form) — neither overload is dead code.

### Q2. State tracking complexity — is `nonRecoverableErrorEventIds` + `requestedSurfacesForEventId` over-engineered or minimal?

Not over-engineered relative to the requirement, but it **is** a parallel-collections pattern (`Messaging.swift:83-87` and `:97-101`) that could be merged. Lifecycle comparison:

| Event | `requestedSurfacesForEventId` | `nonRecoverableErrorEventIds` |
|---|---|---|
| Request begins | `beginRequestFor` sets value (`:1156-1157`) | not set |
| Edge error arrives | unchanged | `handleEdgeErrorResponse` inserts (`:1451`) |
| Request completes | `endRequestFor` removes (`:1168`) | `endRequestFor` removes (`:1171`) |
| Dispatch times out | `fetchPropositions` closure removes (`:1056`) | `fetchPropositions` closure removes (`:1057`) |

I traced both removal sites and **confirmed they are currently symmetric** — no leak exists today (this refutes a hypothesis that they could have desynced silently). But that symmetry is maintained by convention across two files/call sites, not enforced by the type system; a future third cleanup path (or a missed edit to one of the two existing ones) would silently desync them. Per the parallel-collections anti-pattern (see Research Findings), merging into `[String: RequestState]` (surfaces + failed flag) would make this structurally impossible to get wrong. **Severity: MEDIUM** — real simplification opportunity, not a live bug.

### Q3. New error listener necessity — justified or redundant?

**Justified, not redundant.** `handleEdgeErrorResponse` (`Messaging.swift:1435-1452`) is registered in `onRegistered()` (`:282-284`) using the exact same `registerListener(type: EventType.edge, source:, listener:)` pattern as the pre-existing `personalization:decisions` listener immediately above it (`:276-278`) — stylistically consistent, not a new/divergent registration idiom. I found no other Edge error-handling code anywhere in `Messaging.swift` prior to this PR (grep for `errorResponseContent`/`EDGE_ERROR_RESPONSE` returns only this PR's additions). `docs/agents/persistence-write-path-and-errors.md` documents this as mirroring an existing `aepsdk-optimize-ios` pattern, and notes Optimize's own version of this fix has a gap (records the error but doesn't gate eviction on it) that this PR's implementation closes. This is a real, previously-missing safety net for genuine data loss, not duplicated logic.

### Q4. CBE revert cleanliness — does `ParsedPropositions.swift` read cleanly after the revert?

**No — confirmed asymmetric and under-commented.** The `.feed`/`.contentCard` case (`ParsedPropositions.swift:92-99`) and the `.inbox` case (`:119-125`) both carry an explicit `// TODO: gate on shared-state-driven config once available; hardcoded true for now...` comment referencing `OFFLINE_AVAILABILITY_ENABLED`. The `.jsonContent, .htmlContent, .defaultContent` (CBE) case (`:113-115`) has neither a persist bucket nor any comment — just `propositionsToCache.add(proposition, forKey: surface)` under a stale-sounding comment ("code based schemas are cached for reporting") that gives no indication CBE disk persistence was ever attempted or intentionally reverted. Confirmed via grep that no `codeBasedPropositionsToPersist`/`CODE_BASED_PROPOSITIONS`/`updateCodeBasedPropositions` exists anywhere in the current source tree, even though `docs/agents/inbox-cbe-offline-handoff.md` (shipped in this same PR) describes CBE disk persistence in detail as if it were live (§1.1-1.2, listing `codeBasedPropositionsToPersist`, `CODE_BASED_PROPOSITIONS`, `updateCodeBasedPropositions`). A future reader hitting the CBE case with no comment, then separately reading that doc describing CBE persistence as implemented, will reasonably conclude something is broken/missing rather than intentionally reverted. **A one-line comment** (e.g., `// CBE persistence intentionally reverted to memory-only for this iteration — see MOB-XXXX`) at `:112-115` would fix this cheaply. **Severity: MEDIUM.**

### Q5. `OFFLINE_AVAILABILITY_ENABLED` — clean placeholder or permanent scaffolding risk?

`MessagingConstants.swift:30-34` declares `static let OFFLINE_AVAILABILITY_ENABLED = true` with a clear doc comment marking it as a temporary stopgap pending shared-state config. Taken alone this is a reasonably well-labeled placeholder. However, two things push it toward "permanent scaffolding" risk:
1. It is **never toggled** anywhere in the test suite (grep across `AEPMessaging/Tests/` for `OFFLINE_AVAILABILITY_ENABLED` returns zero hits) — the `false` branch of both `if MessagingConstants.OFFLINE_AVAILABILITY_ENABLED { ... }` guards (`ParsedPropositions.swift:96, 123`) is completely untested and, in production, unreachable, since the constant can't be flipped without a code change.
2. It has **no ticket/tracking reference** in its comment (just "TODO... once that config flag is available") — per the feature-flag literature, flags without an enforced expiry or explicit tracking ID are the ones most likely to outlive their intended lifetime.

**Severity: LOW-MEDIUM** as a standalone issue; compounded by Q6/Finding #1 below since it also silently supersedes a similarly-named per-proposition flag that was added in the same PR and never wired up.

### Q6. Reinvention check — does the new tracking reinvent something already available?

`nonRecoverableErrorEventIds` **reuses** the existing in-file convention (private backing var + `queue.sync`/`queue.async` computed property wrapper) already used for `requestedSurfacesForEventId`, `inMemoryPropositions`, `propositionInfo`, etc. (8 total instances of this hand-rolled synchronization boilerplate in `Messaging.swift`). It does not reinvent AEPServices or Swift stdlib functionality — `Set<String>` is the right primitive for a membership check. However, the file already has **three different** idioms for "track state per in-flight request" that this PR's addition does not consolidate:
- `completionHandlers: [CompletionHandler]` — array + linear `firstIndex` scan, keyed by `UUID`
- `requestedSurfacesForEventId: [String: [Surface]]` — dictionary keyed by event-id string
- `nonRecoverableErrorEventIds: Set<String>` — set keyed by the same event-id string (new)

This PR added a fourth flavor of "per-request bookkeeping" rather than consolidating with the dictionary it's always read/written alongside (see Q2). Not a reinvention of an external tool, but a missed opportunity for internal consistency.

---

## Complexity Issues

### HIGH: Dead code — `Proposition.offlineAvailable` is never called

**Issue:** `Proposition.swift:109-124` adds a 17-line computed property `offlineAvailable` that parses `scopeDetails.characteristics.mobileParameters.offline` (handling both the `AnyCodable` and raw-`Any` representations of `scopeDetails`, mirroring the exact dual-format logic already used by `activityId` and `rank`). It is never referenced by any call site in `AEPMessaging/Sources` or `AEPMessaging/Tests` other than its own declaration.

**Evidence:**
- `AEPMessaging/Sources/Proposition.swift:112-124` — full property definition
- Repo-wide grep for `offlineAvailable` returns exactly one hit (the declaration itself); the actual persist gate in `ParsedPropositions.swift:96` and `:123` checks `MessagingConstants.OFFLINE_AVAILABILITY_ENABLED` instead
- `docs/agents/inbox-cbe-offline-handoff.md:73-83` (shipped in this same PR) describes the gate as reading `proposition.offlineAvailable` — directly contradicting the actual shipped code, confirming this was a real design that got swapped for the blunter global flag without removing the now-orphaned property

**Why It's a Problem:** A future engineer reading `Proposition.swift` will reasonably assume `offlineAvailable` is load-bearing (it has a thoughtful implementation and doc comment) and may build new logic on it, not realizing it's disconnected from the actual persistence decision. It also duplicates format-detection branching that already exists twice in the same file (`activityId`, `rank`), so removing it removes triplicated logic, not just an unused property.

**Simpler Alternative:** Either (a) wire it into the gate: `if MessagingConstants.OFFLINE_AVAILABILITY_ENABLED && proposition.offlineAvailable { ... }` in both `ParsedPropositions.swift` branches, giving per-proposition opt-out as the doc originally described, or (b) delete the property entirely until the per-proposition flag is actually needed.

**Confidence:** 0.9

**Caveats:** It's possible a downstream consumer (React Native/ObjC wrapper, out of this repo) reads this property via reflection or another repo entirely, though `offlineAvailable` is not `@objc`-annotated and is defined in a plain `extension Proposition` (not the `@objcMembers` class body), making external visibility unlikely.

**Challenge:** If there's a follow-up PR already staged that wires this property into the gate, this finding would be moot — but as of this PR, shipping an unreachable property is a real cost regardless of future plans, and nothing in the diff or docs indicates a staged follow-up specifically for this property (the docs instead describe it as already active, which is itself the deeper problem — see next finding).

---

### HIGH: Documentation shipped in this PR references a mechanism that does not exist in the code shipped by this PR

**Issue:** `AGENTS.md:64` (new file, added by this PR) states: *"Failed stream close — must not run `applyPropositionChangeFor` (see `personalizationDecisionReceivedForEventId`)."* Similarly, `docs/agents/content-card-offline-known-gaps.md:125-140` (also new in this PR) describes a `decisionsReceivedForEventId: Set<String>` that was supposedly "added to `Messaging.swift`" and marks the scenario "RESOLVED"/"Fixed," with a code snippet showing a guard in `endRequestFor`: `guard decisionsArrived || !inProgressPropositions.isEmpty else { ... }`.

Neither `personalizationDecisionReceivedForEventId` nor `decisionsReceivedForEventId` exists anywhere in the actual `Messaging.swift` (or anywhere else in the repo) shipped by this PR. The real `endRequestFor` (`Messaging.swift:1163-1180`) has **no such guard at all** — it unconditionally calls `applyPropositionChangeFor(eventId:)`.

**Evidence:**
- `AGENTS.md:64`
- `docs/agents/content-card-offline-known-gaps.md:125-140`
- `AEPMessaging/Sources/Messaging.swift:1163-1180` (actual `endRequestFor` — no decisions-received guard present)
- Repo-wide grep for `decisionsReceivedForEventId` and `personalizationDecisionReceivedForEventId` returns zero hits

**Why It's a Problem:** `AGENTS.md` is explicitly the project's canonical, agent-facing ground truth (per this very review's own instructions: "Treat them as ground truth for 'why' decisions were made"). An engineer or AI agent following this doc's pointer will search for a symbol that doesn't exist, lose time, and may incorrectly conclude the R2 requirement ("failed fetch must not mutate disk") is unprotected, potentially prompting a redundant/duplicate re-implementation of a guard that (per my read of `fetchPropositions`'s dispatch-timeout closure and `handleEdgeErrorResponse`) appears to already be covered by a different, newer mechanism (network-availability gate + `nonRecoverableErrorEventIds`). Whether or not the underlying protection is actually complete, shipping self-contradictory ground-truth docs in the same PR as the code is a direct violation of "keep docs and code coherent," and it actively increases — not reduces — cognitive load for exactly the audience (AI agents, per this repo's own stated practice) these docs are written for.

**Simpler Alternative:** Update `AGENTS.md:64` and `content-card-offline-known-gaps.md` Scenario 2 to describe the guard mechanism actually shipped (network-availability check in `fetchPropositions` + `nonRecoverableErrorEventIds` check in `applyPropositionChangeFor`), or explicitly mark the old mechanism as superseded/removed with a pointer to the new one.

**Confidence:** 0.85

**Caveats:** I cannot rule out that `decisionsReceivedForEventId` existed in an earlier iteration of this same branch and was refactored away by a later commit within the same PR, with the doc simply not updated in lockstep — which is the most likely explanation and doesn't change the finding's validity (stale docs in the final PR state are still stale docs).

**Challenge:** If the guard's absence is intentional (i.e., the network-availability gate at the top of `fetchPropositions` combined with the 10s dispatch-timeout closure fully replaces the need for a decisions-received guard, because Edge no longer completion-fires for a truly silent zero-decisions case without also firing an error event), then the code may be correct and only the docs are wrong — which is exactly what I'm flagging. I did not exhaustively verify Edge's actual behavior for every silent-failure permutation (that would require tracing `aepsdk-edge-ios`, out of scope for this file list), so I can't rule out a genuine residual gap; either way the doc/code mismatch itself is the actionable item here.

---

## Simplification Opportunities

### MEDIUM: CBE branch left silently asymmetric after persistence revert

**Issue:** `ParsedPropositions.swift:112-115` (the `.jsonContent, .htmlContent, .defaultContent` case for code-based experiences) has no persist gate and no comment explaining why, while the sibling `.feed`/`.contentCard` (`:92-99`) and `.inbox` (`:119-125`) cases both carry explicit `// TODO: gate on shared-state-driven config...` comments about `OFFLINE_AVAILABILITY_ENABLED`.

**Evidence:**
- `AEPMessaging/Sources/ParsedPropositions.swift:112-115`:
  ```swift
  case .jsonContent, .htmlContent, .defaultContent:
      propositionsToCache.add(proposition, forKey: surface)
  ```
- Compare to `:92-99` and `:119-125`, both of which have the `OFFLINE_AVAILABILITY_ENABLED`-gated persist call plus explanatory comment
- `docs/agents/inbox-cbe-offline-handoff.md:13-48` (shipped in this PR) describes CBE disk persistence (`codeBasedPropositionsToPersist`, `CODE_BASED_PROPOSITIONS`, `cache.updateCodeBasedPropositions`) as if implemented — none of these symbols exist in the current source

**Why It Matters:** A reader who diffs this file against the bundled doc will see CC and inbox both persisting (matching the doc) and reasonably conclude CBE's memory-only behavior is a bug or an oversight, not a deliberate revert — wasting investigation time and risking someone "fixing" it by re-adding CBE disk persistence without understanding why it was pulled.

**How to Simplify:** Add a one-line comment at `:112-113`, e.g.: `// CBE (code-based experience) disk persistence intentionally reverted for this release — see MOB-XXXX. Cached in-memory only.`

**Confidence:** 0.85

---

### MEDIUM: Parallel per-eventId collections instead of one keyed struct

**Issue:** `requestedSurfacesForEventId: [String: [Surface]]` (`Messaging.swift:83-87`) and `nonRecoverableErrorEventIds: Set<String>` (`:97-101`) are two independently-maintained collections keyed by the same event-id string, with add/remove lifecycles that must be kept in sync by hand across two separate call sites (`beginRequestFor`/`endRequestFor`, and the timeout closure inside `fetchPropositions`).

**Evidence:**
- Declarations: `Messaging.swift:83-87`, `:97-101`
- Insert: `:1157` (surfaces, in `beginRequestFor`), `:1451` (error flag, in `handleEdgeErrorResponse`)
- Symmetric removal site #1: `endRequestFor`, `:1168` and `:1171`
- Symmetric removal site #2: `fetchPropositions` timeout closure, `:1056` and `:1057`

**Why It Matters:** I confirmed both removal sites are currently symmetric (no live leak today), but this is maintained by convention, not by the type system. This is a textbook "parallel collections" pattern — any future change that adds a third cleanup path, or that edits one removal call without noticing its sibling, silently desyncs the two collections (e.g., a `nonRecoverableErrorEventIds` entry could survive after its `requestedSurfacesForEventId` entry is gone, quietly changing behavior of a completely unrelated later request that happens to reuse... actually eventIds are UUIDs so reuse isn't the risk; the risk is unbounded growth of one Set if a future edit only cleans up the other collection).

**Simpler Alternative:** Replace both with a single `[String: RequestState]` where `struct RequestState { let surfaces: [Surface]; var failed: Bool = false }`. `beginRequestFor` creates one entry; `handleEdgeErrorResponse` mutates `.failed` on the existing entry; both existing removal call sites become one `removeValue(forKey:)` each instead of two. This structurally eliminates the possibility of the two pieces of state disagreeing about which event IDs are in flight.

**Confidence:** 0.75

**Caveats:** This is a refactor suggestion for a currently-correct design, not a bug fix — the risk is future maintenance, not present behavior.

**Challenge:** Keeping them separate does have a minor benefit: `nonRecoverableErrorEventIds.contains(eventId)` is a slightly cheaper check than `requestedSurfacesForEventId[eventId]?.failed == true` in the hot path of `applyPropositionChangeFor`, though this difference is immaterial at Set/Dictionary scale for this use case (at most a handful of in-flight requests).

---

### MEDIUM: One shared `surfacesToRemove` value applied to three independent disk stores

**Issue:** `applyPropositionChangeFor` (`Messaging.swift:1182-1228`) computes a single `surfacesToRemove` value from `requestedSurfaces.minus(returnedSurfaces)`, where `returnedSurfaces` is derived from the union of `inProgressPropositions.keys` across *all* proposition types combined (`:1202`), then applies that same removal set uniformly to the IAM (`:1209`), content-card (`:1210`), and inbox (`:1211`) disk writes.

**Evidence:**
- `Messaging.swift:1202-1211`
- `docs/agents/content-card-offline-known-gaps.md:12-121` (Scenario 1, shipped in this same PR) documents this exact code path as the root cause of a confirmed, currently-unfixed bug: a surface that returns IAM propositions but zero CC propositions is not added to `surfacesToRemove` (because the surface key is still present via the IAM data), so a CC campaign that ends is never evicted from disk while an IAM campaign remains live on the same surface

**Why It Matters:** This is a case where a "simple," DRY-looking single computation (one removal set for three stores) is actually **under-differentiated** for the problem — the three disk stores have independent lifecycles (a surface can lose its CC campaign while keeping its IAM campaign), but the code treats "any proposition type still present for this surface" as "don't evict anything for this surface" across all three stores. The PR's own bundled documentation confirms this produces stale offline data, which is precisely the kind of correctness cost that "simplify first, differentiate never" produces.

**How to Simplify:** Compute a per-type removal set from each `parsedPropositions.*ToPersist.keys`, as `content-card-offline-known-gaps.md:107-121` itself proposes:
```swift
let ccReturnedSurfaces = Array(parsedPropositions.contentCardPropositionsToPersist.keys)
let ccSurfacesToRemove = requestedSurfaces.minus(ccReturnedSurfaces)
cache.updateContentCardPropositions(parsedPropositions.contentCardPropositionsToPersist, removing: ccSurfacesToRemove)
```
repeated for IAM and inbox independently.

**Confidence:** 0.8 (the bug itself is documented and not something I need to independently re-derive; my contribution is flagging it as a complexity/design root cause relevant to this review, not merely a correctness bug)

**Caveats:** This is arguably more a correctness finding than a pure complexity finding, and the PR's own doc already flags it as a known, deliberately-deferred gap (not something introduced silently) — I'm including it here because the *reason* it exists is a complexity/simplification decision (one shared computation instead of three independent ones) squarely within this review's remit, and other reviewers (code/correctness) may not have visibility into `content-card-offline-known-gaps.md` since it's a docs file.

**Challenge:** The doc explicitly frames this as low-risk today because IAM and CC campaigns conventionally target different surface URIs in standard AJO deployments, so the fix may reasonably be deferred rather than done in this PR — I'm not asserting it must block this PR, only that it's the direct product of the "one simple shared value" design choice being flagged here.

---

### LOW: Forwarding overload could be a default parameter

**Issue:** `getPropositionsForSurfaces(_ surfaces:, _ completion:)` (`Messaging+PublicAPI.swift:159-162`) is a pure 1-line forwarder to the `usePersistedContentCards:` overload.

**Evidence:**
- `Messaging+PublicAPI.swift:159-162` (forwarder) vs. `:171-214` (real implementation)
- Precedent in the same file: `handleNotificationResponse(_:urlHandler:closure:)` (`:29-32`) already uses default parameter values (`urlHandler: ((URL) -> Bool)? = nil`, `closure: ((PushTrackingStatus) -> Void)? = nil`) on an `@objc`-exposed method, proving the pattern is available and already used elsewhere in this exact file

**Why It Matters:** Minor — saves ~6 lines and one fewer symbol for callers/docs to reason about. Not a real duplication-of-logic problem since the forwarder is trivial.

**How to Simplify:** Add `usePersistedContentCards: Bool = false` directly to `getPropositionsForSurfaces(_:usePersistedContentCards:_:)` and delete the 2-argument forwarder. Confirmed via grep that existing Swift call sites use trailing-closure syntax (`getPropositionsForSurfaces(surfaces) { ... }`), which remains valid Swift syntax when a defaulted middle parameter is omitted, so this would not break any of the current 4 call sites across `Messaging+UIPublicAPI.swift`, `InboxUI.swift`, and the demo app.

**Confidence:** 0.6

**Caveats:** The `@objc(getPropositionsForSurfaces:usePersistedContentCards:completion:)` selector would need to stay on the merged method, and the ObjC surface would be unaffected either way since ObjC never sees Swift default values regardless of which method they're attached to. I did not verify this against the actual `@objc` selector conflict rules for a case where an older 2-argument ObjC selector also existed for this same base name (it doesn't appear to, since the old `getPropositionsForSurfaces(_:_:)` overload was never marked `@objc` in the diff).

**Challenge:** Keeping the explicit 2-arg overload does have a minor documentation/discoverability benefit — some engineers prefer scanning autocomplete for a "simple" overload without scrolling through the full parameter doc-comment of the flagged version. This is a stylistic judgment call, not a clear-cut win either way, hence LOW severity.

---

### LOW: Test boilerplate — 3x structurally duplicated cache tests

**Issue:** The 6 new tests in `Cache+MessagingTests.swift` (content-card get/set, inbox get/set) are structurally near-identical to the pre-existing IAM proposition tests in the same file — same shape (`testXPropositionsHappy`, `testXPropositionsNoneInCache`, `testUpdateXPropositionsHappy`), differing only in the cache key constant and surface/proposition fixture values.

**Evidence:**
- `AEPMessaging/Tests/UnitTests/Cache+MessagingTests.swift` (diff adds 77 lines, all following the same 3-tests-per-cache-key template already established for `propositions`)
- Underlying production code already factors this into one shared helper (`Cache+Messaging.swift:74-139`, `propositionsByKey`/`updatePropositionsByKey`)

**Why It Matters:** Low-priority; the duplication is between test files (not production code), and having explicit, readable per-scenario tests (DAMP) is often preferable to a parameterized helper for test suites, since it keeps failure messages self-explanatory. Flagging only because the underlying implementation is already a single shared helper, so a table-driven test (`for key in [PROPOSITIONS, CONTENT_CARD_PROPOSITIONS, INBOX_PROPOSITIONS] { ... }`) would cut ~60 lines with no loss of coverage.

**How to Simplify:** Optional: a small parameterized helper function taking the cache-key constant and getter/setter closures, called once per key. Not required — current tests are clear and correct.

**Confidence:** 0.5

---

## Summary
- Complexity issues found: 2 (both HIGH — dead code, doc/code drift)
- Over-engineering patterns: 0 (the headline new mechanism is appropriately scoped, not over-built)
- UX friction issues: 0 (this module has no end-user-facing UI surface in scope; the public API's UX is addressed under Q1/simplification, not as a standalone UX section, since callers are internal SDK integrators, not end users — the API shape is consistent with existing SDK conventions and does not introduce confusing new patterns)
- Simplification opportunities: 5 (2 MEDIUM design-consequence findings tied to documented bugs, 1 MEDIUM comment-hygiene fix, 2 LOW)

**Recommendation:** REQUEST CHANGES

**Rationale:** Not because the core mechanism is over-engineered — it isn't — but because (a) shipping a dead, never-wired `offlineAvailable` property alongside the hardcoded flag that supersedes it, and (b) shipping `AGENTS.md`/known-gaps docs in the same PR that reference a guard mechanism absent from the actual code, are both cheap-to-fix but real sources of future confusion for exactly the audience (engineers and AI agents) these artifacts are meant to serve. Neither requires a redesign — both are a documentation/cleanup pass away from resolved. The MEDIUM findings (CBE comment, parallel collections, shared removal set) are lower urgency and could reasonably be addressed in a fast follow-up rather than blocking this PR outright, but the two HIGH findings should be resolved before merge since they actively mislead future readers of this repo's own agent-facing ground truth.

---

## Confidence Assessment

**Overall review confidence:** 0.78

**What I could adequately assess:**
- All 7 in-scope source files, read in full (not diff-only) to understand complete context
- All 6 focus questions, each backed by direct grep/read evidence rather than inference
- The overload/default-parameter question, cross-checked against an existing in-file precedent
- The parallel-collection lifecycle question, traced to both add and both remove call sites
- The CBE asymmetry and dead-property findings, confirmed via repo-wide grep (zero other references)

**What I could NOT adequately assess:**
- Whether the network-availability gate + `nonRecoverableErrorEventIds` combination in the current code fully covers every scenario the old (now-removed-but-still-documented) `decisionsReceivedForEventId` guard used to cover — this would require tracing Edge extension internals (`aepsdk-edge-ios`), which is a different repo and out of scope for this file list
- Runtime/concurrency behavior of the `queue.sync`/`queue.async` property wrappers under real load (static reading only)
- Whether UI-layer callers (`Messaging+UIPublicAPI.swift`, `InboxUI.swift`, explicitly out of scope) introduce any additional overload duplication beyond the simple forwarding I confirmed via grep

**Mitigations applied:**
- Used repo-wide grep (not just diff reading) to positively confirm absence of symbols (`offlineAvailable` callers, `decisionsReceivedForEventId`, `codeBasedPropositions*`) rather than relying on diff context alone, which could have missed usages outside the diffed hunks
- Cross-referenced the PR's own bundled documentation (`docs/agents/*.md`) against the actual shipped code line-by-line for the specific claims relevant to each focus question, rather than treating the docs as automatically accurate
- Flagged confidence explicitly lower (0.6-0.75) on findings that are refactor suggestions for currently-correct behavior, versus higher confidence (0.85-0.9) on findings backed by direct contradiction between doc and code
