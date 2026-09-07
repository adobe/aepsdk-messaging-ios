---
title: Architecture Overview
entity_type: concept
tier: knowledge
confidence: 0.8
source: inferred
tags: [overview, architecture, start-here, messaging, iam, contentcards, inbox, liveactivity]
relationships:
  - type: applies_to
    target: "Core Messaging Engine"
  - type: applies_to
    target: "UI Layer (Content Cards + Inbox)"
---

# AEPMessaging iOS SDK — Architecture Overview

**Purpose:** Adobe Experience Platform Messaging SDK for iOS enables In-App Messages (IAM), Content Cards, Inbox UI, Push Notifications, and Live Activities with offline persistence, edge event streaming, and rules-based personalization.

## Top 5 Domains

1. **Messaging Core** — Core event handling, proposition caching, network gate logic (Messaging.swift, ~9.5K LOC)
2. **UI Layer** — SwiftUI components for Content Cards UI, Inbox UI, custom modifiers, view templates
3. **LiveActivity** — Live Activity integration for dynamic push-based updates
4. **Data Models** — Schemas, Content Card parsing, Message/Feed/FeedItem definitions
5. **Class Extensions** — AEPCore bridge (Cache, Event, UserProfile), String/View utility extensions

## Key Coupling Hotspots

| Hotspot | Reason | Impact |
|---------|--------|--------|
| **Messaging ↔ Cache+Edge** | Offline persistence + network availability gating | CC cold-start hydration, IAM rules on disk |
| **UI ↔ ParsedPropositions** | Feed/Message rendering depends on structured data | Changes to data model ripple to all views |
| **LiveActivity ↔ Messaging** | Live Activity dynamic updates via Messaging state | Bidirectional dependency on proposition state |

## Primary Type Systems

- **Proposition:** `Message`, `ContentCard` + related structures (Schemas)
- **Caching:** ContentCard + IAM propositions (in-memory + disk via Cache)
- **UI Models:** Feed, FeedItem, Content Card container types
- **Rules Engine:** `ContentCardRulesEngine`, personalization via Experience Edge

## First-to-Read Files

| File | Purpose |
|------|---------|
| `AGENTS.md` | Agent guidance on CC offline/persistence, network availability layer |
| `AEPMessaging/Sources/Messaging.swift` | Main SDK entry point; core API + offline hydration logic |
| `AEPMessaging/Sources/ParsedPropositions.swift` | Content Card → persistence/memory conversion |
| `Documentation/` | Tutorials on Inbox events, Content Card offline discovery |

Aliases / also known as: iOS Messaging SDK, AEPMessaging, Adobe Messaging
