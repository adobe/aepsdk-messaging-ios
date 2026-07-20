---
last_compiled_date: 2026-07-13
version: "1.0"
---

# AGENTS.md — aepsdk-messaging-ios

Adobe Experience Platform **Messaging** iOS SDK (`AEPMessaging`). In-App Messages (IAM), Content Cards, Inbox UI, push, Live Activities.

## Before you change code

1. **Content Card offline / persistence** — read the implementation guide:
   - [`docs/agents/content-card-offline-implementation.md`](docs/agents/content-card-offline-implementation.md)
2. **Network availability layer (Core + Messaging gate)** — read before changing offline/network gating:
   - [`docs/agents/network-availability-layer.md`](docs/agents/network-availability-layer.md)
3. **Inbox + CBE offline persistence + simulation handoff** — read this before touching ParsedPropositions, Cache+Messaging, or InboxUI:
   - [`docs/agents/inbox-cbe-offline-handoff.md`](docs/agents/inbox-cbe-offline-handoff.md)
4. Human-facing specs (if present in repo):
   - `Documentation/ContentCardOfflineDiscoveryAndImplementation.md`
   - `Documentation/ContentCardOfflineAvailability.md`

## Build & test

```bash
make pod-install # first time / after Podfile change
make open        # AEPMessaging.xcworkspace
make unit-test
make functional-test
make lint
```

Simulator destination is defined in `Makefile` (`IOS_DESTINATION`).

## Content Card offline — agent summary

| Topic | Decision / state |
|-------|------------------|
| **Disk key** | `contentCardPropositions` (separate from IAM `propositions`) |
| **`resetIdentities`** | **Clears** CC cache (`clearContentCards`) — unlike IAM |
| **Cold start** | No auto-hydrate; opt-in `usePersistedContentCards: true` on get |
| **Failed fetch** | Disk unchanged; `endRequestFor` guard on zero decisions |
| **Successful update** | `cache.updateContentCardPropositions` in `applyPropositionChangeFor` |
| **Dismiss cold-start flash** | **Open** — Option B: evict memory + disk on `track(.dismiss)` |
| **Empty `items[]`** | **Open** — do not persist shells (PLATIR-64717) |
| **Public clear API** | **Open** — `clearCachedContentCardPropositions()` |
| **Network gate** | `MobileCore.isNetworkAvailable()` skips Edge on update; get is immediate + disk hydrate |

## Key source files (offline CC)

| File | Role |
|------|------|
| `AEPMessaging/Sources/Messaging.swift` | `hydrateContentCardRulesEngineFromDisk`, `endRequestFor` guard, `retrieveMessages` |
| `AEPMessaging/Sources/ClassExtensions/Cache+Messaging.swift` | `contentCardPropositions` get/set |
| `AEPMessaging/Sources/ParsedPropositions.swift` | `contentCardPropositionsToPersist` |
| `AEPMessaging/Sources/Messaging+PublicAPI.swift` | `getPropositionsForSurfaces`, `updatePropositionsForSurfacesWithCompletionHandler` |
| `AEPMessaging/Sources/UI/Messaging+UIPublicAPI.swift` | `getContentCardsUI(..., usePersistedContentCards:)` |
| `TestApps/MessagingDemoAppSwiftUI/AppPages/CardsView.swift` | Demo offline / Log Props flows |

## Do not assume

- **Dismiss writes `disqualify` to Event History** — it writes **`dismiss`**; journey rules insert **`disqualify`** later.
- **IAM parity for dismiss cache** — CC feeds need disk eviction on dismiss (Option B); IAM keeps rules on disk.
- **Refresh persists** — only successful `updatePropositions` writes disk.
- **Failed stream close** — must not run `applyPropositionChangeFor` (see `personalizationDecisionReceivedForEventId`).

## Open implementation work (priority)

See [`docs/agents/content-card-offline-implementation.md`](docs/agents/content-card-offline-implementation.md) §10.

1. **P0** — Option B dismiss eviction
2. **P0** — Functional E2E offline tests on device
3. **P1** — Public `clearCachedContentCardPropositions()`
4. **P1** — Skip persist empty `items[]` in `ParsedPropositions`
