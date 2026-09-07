---
title: Core Messaging Engine
entity_type: concept
tier: knowledge
confidence: 0.75
source: inferred
tags: [domain, core, messaging, engine, personalization, offline, network-gate]
relationships:
  - type: applies_to
    target: "Architecture Overview"
  - type: applies_to
    target: "Network Availability Layer"
  - type: applies_to
    target: "Content Card Offline Persistence"
---

# Core Messaging Engine

**Layer:** Domain / Core Event Processing

**Key Entry Points:**
- `Messaging.swift` — Main SDK singleton; proposition fetch/update, event handling
- `Messaging+PublicAPI.swift` — Surface APIs: `getPropositionsForSurfaces()`, `updatePropositionsForSurfaces()`
- `Messaging+EdgeEvents.swift` — Edge event streaming, personalization decision processing

## Core Responsibilities

1. **Proposition Management**
   - Request propositions from Edge (surfaces: `mobileapp://messaging`)
   - Persist successful responses to disk (ContentCard + IAM separately)
   - Hydrate on cold start (`hydrateContentCardRulesEngineFromDisk`)

2. **Network Gating**
   - Query `MobileCore.isNetworkAvailable()` before Edge call
   - Skip network on offline; serve disk cache immediately for GET
   - Fail gracefully: zero decisions = use cached rules

3. **Event Dispatch**
   - `personalizationDecisionReceivedForEventId()` — Apply new propositions
   - `applyPropositionChangeFor()` — Merge into in-memory state + write disk
   - Track `endRequestFor()` to guard against streaming close without data

## Key Symbols

| Symbol | Role |
|--------|------|
| `Messaging` | Singleton facade; event listener on AEPCore |
| `Message` | In-App Message (fullscreen + template variants) |
| `ContentCard` | Card in a feed (structured content) |
| `Proposition` | Wrapper: payload (Message/ContentCard) + metadata |
| `ContentCardRulesEngine` | Cached rules for cold-start rendering |

## Known Gotchas

- **Dismiss eviction:** CC dismiss writes `dismiss` event; journey rules add `disqualify` later (not immediate)
- **Refresh doesn't persist:** Only successful `updatePropositions` writes disk; failed fetch leaves cache untouched
- **Streaming close:** If Edge stream closes without sending decision, must NOT run `applyPropositionChangeFor` (guard with error state)

Aliases / also known as: Messaging core, proposition engine, personalization layer
