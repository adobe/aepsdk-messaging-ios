# `servedFromPersistentCache` flag — how and when it updates

Scenario-based view of when the content card `servedFromPersistentCache` flag gets set,
for the two SDK calls that can change it: `updatePropositionsForSurfaces()` and
`getPropositionsForSurfaces()` / `getContentCardsUI()`.

**Includes the error-handling fix**: a failed request (recoverable — Edge still retrying, or
non-recoverable — Edge's `errorResponseContent` event recorded) now leaves the flag and the
underlying card **completely unchanged**, instead of the old behavior where a non-recoverable
error could wipe both. See `persistence-write-path-and-errors.md` for the full error taxonomy.

```mermaid
flowchart TD
    A(["App calls an SDK API"])
    A --> B{"Which call?"}

    B -->|"updatePropositionsForSurfaces()"| U1{"Network\navailable?"}
    B -->|"getPropositionsForSurfaces() /\ngetContentCardsUI()"| G1{"Cards already\nin memory?"}

    %% UPDATE — network available
    U1 -->|"Yes"| U1B{"Request\nresult?"}

    U1B -->|"Success, real data"| U2["Fresh cards fetched from server\nSaved to disk + kept in memory"]
    U2 --> U3["🟢 FLAG SET: network\n(servedFromPersistentCache = false)"]

    U1B -->|"Success, genuinely empty\n(no campaigns for surface)"| U2B["Card evicted from disk + memory\n(FR-7 — correct, campaign gone)"]
    U2B --> U3B["⚪ NO FLAG\n(no card to display, no event fires)"]

    U1B -->|"Recoverable error\n(408/429/502/503/504/507)"| U4A["Edge retries in background\nhandleEdgeErrorResponse ignores it\n(not recorded as failed)"]
    U4A --> U5["⚪ FLAG UNCHANGED\nexisting card + origin PRESERVED"]

    U1B -->|"Non-recoverable error\n(400/401/403/404/500/other)"| U4B["errorResponseContent recorded\napplyPropositionChangeFor skips eviction\nfor this request's surfaces"]
    U4B --> U5

    %% UPDATE — network NOT available
    U1 -->|"No"| U4["fetchPropositions returns immediately\nDisk untouched, memory untouched"]
    U4 --> U5

    %% GET — memory has data
    G1 -->|"Yes"| G2["Return cards straight from memory\nNo disk read"]
    G2 --> G3["⚪ FLAG UNCHANGED\n(reflects however memory was filled)"]

    %% GET — memory empty
    G1 -->|"No"| G3a["Read persisted cards from disk\nLoad into memory"]
    G3a --> G4["🔵 FLAG SET: disk\n(servedFromPersistentCache = true)"]

    U3 --> D(["Card shown on screen"])
    U5 --> D
    G3 --> D
    G4 --> D

    D --> E["Display event sent to Edge\ncarries the flag set above"]

    style U3 fill:#c8e6c9,stroke:#388e3c
    style G4 fill:#bbdefb,stroke:#1976d2
    style U5 fill:#c8e6c9,stroke:#388e3c
    style G3 fill:#eeeeee,stroke:#9e9e9e
    style U3B fill:#eeeeee,stroke:#9e9e9e
    style U1 fill:#fff3e0,stroke:#ff9800
    style U1B fill:#fff3e0,stroke:#ff9800
    style G1 fill:#fff3e0,stroke:#ff9800
```

## Summary

| Call | Condition | What happens | Flag after |
|------|-----------|---------------|-----------|
| `updatePropositionsForSurfaces()` | Network unavailable | Update never sent, disk & memory untouched | unchanged |
| `updatePropositionsForSurfaces()` | Success, real data returned | Fresh cards fetched, saved to disk + memory | `network` (`false`) |
| `updatePropositionsForSurfaces()` | Success, genuinely empty response | Card evicted (campaign gone — FR-7, correct) | no card, no flag |
| `updatePropositionsForSurfaces()` | Recoverable error (Edge still retrying) | Existing card + flag preserved | unchanged |
| `updatePropositionsForSurfaces()` | Non-recoverable error (`errorResponseContent`) | Existing card + flag preserved (fix) | unchanged |
| `getPropositionsForSurfaces()` / `getContentCardsUI()` | Cards already in memory | Returned directly, no disk read | unchanged |
| `getPropositionsForSurfaces()` / `getContentCardsUI()` | Cards not in memory | Read from disk, loaded into memory | `disk` (`true`) |

The flag is only ever **written** by a successful network update with real data (→ `network`) or a
disk hydrate that fills previously-empty memory (→ `disk`). Any call that returns data already
sitting in memory leaves the flag as-is. Critically, a **failed** update — recoverable or
non-recoverable — no longer touches the flag or the underlying card at all: only a genuinely empty
*successful* response is treated as "the campaign is gone."
