---
title: "Test Framework: XCTest + SwiftUI Testing"
entity_type: pattern
tier: procedures
confidence: 0.75
source: inferred
tags: [testing, xctest, unit-tests, functional-tests, swiftui-testing]
relationships:
  - type: applies_to
    target: "Core Messaging Engine"
  - type: applies_to
    target: "UI Layer (Content Cards + Inbox)"
---

# Test Framework

**Primary:** XCTest (Apple's native unit testing) + SwiftUI Preview tests

## Test Structure

```
Tests/
├── AEPMessagingTests/
│   ├── MessagingTests.swift         # Unit: Messaging core
│   ├── UITests/                      # UI component tests
│   ├── OfflineTests/                 # Offline persistence
│   └── [...functional tests]
├── FunctionalTests/                  # Integration / E2E
└── AEPMessagingIntegrationTests/
```

## How to Run

```bash
make unit-test          # XCTest suite
make functional-test    # Functional/integration tests
```

## Testing Strategies

| Scope | Framework | Location | Example |
|-------|-----------|----------|---------|
| Unit | XCTest | AEPMessagingTests/ | Message parsing, ContentCard models |
| UI | XCTest + Preview | UITests/ | SwiftUI view rendering |
| Offline | XCTest | OfflineTests/ | Disk hydration, cache eviction |
| E2E | XCTest | FunctionalTests/ | Edge → Messaging → UI pipeline |

## When to Write Tests

- **New proposition type:** Model + parsing test
- **API change:** Public API test in MessagingTests
- **Offline logic:** Explicit offline scenario in OfflineTests
- **UI component:** Preview test for rendering

## Known Gaps

- **Offline E2E on device:** No functional end-to-end offline tests on real device (P0 work)
- **Live Activity tests:** Limited coverage of ActivityKit integration

Aliases / also known as: XCTest, unit tests, functional tests, testing
