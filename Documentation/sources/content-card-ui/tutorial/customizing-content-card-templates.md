# Customizing Content Card Templates

This tutorial explains how to customize the UI of content cards in your application.

## Overview

Messaging extension provides a way to customize content cards based on the template type. You can customize the content card templates using the [ContentCardCustomizing](../public-classes/contentcardcustomizing.md) protocol.

## Implementing ContentCardCustomizing

Perform the following steps to customize content card templates:

1. Conform to the ContentCardCustomizing protocol in your class or struct.
2. Implement the desired methods of the ContentCardCustomizing protocol.

Below is an example implementation of `ContentCardCustomizing`. In this example, the `HomePageCardCustomizer` class conforms to the `ContentCardCustomizing` protocol and customizes the `SmallImageTemplate` content card template:

```swift
class HomePageCardCustomizer: ContentCardCustomizing {
    
    func customize(template: SmallImageTemplate) {
        // customize UI elements
        template.title.textColor = .primary
        template.title.font = .subheadline
        template.body?.textColor = .secondary
        template.buttons?.first?.text.font = .system(size: 13)
        
        // customize stack structure
        template.rootHStack.spacing = 15
        template.textVStack.alignment = .leading
        template.textVStack.spacing = 10
        
        // add custom modifiers
        template.buttonHStack.modifier = AEPViewModifier(ButtonHStackModifier())
        template.rootHStack.modifier = AEPViewModifier(RootHStackModifier())
        
        // customize the dismiss buttons
        template.dismissButton?.image.iconColor = .primary
        template.dismissButton?.image.iconFont = .system(size: 10)
    }
    
    struct RootHStackModifier : ViewModifier {
        func body(content: Content) -> some View {
             content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing)
         }
    }
    
    struct ButtonHStackModifier : ViewModifier {
        func body(content: Content) -> some View {
             content
                .frame(maxWidth: .infinity, alignment: .trailing)
         }
    }
}
```

## Applying Customizations

To apply the customizations to the content card templates, pass the customizer to the `getContentCardsUI` API. The customizer will be called for each content card template type that is recognized by the Messaging extension.

```swift
let homePageSurface = Surface(path: "homepage")
let homePageCustomizer = HomePageCardCustomizer()
Messaging.getContentCardsUI(for: homePageSurface,
                             customizer: homePageCustomizer) { result in
    // handle result
}
```

Customize the content card templates for different surfaces by creating a customizer for each surface. For example, the following code snippet customizes the content card templates for the "homepage" and "detailpage" content cards separately:

```swift
let homePageSurface = Surface(path: "homepage")
let homePageCustomizer = HomePageCardCustomizer()
Messaging.getContentCardsUI(for: homePageSurface,
                             customizer: homePageCustomizer) { result in
    // handle result
}

let detailPageSurface = Surface(path: "detailpage")
let detailPageCustomizer = DetailPageCardCustomizer()
Messaging.getContentCardsUI(for: detailPageSurface,
                             customizer: detailPageCustomizer) { result in
    // handle result
}
```