#!/bin/bash
#
# Copyright 2026 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

# Builds a Swift 6 language mode app target that calls the public Messaging APIs from main actor code.
# Only the consumer target is in Swift 6 mode; AEPMessaging and its dependencies keep their own modes.

set -e

PROJECT_NAME=Swift6Consumer

rm -rf $PROJECT_NAME
mkdir -p $PROJECT_NAME/Sources/$PROJECT_NAME $PROJECT_NAME/Sources/MainActorConsumer && cd $PROJECT_NAME

cat > Package.swift <<'EOF'
// swift-tools-version:6.2
import PackageDescription
let package = Package(
    name: "Swift6Consumer",
    platforms: [.iOS(.v15)],
    products: [.library(name: "Swift6Consumer", targets: ["Swift6Consumer", "MainActorConsumer"])],
    dependencies: [.package(name: "AEPMessaging", path: "../")],
    targets: [
        .target(
            name: "Swift6Consumer",
            dependencies: [
                .product(name: "AEPMessaging", package: "AEPMessaging"),
                .product(name: "AEPMessagingNotification", package: "AEPMessaging")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "MainActorConsumer",
            dependencies: [.product(name: "AEPMessaging", package: "AEPMessaging")],
            swiftSettings: [.swiftLanguageMode(.v6), .defaultIsolation(MainActor.self)]
        )
    ]
)
EOF

cat > Sources/$PROJECT_NAME/Swift6Consumer.swift <<'EOF'
import AEPMessaging
import AEPMessagingNotification
import SwiftUI
import UserNotifications

@MainActor
final class Swift6Consumer {
    var updated = false
    var propositionCount = 0
    var cardCount = 0
    var pushStatus: PushTrackingStatus?

    func exercise(surface: Surface, response: UNNotificationResponse) {
        Messaging.updatePropositionsForSurfaces([surface]) { success in
            Task { @MainActor in self.updated = success }
        }
        Messaging.getPropositionsForSurfaces([surface]) { propositions, _ in
            let count = propositions?.count ?? 0
            Task { @MainActor in self.propositionCount = count }
        }
        Messaging.getContentCardsUI(for: surface) { result in
            let count = (try? result.get())?.count ?? 0
            Task { @MainActor in self.cardCount = count }
        }
        Messaging.handleNotificationResponse(response, urlHandler: { _ in false }) { status in
            Task { @MainActor in self.pushStatus = status }
        }
    }
}

struct CardsScreen: View, ContentCardUIEventListening, InboxEventListening {
    var body: some View { Text("cards") }

    func onDisplay(_ card: ContentCardUI) {}
    func onDismiss(_ card: ContentCardUI) {}
    func onInteract(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool { false }

    func onLoading(_ inbox: InboxUI) {}
    func onSuccess(_ inbox: InboxUI) {}
    func onError(_ inbox: InboxUI, _ error: Error) {}
    func onCardDismissed(_ card: ContentCardUI) {}
    func onCardDisplayed(_ card: ContentCardUI) {}
    func onCardInteracted(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool { false }
    func onCardCreated(_ card: ContentCardUI) {}
}

final class CardCoordinator: ContentCardUIEventListening, ContentCardCustomizing {
    func customize(template: SmallImageTemplate) { template.title.textColor = .red }

    func onDisplay(_ card: ContentCardUI) {}
    func onDismiss(_ card: ContentCardUI) {}
    func onInteract(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool { false }
}

final class InboxCoordinator: InboxEventListening, ContentCardCustomizing {
    func customize(template: LargeImageTemplate) { template.title.textColor = .blue }

    func onLoading(_ inbox: InboxUI) {}
    func onSuccess(_ inbox: InboxUI) {}
    func onError(_ inbox: InboxUI, _ error: Error) {}
    func onCardDismissed(_ card: ContentCardUI) {}
    func onCardDisplayed(_ card: ContentCardUI) {}
    func onCardInteracted(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool { false }
    func onCardCreated(_ card: ContentCardUI) {}
}

struct StyledCardsScreen: View, ContentCardCustomizing {
    var body: some View { Text("styled") }

    func customize(template: ImageOnlyTemplate) {}
}

@MainActor
func loadCustomizedCards(surface: Surface) -> InboxUI {
    let cards = CardCoordinator()
    Messaging.getContentCardsUI(for: surface, customizer: cards, listener: cards) { result in
        let count = (try? result.get())?.count ?? 0
        Task { @MainActor in print(count) }
    }
    Messaging.getContentCardsUI(for: surface, customizer: StyledCardsScreen()) { _ in }
    let inbox = InboxCoordinator()
    return InboxUI(surface: surface, customizer: inbox, listener: inbox)
}
EOF

cat > Sources/MainActorConsumer/MainActorConsumer.swift <<'EOF'
import AEPMessaging

final class PlainCustomizer: ContentCardCustomizing {
    func customize(template: SmallImageTemplate) { template.title.textColor = .red }
}

func loadCards(surface: Surface) -> InboxUI {
    Messaging.getContentCardsUI(for: surface, customizer: PlainCustomizer()) { _ in }
    return InboxUI(surface: surface, customizer: PlainCustomizer())
}
EOF

xcodebuild build -scheme $PROJECT_NAME -destination 'generic/platform=iOS Simulator'

cd ../
rm -rf $PROJECT_NAME
