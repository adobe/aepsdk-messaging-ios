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
    import AEPServices
    import SwiftUI
#endif

/// `AEPAsyncImage` provides a convenient way to load images asynchronously with built-in support for caching
/// Use this view for displaying images from remote URLs, caching them to reduce redundant network requests,
/// and seamlessly handling dark/light mode updates.
@available(iOS 15.0, *)
struct AEPAsyncImageView<Content>: View where Content: View {
    /// The model containing the data about the image.
    private let model: AEPImage

    /// A closure that takes an `AsyncImagePhase` and returns a SwiftUI `View` for each phase.
    /// This provides flexibility in displaying loading indicators, fallback images, or the downloaded image.
    private let content: (AsyncImagePhase) -> Content

    /// The current loading phase of the image.
    @State private var phase: AsyncImagePhase = .empty

    /// The color scheme environment variable to detect light/dark mode changes and reload the image if needed.
    @Environment(\.colorScheme) private var colorScheme

    /// Initializes the `AEPAsyncImage` with a AEPImage model class  and content closure.
    ///
    /// - Parameters:
    ///   - model: The AEPImage model class that contains data to populate the image
    ///   - content: A closure that defines the view to display for each image loading phase.
    init(_ model: AEPImage,
         @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.model = model
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
        // Determine the URL to use based on color scheme
        let url = themeBasedURL(colorScheme)
        if let cachedImage = ContentCardImageCache[url] {
            phase = .success(Image(uiImage: cachedImage))
        } else {
            downloadImage(from: url)
        }
    }

    /// Downloads the image from the provided URL, caching it upon successful retrieval.
    ///
    /// - Parameter url: The URL to download the image from.
    private func downloadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                handleDownloadResult {
                    phase = .failure(error)
                }
                return
            }

            if let data = data, let image = UIImage(data: data) {
                ContentCardImageCache[url] = image
                handleDownloadResult {
                    phase = .success(Image(uiImage: image))
                }
            } else {
                handleDownloadResult {
                    phase = .empty
                }
            }
        }.resume()
    }

    /// Determines the appropriate URL for the image based on the device's color scheme.
    /// - Parameter colorScheme: The `ColorScheme` that determines whether to use light or dark mode URL.
    ///
    /// - Returns: The URL to be used for the image.
    private func themeBasedURL(_ colorScheme: ColorScheme) -> URL {
        if colorScheme == .dark {
            return model.darkUrl ?? model.url!
        } else {
            return model.url!
        }
    }

    /// Handles the result of a download operation.
    /// This method ensures that UI updates occur only when the app is visible to the user.
    /// It executes the provided closure on the main queue if the app is not in the background.
    ///
    /// - Parameter updatePhase: A closure that updates the UI depending on download result
    private func handleDownloadResult(_ updatePhase: @escaping () -> Void) {
        if !AppStateManager.shared.isAppInBackground {
            Log.debug(label: UIConstants.LOG_TAG, "Updating downloaded image to content card.")
            DispatchQueue.main.async {
                updatePhase()
            }
        } else {
            Log.debug(label: UIConstants.LOG_TAG, "Preventing to apply downloaded image in background")
        }
    }
}
