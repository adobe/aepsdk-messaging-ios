/*
Copyright 2023 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/

import AEPMessaging
import SwiftUI

struct InboxView: View, ContentCardUIEventListening, InboxEventListening {

    @State private var inboxUI: InboxUI?

    var body: some View {
        VStack(spacing: 0) {
            if let inboxUI = inboxUI {
                inboxUI.view
            }
        }
        .navigationTitle("Inbox Demo")
        .onAppear {
            // Only initialize once
            guard inboxUI == nil else { return }
            let surface = Surface(path: Constants.SurfaceName.INBOX)
            // Get InboxUI immediately - it starts in loading state
            let inbox = Messaging.getInboxUI(
                for: surface,
                customizer: InboxCustomizer(),
                listener: self
            )
            inboxUI = inbox

            // Configure inbox properties
            inbox.isPullToRefreshEnabled = true
            inbox.cardSpacing = 20
            inbox.contentPadding = EdgeInsets(top: 20, leading: 10, bottom: 20, trailing: 10)

            // Uncomment to apply custom views:
            // applyCustomHeadingView(inbox)
            // applyCustomLoadingView(inbox)
            // applyCustomErrorView(inbox)
            // applyCustomEmptyView(inbox)
        }
    }

    // MARK: - Custom View Helpers

    private func applyCustomHeadingView(_ inbox: InboxUI) {
        inbox.setHeadingView { heading in
            AnyView(
                HStack {
                    Text(heading.content)
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            )
        }
    }

    private func applyCustomLoadingView(_ inbox: InboxUI) {
        inbox.setLoadingView {
            AnyView(
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(2.0)
                        .tint(.blue)
                    Text("Loading your offers")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            )
        }
    }

    private func applyCustomErrorView(_ inbox: InboxUI) {
        inbox.setErrorView { _ in
            AnyView(
                VStack(spacing: 20) {
                    Image("ErrorMessageIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)

                    VStack(spacing: 8) {
                        Text("SORRY")
                            .font(.system(size: 32, weight: .thin))
                            .foregroundColor(.gray)
                            .tracking(4)
                        Text("something went wrong")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(.gray)
                        Text("on our end")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 8)

                    Button {
                        inbox.refresh()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            )
        }
    }

    private func applyCustomEmptyView(_ inbox: InboxUI) {
        inbox.setEmptyView { _ in
            AnyView(
                VStack(spacing: 24) {
                    Image("emptyMessageIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 140)
                        .shadow(color: .blue.opacity(0.2), radius: 10, x: 0, y: 4)

                    VStack(spacing: 12) {
                        Text("No new message")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("Check back later for exciting offers\n(or boring ads, we'll surprise you! 🎁)")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 32)

                    Button {
                        inbox.refresh()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(24)
                        .shadow(color: .blue.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            )
        }
    }

    // MARK: - Event Listeners

    // Inbox Events
    func onLoading(_ inbox: InboxUI) {
        print("Inbox is loading...")
    }

    func onSuccess(_ inbox: InboxUI) {
        print("Inbox loaded successfully")
    }

    func onError(_ inbox: InboxUI, _ error: Error) {
        print("Inbox error: \(error.localizedDescription)")
    }

    // Content Card Events
    func onCardDismissed(_ card: ContentCardUI) {
        print("Card dismissed: \(card.id)")
    }

    func onCardDisplayed(_ card: ContentCardUI) {
        print("Card displayed: \(card.id)")
    }

    func onCardInteracted(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool {
        print("Card interacted: \(interactionId)")
        return false // Return false to allow default URL handling
    }

    func onCardCreated(_ card: ContentCardUI) {
        print("Card created: \(card.id)")
    }
}

// MARK: - Inbox Card Customizer

class InboxCustomizer: ContentCardCustomizing {

    func customize(template: LargeImageTemplate) {
        template.title.textColor = .primary
        template.title.font = .system(size: 16, weight: .bold)
        template.body?.textColor = .secondary
        template.body?.font = .caption

        template.buttons?.first?.text.font = .system(size: 13)
        template.buttons?.first?.text.textColor = .primary
        template.buttons?.first?.modifier = AEPViewModifier(InboxButtonModifier())

        template.image?.contentMode = .fill
        template.image?.modifier = AEPViewModifier(InboxLargeImageModifier())

        template.rootVStack.spacing = 0
        template.textVStack.alignment = .leading
        template.textVStack.spacing = 4
        template.textVStack.modifier = AEPViewModifier(InboxTextAreaModifier())
        template.buttonHStack.modifier = AEPViewModifier(InboxLargeButtonHStackModifier())
        template.modifier = AEPViewModifier(InboxCardContainerModifier())

        template.dismissButton?.image.iconColor = .white
        template.dismissButton?.image.iconFont = .system(size: 12, weight: .semibold)
    }

    func customize(template: SmallImageTemplate) {
        template.title.textColor = .primary
        template.title.font = .system(size: 15, weight: .bold)
        template.body?.textColor = .secondary
        template.body?.font = .caption

        template.buttons?.first?.text.font = .system(size: 13)
        template.buttons?.first?.text.textColor = .primary
        template.buttons?.first?.modifier = AEPViewModifier(InboxButtonModifier())

        template.image?.modifier = AEPViewModifier(InboxSmallImageModifier())

        template.rootHStack.spacing = 0
        template.textVStack.alignment = .leading
        template.textVStack.spacing = 4
        template.textVStack.modifier = AEPViewModifier(InboxTextAreaModifier())
        template.buttonHStack.modifier = AEPViewModifier(InboxSmallButtonHStackModifier())
        template.modifier = AEPViewModifier(InboxCardContainerModifier())

        template.dismissButton?.image.iconColor = .primary
        template.dismissButton?.image.iconFont = .system(size: 10, weight: .semibold)

        template.unreadIcon?.image.iconColor = .yellow
        template.unreadIcon?.image.iconFont = .system(size: 20, weight: .semibold)
        template.unreadIcon?.alignment = .topLeading
    }

    func customize(template: ImageOnlyTemplate) {
        template.dismissButton?.image.iconColor = .white
        template.dismissButton?.image.iconFont = .system(size: 10)
    }
}

// MARK: - Large Image Modifiers

struct InboxLargeImageModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180)
            .clipped()
    }
}

// MARK: - Small Image Modifiers

struct InboxSmallImageModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(width: 110)
            .frame(maxHeight: .infinity)
            .clipped()
    }
}

// MARK: - Shared Modifiers

struct InboxTextAreaModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 4)
    }
}

struct InboxCardContainerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

struct InboxLargeButtonHStackModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
    }
}

struct InboxSmallButtonHStackModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
    }
}

struct InboxButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 6)
            .padding(.horizontal, 14)
            .background(Color.primary.opacity(0.08))
            .cornerRadius(8)
    }
}
