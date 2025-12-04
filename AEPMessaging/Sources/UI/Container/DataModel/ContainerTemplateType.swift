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

import Foundation

/// Container template type enum based on orientation and unread settings
@available(iOS 15.0, *)
public enum ContainerTemplateType: String, CaseIterable {
    /// Inbox template: vertical scrolling with unread indicator
    case inbox = "Inbox"
    
    /// Carousel template: horizontal scrolling without unread indicator
    case carousel = "Carousel"
    
    /// Custom template: configurable scrolling and unread settings
    case custom = "Custom"
    
    /// Unknown template type
    case unknown = "Unknown"
}
