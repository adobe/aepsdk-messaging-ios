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

// MARK: - Model

struct CBEContentItem: Identifiable {
    let id = UUID()
    let offerId: String
    let title: String
    let description: String
    let body: String
    /// Any fields in the JSON object beyond id/title/description/body
    let extra: [(key: String, value: String)]
}

// MARK: - View

struct CodeBasedView: View {
    // Surface path — editable so testers can switch surfaces without a rebuild
    @State private var surfacePath: String = Constants.SurfaceName.CBE_JSON

    // XDM input — pre-filled with the Chipotle Newport-offer example
    @State private var xdmInput: String = ""
    @State private var xdmParseError: String = ""

    // Fetch state
    @State private var isLoading: Bool = false
    @State private var fetchStatus: String = ""
    @State private var contentItems: [CBEContentItem] = []
    @State private var didFetch: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // ── Surface ───────────────────────────────────────────────
                sectionHeader("Surface")
                TextField("Surface path (e.g. akhil-test)", text: $surfacePath)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                Divider()

                // ── XDM Input ─────────────────────────────────────────────
                sectionHeader("XDM Data (JSON)")

                TextEditor(text: $xdmInput)
                    .frame(minHeight: 80, maxHeight: 140)
                    .font(.system(.footnote, design: .monospaced))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                    )

                if !xdmParseError.isEmpty {
                    Text(xdmParseError)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Divider()

                // ── Fetch Buttons ─────────────────────────────────────────
                HStack(spacing: 12) {
                    Button {
                        fetch(useXdm: true)
                    } label: {
                        Label("Fetch with XDM", systemImage: "arrow.down.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)

                    Button {
                        fetch(useXdm: false)
                    } label: {
                        Label("Fetch with nil", systemImage: "arrow.down.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isLoading)
                }

                // ── Status ────────────────────────────────────────────────
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Fetching propositions…").font(.caption).foregroundColor(.secondary)
                    }
                } else if !fetchStatus.isEmpty {
                    Text(fetchStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }

                Divider()

                // ── Results ───────────────────────────────────────────────
                sectionHeader("Offer Content")

                if contentItems.isEmpty && didFetch && !isLoading {
                    Text("No content returned for this surface / XDM combination.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(contentItems) { item in
                        offerCard(item)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Code Based")
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.headline)
    }

    @ViewBuilder
    private func offerCard(_ item: CBEContentItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !item.title.isEmpty {
                Text(item.title)
                    .font(.title3).bold()
            }
            if !item.description.isEmpty {
                Text(item.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            if !item.body.isEmpty {
                Text(item.body)
                    .font(.body)
            }
            if !item.offerId.isEmpty {
                Text("ID: \(item.offerId)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            // Extra fields (e.g. deviceModel, restaurantID, etc.)
            ForEach(item.extra, id: \.key) { pair in
                HStack(alignment: .top, spacing: 4) {
                    Text("\(pair.key):")
                        .font(.caption).bold()
                    Text(pair.value)
                        .font(.caption)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }

    // MARK: - Fetch Logic

    private func fetch(useXdm: Bool) {
        xdmParseError = ""
        contentItems = []
        didFetch = false
        isLoading = true

        // Parse XDM if requested
        var xdm: [String: Any]? = nil
        if useXdm {
            let trimmed = xdmInput.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let data = trimmed.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                xdmParseError = "⚠️ Invalid JSON — check XDM input"
                isLoading = false
                return
            }
            xdm = parsed
        }

        fetchStatus = useXdm
            ? "Last: WITH XDM → \(xdmInput.trimmingCharacters(in: .whitespacesAndNewlines))"
            : "Last: NO XDM (nil)"

        let surface = Surface(path: surfacePath)
        Messaging.updatePropositionsForSurfaces([surface], withXdm: xdm) { _ in
            Messaging.getPropositionsForSurfaces([surface]) { dict, _ in
                DispatchQueue.main.async {
                    isLoading = false
                    didFetch = true
                    contentItems = parseContentItems(from: dict)
                }
            }
        }
    }

    // MARK: - Parsing

    private func parseContentItems(from dict: [Surface: [Proposition]]?) -> [CBEContentItem] {
        var items: [CBEContentItem] = []
        let knownKeys: Set<String> = ["id", "title", "description", "body"]

        for (_, props) in (dict ?? [:]) {
            for prop in props {
                for propItem in prop.items where propItem.schema == .jsonContent {
                    let objects: [[String: Any]]
                    if let arr = propItem.jsonContentArray as? [[String: Any]] {
                        objects = arr
                    } else if let single = propItem.jsonContentDictionary {
                        objects = [single]
                    } else {
                        objects = []
                    }

                    for obj in objects {
                        let extra = obj
                            .filter { !knownKeys.contains($0.key) }
                            .map { (key: $0.key, value: String(describing: $0.value)) }
                            .sorted { $0.key < $1.key }
                        items.append(CBEContentItem(
                            offerId:     obj["id"]          as? String ?? "",
                            title:       obj["title"]       as? String ?? "",
                            description: obj["description"] as? String ?? "",
                            body:        obj["body"]        as? String ?? "",
                            extra:       extra
                        ))
                    }
                }
            }
        }
        return items
    }
}

#Preview {
    NavigationView {
        CodeBasedView()
    }
}
