---
title: "Hub: Messaging.swift"
entity_type: observation
tier: knowledge
confidence: 0.75
source: inferred
tags: [hub, core, messaging-engine, entry-point, api]
relationships:
  - type: applies_to
    target: "Core Messaging Engine"
  - type: applies_to
    target: "Architecture Overview"
---

# Hub File: Messaging.swift

**Path:** `AEPMessaging/Sources/Messaging.swift`

**CodeRank:** Central (9.5K LOC, widely referenced)

**Key Symbols:**
- `Messaging` — Main SDK singleton
- `hydrateContentCardRulesEngineFromDisk()` — Cold-start offline hydration
- `endRequestFor()` — Guard against failed streams
- `applyPropositionChangeFor()` — Merge propositions, update disk/memory
- `personalizationDecisionReceivedForEventId()` — Event listener for Edge responses

## When You Edit Here

**Scenarios:**
- Adding new API surface for proposition fetching/updating
- Changing offline persistence strategy (disk key, format)
- Adjusting network availability gating logic
- Modifying event handling flow (Edge → apply → render)

## Criticality

This file is the central hub for all Messaging lifecycle. Changes here ripple to:
- Public API (`Messaging+PublicAPI.swift`)
- UI layer (gets propositions from here)
- Cache/persistence (writes to Core Cache)

## Architecture Notes

- Event-driven: listens for Edge + Core events
- State is mostly immutable (propositions) + mutable (in-memory cache)
- Offline-first: tries disk before network on cold start

Aliases / also known as: Messaging singleton, main SDK, messaging-core.swift, proposition engine
