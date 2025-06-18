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

/// A utility class for building JSON schema and sample payloads for Live Activity types
@available(iOS 16.1, *)
final class LiveActivityDebugSchemaBuilder {
    // MARK: - Constants
    
    private enum JSONSchemaKeys {
        static let type = "type"
        static let properties = "properties"
        static let required = "required"
        static let items = "items"
        static let additionalProperties = "additionalProperties"
        static let null = "null"
        static let string = "string"
        static let integer = "integer"
        static let number = "number"
        static let boolean = "boolean"
        static let object = "object"
        static let array = "array"
    }
    
    private enum PayloadKeys {
        static let attributesType = "attributes-type"
        static let attributes = "attributes"
        static let contentState = "content-state"
    }
    
    private enum EventDataKeys {
        static let samplePayload = "examplePayload"
        static let jsonSchema = "jsonSchema"
    }
    
    // MARK: - Public Methods
    
    /// Builds the complete event data containing both sample payload and JSON schema
    /// - Parameters:
    ///   - attributeTypeName: The name of the Live Activity type
    ///   - attributes: The attributes object to analyze
    ///   - contentState: The content state object to analyze
    /// - Returns: A dictionary containing both sample payload and JSON schema
    static func buildEventData(attributeTypeName: String, attributes: Any, contentState: Any) -> [String: Any] {
        [
            EventDataKeys.samplePayload: buildSamplePayload(attributeTypeName: attributeTypeName, attributes: attributes, contentState: contentState),
            EventDataKeys.jsonSchema: buildJSONSchema(attributeTypeName: attributeTypeName, attributes: attributes, contentState: contentState)
        ]
    }
    
    // MARK: - Private Methods
    
    /// Builds a sample payload from the given objects
    private static func buildSamplePayload(attributeTypeName: String, attributes: Any, contentState: Any) -> [String: Any] {
        [
            PayloadKeys.attributesType: attributeTypeName,
            PayloadKeys.attributes: toJSON(attributes),
            PayloadKeys.contentState: toJSON(contentState)
        ]
    }
        
    /// Builds a JSON schema from the given objects
    private static func buildJSONSchema(attributeTypeName: String, attributes: Any, contentState: Any) -> [String: Any] {
        [
            PayloadKeys.attributesType: attributeTypeName,
            PayloadKeys.attributes: buildJSONSchemaObject(of: attributes),
            PayloadKeys.contentState: buildJSONSchemaObject(of: contentState)
        ]
    }
    
    /// Maps a Swift type name to its JSON schema type
    private static func mapTypeToJSONSchemaType(_ typeName: String) -> String {
        switch typeName {
        case "String":
            return JSONSchemaKeys.string
        case "Int", "Int8", "Int16", "Int32", "Int64",
             "UInt", "UInt8", "UInt16", "UInt32", "UInt64":
            return JSONSchemaKeys.integer
        case "Double", "Float", "Float32", "Float64":
            return JSONSchemaKeys.number
        case "Bool":
            return JSONSchemaKeys.boolean
        default:
            return JSONSchemaKeys.object
        }
    }
    
    /// Reflects a Swift value's type into a JSON-Schema snippet
    private static func buildJSONSchemaObject(of value: Any) -> [String: Any] {
        let mirror = Mirror(reflecting: value)
        let rawType = String(describing: Swift.type(of: value))
        
        // Handle optional types
        if mirror.displayStyle == .optional {
            return handleOptionalType(mirror: mirror)
        }
        
        // Handle arrays
        if let array = value as? [Any] {
            return buildArraySchema(array: array)
        }
        
        // Handle dictionaries
        if let dict = value as? [AnyHashable: Any] {
            return buildDictionarySchema(dict: dict)
        }
        
        // Handle leaf types
        if mirror.children.isEmpty || mirror.displayStyle == .enum || rawType.hasPrefix("Swift.") {
            return buildLeafTypeSchema(rawType: rawType)
        }
        
        // Handle structs and classes
        return buildStructOrClassSchema(mirror: mirror)
    }
    
