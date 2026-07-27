# Content card / inbox persistence — write, read, and clear flows

Current implementation (post explicit-flag redesign — no automatic memory-first/disk-fallback).
Traces exactly how disk gets written on `updatePropositionsForSurfaces`, how the app explicitly
requests persisted data via `usePersistedContentCards`, and what `clearPersistedPropositions()` does.

## 1. Write path — `updatePropositionsForSurfaces([surface])`

```
App calls updatePropositionsForSurfaces([surface])
│
├─ Network available?
│    │
│    ├─ No  → Skipped, handler(false). NOTHING written to disk.
│    │
│    └─ Yes → Edge request dispatched
│              │
│              └─ Edge response
│                   │
│                   ├─ Non-recoverable error (errorResponseContent)
│                   │    → nonRecoverableErrorEventIds.insert(requestId)
│                   │    → falls through to applyPropositionChangeFor anyway
│                   │
│                   └─ Success, with propositions
│                        → falls through to applyPropositionChangeFor
```

### `applyPropositionChangeFor(eventId)` — the WRITE path

```
ParsedPropositions parses response into per-type buckets
│
├─ requestFailed? (eventId in nonRecoverableErrorEventIds)
│    │
│    ├─ Yes → surfacesToRemove = []
│    │        Nothing evicted — existing data preserved
│    │
│    └─ No  → surfacesToRemove = requestedSurfaces − returnedSurfaces
│             (FR-7: a requested surface absent from the response
│              means the campaign is genuinely gone)
│
├─ DISK WRITE (each gated by offlineAvailable on the proposition)
│    ├─ cache.updateContentCardPropositions(...)   key: contentCardPropositions
│    ├─ cache.updateCodeBasedPropositions(...)      key: codeBasedPropositions
│    ├─ cache.updateInboxPropositions(...)          key: inboxPropositions
│    └─ cache.updatePropositions(...)  [IAM]        key: propositions
│
├─ IN-MEMORY WRITE
│    ├─ qualifiedContentCardsBySurface
│    ├─ inMemoryPropositions (CBE)
│    └─ inboxPropositionsBySurface
│
└─ updateRulesEngines()
     → origin[surface] = .network
     → (servedFromPersistentCache = false)

Result: disk + memory now hold the latest successful data.
```

## 2. Read path — two explicit variants, no automatic fallback

```
App wants to READ propositions
│
├─ getPropositionsForSurfaces(surfaces, completion)
│    — same as passing usePersistedContentCards: false (the default)
│
├─ getPropositionsForSurfaces(surfaces, usePersistedContentCards: true, completion)
│
└─ getContentCardsUI(for:, ...) — same two variants, forwards to the above
```

### 2a. Memory-only path (default — `usePersistedContentCards: false`)

```
retrieveMessages(for:, event:)
│
├─ NO disk access at all
│
├─ Read qualifiedContentCardsBySurface
│       + inMemoryPropositions (CBE)
│       + inboxPropositionsBySurface
│   for the requested surfaces
│
└─ Merge → response event
     (empty array if nothing was in memory)
        │
        └─ completion(propositions, nil) back to app
```

### 2b. Explicit disk path (`usePersistedContentCards: true`)

```
retrieveMessages(for:, event:)
│
├─ hydrateContentCardRulesEngineFromDisk(requestedSurfaces)
│    ├─ reads cache.contentCardPropositions
│    ├─ replaceRules + seed event
│    │   (expiry / event history re-evaluated — same as a real rules pass)
│    └─ origin[surface] = .disk
│         (servedFromPersistentCache = true)
│
├─ hydrateInboxPropositionsFromDisk(requestedSurfaces)
│    ├─ reads cache.inboxPropositions
│    └─ direct assignment — no rules to evaluate
│
├─ Read qualifiedContentCardsBySurface (now filled from disk)
│       + inboxPropositionsBySurface
│   for the requested surfaces
│
└─ Merge → response event
        │
        └─ completion(propositions, nil) back to app
```

**Note:** the explicit disk path hydrates from disk for *every* requested surface, not only the ones missing from memory — the caller is asking for the persisted copy specifically, not a gap-fill.

## 3. Clear path — `clearPersistedPropositions()`

```
App calls clearPersistedPropositions()
│
└─ clearPersistedContentCardAndInboxPropositions()
     │
     ├─ clearContentCards()
     │    ├─ memory + rules + origin flag cleared
     │    └─ cache.remove(contentCardPropositions)
     │
     └─ inboxPropositionsBySurface = [:]
          cache.remove(inboxPropositions)

Result: disk + memory empty for content cards / inbox.
CBE (codeBasedPropositions) is NOT touched.
```

## Code locations

| Flow | Function | File |
|------|----------|------|
| Write (network → disk + memory) | `applyPropositionChangeFor(eventId:)` | `AEPMessaging/Sources/Messaging.swift` |
| Read (memory-only, default) | `retrieveMessages(for:event:)` — `if event.usePersistedContentCards` branch skipped | `AEPMessaging/Sources/Messaging.swift` |
| Read (explicit disk) | same function, branch taken; calls `hydrateContentCardRulesEngineFromDisk` / `hydrateInboxPropositionsFromDisk` | `AEPMessaging/Sources/Messaging.swift` |
| Clear | `clearPersistedContentCardAndInboxPropositions()` | `AEPMessaging/Sources/Messaging.swift` |
| Public read API | `getPropositionsForSurfaces(_:usePersistedContentCards:_:)` | `AEPMessaging/Sources/Messaging+PublicAPI.swift` |
| Public read API (UI) | `getContentCardsUI(for:usePersistedContentCards:...)` | `AEPMessaging/Sources/UI/Messaging+UIPublicAPI.swift` |
| Public clear API | `clearPersistedPropositions()` | `AEPMessaging/Sources/Messaging+PublicAPI.swift` |

## Key facts

- **No automatic fallback.** Memory-empty does NOT trigger a disk read on its own anymore. Disk is touched only when the caller passes `usePersistedContentCards: true`.
- **Explicit disk read hydrates ALL requested surfaces**, not just the ones missing from memory — the caller is asking for the persisted copy specifically.
- **CBE is write-only to disk.** `codeBasedPropositions` is written on every successful update but has no read-back path; `clearPersistedPropositions()` does not touch it either.
- **A failed request (non-recoverable Edge error) never evicts existing data** — disk, memory, rules, and the `servedFromPersistentCache` origin tag are all preserved when `nonRecoverableErrorEventIds` contains the request id.
- **Content cards re-evaluate their rules on disk hydrate** (expiry, event history) via a seed event through the rules engine; inbox propositions are a direct assignment with no rules to evaluate.
