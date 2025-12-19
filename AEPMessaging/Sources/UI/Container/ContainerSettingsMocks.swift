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
    import SwiftUI
#endif
import Foundation
import AEPServices

/// Mock implementations for testing ContainerSettings locally without server dependency
@available(iOS 15.0, *)
public extension Messaging {
    
    /// Mock version of getContentCardContainerUI for local testing
    /// This simulates the complete flow including proposition fetching and container creation
    static func getContentCardContainerUIMock(for surface: Surface,
                                             customizer: ContentCardCustomizing? = nil,
                                             listener: ContainerEventListening? = nil,
                                             _ completion: @escaping (Result<ContainerUI, ContainerUIError>) -> Void) {
        
        print("🧪 Mock: Getting container UI for surface: \(surface.uri)")
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Use mock propositions
            getPropositionsForSurfacesMock([surface]) { propositionDict, error in
                if let error = error {
                    Log.error(label: UIConstants.LOG_TAG,
                              "Mock: Error retrieving propositions for surface, \(surface.uri). Error \(error)")
                    completion(.failure(.dataUnavailable))
                    return
                }
                
                // Extract container settings using the same logic as real implementation
                guard let propositions = propositionDict?[surface] else {
                    completion(.failure(.dataUnavailable))
                    return
                }
                
                // Search for container settings in propositions using functional approach
                // Debug: Check all propositions and items
                print("🧪 Mock: Checking \(propositions.count) propositions for container settings")
                for (propIndex, proposition) in propositions.enumerated() {
                    print("🧪 Mock: Proposition \(propIndex): \(proposition.items.count) items")
                    for (itemIndex, item) in proposition.items.enumerated() {
                        print("🧪 Mock: Item \(itemIndex): schema=\(item.schema), containerSettings=\(item.containerSchemaData != nil)")
                    }
                }
                
                let containerSettings = propositions
                    .flatMap { $0.items }
                    .compactMap { $0.containerSchemaData }
                    .first
                
                print("🧪 Mock: Found container settings: \(containerSettings != nil)")
                
                // Ensure container settings are present
                guard let containerSettings = containerSettings else {
                    Log.error(label: UIConstants.LOG_TAG,
                              "Mock: No container settings found in propositions for surface: \(surface.uri)")
                    completion(.failure(.containerSettingsNotFound))
                    return
                }
                
                // Create the container UI with the required container settings
                let containerUI = ContainerUI(
                    surface: surface,
                    containerSettings: containerSettings,
                    customizer: customizer,
                    listener: listener
                )
                
                print("✅ Mock: Container UI created successfully")
                completion(.success(containerUI))
            }
        }
    }
    
    /// Mock version of getPropositionsForSurfaces that returns realistic test data
    static func getPropositionsForSurfacesMock(_ surfaces: [Surface],
                                              _ completion: @escaping ([Surface: [Proposition]]?, Error?) -> Void) {
        
        print("🧪 Mock: Getting propositions for \(surfaces.count) surface(s)")
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            var result: [Surface: [Proposition]] = [:]
            
            for surface in surfaces {
                let propositions = createMockPropositions(for: surface)
                result[surface] = propositions
                print("🧪 Mock: Created \(propositions.count) propositions for surface: \(surface.uri)")
            }
            
            completion(result, nil)
        }
    }
    
    /// Creates realistic mock propositions with container settings and content cards
    private static func createMockPropositions(for surface: Surface) -> [Proposition] {
        print("🧪 Mock: Creating propositions for surface: \(surface.uri)")
        
        // Create container settings proposition
        let containerProposition = createMockContainerProposition(surface: surface)
        print("🧪 Mock: Created container proposition with \(containerProposition.items.count) items")
        
        // Debug the container proposition items
        for (index, item) in containerProposition.items.enumerated() {
            print("🧪 Mock: Container item \(index): schema=\(item.schema), hasContainerSettings=\(item.containerSchemaData != nil)")
        }
        
        // Create content card propositions (one of each template)
        let cardPropositions = createMockContentCardPropositions(count: 3, surface: surface)
        print("🧪 Mock: Created \(cardPropositions.count) content card propositions")
        
        return [containerProposition] + cardPropositions
    }
    
    /// Creates a mock proposition containing container settings
    private static func createMockContainerProposition(surface: Surface) -> Proposition {
        print("🧪 Mock: Creating container proposition")
        
        // Simple vertical layout container
        let containerJSON: [String: Any] = [
            "heading": ["content": "📥 Messages"],
            "layout": ["orientation": "vertical"],
            "capacity": 3,
            "emptyStateSettings": [
                "message": ["content": "No messages yet, check back soon!"],
                "image": [
                    "url": "https://example.com/empty-inbox.png",
                    "darkUrl": "https://example.com/empty-inbox-dark.png"
                ]
            ],
            "unread_indicator": [
                "unread_bg": [
                    "clr": [
                        "light": "0xFF4444FF",
                        "dark": "0xFF6666FF"
                    ]
                ],
                "unread_icon": [
                    "placement": "topleft",
                    "image": [
                        "url": "https://example.com/unread.png",
                        "darkUrl": "https://example.com/unread-dark.png"
                    ]
                ]
            ],
            "isUnreadEnabled": true
        ]
        
        // Create item structure matching real SDK format
        let itemData: [String: Any] = containerJSON
        print("🧪 Mock: Container JSON data: \(containerJSON)")
        
        // Create mock item structure
        let mockItem: [String: Any] = [
            "id": "container-settings",
            "schema": MessagingConstants.PersonalizationSchemas.CONTAINER_SETTINGS, 
            "data": itemData
        ]
        print("🧪 Mock: Created mock item structure: \(mockItem)")
        
        // Create mock proposition
        let propositionId = "container-\(surface.uri.hashValue.magnitude)"
        print("🧪 Mock: Creating proposition with id: \(propositionId)")
        
        return createMockProposition(
            id: propositionId,
            surface: surface,
            items: [mockItem]
        )
    }
    
    /// Creates mock content card propositions (exactly one of each template)
    private static func createMockContentCardPropositions(count: Int, surface: Surface) -> [Proposition] {
        let cardTemplates = ["SmallImage", "LargeImage", "ImageOnly"]
        var propositions: [Proposition] = []
        
        // Ensure we create exactly one of each template type
        for i in 0..<min(count, cardTemplates.count) {
            let template = cardTemplates[i] // Direct assignment, not modulo
            let isUnread = i < 2 // First two cards are unread
            
            print("🧪 Mock: Creating card \(i) with template: \(template)")
            
            let cardData = createMockContentCardData(
                template: template,
                index: i,
                isUnread: isUnread,
                surface: surface
            )
            
            let proposition = createMockProposition(
                id: "card-\(template.lowercased())-\(i)-\(surface.uri.hashValue.magnitude)",
                surface: surface,
                items: [cardData]
            )
            
            propositions.append(proposition)
        }
        
        return propositions
    }
    
    /// Gets template JSON based on existing test samples
    private static func loadTemplateJSON(for template: String) -> [String: Any]? {
        switch template {
        case "SmallImage":
            print("🧪 Mock: Using embedded SmallImageTemplate JSON")
            return [
                "expiryDate": 1723163897,
                "meta": [
                    "adobe": ["template": "SmallImage"],
                    "customKey": "customValue"
                ],
                "content": [
                    "actionUrl": "https://actionUrl.com",
                    "title": ["content": "Card Title"],
                    "body": ["content": "Card Body"],
                    "image": [
                        "url": "https://picsum.photos/320/200?random=small",
                        "darkUrl": "https://picsum.photos/320/200?random=small&grayscale"
                    ],
                    "dismissBtn": ["style": "simple"],
                    "buttons": [
                        [
                            "interactId": "purchaseID",
                            "text": ["content": "Buy"],
                            "actionUrl": "https://adobe.com/offer"
                        ],
                        [
                            "interactId": "cancelID", 
                            "text": ["content": "Cancel"],
                            "actionUrl": "app://home"
                        ]
                    ]
                ],
                "contentType": "application/json",
                "publishedDate": 1691541497
            ]
            
        case "LargeImage":
            print("🧪 Mock: Using embedded LargeImageTemplate JSON")
            return [
                "publishedDate": 1701538942,
                "expiryDate": 1712190456,
                "contentType": "application/json",
                "content": [
                    "actionUrl": "https://luma.com/sale",
                    "title": ["content": "Card Title"],
                    "body": ["content": "body"],
                    "image": [
                        "url": "https://picsum.photos/400/300?random=large",
                        "darkUrl": "https://picsum.photos/400/300?random=large&grayscale"
                    ],
                    "dismissBtn": ["style": "simple"],
                    "buttons": [
                        [
                            "interactId": "purchaseID",
                            "text": ["content": "Buy"],
                            "actionUrl": "https://adobe.com/offer"
                        ],
                        [
                            "interactId": "cancelID",
                            "text": ["content": "Cancel"],
                            "actionUrl": "app://home"
                        ]
                    ]
                ],
                "meta": [
                    "adobe": ["template": "LargeImage"],
                    "customKey": "customValue"
                ]
            ]
            
        case "ImageOnly":
            print("🧪 Mock: Using embedded ImageOnlyTemplate JSON")
            return [
                "publishedDate": 1701538942,
                "expiryDate": 1712190456,
                "contentType": "application/json",
                "content": [
                    "actionUrl": "https://google.com",
                    "image": [
                        "url": "https://picsum.photos/350/350?random=imageonly",
                        "darkUrl": "https://picsum.photos/350/350?random=imageonly&grayscale",
                        "alt": "Beautiful imagery"
                    ],
                    "dismissBtn": ["style": "simple"]
                ],
                "meta": [
                    "adobe": ["template": "ImageOnly"],
                    "customKey": "customValue"
                ]
            ]
            
        default:
            return nil
        }
    }
    
    /// Creates mock content card data using existing JSON templates or fallback
    private static func createMockContentCardData(template: String, index: Int, isUnread: Bool, surface: Surface) -> [String: Any] {
        // Try to load from existing JSON template files first
        if let templateJSON = loadTemplateJSON(for: template) {
            // Use the loaded template as base and customize it
            var content = templateJSON["content"] as? [String: Any] ?? [:]
            var meta = templateJSON["meta"] as? [String: Any] ?? [:]
            
            // Customize titles specifically for each template type
            let templateSpecificTitles = [
                "SmallImage": "🎯 Special Offer",
                "LargeImage": "✨ New Feature Alert", 
                "ImageOnly": "🔥 Limited Time Deal"
            ]
            
            // Update title if present in template
            if content["title"] != nil {
                let title = templateSpecificTitles[template] ?? "📱 App Update Available"
                content["title"] = ["content": title]
            }
            
            // Update image URLs to use index-specific Lorem Picsum images
            if var image = content["image"] as? [String: Any] {
                let baseId = index * 10 + 100 // Generate different image IDs
                image["url"] = "https://picsum.photos/id/\(baseId)/320/200"
                image["darkUrl"] = "https://picsum.photos/id/\(baseId)/320/200?grayscale"
                content["image"] = image
            }
            
            // Ensure meta has correct template info
            var adobe = meta["adobe"] as? [String: Any] ?? [:]
            adobe["template"] = template
            meta["adobe"] = adobe
            meta["surface"] = surface.uri
            meta["unread"] = isUnread
            meta["sentDate"] = getMockSentDate(index: index)
            
            // Structure matching real SDK format
            let itemData: [String: Any] = [
                "content": content,
                "publishedDate": templateJSON["publishedDate"] as? Int ?? Int(Date().timeIntervalSince1970) - (index * 3600),
                "expiryDate": templateJSON["expiryDate"] as? Int ?? Int(Date().timeIntervalSince1970) + 86400 * 30,
                "contentType": templateJSON["contentType"] as? String ?? "application/json",
                "meta": meta
            ]
            
            return [
                "id": "content-card-\(template.lowercased())-\(index)",
                "schema": MessagingConstants.PersonalizationSchemas.CONTENT_CARD,
                "data": itemData
            ]
        }
        
        // Fallback to custom mock data if JSON loading fails
        print("🧪 Mock: Using fallback content for \(template)")
        let titles = [
            "🎯 Special Offer #\(index + 1)",
            "✨ New Feature Alert",
            "🔥 Limited Time Deal",
            "📱 App Update Available"
        ]
        
        let bodies = [
            "Don't miss out on this amazing opportunity to save big!",
            "Check out the latest features we've added just for you.",
            "Hurry! This exclusive deal expires soon.",
            "Update now to get the latest improvements and bug fixes."
        ]
        
        let imageUrls = [
            "https://picsum.photos/320/200?random=\(index + 10)",
            "https://picsum.photos/320/200?random=\(index + 20)",
            "https://picsum.photos/320/200?random=\(index + 30)",
            "https://picsum.photos/320/200?random=\(index + 40)"
        ]
        
        var content: [String: Any] = [
            "title": ["content": titles[index % titles.count]],
            "body": ["content": bodies[index % bodies.count]],
            "actionUrl": "https://example.com/action/\(index)",
            "dismissBtn": ["style": "simple"]
        ]
        
        // Add image for templates that support it
        if template != "NoImage" {
            content["image"] = [
                "url": imageUrls[index % imageUrls.count],
                "alt": "Mock image for card \(index + 1)"
            ]
        }
        
        // Add button for some cards
        if index % 2 == 0 {
            content["buttons"] = [[
                "text": ["content": "Learn More"],
                "id": "button-\(index)",
                "interactId": "learnMoreClicked",
                "actionUrl": "https://example.com/learn-more/\(index)"
            ]]
        }
        
        // Structure matching real SDK format - content goes inside data field
        let itemData: [String: Any] = [
            "content": content,  // Content nested inside data
            "publishedDate": Int(Date().timeIntervalSince1970) - (index * 3600), // Stagger times
            "expiryDate": Int(Date().timeIntervalSince1970) + 86400 * 30, // 30 days from now
            "contentType": "application/json",
            "meta": [
                "surface": surface.uri,
                "unread": isUnread,
                "adobe": ["template": template],
                "sentDate": getMockSentDate(index: index)
            ]
        ]
        
        return [
            "id": "content-card-\(template.lowercased())-\(index)",
            "schema": MessagingConstants.PersonalizationSchemas.CONTENT_CARD,
            "data": itemData  // This becomes the itemData in PropositionItem
        ]
    }
    
    /// Gets a mock "sent date" string for variety
    private static func getMockSentDate(index: Int) -> String {
        let timeStrings = ["Just now", "5 minutes ago", "1 hour ago", "2 hours ago", "Yesterday", "2 days ago"]
        return timeStrings[index % timeStrings.count]
    }
    
    /// Creates a mock Proposition object
    private static func createMockProposition(id: String, surface: Surface, items: [[String: Any]]) -> Proposition {
        print("🧪 Mock: createMockProposition called with id: \(id), \(items.count) items")
        
        // Note: This is a simplified mock creation
        // In reality, we'd need to properly construct Proposition objects
        // For now, we'll create a basic structure that works with our parsing
        
        let _: [String: Any] = [
            "id": id,
            "scope": surface.uri,
            "items": items
        ]
        
        // Create a mock Proposition
        // Extract the required fields from each item to create MockPropositionItem correctly
        let propositionItems = items.compactMap { itemDict -> MockPropositionItem? in
            print("🧪 Mock: Processing item dict: \(itemDict)")
            guard let itemId = itemDict["id"] as? String,
                  let schemaString = itemDict["schema"] as? String,
                  let data = itemDict["data"] as? [String: Any] else {
                print("🧪 Mock: Warning - Missing required fields in item: \(itemDict)")
                return nil
            }
            print("🧪 Mock: Creating MockPropositionItem with itemId: \(itemId), schema: \(schemaString)")
            let item = MockPropositionItem(itemId: itemId, schema: schemaString, data: data)
            print("🧪 Mock: Created item with schema: \(item.schema), containerSettings: \(item.containerSchemaData != nil)")
            return item
        }
        
        print("🧪 Mock: Created proposition with \(propositionItems.count) proposition items")
        return MockProposition(id: id, surface: surface, items: propositionItems)
    }
}

