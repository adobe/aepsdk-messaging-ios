# Module: persistence_core

Core read/write/error-handling API contract: explicit `usePersistedContentCards` flag,
`clearPersistedPropositions()`, non-recoverable Edge error guard, CBE revert to memory-only.

## Source
- AEPMessaging/Sources/Messaging.swift
- AEPMessaging/Sources/Messaging+PublicAPI.swift
- AEPMessaging/Sources/MessagingConstants.swift
- AEPMessaging/Sources/ParsedPropositions.swift
- AEPMessaging/Sources/ClassExtensions/Cache+Messaging.swift
- AEPMessaging/Sources/ClassExtensions/Event+Messaging.swift
- AEPMessaging/Sources/Proposition.swift

## Tests
- AEPMessaging/Tests/UnitTests/Cache+MessagingTests.swift
- AEPMessaging/Tests/UnitTests/Messaging+StateTests.swift
- AEPMessaging/Tests/UnitTests/MessagingTests.swift
- AEPMessaging/Tests/UnitTests/MessagingProcessCompletedEventTests.swift
- AEPMessaging/Tests/UnitTests/ParsedPropositionsTests.swift
- AEPMessaging/Tests/UnitTests/Messaging+PublicApiTest.swift
- AEPMessaging/Tests/TestHelpers/MockCache.swift
- AEPMessaging/Tests/TestHelpers/MockNetworkConnectivityService.swift