    /// Handles optional types in the schema
    private static func handleOptionalType(mirror: Mirror) -> [String: Any] {
        // Get the type name to determine the base type
        let typeName = String(describing: mirror.subjectType)
        
        if typeName.hasPrefix("Optional<") {
            let baseTypeName = typeName.dropFirst(9).dropLast(1)
            
            // Check if it's an array type
            if String(baseTypeName).contains("Array<") || String(baseTypeName).hasSuffix("[]") {
                return [JSONSchemaKeys.type: JSONSchemaKeys.array]
            }
            
            // Try to map it to a primitive type
            let mappedType: String = mapTypeToJSONSchemaType(String(baseTypeName))
            
            // If it maps to a primitive type, return that
            if mappedType != JSONSchemaKeys.object {
                return [JSONSchemaKeys.type: mappedType]
            } else {
                // For custom types (structs/classes), explore their properties if available
                if let child = mirror.children.first {
                    return buildJSONSchemaObject(of: child.value)
                } else {
                    // If no children (nil value), return object type for custom types
                    return [JSONSchemaKeys.type: JSONSchemaKeys.object]
                }
            }
        }
        
        // Fallback for non-optional types
        return [JSONSchemaKeys.type: JSONSchemaKeys.null]
    }
        
    /// Builds schema for array types
    private static func buildArraySchema(array: [Any]) -> [String: Any] {
        let itemsSchema: [String: Any]
        if let first = array.first {
            itemsSchema = buildJSONSchemaObject(of: first)
        } else {
            itemsSchema = [JSONSchemaKeys.type: JSONSchemaKeys.object]
        }
        return [
            JSONSchemaKeys.type: JSONSchemaKeys.array,
            JSONSchemaKeys.items: itemsSchema
        ]
    }

    /// Builds schema for dictionary types
    private static func buildDictionarySchema(dict: [AnyHashable: Any]) -> [String: Any] {
        let valueSchema: [String: Any]
        if let (_, firstVal) = dict.first {
            valueSchema = buildJSONSchemaObject(of: firstVal)
        } else {
            valueSchema = [JSONSchemaKeys.type: JSONSchemaKeys.object]
        }
        return [
            JSONSchemaKeys.type: JSONSchemaKeys.object,
            JSONSchemaKeys.additionalProperties: valueSchema
        ]
    }

    /// Builds schema for leaf types (primitives)
    private static func buildLeafTypeSchema(rawType: String) -> [String: Any] {
        return [JSONSchemaKeys.type: mapTypeToJSONSchemaType(rawType)]
    }

    /// Builds schema for structs and classes
    private static func buildStructOrClassSchema(mirror: Mirror) -> [String: Any] {
        var properties: [String: Any] = [:]
        var required: [String] = []
        
        for child in mirror.children {
            guard let key = child.label, !key.hasPrefix("_") else { continue }
            let childSchema = buildJSONSchemaObject(of: child.value)
            properties[key] = childSchema
            
            let childTypeName = String(describing: Swift.type(of: child.value))
            if !childTypeName.hasPrefix("Optional<") {
                required.append(key)
            }
        }
        
        var result: [String: Any] = [
            JSONSchemaKeys.type: JSONSchemaKeys.object,
            JSONSchemaKeys.properties: properties
        ]
        if !required.isEmpty {
            result[JSONSchemaKeys.required] = required
        }
        return result
    }
    
    /// Converts a Swift value to a JSON-compatible format by recursively processing its structure
    /// - Parameter value: The Swift value to convert
    /// - Returns: A JSON-compatible value (String, Number, Bool, Array, Dictionary, or NSNull)
    private static func toJSON(_ value: Any) -> Any {
        let mirror = Mirror(reflecting: value)

        // Handle optional types
        if mirror.displayStyle == .optional {
            if let child = mirror.children.first {
                return toJSON(child.value)
            }
            return NSNull()
        }

        // Handle arrays
        if let array = value as? [Any] {
            return array.map { toJSON($0) }
        }

        // Handle dictionaries
        if let dict = value as? [AnyHashable: Any] {
            return dict.reduce(into: [String: Any]()) { result, pair in
                result["\(pair.key)"] = toJSON(pair.value)
            }
        }

        // Handle leaf types
        if mirror.children.isEmpty {
            return value
        }

        // Handle structs and classes
        return mirror.children.reduce(into: [String: Any]()) { result, child in
            guard let label = child.label, !label.hasPrefix("_") else { return }
            result[label] = toJSON(child.value)
        }
    }
} 