// MARK: - Mock Objects

/// Mock Proposition for testing
@available(iOS 15.0, *)
class MockProposition: Proposition {
    init(id: String, surface: Surface, items: [PropositionItem]) {
        // Create proper scopeDetails with activity ID for activityId computation
        let scopeDetails: [String: Any] = [
            MessagingConstants.Event.Data.Key.Personalization.ACTIVITY: [
                MessagingConstants.Event.Data.Key.Personalization.ID: id
            ]
        ]
        super.init(uniqueId: id, scope: surface.uri, scopeDetails: scopeDetails, items: items)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

/// Mock PropositionItem for testing
@available(iOS 15.0, *)
class MockPropositionItem: PropositionItem {
    init(itemId: String, schema: String, data: [String: Any]) {
        let schemaType = SchemaType(from: schema)
        print("🧪 Mock: Creating MockPropositionItem with id: \(itemId), schema: \(schema)")
        super.init(itemId: itemId, schema: schemaType, itemData: data)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override var contentCardSchemaData: ContentCardSchemaData? {
        // Check if this is a content card item
        guard schema.toString().contains("content-card") else {
            return nil
        }
        
        // Convert itemData to ContentCardSchemaData (itemData is the `data` field)
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: itemData)
            let contentCard = try JSONDecoder().decode(ContentCardSchemaData.self, from: jsonData)
            
            // Debug template detection
            if let meta = itemData["meta"] as? [String: Any],
               let adobe = meta["adobe"] as? [String: Any],
               let template = adobe["template"] as? String {
                print("🧪 Mock: Decoded ContentCard with template: \(template)")
                
                // Special debug for ImageOnly template
                if template == "ImageOnly" {
                    if let content = itemData["content"] as? [String: Any],
                       let image = content["image"] as? [String: Any] {
                        print("🧪 Mock: ImageOnly has image data: \(image)")
                    } else {
                        print("🧪 Mock: WARNING - ImageOnly missing image data in content!")
                        print("🧪 Mock: Content structure: \(itemData["content"] ?? "nil")")
                    }
                }
            } else {
                print("🧪 Mock: Warning - No template found in meta.adobe.template")
                print("🧪 Mock: Meta structure: \(itemData["meta"] ?? "nil")")
            }
            
            return contentCard
        } catch {
            print("🧪 Mock: Failed to decode ContentCardContainerSchemaData: \(error)")
            print("🧪 Mock: ItemData structure: \(itemData)")
            return nil
        }
    }
    
    override var containerSchemaData: ContainerSchemaData? {
        print("🧪 Mock: containerSettingsContainerSchemaData called for schema: \(schema.toString())")
        
        // Check if this is a container settings item
        guard schema.toString().contains("container-settings") else {
            print("🧪 Mock: Schema doesn't contain 'container-settings', returning nil")
            return nil
        }
        
        print("🧪 Mock: Schema matches container-settings, attempting to decode")
        print("🧪 Mock: ItemData keys: \(Array(itemData.keys))")
        print("🧪 Mock: ItemData: \(itemData)")
        
        // Convert itemData to ContainerSchemaData (itemData is the `data` field)
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: itemData)
            print("🧪 Mock: Successfully serialized itemData to JSON")
            let containerSettings = try JSONDecoder().decode(ContainerSchemaData.self, from: jsonData)
            print("🧪 Mock: Successfully decoded ContainerSchemaData")
            return containerSettings
        } catch {
            print("🧪 Mock: Failed to decode ContainerSchemaData: \(error)")
            print("🧪 Mock: ItemData structure: \(itemData)")
            return nil
        }
    }
}
