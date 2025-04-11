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

#if canImport(ActivityKit)
    import ActivityKit
#endif

// Extension on Activity where the Attributes conform to LiveActivityAttributes
@available(iOS 16.1, *)
extension Activity where Attributes: LiveActivityAttributes {
    /// Returns a concise string describing the key details of this `Activity` and its attributes.
    ///
    /// - Parameter includeLiveActivityData: A Boolean value indicating whether to include the
    ///   full `LiveActivityData` details in the returned string. Defaults to `false`.
    /// - Returns: A debug string summarizing this `Activity` and, optionally, its `liveActivityData`.
    func debugDescription(includeLiveActivityData: Bool = false) -> String {
        let attributeTypeName = Attributes.attributeTypeName
        let liveActivityData = attributes.liveActivityData
        let liveActivityID = liveActivityData.liveActivityID ?? MessagingConstants.Event.Data.Value.UNAVAILABLE

        var result = "Type: \(attributeTypeName), Apple Live Activity ID: \(id), LiveActivityID: \(liveActivityID)"
        if includeLiveActivityData {
            result = "\(result), LiveActivityData: \(liveActivityData)"
        }

        return result
    }
}
