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

import AEPCore
import Foundation

// MARK: Event extension

extension Event {
    /// Decode an instance of given type from the event data.
    /// - Parameter key: Event data key, default value is nil.
    /// - Returns: Optional type instance
    func getTypedData<T: Decodable>(for key: String? = nil) -> T? {
        let key = key ?? ""
        guard
            let jsonObject = !key.isEmpty ? data?[key] : data as Any,
            let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject)
        else {
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: jsonData)
    }

    /// Creates a response event with specified AEPError type added in the Event data.
    /// - Parameter error: type of AEPError
    /// - Returns: error response Event
    func createErrorResponseEvent(_ error: AEPError) -> Event {
        createResponseEvent(name: OptimizeConstants.EventNames.OPTIMIZE_RESPONSE,
                            type: EventType.optimize,
                            source: EventSource.responseContent,
                            data: [
                                OptimizeConstants.EventDataKeys.RESPONSE_ERROR: error.rawValue
                            ])
    }
}
