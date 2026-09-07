# HLD Review — ui_layer (PR #495)

## Summary
The new `usePersistedContentCards` flag is name-identical but semantically inconsistent across its three call sites, and `InboxUI` bakes it into an immutable, construction-time switch that bypasses the SDK's existing dynamic network-availability gate instead of composing with it — both are real architectural footguns for API consumers, on top of a silent error-contract change in `getContentCardsUI`.

---

## Design Flaws

### CRITICAL Flaws

No critical flaws identified.

---

### MAJOR Flaws

**[MAJOR-1]: One flag name, two different behavioral contracts, no way to tell which one you're getting**
- **What's Wrong:** `usePersistedContentCards` is documented and implemented differently depending on which of the three public entry points is used:
  - On `Messaging.getPropositionsForSurfaces(_:usePersistedContentCards:_:)` (persistence_core) it means "additionally hydrate disk into the in-memory cache and read from it" — an additive read-mode toggle. Network is never part of this call's contract either way (per its own doc: "Recommended usage: call `updatePropositionsForSurfacesWithCompletionHandler` first...").
  - On `Messaging.getContentCardsUI(for:usePersistedContentCards:...)` (`AEPMessaging/Sources/UI/Messaging+UIPublicAPI.swift:46-51`) the flag is forwarded verbatim to `getPropositionsForSurfaces` — same additive-read semantics, no network implication, consistent with core.
  - On `Messaging.getInboxUI(for:usePersistedContentCards:...)` / `InboxUI.performRefresh()` (`AEPMessaging/Sources/UI/Inbox/InboxUI.swift:162-177`), the same flag now ALSO suppresses the call to `Messaging.updatePropositionsForSurfaces` entirely — a network-mode toggle layered on top of the read-mode toggle. This behavior does not exist for the other two call sites.
- **Impact:** A developer who learns the flag's meaning from `getContentCardsUI` (or from the core API's doc comment) will reasonably assume `getInboxUI(usePersistedContentCards: true)` also just "additionally reads disk" while still keeping normal update/refresh behavior. Instead it silently and permanently removes the network call from that `InboxUI` instance's entire lifecycle. There is no compiler signal and no runtime warning — the divergence is purely in prose documentation that lives in three different places.
- **Evidence:** `AEPMessaging/Sources/UI/Inbox/InboxUI.swift:99-102` (doc comment on the stored property, describing the network-skip behavior unique to this call site) vs. `AEPMessaging/Sources/Messaging+PublicAPI.swift:164-169` (core doc: "in addition to the in-memory cache... When false (default), only in-memory propositions are returned" — no mention of network at all).
- **Recommended Fix:** Either (a) rename the `InboxUI`/`getInboxUI` parameter to something that names the stronger behavior explicitly (e.g. `skipNetworkRefresh` or `offlineOnly`), or (b) split it into two orthogonal parameters (`hydrateFromDisk: Bool` and `skipNetworkUpdate: Bool`) so the two independent decisions aren't conflated under one name that already has a narrower meaning elsewhere in the same SDK.

---

**[MAJOR-2]: `InboxUI`'s persistence mode is a static, construction-time decision that bypasses the SDK's own dynamic network-availability gate instead of using it**
- **What's Wrong:** `updatePropositionsForSurfaces` already self-gates on `MobileCore.isNetworkAvailable()` and completes immediately (no Edge dispatch, no 5–10s timeout) when the device is offline — this is the purpose-built mechanism documented in `docs/agents/network-availability-layer.md` and implemented at `AEPMessaging/Sources/Messaging.swift:367-374`. Given that, `InboxUI` did not need a manual "never call network" switch to get good offline behavior — simply always calling `updatePropositionsForSurfaces` already yields fast, non-blocking offline behavior automatically, and resumes live updates the moment the device reconnects.
  Instead, this PR adds `usePersistedContentCards` as a `private let` (immutable) set once in `init` (`InboxUI.swift:102,116`), and `performRefresh()` uses it to permanently skip the `updatePropositionsForSurfaces` call for the entire lifetime of that `InboxUI` instance (`InboxUI.swift:162-177`). This is a static, developer-chosen mode, not a reaction to actual connectivity — it does not self-heal. An `InboxUI` constructed with `usePersistedContentCards: true` while offline will *never* fetch live data again, even after the device reconnects, unless the caller discards the object and constructs a new one.
