---
title: Data Models & Schemas
entity_type: concept
tier: knowledge
confidence: 0.7
source: inferred
tags: [domain, data-models, schemas, propositions, parsing, codable]
relationships:
  - type: applies_to
    target: "Architecture Overview"
  - type: applies_to
    target: "Core Messaging Engine"
---

# Data Models & Schemas

**Layer:** Domain / Data Structures

**Directory:** `AEPMessaging/Sources/` → Message.swift, ContentCard.swift, Schemas/

## Core Type Hierarchy

```
Proposition
├── Message (fullscreen in-app message)
│   ├── FullscreenMessage (template variant)
│   └── HTML/Native content variants
├── ContentCard (feed item)
│   ├── Items[] (structured content blocks)
│   └── Metadata (tracking, expiry)
└── Metadata (tracking, interaction hints)
```

## Key Files

| File | Purpose |
|------|---------|
| `Message.swift` | IAM proposition model; fullscreen message structure |
| `ContentCard.swift` | Feed card model; supports multiple item types |
| `Feed.swift` | Container for multiple ContentCards |
| `FeedItem.swift` | Individual feed item (title, body, image, CTA) |
| `Schemas/` | JSON schema definitions + Codable conformance |
| `ParsedPropositions.swift` | Conversion logic: raw Edge data → cached format |

## Key Responsibilities

1. **Decoding**
   - Parse Edge JSON responses into typed structs (Codable)
   - Validate required fields, provide sensible defaults

2. **Persistence**
   - Convert Propositions → persistent format (disk-friendly JSON)
   - `contentCardPropositionsToPersist()` — filter/transform before write

3. **Rendering**
   - Models expose render-ready properties (images as URLs, text templated)
   - Support fallbacks for missing optional fields

## Known Patterns

- **Codable conformance:** All models are Codable (JSON round-trip safe)
- **Optional fields:** Graceful degradation if Edge omits non-critical data
- **Empty items handling:** OPEN — do not persist shells with empty `items[]` (PLATIR-64717)

Aliases / also known as: Message, ContentCard, Proposition, model definitions
