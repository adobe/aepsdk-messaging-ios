/*
Copyright 2025 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/

import SwiftUI
import ActivityKit

// MARK: - Section Header & Description
struct BigHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.title)
            .bold()
            .foregroundColor(.accentColor)
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.title3)
            .bold()
            .foregroundColor(.primary.opacity(0.7))
    }
}

 struct SectionSubHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.subheadline)
            .bold()
            .foregroundColor(.brown)
    }
}

struct SectionDescription: View {
    let text: String
    var body: some View {
        Text(text)
            .fontWeight(.regular)
            .foregroundColor(.secondary)
            .font(.system(size: 10))
    }
}

// MARK: - Helper: Truncate Token
func truncateToken(_ token: String) -> String {
    let prefixCount = min(5, token.count)
    let suffixCount = min(5, token.count - prefixCount)
    
    guard token.count > (prefixCount + suffixCount) else {
        return token
    }
    
    let start = token.startIndex
    let prefix = token[start..<token.index(start, offsetBy: prefixCount)]
    let suffix = token[token.index(token.endIndex, offsetBy: -suffixCount)..<token.endIndex]
    return "\(prefix).....\(suffix)"
}


// MARK: - Generic Push-to-Start Section

/// Displays a push-to-start token (iOS 17.2+).
/// You can reuse this for both GameScore and FoodDelivery by passing the correct Attributes.
@available(iOS 17.2, *)
struct PushToStartSection<Attributes: ActivityAttributes>: View {
    
    /// The push-to-start token you get from `PushTokenManager`.
    var pushToStartToken: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionHeader(title: "Remote")
                Spacer()
                SectionSubHeader(title: "iOS 17.2+")
            }
            SectionDescription(text: "Use this push-to-start token to send a push notification that starts the Live Activity remotely.")
            
            HStack {
                let displayToken = pushToStartToken.isEmpty
                    ? "Not available"
                    : truncateToken(pushToStartToken)
                
                Text(displayToken)
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Copy button
                Button {
                    UIPasteboard.general.string = pushToStartToken
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .foregroundColor(pushToStartToken.isEmpty ? .gray : .blue)
                .disabled(pushToStartToken.isEmpty)
            }
        }
        .padding(.horizontal)
    }
}