- **Impact:** Two independent, non-composing "offline" mechanisms now exist in the same SDK: (1) the dynamic, reconnect-aware gate in `Messaging.swift`/`AEPCore`, and (2) this static, construction-time UI-layer switch. A real integrator wiring up pull-to-refresh (`isPullToRefreshEnabled`, `InboxUI.swift:77`, driving `refreshAsync()` at `InboxUI.swift:143-149`) on an `InboxUI` built with `usePersistedContentCards: true` will find that the pull-to-refresh gesture — which users universally expect to fetch fresh server data — instead only ever re-reads (and re-hydrates from disk on every pull, per `Messaging.swift:1374-1377`) the same persisted cache, indefinitely, regardless of whether the network is actually available. There is no parameter on `refresh()`/`refreshAsync()` and no mutable property to force a one-off live refresh; the only escape is to construct an entirely new `InboxUI`, which drops `@Published` state, view identity, and any listener/customizer wiring the app already set up.
- **Evidence:** `InboxUI.swift:99-124` (immutable flag, no setter, no public getter); `InboxUI.swift:158-177` (`performRefresh` branches once on the immutable flag with an early `return`, permanently short-circuiting the network path); `docs/agents/network-availability-layer.md:74-85,201-225` (the existing dynamic gate this duplicates/bypasses).
- **Recommended Fix:** Reconsider whether `InboxUI` needs this flag at all — relying on the existing `isNetworkAvailable()` gate inside `updatePropositionsForSurfaces` may already deliver the desired offline UX without any new API surface. If an explicit "persisted-only, cold-start" mode is still wanted (e.g., to force disk hydration without even attempting the fast network no-op), expose it as a mutable property or a `refresh(usePersistedContentCards: Bool = false)` parameter rather than an immutable constructor argument, so pull-to-refresh and programmatic refresh calls can opt back into live data without recreating the object.

---

