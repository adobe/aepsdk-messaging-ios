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

import AEPServices
import Foundation

@objc(AEPSurface)
@objcMembers
public class Surface: NSObject, Codable {
    /// Unique surface URI string
    public let uri: String

    var isValid: Bool {
        guard URL(string: uri) != nil else {
            Log.warning(label: MessagingConstants.LOG_TAG,
                        "Invalid surface URI found \(uri).")
            return false
        }
        return true
    }

    public init(path: String) {
        guard !path.isEmpty else {
            uri = ""
            return
        }
        uri = Bundle.main.mobileappSurface + MessagingConstants.PATH_SEPARATOR + path
    }

    init(uri: String) {
        self.uri = uri
    }

    override convenience init() {
        self.init(uri: Bundle.main.mobileappSurface)
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Surface else {
            return false
        }
        return uri == rhs.uri
    }

    override public var hash: Int {
        var hasher = Hasher()
        hasher.combine(uri)
        return hasher.finalize()
    }
}
