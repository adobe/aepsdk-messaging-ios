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

#if canImport(SwiftUI)
    import SwiftUI
#endif

/// `AEPAsyncImage` provides a convenient way to load images asynchronously with built-in support for caching
/// Use this view for displaying images from remote URLs, caching them to reduce redundant network requests,
/// and seamlessly handling dark/light mode updates.
@available(iOS 15.0, *)
struct AEPAsyncImage<Content>: View where Content: View {
    /// The URL of the image to load in light mode.
    private let lightModeURL: URL

    /// The URL of the image to load in dark mode.
    private let darkModeURL: URL?

    /// A closure that takes an `AsyncImagePhase` and returns a SwiftUI `View` for each phase.
    /// This provides flexibility in displaying loading indicators, fallback images, or the downloaded image.
    private let content: (AsyncImagePhase) -> Content

    /// The current loading phase of the image.
    @State private var phase: AsyncImagePhase = .empty

    /// The color scheme environment variable to detect light/dark mode changes and reload the image if needed.
    @Environment(\.colorScheme) private var colorScheme

    /// Initializes the `AEPAsyncImage` with a URL and content closure.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load.
    ///   - content: A closure that defines the view to display for each image loading phase.
    init(lightModeURL: URL,
         darkModeURL: URL? = nil,
         @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.lightModeURL = lightModeURL
        self.darkModeURL = darkModeURL
        self.content = content
    }

    /// The main view body of `AEPAsyncImage`, which uses the `content` closure to display the appropriate
    /// UI based on the current image loading phase.
    var body: some View {
        content(phase)
            .onAppear {
                loadImage(for: colorScheme)
            }
            .onChange(of: colorScheme) { newColorScheme in
                loadImage(for: newColorScheme)
            }
    }

    /// Loads the image from cache if available, or initiates a download if the image is not cached.
    ///
    /// - Parameter colorScheme: The `ColorScheme` that determines whether to use light or dark mode URL.
    private func loadImage(for colorScheme: ColorScheme) {
        // Determine the URL to use based on color scheme, defaulting to lightModeURL if darkModeURL is nil.
        let currentURL = (colorScheme == .dark ? darkModeURL : lightModeURL) ?? lightModeURL
        if let cachedImage = ImageCache[currentURL] {
            phase = .success(Image(uiImage: cachedImage))
        } else {
            downloadImage(from: currentURL)
        }
    }

    /// Downloads the image from the provided URL, caching it upon successful retrieval.
    ///
    /// - Parameter url: The URL to download the image from.
    private func downloadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    phase = .failure(error)
                }
                return
            }

            if let data = data, let image = UIImage(data: data) {
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
