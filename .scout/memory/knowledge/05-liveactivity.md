---
title: Live Activity Integration
entity_type: concept
tier: knowledge
confidence: 0.68
source: inferred
tags: [domain, liveactivity, ios, dynamic-updates, push]
relationships:
  - type: applies_to
    target: "Architecture Overview"
  - type: applies_to
    target: "Core Messaging Engine"
---

# Live Activity Integration

**Layer:** Feature / iOS 16+ Dynamic Updates

**Directory:** `AEPMessaging/Sources/LiveActivity/`

## Purpose

Enable iOS 16+ Live Activities — dynamic push-based notification updates displayed on lock screen & Dynamic Island. Integrates with Messaging engine for state synchronization.

## Structure

```
LiveActivity/
├── LiveActivityAttributes.swift      # Activity type definition
├── LiveActivityTracker.swift         # State lifecycle management
├── Persistence/
│   ├── LiveActivityData.swift
│   └── ContentState.swift
└── [...implementation files]
```

## Key Responsibilities

1. **State Management**
   - Maintain Live Activity state synchronized with Messaging propositions
   - Track activity lifecycle (start, update, end)

2. **Persistence**
   - Store Live Activity data on disk (recovery on app relaunch)
   - Resume interrupted activities

3. **Integration**
   - Bridge between Messaging events and Live Activity updates
   - Support custom content templates

## Key Types

| Type | Role |
|------|------|
| `LiveActivityAttributes` | iOS ActivityKit attribute model |
| `LiveActivityTracker` | Manages activity lifecycle |
| `LiveActivityData` | Persistent state structure |

## Coupling to Core

- **Bidirectional:** Changes to Messaging propositions may trigger Live Activity updates
- **State sync:** Live Activity completion may trigger tracking events

Aliases / also known as: Live Activity, ActivityKit integration, dynamic notifications
