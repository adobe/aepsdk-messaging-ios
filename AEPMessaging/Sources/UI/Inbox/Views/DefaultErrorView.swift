/*
 Copyright 2026 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

#if canImport(SwiftUI)
    import SwiftUI
#endif
import Foundation

/// Default error view shown when content cards fail to load
@available(iOS 15.0, *)
struct DefaultErrorView: View {
    let error: Error
    let onRetry: () -> Void
    
    private enum Constants {
        static let verticalSpacing: CGFloat = 16
        static let iconSize: CGFloat = 48
        static let icon = "exclamationmark.triangle"
        static let title = "Error loading content cards"
        static let buttonTitle = "Try Again"
    }
    
    var body: some View {
        VStack(spacing: Constants.verticalSpacing) {
            Image(systemName: Constants.icon)
                .font(.system(size: Constants.iconSize))
                .foregroundColor(.red)
            
            Text(Constants.title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(Constants.buttonTitle) {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

