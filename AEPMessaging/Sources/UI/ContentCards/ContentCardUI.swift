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

import AEPServices
import Foundation

/// ContentCardUI is a class that holds data for a content card and provides a SwiftUI view representation of that content.
@available(iOS 15.0, *)
public class ContentCardUI: Identifiable {

    /// The underlying data model for the content card.
    let proposition: Proposition

    /// The schema data associated with the content card.
    public let schemaData: ContentCardSchemaData

    /// Priority of the `Proposition` entered in the AJO UI for the corresponding campaign
    public var priority: Int {
        proposition.priority
    }

    /// The template that defines the content card
    public let template: any ContentCardTemplate

    /// The host app listener for the content card UI events.
    let listener: ContentCardUIEventListening?

    /// SwiftUI view that represents the content card
    /// TODO: Make adjustments to remove AnyView
    public lazy var view: some View = AnyView(template.view)

    /// Metadata associated with the ContentCard
    public var meta: [String: Any]? {
        proposition.items.first?.contentCardSchemaData?.meta
    }
    
    /// Read status for content cards, persisted between app launches.
    ///
    /// The read status is managed by `ReadStatusManager` which tracks:
    /// - Individual card read status (activityId → isRead)
    /// - Surface ownership (activityId → Set of surface URIs)
    ///
    /// This ensures read status is preserved when the same campaign appears
    /// across multiple surfaces, and is only deleted when no surface references
    /// the campaign anymore.
    ///
    /// Defaults to `false` for new cards that haven't been interacted with.
    public var isRead: Bool {
        get {
            return ReadStatusManager.shared.getReadStatus(for: proposition.activityId) ?? false
        }
        set {
            ReadStatusManager.shared.setReadStatus(newValue, for: proposition.activityId)
            template.updateUnreadState(isRead: newValue)
        }
    }
    
    /// Marks this content card as read.
    ///
    /// The read status is persisted and will be maintained across app launches.
    ///
    /// This method is automatically called when the user interacts with the card
    /// (button click, tap, etc.), but can also be called manually if needed.
    ///
    public func markAsRead() {
        isRead = true
    }
    
    /// Factory method to create a `ContentCardUI` instance based on the provided schema data.
    /// - Parameters:
    ///    - proposition: The `Proposition` containing content card template information
    ///    - customizer: An optional object conforming to `ContentCardCustomizing` protocol that allows for custom styling of the content card
    ///    - listener: An optional object conforming to `ContentCardUIEventListening` protocol implemented by the host app to listen to UI events from the content card
    ///    - inboxSettings: Optional settings that apply specific configurations to content cards when displayed within an inbox
    /// - Returns: An initialized `ContentCardUI` instance, or `nil` if unable to create template from proposition
    static func createInstance(with proposition: Proposition,
                               customizer: ContentCardCustomizing?,
                               listener: ContentCardUIEventListening?,
                               inboxSettings: InboxSettings? = nil) -> ContentCardUI? {
        guard let schemaData = proposition.items.first?.contentCardSchemaData else {
            return nil
        }

        guard let template = TemplateBuilder.buildTemplate(from: schemaData, customizer: customizer, inboxSettings: inboxSettings) else {
            return nil
        }

        // Initialize the ContentCardUI with the proposition and template
        let contentCardUI = ContentCardUI(proposition, schemaData, template, listener)

        // set the listener for the template
        template.eventHandler = contentCardUI
        
        return contentCardUI
    }

    /// Initializes a new `ContentCardUI` instance with the given schema data and template.
    /// - Parameters:
    ///   - proposition: The `Proposition` containing the content card template's information
    ///   - schemaData: The `ContentCardSchemaData` containing information about content card
    ///   - template: The template that defines the content card's layout and behavior.
    ///   - listener: An optional listener conforming to the `ContentCardUIEventListening` protocol,
    ///               allowing the host application to handle UI events triggered by the content card.
    /// - Note : This initializer is private to ensure that `ContentCardUI` instances are only created through the `createInstance` factory method.
    private init(_ proposition: Proposition, _ schemaData: ContentCardSchemaData,
                 _ template: any ContentCardTemplate, _ listener: ContentCardUIEventListening?) {
        self.proposition = proposition
        self.template = template
        self.listener = listener
        self.schemaData = schemaData
        
        // Initialize the template's read state from ReadStatusManager
        let currentReadStatus = ReadStatusManager.shared.getReadStatus(for: proposition.activityId) ?? false
        template.updateUnreadState(isRead: currentReadStatus)
    }
}
