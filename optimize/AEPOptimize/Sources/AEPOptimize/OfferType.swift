/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

/// Enum representing the supported Offer Types.
@objc(AEPOfferType)
public enum OfferType: Int, Codable {
    /// Unknown Offer type
    case unknown = 0

    /// JSON Offer
    case json = 1

    /// Plain text Offer
    case text = 2

    /// Html Offer
    case html = 3

    /// Image Offer
    case image = 4

    /// Initializes OfferType with the provided format string.
    /// - Parameter format: Offer format string
    init(from format: String) {
        switch format {
        case "application/json":
            self = .json

        case "text/plain":
            self = .text

        case "text/html":
            self = .html

        default:
            self = format.starts(with: "image/") ? .image : .unknown
        }
    }
}
