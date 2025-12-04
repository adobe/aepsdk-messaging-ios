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

/// An enum which describes different errors that ContainerSettingsUI API's can return
@available(iOS 15.0, *)
public enum ContainerUIError: Int, Error {
    public typealias RawValue = Int
    
    /// No propositions were returned for the specified surface
    case dataUnavailable = 1
    
    /// Container settings were not found in the propositions
    case containerSettingsNotFound = 2
    
    /// Invalid container settings schema or parsing failed
    case invalidContainerSettings = 3
    
    /// Container creation failed due to internal error
    case containerCreationFailed = 4
}

/// Extension to provide user-friendly error descriptions
@available(iOS 15.0, *)
extension ContainerUIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .dataUnavailable:
            return "No propositions available for the specified surface"
        case .containerSettingsNotFound:
            return "Container settings not found in propositions"
        case .invalidContainerSettings:
            return "Invalid container settings schema or parsing failed"
        case .containerCreationFailed:
            return "Container creation failed due to internal error"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .dataUnavailable:
            return "The surface may not be configured or no campaigns are targeting it"
        case .containerSettingsNotFound:
            return "The propositions do not contain valid container settings data"
        case .invalidContainerSettings:
            return "The container settings JSON schema is malformed or incompatible"
        case .containerCreationFailed:
            return "An internal error occurred while creating the container UI"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .dataUnavailable:
            return "Verify the surface configuration and ensure campaigns are active"
        case .containerSettingsNotFound:
            return "Check that the proposition contains container settings in the expected format"
        case .invalidContainerSettings:
            return "Validate the container settings JSON against the expected schema"
        case .containerCreationFailed:
            return "Check logs for additional error details and retry the operation"
        }
    }
}
