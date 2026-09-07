---
title: Content Card Offline Persistence
entity_type: concept
tier: knowledge
confidence: 0.75
source: inferred
tags: [feature, offline, persistence, content-cards, cache, disk]
relationships:
  - type: applies_to
    target: "Core Messaging Engine"
  - type: applies_to
    target: "Data Models & Schemas"
  - type: applies_to
    target: "Network Availability Layer"
---

# Content Card Offline Persistence

**Documentation:** `docs/agents/content-card-offline-implementation.md`

**Feature:** Content Cards persist to disk and hydrate on cold start (unlike IAM, which only keeps rules).

## Design Decision Table

| Item | Value | Notes |
|------|-------|-------|
| **Disk Key** | `contentCardPropositions` | Separate from IAM `propositions` |
| **resetIdentities Behavior** | **Clears** CC cache | Differs from IAM (which keeps rules) |
| **Cold Start Strategy** | Opt-in: `usePersistedContentCards: true` | No auto-hydrate by default |
| **Failed Fetch** | Disk unchanged | Apply zero-decisions guard to prevent crash |
| **Successful Update** | Write to `Cache.updateContentCardPropositions()` | In-memory + disk sync |
| **Dismiss Behavior** | Writes `dismiss` event; rules add `disqualify` later | Not immediate eviction |
| **Empty items[]** | OPEN — do not persist | PLATIR-64717 (P1 work) |
| **Public Clear API** | OPEN — `clearCachedContentCardPropositions()` | P1 work |

## Implementation Files

| File | Responsibility |
|------|-----------------|
| `Messaging.swift` | `hydrateContentCardRulesEngineFromDisk()`, `endRequestFor()` guard |
| `Messaging+PublicAPI.swift` | `getPropositionsForSurfaces(..., usePersistedContentCards:)` |
| `Cache+Messaging.swift` | `contentCardPropositions` getter/setter |
| `ParsedPropositions.swift` | `contentCardPropositionsToPersist()` |

## Open Work (Priority)

- **P0:** Option B dismiss eviction (clear memory + disk on dismiss)
- **P0:** Functional E2E offline tests on device
- **P1:** Public clear API
- **P1:** Skip persist empty items[] shells

## Cold-Start Flash Prevention

**Option B (Recommended):** Evict on dismiss — remove from both memory and disk to prevent flash on next cold start.

Aliases / also known as: CC offline, card persistence, offline cache, cold-start hydration
