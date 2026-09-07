# PR #495

**PR Number:** #495
**Author:** Unknown
**State:** open
**Base Branch:** main
**Head Branch:** unknown

## Description



## Commits

```
Removed config
card views changes revert
mock network service fixes
reverted overloaded paramter of usepersistent storagr from getprop and getcontentCardui Apis
remove incorrect 'inbox' reference from usePersistedContentCards doc comment
revert inbox persistence changes and restore main-branch comments in ParsedPropositions
removed inbox ui tests
removing inbox ui changes
removed inbox ui related changes
refactoring code for removing code[dxcpr]
Added network simulation
added disk and in memory paths
added logs for global config too
Added global configuration
qualification , disqualification rules handling on hydrate
added rules evaluation on bootup
Make InboxUI's persistence mode changeable per-call, not just at init
Remove dev-time agent docs from tracking, keep local via .gitignore
Address code review findings: identity-reset leak, dead code, test coverage
Add explicit offline-read APIs for content cards and inbox

```

## Files Changed

```
 .gitignore                                         |   4 +-
 AEPMessaging.xcodeproj/project.pbxproj             | 133 +------
 .../xcshareddata/swiftpm/Package.resolved          |  34 --
 .../Sources/ClassExtensions/Cache+Messaging.swift  |  90 +++--
 .../Sources/ClassExtensions/Event+Messaging.swift  |  22 ++
 AEPMessaging/Sources/Messaging+PublicAPI.swift     |  39 +-
 AEPMessaging/Sources/Messaging+State.swift         |  21 +-
 AEPMessaging/Sources/Messaging.swift               | 368 ++++++++++++++++---
 AEPMessaging/Sources/MessagingConstants.swift      |  22 ++
 AEPMessaging/Sources/ParsedPropositions.swift      |   8 +-
 AEPMessaging/Sources/Proposition.swift             |   5 +
 .../Sources/UI/Messaging+UIPublicAPI.swift         |  17 +-
 .../IntegrationTests/GetContentCardUITest.swift    |  59 ++-
 AEPMessaging/Tests/TestHelpers/MockCache.swift     |  13 +-
 .../MockNetworkConnectivityService.swift           |  27 ++
 .../Tests/UnitTests/Cache+MessagingTests.swift     |  44 +++
 .../UnitTests/Messaging+EdgeEventsTests.swift      |  81 ++++
 .../Tests/UnitTests/Messaging+PublicApiTest.swift  |  20 +-
 .../Tests/UnitTests/Messaging+StateTests.swift     |  59 +++
 .../MessagingProcessCompletedEventTests.swift      |  83 ++++-
 AEPMessaging/Tests/UnitTests/MessagingTests.swift  |  31 +-
 .../Tests/UnitTests/ParsedPropositionsTests.swift  |  14 +-
 .../UITests/Messaging+UIPublicApiTest.swift        |  63 ++++
 Podfile                                            |   7 +-
 Podfile.lock                                       |  50 ++-
 TestApps/MessagingDemoAppSwiftUI/AppDelegate.swift |  32 +-
 .../AppPages/CardsView.swift                       | 408 +++++++++++++++++++--
 .../AppPages/ElementViews/TabHeader.swift          |   2 +-
 TestApps/MessagingDemoAppSwiftUI/Constants.swift   |  17 +-
 29 files changed, 1442 insertions(+), 331 deletions(-)

```

## Diff Files

- **Summary:** `pr495_diff/_summary.md`
- **File List:** `pr495_diff/_file_list.md`
- **Per-file Diffs:** `pr495_diff/`
