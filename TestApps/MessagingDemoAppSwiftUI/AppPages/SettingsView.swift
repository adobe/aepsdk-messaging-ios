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

import AEPEdgeConsent
import SwiftUI

struct SettingsView: View {
    @State private var collectConsent: CollectConsentValue = .unknown
    @State private var isLoading = false
    @State private var lastAction: String = ""

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
                if !lastAction.isEmpty {
                    lastActionSection
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .onAppear { readConsent() }
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
