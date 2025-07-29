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

import ActivityKit

/// A protocol that enables Live Activities to integrate with Adobe Experience Platform.
///
/// Conforming types can associate required Adobe Experience Platform data with iOS Live Activities.
/// Any custom `ActivityAttributes` struct must implement this protocol when registering
/// a Live Activity with the SDK.
@available(iOS 16.1, *)
public protocol LiveActivityAttributes: ActivityAttributes {
    /// The Adobe Experience Platform data associated with the Live Activity.
    var liveActivityData: LiveActivityData { get }
}
