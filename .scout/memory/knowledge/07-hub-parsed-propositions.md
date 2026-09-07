---
title: "Hub: ParsedPropositions.swift"
entity_type: observation
tier: knowledge
confidence: 0.7
source: inferred
tags: [hub, data-models, persistence, codable, parsing]
relationships:
  - type: applies_to
    target: "Data Models & Schemas"
  - type: applies_to
    target: "Content Card Offline Persistence"
---

# Hub File: ParsedPropositions.swift

**Path:** `AEPMessaging/Sources/ParsedPropositions.swift`

**CodeRank:** High (bridges Edge JSON → persistent format)

**Key Symbols:**
- `ParsedPropositions` — Wrapper for decoded proposition arrays
- `contentCardPropositionsToPersist()` — Filter + format for disk
- Codable conformance for Edge JSON deserialization

## When You Edit Here

**Scenarios:**
- Changing Content Card persistence format (keys, structure)
- Adding new proposition type (beyond Message/ContentCard)
- Handling Edge payload evolution (new fields, deprecations)
- Optimizing disk size for large feeds

## Criticality

Bridge between Edge (unstructured JSON) and Cache (typed structures). Changes here:
- Affect what gets written to disk via `Cache.updateContentCardPropositions()`
- Ripple to offline hydration in `Messaging.swift`
- Impact UI rendering if model structures change

## Known Open Items

- **PLATIR-64717:** Do not persist shells (cards with empty `items[]`)
- Filter empty results before write to disk

Aliases / also known as: Proposition parser, persistence converter, codable bridge
