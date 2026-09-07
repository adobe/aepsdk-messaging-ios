---
title: Network Availability Layer
entity_type: concept
tier: knowledge
confidence: 0.72
source: inferred
tags: [architecture, offline, network-gate, core-messaging-bridge]
relationships:
  - type: applies_to
    target: "Core Messaging Engine"
  - type: applies_to
    target: "Architecture Overview"
---

# Network Availability Layer

**Documentation:** `docs/agents/network-availability-layer.md`

**Purpose:** Centralized decision point for whether Messaging should make network calls (Edge) or fall back to offline (disk cache).

## Design

- **Query:** `MobileCore.isNetworkAvailable()` before making Edge requests
- **Behavior:**
  - Online: proceed with network fetch
  - Offline: skip Edge, serve disk cache on GET
  - Failed fetch: cache untouched; apply zero-decisions guard

## Impact on Messaging Flow

| Operation | Network | Offline | Behavior |
|-----------|---------|---------|----------|
| `getPropositions()` | Edge call | Disk hydration | Immediate return (no wait for network) |
| `updatePropositions()` | Edge call | Skip Edge, fail gracefully | Disk unchanged; trigger zero-decisions guard |
| Cold start | Hydrate from disk first | N/A | Parallel: try Edge + load disk |

## Key Files

- `AEPMessaging/Sources/Messaging.swift` — Query point
- `AEPMessaging/Sources/ClassExtensions/Cache+Messaging.swift` — Disk read/write
- Integration: `MobileCore.isNetworkAvailable()` from AEPCore

## Known Gotchas

- **Network gate is one-time check:** If network status changes mid-request, current request completes as-is (no automatic retry on status change)
- **Edge timeout:** Network available but Edge times out = failed fetch = cache stays put

Aliases / also known as: Network gating, offline gate, network availability check
