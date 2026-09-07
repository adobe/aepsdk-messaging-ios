---
title: Build System
entity_type: procedure
tier: procedures
confidence: 0.8
source: inferred
tags: [build, workflow, makefile, cocoapods, xcode]
---

# Build System

**Primary:** Makefile (convenience wrapper) + CocoaPods + Xcode

**Root Config Files:**
- `Makefile` — Target destinations, common build commands
- `Podfile` — Dependency specification (AEPCore, AEPServices, etc.)
- `AEPMessaging.podspec` — CocoaPod spec for distribution
- `*.xcodeproj/` — Xcode project

## Entry Commands

```bash
make pod-install       # First time / after Podfile change
make open             # Open AEPMessaging.xcworkspace in Xcode
make unit-test        # Run unit tests
make functional-test  # Run functional/integration tests
make lint             # SwiftLint validation
```

## Key Environment

- **iOS Destination:** Defined in Makefile (`IOS_DESTINATION`)
- **Swift Version:** 5.x minimum
- **Dependencies:** AEPCore (for Cache, Event, UserProfile extensions)

## CocoaPods Setup

```bash
cd <repo>
pod install
# Creates AEPMessaging.xcworkspace (always open .xcworkspace, not .xcodeproj)
```

## Known Caveats

- Must run `make pod-install` after Podfile.lock changes
- Always use `.xcworkspace`, not `.xcodeproj` (Pod dependencies won't link)
- Test destination in Makefile must match local Xcode version capabilities

Aliases / also known as: Build, cocoapods, xcode build
