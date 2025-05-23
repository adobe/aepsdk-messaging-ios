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

import AEPServices
import Foundation

@available(iOS 15.0, *)
public extension Messaging {
    /// Retrieves the content cards UI for a given surface.
    /// - Parameters:
    ///   - surface: The surface for which to retrieve the content cards.
    ///   - customizer: An optional ContentCardCustomizable object to customize the appearance of the content card template.
    ///   - listener: An optional ContentCardUIEventListening object to listen to UI events from the content card.
    ///   - completion: A completion handler that is called with a `Result` type containing either:
    ///     - success([ContentCardUI]):  An array of `ContentCardUI` objects if the operation is successful.
    ///     - failure(Error) : An error indicating the failure reason
    static func getContentCardsUI(for surface: Surface,
                                  customizer: ContentCardCustomizing? = nil,
                                  listener: ContentCardUIEventListening? = nil,
                                  _ completion: @escaping (Result<[ContentCardUI], Error>) -> Void) {
        // Request propositions for the specified surface from Messaging extension.
        Messaging.getPropositionsForSurfaces([surface]) { propositionDict, error in
            if let error = error {
                Log.error(label: UIConstants.LOG_TAG,
                          "Error retrieving content cards UI for surface, \(surface.uri). Error \(error)")
                completion(.failure(error))
                return
            }

            var cards: [ContentCardUI] = []

            // unwrap the proposition items for the given surface. Bail out with error if unsuccessful
            guard let propositions = propositionDict?[surface] else {
                completion(.failure(ContentCardUIError.dataUnavailable))
                return
            }

            for proposition in propositions {
                // attempt to create a ContentCardUI instance with the schema data.
                guard let contentCard = ContentCardUI.createInstance(with: proposition,
                                                                     customizer: customizer,
                                                                     listener: listener) else {
                    Log.warning(label: UIConstants.LOG_TAG,
                                "Failed to create ContentCardUI for proposition with ID: \(proposition.uniqueId)")
                    continue
                }

                // append the successfully created content card to the cards array.
                cards.append(contentCard)
            }

            completion(.success(cards))
        }
    }
}
