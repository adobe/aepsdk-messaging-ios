---
title: Edge Event Streaming & Personalization
entity_type: observation
tier: knowledge
confidence: 0.7
source: inferred
tags: [architecture, edge, events, personalization, streaming]
relationships:
  - type: applies_to
    target: "Core Messaging Engine"
---

# Edge Event Streaming & Personalization

**Implementation:** `Messaging+EdgeEvents.swift`

**Purpose:** Listen for personalization decisions from Adobe Experience Platform Edge and apply them to the SDK state.

## Event Flow

```
Edge Network
    ↓
personalizationDecisionReceivedForEventId(eventId, decisions)
    ↓
applyPropositionChangeFor(decisions, eventId)
    ↓
Update in-memory state + write Cache + notify listeners
```

## Key Responsibilities

1. **Decision Reception**
   - `personalizationDecisionReceivedForEventId()` — Event listener callback
   - Parse Edge response into Propositions

2. **State Merge**
   - `applyPropositionChangeFor()` — Merge new propositions with existing state
   - Update both in-memory cache + disk (Cache+Messaging)

3. **Error Handling**
   - Guard: if Edge stream closes without decision, don't apply partial state
   - Fail gracefully: zero decisions = keep existing rules

## Known Gotchas

- **Streaming close without data:** Must NOT run `applyPropositionChangeFor()` if stream fails
- **Batch vs. stream:** Edge may send multiple decisions in batch or stream; handle both cases
- **Event ID tracking:** Track which events have been processed to avoid re-applying

## Testing Strategy

- **Unit:** Mock Edge responses, verify state merge
- **Integration:** Real Edge connection (requires test workspace)
- **Offline:** Verify behavior when Edge unavailable (network gate)

Aliases / also known as: Edge events, personalization, decision streaming
