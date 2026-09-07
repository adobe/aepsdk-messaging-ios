# Public exposure of `activityId` / `activity` / `scopeDetails` (MOB-24075)

Context: [PLATIR-66352](https://jira.corp.adobe.com/browse/PLATIR-66352) — TATTS GROUP needs a **stable per-authored-card identifier** on iOS to use as a local dedup key (per-user "show once"). Android already exposes this via `AepUITemplate.id`; iOS Optimize already exposes it via `OptimizeProposition.activity`. This change brings AEPMessaging to parity.

---

## The payload (unchanged) — where the id lives

The identifier already arrives in every personalization response. Nothing about the payload changed — only the **access level** of the fields that read it. Example from `AEPMessaging/Tests/Resources/contentCardProposition.json`:

```json
{
  "id": "c2aa4a73-a534-44c2-baa4-a12980e5bb9d",
  "scope": "mobileapp://mockPackageName/apifeed",
  "scopeDetails": {
    "decisionProvider": "AJO",
    "correlationID": "b5095046-7fd7-4961-871f-9d68f2dc335f",
    "characteristics": {
      "eventToken": "eyJtZXNzYWdlRXhlY3V0aW9uIjp..."
    },
    "activity": {
      "id": "9c8ec035-6b3b-470e-8ae5-e539c7123809#c7c1497e-e5a3-4423-ae37-ba76e1e44342"
    }
  },
  "items": [
    {
      "id": "9d6eff2c-39a7-4aa1-9657-d642e26c5176",
      "schema": "https://ns.adobe.com/personalization/ruleset-item",
      "data": { }
    }
  ]
}
```

### Field mapping

| JSON path | SDK property | Meaning | Stable across fetches? |
|---|---|---|---|
| `id` | `Proposition.uniqueId` | Per-response envelope UUID | ❌ No — regenerates each fetch |
| `scope` | `Proposition.scope` | The surface | ✅ (but it's the surface, not a card id) |
| `scopeDetails` | `Proposition.scopeDetails` | Decision metadata container | ✅ |
| `scopeDetails.activity` | `Proposition.activity` | Authored activity object | ✅ |
| `scopeDetails.activity.id` | `Proposition.activityId` | **Authored campaign/action id** (`campaignID#campaignActionID`) | ✅ **Yes — the dedup key** |
| `items[].id` | `PropositionItem.itemId` | Item/offer-level id | ✅ (but item-level, a *different* id) |

Key point: **`activity.id` is nested inside `scopeDetails`** — not top-level, not on the item. The same value is echoed in the rule's `iam.id` (used internally for qualify/disqualify tracking), which is why it is guaranteed stable.

---

## Before vs After — the only difference is access level

### `Proposition`

| Member | Before | After |
|---|---|---|
| `scopeDetails: [String: Any]` | `var` (internal) | `@objc public var` |
| `activity: [String: Any]` | did not exist | `@objc public var` (computed from `scopeDetails`) |
| `activityId: String` | `var` (internal, in extension) | `@objc public var` |

```swift
// BEFORE — internal, not reachable by host apps
var scopeDetails: [String: Any]
var activityId: String { /* reads scopeDetails["activity"]["id"] */ }

// AFTER — public
@objc public var scopeDetails: [String: Any]
@objc public var activity: [String: Any] { /* scopeDetails["activity"] */ }
@objc public var activityId: String { /* scopeDetails["activity"]["id"] */ }
```

### `ContentCardUI`

Content-card customers hold `[ContentCardUI]`, not `Proposition`. Its `proposition` back-reference is (and stays) internal, so passthrough accessors were added — matching the existing `priority` / `meta` pattern.

| Member | Before | After |
|---|---|---|
| `proposition` | `let` (internal) | `let` (internal — unchanged) |
| `activity: [String: Any]` | did not exist | `public var` → `proposition.activity` |
| `activityId: String` | did not exist | `public var` → `proposition.activityId` |

```swift
// AFTER — reachable from a content card the host app already holds
public var activity: [String: Any] { proposition.activity }
public var activityId: String { proposition.activityId }
```

No logic, decoding, or payload changed — these are read-only accessors over data already present.

---

## Customer usage — direct Optimize analog

```swift
// AEPOptimize (existing):
let id = optimizeProposition.activity["id"]

// AEPMessaging — raw propositions (getPropositionsForSurfaces):
let id = proposition.activityId            // or proposition.activity["id"]

// AEPMessaging — content cards (getContentCardsUI):  ← the PLATIR-66352 path
let id = contentCard.activityId            // or contentCard.activity["id"]
```

For the sample payload above, all of these return:

```
9c8ec035-6b3b-470e-8ae5-e539c7123809#c7c1497e-e5a3-4423-ae37-ba76e1e44342
```

This is the iOS equivalent of Android's `aepUI.getTemplate().id`, closing the MOB-24075 parity gap.

---

## Why not `PropositionItem`?

`PropositionItem` is a public class, but it is **not** a usable path for the activity id:

- It has no `activity` / `scopeDetails` / `activityId` member.
- Its `weak var proposition: Proposition?` back-reference is **internal**, so item → proposition → activity traversal is not possible from host code.
- `PropositionItem.itemId` is public and stable, but it is the **item-level** id, not the authored **activity-level** id, and does not match the Optimize parity surface.

Parity in Optimize is at the proposition level (`OptimizeProposition.activity`), so exposing `activity` on `Proposition` (+ the `ContentCardUI` passthrough) is the correct and sufficient surface.