**[MAJOR-3]: `getContentCardsUI` silently changes its error contract for all existing callers, not just new adopters of the flag**
- **What's Wrong:** Previously, when the persistence_core response dictionary had no entry for the requested surface, `getContentCardsUI` failed with `.failure(ContentCardUIError.dataUnavailable)`. This PR changes that unconditionally — for both the new flagged overload and the pre-existing default-`false` call path — to treat a missing/absent surface entry the same as an empty array: `.success([])` (`AEPMessaging/Sources/UI/Messaging+UIPublicAPI.swift:57`, replacing the old `guard let ... else { completion(.failure(...)) }`). `ContentCardUIError.dataUnavailable` (`ContentCardUIError.swift:19`) now has no remaining production call site in this file and appears unreachable from this API.
- **Impact:** This is a behavior change bundled into a PR framed as purely additive (new optional parameter/overload). Any existing app that branches on `.failure` vs `.success` to distinguish "no data available yet" from "confirmed empty" will silently stop seeing that failure branch after upgrading, even if it never touches `usePersistedContentCards`. This is exactly the kind of undocumented contract change that should either be called out explicitly in the PR description/changelog or shipped as its own change, since it affects 100% of existing callers, not just those opting into the new flag.
- **Evidence:** `pr495_diff/AEPMessaging/Sources/UI/Messaging+UIPublicAPI.swift.diff` lines 52-57; `AEPMessaging/Sources/UI/ContentCards/ContentCardUIError.swift:19`.
- **Recommended Fix:** Document this as an explicit, intentional API contract change in the PR description (or revert to preserving the original failure path for the case where the surface key is truly absent from the response, only relaxing it for the new persisted-read path if that's the actual intent).

---

### MINOR Flaws

**[MINOR-1]: No introspection of `InboxUI`'s current mode**
- **What's Wrong:** `usePersistedContentCards` is `private` with no public getter (`InboxUI.swift:102`). Combined with MAJOR-2, a consumer wrapping `InboxUI` in their own view model has no way to even detect, let alone change, which mode a given instance is in.
- **Impact:** Makes it harder for app code to build its own compensating logic (e.g., showing a "you're viewing cached content" banner, or deciding whether to offer a manual "go online" action) without the app separately tracking the value it originally passed to `getInboxUI`.
- **Suggestion:** Expose a read-only public property, e.g. `public let usePersistedContentCards: Bool`.

**[MINOR-2]: Persisted-mode refresh re-hydrates from disk on every pull-to-refresh with no debounce**
- **What's Wrong:** Per the core's own doc comment (`Messaging.swift:1361-1364`), setting the flag hydrates content-card and inbox propositions from disk "for ALL requested surfaces" on every call, not only when memory is missing them. Since `InboxUI.performRefresh()` takes this path on every `refresh()`/`refreshAsync()` invocation when the mode is persisted-only, every pull-to-refresh gesture triggers a full disk read even though the on-disk data cannot have changed since the network was never contacted.
- **Impact:** Wasted disk I/O on every user-triggered refresh in offline mode; not correctness-breaking, but a needless cost for a UI feature (pull-to-refresh) that in this mode can never produce new data.
- **Suggestion:** Consider a lightweight guard (e.g., skip re-hydration if a hydration already occurred and no persisted-cache write has happened since) or explicitly document that pull-to-refresh is a no-op in persisted-only mode so integrators don't enable it for that configuration.

**[MINOR-3]: New behavior paths are untested**
- **What's Wrong:** The only new test (`Messaging+UIPublicApiTest.swift`) exercises the default (`usePersistedContentCards` absent) call path and asserts only that `GET_PROPOSITIONS` is `true` in the dispatched event — it does not assert the value of `USE_PERSISTED_CONTENT_CARDS` in the event data for either the default or the flagged overload, and there is no test for `getInboxUI(usePersistedContentCards: true)`'s network-skip behavior or for `InboxUI.performRefresh()`'s branch at all in this module's file list.
- **Impact:** The two behaviors this review flags as MAJOR-1/MAJOR-2 (semantic divergence, permanent network skip) have no regression coverage at the UI layer, so a future refactor could silently change either without any test failing.
- **Suggestion:** Add tests asserting the event payload's `USE_PERSISTED_CONTENT_CARDS` value for both `getContentCardsUI` overloads, and an `InboxUI`-level test confirming `updatePropositionsForSurfaces` is never invoked when constructed with `usePersistedContentCards: true`.

---

## Verdict

**Recommendation:** APPROVE WITH FIXES

| Severity | Count | Action |
|----------|-------|--------|
| Critical | 0 | — |
| Major | 3 | Should fix before merge |
| Minor | 3 | Track for follow-up |

**Summary:** The UI layer's mechanical forwarding of `usePersistedContentCards` into `getContentCardsUI` is sound, but reusing the same flag name in `InboxUI` to also mean "never call the network, forever, from construction time" is a semantic overload that will mislead API consumers and duplicates a network-availability decision the SDK already makes dynamically and correctly elsewhere. The unrelated tightening of `getContentCardsUI`'s error contract (dataUnavailable → success([])) is a silent breaking change for existing callers that should be called out or reverted. None of these are launch-blocking crashes, but all three MAJOR items should be resolved or explicitly accepted before merge given they affect the SDK's public contract.

---

## Structured Finding Summary

- **Total findings:** CRITICAL: 0, MAJOR: 3, MINOR: 3
- **Overall confidence in this review:** 0.8
- **Areas not fully assessed:**
  - I did not exhaustively verify every call site of `Messaging.updatePropositionsForSurfaces` across the whole SDK to confirm the dynamic network gate (`isNetworkAvailable()`) behaves identically in all Messaging versions/branches; my evidence is from the current `Messaging.swift` and `docs/agents/network-availability-layer.md`, which could be slightly ahead of or behind the exact code in this PR's base commit.
  - I did not review `Messaging.swift`, `ParsedPropositions.swift`, or `Cache+Messaging.swift` in depth (out of scope per the persistence_core review split); MAJOR-2's claim about the core's disk-hydration cost per call is based on the doc comment at `Messaging.swift:1361-1364` rather than a full trace of `hydrateContentCardRulesEngineFromDisk`/`hydrateInboxPropositionsFromDisk`.
  - I did not verify how `InboxView` (SwiftUI, not in this module's file list) wires `isPullToRefreshEnabled` to `refreshAsync()`; this is inferred from the property/method names and doc comments in `InboxUI.swift`.

**Challenge to my own findings:** MAJOR-2 assumes an app author would want live data via pull-to-refresh after a persisted-only cold start — if the intended use case is strictly "fully offline screens that should never touch network" (e.g., a dedicated downloads/kiosk mode), the immutable design is defensible and pull-to-refresh simply shouldn't be enabled alongside it. That intent isn't stated anywhere in the code or docs reviewed, so the finding stands as a documentation/API-clarity gap at minimum, and a design gap if the cold-start-then-refresh use case is in fact intended (which the AGENTS.md "Cold start" row — "No auto-hydrate; opt-in `usePersistedContentCards: true` on get" — suggests it is, since that pattern implies opt-in disk read followed by normal online operation).
