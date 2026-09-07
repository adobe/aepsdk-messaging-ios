---
title: "Docs: AGENTS.md"
entity_type: concept
tier: reference
confidence: 0.8
source: inferred
tags: [docs, root, agents, implementation-guide, offline]
---

# Docs: AGENTS.md

**Path:** `/AGENTS.md` (repository root)

**Purpose:** Agent guidance on AEPMessaging implementation, architecture decisions, and offline persistence strategy.

## Key Topics Covered

1. **Before You Change Code**
   - Content Card offline/persistence implementation guide
   - Network availability layer (Core + Messaging gate)
   - Inbox + CBE offline persistence + simulation handoff

2. **Build & Test**
   - Standard make targets: `pod-install`, `open`, `unit-test`, `functional-test`, `lint`

3. **Content Card Offline — Design Table**
   - Disk key: `contentCardPropositions`
   - resetIdentities: **clears** CC cache (unlike IAM)
   - Cold start: opt-in via `usePersistedContentCards: true`
   - Failed fetch: disk unchanged; guard on zero decisions
   - Empty items[]: OPEN — do not persist shells (PLATIR-64717)

4. **Open Implementation Work (Priority)**
   - P0: Option B dismiss eviction
   - P0: Functional E2E offline tests on device
   - P1: Public `clearCachedContentCardPropositions()`
   - P1: Skip persist empty `items[]` in ParsedPropositions

## When to Read

- Before starting work on offline/persistence features
- When implementing new proposition types
- Before making changes to network gating logic
- To understand Design decisions (do NOT assume patterns)

## Related Docs

- `docs/agents/content-card-offline-implementation.md` — Deep dive on offline architecture
- `docs/agents/network-availability-layer.md` — Network gate design
- `docs/agents/inbox-cbe-offline-handoff.md` — Inbox persistence strategy

Aliases / also known as: AGENTS, agent guidance, implementation guidelines
