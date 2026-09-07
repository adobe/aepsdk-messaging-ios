---
title: UI Layer (Content Cards + Inbox)
entity_type: concept
tier: knowledge
confidence: 0.72
source: inferred
tags: [domain, ui, swiftui, contentcards, inbox, views, rendering]
relationships:
  - type: applies_to
    target: "Architecture Overview"
  - type: applies_to
    target: "Data Models"
---

# UI Layer — Content Cards & Inbox

**Layer:** Presentation / SwiftUI Components

**Directory:** `AEPMessaging/Sources/UI/` → ContentCards, Inbox, UIElements

## Structure

```
UI/
├── ContentCards/
│   ├── ContentCardUI.swift          # Main view, FeedUI adapter
│   ├── CardContainerUI.swift        # Card item rendering
│   └── [...card templates]
├── Inbox/
│   ├── InboxUI.swift                # Inbox list view
│   ├── InboxMessagesView.swift      # Message display
│   └── [...inbox views]
└── UIElements/
    ├── View+CustomModifiers.swift   # Custom .modifiers
    └── [...shared utilities]
```

## Key Responsibilities

1. **Content Card Display**
   - Render `Feed` (list of `FeedItem` → `ContentCard`)
   - Support custom layouts via templates (banner, carousel, hero)
   - Handle offline: show cached cards on cold start (if `usePersistedContentCards: true`)

2. **Inbox Display**
   - List `Message` items with state tracking (read/archived)
   - Enable deep linking to message content
   - Optional event tracking on interactions

3. **Shared Utilities**
   - View modifiers for styling, animations, accessibility
   - Gesture handlers, layout helpers

## Key Types

| Type | Role |
|------|------|
| `ContentCardUI` | Root view for card feed display |
| `InboxUI` | Root view for message inbox display |
| `FeedUI` | Adapter layer between `Feed` model and SwiftUI |
| `CardContainerUI` | Generic card item renderer (layout agnostic) |

## Integration Points

- **Cold Start:** `getContentCardsUI(..., usePersistedContentCards: true)` → hydrate from disk
- **Event Tracking:** Optional callback on card/message interactions
- **State Updates:** Re-render on proposition change via state publishers

## Design Patterns

- **Model-driven rendering:** UI reads from structured models (no string parsing in views)
- **Accessibility:** Custom modifiers ensure WCAG compliance
- **Offline-first:** Views gracefully degrade when cache unavailable

Aliases / also known as: SwiftUI views, card rendering, message display, UI components
