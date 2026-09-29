/*
Copyright 2024 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/

import AEPCore
import AEPEdge
import AEPEdgeConsent
import AEPEdgeIdentity
import AEPMessaging
import SwiftUI
import UIKit

struct SettingsView: View {
    @State private var collectConsent: CollectConsentValue = .unknown
    @State private var isLoading = false
    @State private var lastAction: String = ""
    @State private var pushToken: String? = UserDefaults.standard.string(forKey: "devicePushToken")
    @State private var liveActivityTokenCount: Int = TokenCollector.heldPushToStartTokens.count
    @State private var ecid: String?
    @State private var emailInput: String = ""
    @State private var currentEmails: [String] = []

    private static let emailNamespace = "Email"

    enum CollectConsentValue: String {
        case yes = "y"
        case no = "n"
        case pending = "p"
        case unknown = "—"

        var label: String {
            switch self {
            case .yes:     return "Yes (y)"
            case .no:      return "No (n)"
            case .pending: return "Pending (p)"
            case .unknown: return "Unknown"
            }
        }

        var color: Color {
            switch self {
            case .yes:     return .green
            case .no:      return .red
            case .pending: return .orange
            case .unknown: return .secondary
            }
        }
    }

    var body: some View {
        NavigationView {
            List {
                currentConsentSection
                changeConsentSection
                pushTokenSection
                liveActivitySection
                identitySection
                identityResetSection
                if !lastAction.isEmpty {
                    lastActionSection
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .onAppear {
                readConsent()
                pushToken = UserDefaults.standard.string(forKey: "devicePushToken")
                liveActivityTokenCount = TokenCollector.heldPushToStartTokens.count
                refreshIdentity()
            }
        }
    }

    // MARK: - Sections

    private var currentConsentSection: some View {
        Section {
            HStack {
                Label("Collect Consent", systemImage: "checkmark.shield")
                Spacer()
                if isLoading {
                    ProgressView()
                        .padding(.trailing, 4)
                } else {
                    Text(collectConsent.label)
                        .foregroundColor(collectConsent.color)
                        .bold()
                }
            }
            .padding(.vertical, 4)

            Button {
                readConsent()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        } header: {
            Text("Current Consent")
        } footer: {
            Text("The current collect consent value stored in the SDK.")
        }
    }

    private var changeConsentSection: some View {
        Section {
            consentButton(
                title: "Set Yes",
                subtitle: "Allow data collection",
                icon: "checkmark.circle.fill",
                iconColor: .green,
                value: "y"
            )
            consentButton(
                title: "Set No",
                subtitle: "Block data collection",
                icon: "xmark.circle.fill",
                iconColor: .red,
                value: "n"
            )
            consentButton(
                title: "Set Pending",
                subtitle: "Defer until user chooses",
                icon: "questionmark.circle.fill",
                iconColor: .orange,
                value: "p"
            )
        } header: {
            Text("Change Consent")
        } footer: {
            Text("Calls Consent.update(with:) and refreshes the displayed value.")
        }
    }

    private var pushTokenSection: some View {
        Section {
            HStack {
                Label("Device Token", systemImage: "bell.badge")
                Spacer()
                Text(pushToken.map { String($0.prefix(12)) + "…" } ?? "Not Available")
                    .font(.footnote)
                    .foregroundColor(pushToken == nil ? .secondary : .primary)
                    .lineLimit(1)
            }
            .padding(.vertical, 4)

            Button {
                sendPushToken()
            } label: {
                Label("Send Push Token", systemImage: "paperplane")
            }
            .disabled(pushToken == nil)

            Button(role: .destructive) {
                sendNilPushToken()
            } label: {
                Label("Send Nil Token (Clear)", systemImage: "bell.slash")
            }
        } header: {
            Text("Push Token")
        } footer: {
            Text("\"Send Push Token\" calls MobileCore.setPushIdentifier() with the stored device token. \"Send Nil Token\" calls MobileCore.setPushIdentifier(nil), which syncs an empty token (\"\") to the profile. The stored token is preserved so you can re-send it afterward.")
        }
    }

    private var liveActivitySection: some View {
        Section {
            HStack {
                Label("Held PtS Tokens", systemImage: "bolt.horizontal.circle")
                Spacer()
                Text("\(liveActivityTokenCount)")
                    .font(.footnote)
                    .foregroundColor(liveActivityTokenCount == 0 ? .secondary : .primary)
            }
            .padding(.vertical, 4)

            Button {
                sendLiveActivityTokens()
            } label: {
                Label("Send Live Activity Token(s)", systemImage: "paperplane")
            }
            .disabled(liveActivityTokenCount == 0)

            Button(role: .destructive) {
                clearLiveActivities()
            } label: {
                Label("Clear Live Activities", systemImage: "clear")
            }
        } header: {
            Text("Live Activities")
        } footer: {
            Text("\"Send Live Activity Token(s)\" re-syncs the held push-to-start tokens. \"Clear Live Activities\" calls Messaging.clearLiveActivities(), which sends empty push-to-start tokens (update tokens are not sent) and then fully tears down local Live Activity state (all tokens and listener tasks are cleared). Call registerLiveActivities(_:) again to resume token collection.")
        }
    }

    private var identitySection: some View {
        Section {
            HStack {
                Label("ECID", systemImage: "person.text.rectangle")
                Spacer()
                Text(ecid ?? "Not Available")
                    .font(.footnote.monospaced())
                    .foregroundColor(ecid == nil ? .secondary : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .textSelection(.enabled)
            }
            .padding(.vertical, 4)

            HStack {
                Label("Email", systemImage: "envelope")
                Spacer()
                Text(currentEmails.isEmpty ? "None" : currentEmails.joined(separator: ", "))
                    .font(.footnote)
                    .foregroundColor(currentEmails.isEmpty ? .secondary : .primary)
                    .lineLimit(1)
            }
            .padding(.vertical, 4)

            TextField("Enter email address", text: $emailInput)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit { updateIdentity() }

            Button {
                updateIdentity()
            } label: {
                Label("Update Identity", systemImage: "person.crop.circle.badge.checkmark")
            }
            .disabled(!isValidEmail(emailInput))

            Button {
                sendStitchingExperienceEvent()
            } label: {
                Label("Send Experience Event", systemImage: "paperplane.circle")
            }
            .disabled(ecid == nil)

            Button {
                UIPasteboard.general.string = ecid
                lastAction = "Copied ECID to clipboard."
            } label: {
                Label("Copy ECID", systemImage: "doc.on.doc")
            }
            .disabled(ecid == nil)

            Button {
                refreshIdentity()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        } header: {
            Text("Identity")
        } footer: {
            Text("\"Update Identity\" calls Identity.updateIdentities(with:) with the entered address in the \"Email\" namespace (authenticated), stitching it to the current ECID. Any previously set email is removed first so only one email is linked. \"Send Experience Event\" sends a userAccount.login experience event via Edge.sendEvent; Edge attaches the current identityMap (ECID + Email), so the stitch reaches the profile. To test two profiles: set email A, Send Experience Event, Reset Identity (new ECID), then set email B and Send Experience Event.")
        }
    }

    private var identityResetSection: some View {
        Section {
            Button(role: .destructive) {
                resetIdentity()
            } label: {
                Label("Reset Identity", systemImage: "arrow.counterclockwise.circle")
            }
        } header: {
            Text("Identity Reset")
        } footer: {
            Text("Calls MobileCore.resetIdentities() and re-registers for remote notifications.")
        }
    }

    private var lastActionSection: some View {
        Section {
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundColor(.accentColor)
                Text(lastAction)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Last Action")
        }
    }

    // MARK: - Helpers

    private func consentButton(title: String, subtitle: String, icon: String, iconColor: Color, value: String) -> some View {
        Button {
            updateConsent(to: value)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if collectConsent.rawValue == value {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .font(.footnote.bold())
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func updateConsent(to value: String) {
        Consent.update(with: ["consents": ["collect": ["val": value]]])
        lastAction = "Called Consent.update(collect: \"\(value)\")"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            readConsent()
        }
    }

    private func resetIdentity() {
        Identity.getExperienceCloudId { oldEcid, _ in
            MobileCore.resetIdentities()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                UIApplication.shared.registerForRemoteNotifications()
                Identity.getExperienceCloudId { newEcid, _ in
                    DispatchQueue.main.async {
                        let from = oldEcid?.prefix(8) ?? "nil"
                        let to = newEcid?.prefix(8) ?? "nil"
                        lastAction = "Reset identities. ECID: \(from)... -> \(to)..."
                        refreshIdentity()
                    }
                }
            }
        }
    }

    private func isValidEmail(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let atIndex = trimmed.firstIndex(of: "@") else { return false }
        return !trimmed.contains(" ")
            && atIndex != trimmed.startIndex
            && trimmed[trimmed.index(after: atIndex)...].contains(".")
    }

    private func refreshIdentity() {
        Identity.getExperienceCloudId { value, _ in
            DispatchQueue.main.async { ecid = value }
        }
        Identity.getIdentities { identityMap, _ in
            let emails = identityMap?.getItems(withNamespace: Self.emailNamespace)?.map { $0.id } ?? []
            DispatchQueue.main.async { currentEmails = emails }
        }
    }

    private func sendStitchingExperienceEvent() {
        // Edge automatically attaches the current identityMap (ECID + any updated identities such
        // as Email) to every experience event, so this request carries the ECID/Email stitch.
        let xdm: [String: Any] = ["eventType": "userAccount.login"]
        let experienceEvent = ExperienceEvent(xdm: xdm)
        let ecidPrefix = ecid.map { String($0.prefix(8)) + "..." } ?? "nil"
        let emails = currentEmails.isEmpty ? "none" : currentEmails.joined(separator: ", ")
        lastAction = "Sending experience event (ECID: \(ecidPrefix), Email: \(emails))..."

        Edge.sendEvent(experienceEvent: experienceEvent) { handles in
            DispatchQueue.main.async {
                lastAction = "Sent experience event (ECID: \(ecidPrefix), Email: \(emails)). Received \(handles.count) response handle(s)."
            }
        }
    }

    private func updateIdentity() {
        let email = emailInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(email) else {
            lastAction = "Enter a valid email address."
            return
        }

        Identity.getIdentities { identityMap, _ in
            // Remove any previously linked email so the profile is stitched to only the new one.
            let existingEmails = identityMap?.getItems(withNamespace: Self.emailNamespace) ?? []
            for item in existingEmails where item.id != email {
                Identity.removeIdentity(item: item, withNamespace: Self.emailNamespace)
            }

            let newMap = IdentityMap()
            newMap.add(item: IdentityItem(id: email, authenticatedState: .authenticated, primary: false),
                       withNamespace: Self.emailNamespace)
            Identity.updateIdentities(with: newMap)

            DispatchQueue.main.async {
                let ecidPrefix = ecid.map { String($0.prefix(8)) + "..." } ?? "nil"
                lastAction = "Called Identity.updateIdentities with Email: \(email) (ECID: \(ecidPrefix))"
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    refreshIdentity()
                }
            }
        }
    }

    private func sendPushToken() {
        guard let hexToken = pushToken, !hexToken.isEmpty else {
            lastAction = "No push token available to send."
            return
        }
        var tokenData = Data()
        var index = hexToken.startIndex
        while index < hexToken.endIndex {
            let nextIndex = hexToken.index(index, offsetBy: 2)
            guard nextIndex <= hexToken.endIndex,
                  let byte = UInt8(hexToken[index..<nextIndex], radix: 16) else {
                lastAction = "Failed to parse push token."
                return
            }
            tokenData.append(byte)
            index = nextIndex
        }
        MobileCore.setPushIdentifier(tokenData)
        lastAction = "Called setPushIdentifier with token: \(String(hexToken.prefix(12)))…"
    }

    private func sendNilPushToken() {
        // Passing nil is collapsed to an empty token ("") by AEPCore and synced to the profile,
        // clearing a previously registered token. The stored device token is intentionally left
        // in UserDefaults so it can be re-sent with "Send Push Token".
        MobileCore.setPushIdentifier(nil)
        lastAction = "Called setPushIdentifier(nil) — cleared push token (synced as \"\")."
    }

    private func sendLiveActivityTokens() {
        let count = TokenCollector.resendHeldPushToStartTokens()
        lastAction = count > 0
            ? "Re-sent \(count) Live Activity push-to-start token(s)."
            : "No held Live Activity tokens to send."
    }

    private func clearLiveActivities() {
        if #available(iOS 16.1, *) {
            Messaging.clearLiveActivities()
            lastAction = "Called Messaging.clearLiveActivities()."
        } else {
            lastAction = "Live Activities require iOS 16.1 or later."
        }
    }

    private func readConsent() {
        isLoading = true
        Consent.getConsents { consents, error in
            DispatchQueue.main.async {
                isLoading = false
                guard error == nil, let consents = consents else {
                    collectConsent = .unknown
                    return
                }
                let val = (consents["consents"] as? [String: Any])
                    .flatMap { $0["collect"] as? [String: Any] }
                    .flatMap { $0["val"] as? String }
                    ?? ""
                collectConsent = CollectConsentValue(rawValue: val) ?? .unknown
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
