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

import SwiftUI

@available(iOS 15.0, *)
struct AEPAsyncImage<Content>: View where Content: View {
    
    private let url: URL
    private let content: (AsyncImagePhase) -> Content
    @State private var phase: AsyncImagePhase = .empty
    @Environment(\.colorScheme) private var colorScheme // Observe color scheme changes

    init(
        url: URL,
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ) {
        self.url = url
        self.content = content
    }

    var body: some View {
        content(phase)
            .onAppear {
                loadImage()
            }
            .onChange(of: colorScheme) { newColorSchema in
                loadImage() // Reload the image when theme changes
            }
    }

    private func loadImage() {
        if let cachedImage = ImageCache[url] {
            // Use cached image
            phase = .success(Image(uiImage: cachedImage))
        } else {
            // Download the image
            downloadImage()
        }
    }

    private func downloadImage() {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    phase = .failure(error)
                }
                return
            }

            if let data = data, let image = UIImage(data: data) {
                // Cache the downloaded image
                ImageCache[url] = image
                DispatchQueue.main.async {
                    phase = .success(Image(uiImage: image))
                }
            } else {
                DispatchQueue.main.async {
                    phase = .empty
                }
            }
        }.resume()
    }
}
