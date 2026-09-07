# Branch Review: MOB-25109/offline-content-card-availability

**Branch:** MOB-25109/offline-content-card-availability
**Base:** origin/main
**Author:** namArora3112
**Review Type:** Self-review (no PR)

## Commits

```
Changed implementation of tracking events
integration tests fixes
unit tests fixes
default to false when content card is not present
called isNetworkAvailable funcion on bootup
tracking fixes
fixed isnetwork availability guard for udpate proposition
network api tests fixes
Added network check when device is offline
Merge origin/main into MOB-25109/offline-content-card-availability
removed unit tests
Reverted getprop to be part of queue was omitted from earlier builds
fixing flaky tests
Reverted content card ui behaviour in case of no data available
tests fixes
Removed config
card views changes revert
mock network service fixes
reverted overloaded paramter of usepersistent storagr from getprop and getcontentCardui Apis
remove incorrect 'inbox' reference from usePersistedContentCards doc comment

```

## Files Changed

```
 .gitignore                                         |   4 +-
 AEPMessaging.xcodeproj/project.pbxproj             |  52 +-
 .../xcshareddata/swiftpm/Package.resolved          |  34 --
 .../Sources/ClassExtensions/Cache+Messaging.swift  |  90 +++-
 .../Sources/ClassExtensions/Event+Messaging.swift  |  22 +
 AEPMessaging/Sources/Messaging+PublicAPI.swift     |  39 +-
 AEPMessaging/Sources/Messaging+State.swift         |  21 +-
 AEPMessaging/Sources/Messaging.swift               | 506 +++++++++++++++++---
 AEPMessaging/Sources/MessagingConstants.swift      |  22 +
 AEPMessaging/Sources/ParsedPropositions.swift      |   8 +-
 .../Sources/UI/Messaging+UIPublicAPI.swift         |  13 +-
 .../MessagingNotificationTrackingTests.swift       |   4 +-
 .../IntegrationTests/GetContentCardUITest.swift    |  62 ++-
 .../HelperClasses/IntegrationTestBase.swift        |   5 +
 .../HelperClasses/MockNetworkService.swift         |   3 +
 AEPMessaging/Tests/TestHelpers/MockCache.swift     |  13 +-
 .../MockNetworkConnectivityService.swift           |  27 ++
 .../Tests/UnitTests/Cache+MessagingTests.swift     |  44 ++
 .../UnitTests/Messaging+EdgeEventsTests.swift      |  82 ++++
 .../Tests/UnitTests/Messaging+PublicApiTest.swift  |  20 +-
 .../Tests/UnitTests/Messaging+StateTests.swift     |  40 ++
 .../MessagingProcessCompletedEventTests.swift      |  97 +++-
 AEPMessaging/Tests/UnitTests/MessagingTests.swift  |  62 ++-
 .../Tests/UnitTests/ParsedPropositionsTests.swift  |  20 +-
 .../UITests/Messaging+UIPublicApiTest.swift        |  63 +++
 Podfile                                            |   7 +-
 Podfile.lock                                       |  50 +-
 TestApps/MessagingDemoAppSwiftUI/AppDelegate.swift |  32 +-
 .../AppPages/CardsView.swift                       | 527 +++++++++++++++++++--
 .../AppPages/ElementViews/TabHeader.swift          |   2 +-
 TestApps/MessagingDemoAppSwiftUI/Constants.swift   |  17 +-
 31 files changed, 1714 insertions(+), 274 deletions(-)

```

## Diff Files

- **Summary:** `MOB-25109-offline-content-card-availability_diff/_summary.md`
- **File List:** `MOB-25109-offline-content-card-availability_diff/_file_list.md`
- **Per-file Diffs:** `MOB-25109-offline-content-card-availability_diff/`
