# Listening to Inbox Events

This tutorial explains how to listen to events from the Inbox in your application.

## Overview

The Messaging extension provides a way to listen to events from both the Inbox container and individual content cards within it. By conforming to the `InboxEventListening` protocol, you can respond to inbox-level state changes and individual content card interactions.

## Inbox-Level Events

These events track the overall state of the inbox container.

### onLoading

Called when the inbox begins loading content. This happens when the `InboxUI` is first created or when the user triggers a refresh (pull-to-refresh or programmatic).

```swift
func onLoading(_ inbox: InboxUI) {
    print("Inbox is loading...")
}
```

### onSuccess

Called when the inbox successfully loads content. This event is triggered whether the inbox contains cards or is empty.

```swift
func onSuccess(_ inbox: InboxUI) {
    print("Inbox loaded successfully")
}
```

### onError

Called when the inbox encounters an error while loading. Common error scenarios include container settings not found, network failures, or invalid surface configuration.

```swift
func onError(_ inbox: InboxUI, _ error: Error) {
    print("Inbox error: \(error.localizedDescription)")
}
```

## Content Card Events

These events track interactions with individual content cards within the inbox.

### onCardCreated

Called when a content card is created and configured. This happens once per card when the inbox loads or refreshes.

```swift
func onCardCreated(_ card: ContentCardUI) {
    print("Card created: \(card.id)")
}
```

### onCardDisplayed

Called when a content card is displayed to the user. Use this event to track impressions.

```swift
func onCardDisplayed(_ card: ContentCardUI) {
    AnalyticsService.trackImpression(cardId: card.id)
}
```

> Note - This event is triggered automatically by the SDK when the card appears on screen. You do not need to manually call any display methods.

### onCardInteracted

Called when a user interacts with a content card (taps a button, clicks a link, etc.). The return value determines how the SDK handles the `actionURL`.

**Parameters:**
- `card` - The content card that was interacted with
- `interactionId` - Unique identifier for the interaction (button ID, link ID, etc.)
- `actionURL` - Optional URL associated with the interaction

**Return Value:**
- Return `true` if your application handled the URL (prevents SDK from opening it)
- Return `false` to let the SDK open the URL

```swift
func onCardInteracted(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool {
    guard let url = actionURL else { return false }
    
    if url.scheme == "myapp" {
        navigateToDeepLink(url)
        return true // URL handled by app
    }
    
    return false // Let SDK handle URL
}
```

**Read Status Tracking:**

When a card is interacted with, it is automatically marked as **read** and persisted. The read status persists between app launches and affects unread indicator visibility (if enabled).

### onCardDismissed

Called when a user dismisses a content card by tapping the dismiss button.

```swift
func onCardDismissed(_ card: ContentCardUI) {
    print("Card dismissed: \(card.id)")
}
```

> Note - The Inbox automatically removes dismissed cards from the UI.
## Implement InboxEventListening

To listen to inbox events, conform to the `InboxEventListening` protocol and pass the listener to the `getInboxUI` API.

```swift
import SwiftUI
import AEPMessaging

struct InboxPage: View, InboxEventListening {
    
    let inboxUI: InboxUI
    @State private var showError = false
    @State private var errorMessage = ""
    
    init() {
        let inboxSurface = Surface(path: "inbox")
        inboxUI = Messaging.getInboxUI(for: inboxSurface, listener: self)
        inboxUI.isPullToRefreshEnabled = true
    }
    
    var body: some View {
        NavigationView {
            inboxUI.view
                .navigationTitle("Inbox")
                .alert("Error", isPresented: $showError) {
                    Button("OK") { showError = false }
                } message: {
                    Text(errorMessage)
                }
        }
        .onAppear {
            Messaging.updatePropositionsForSurfaces([Surface(path: "inbox")])
        }
    }
    
    // MARK: - Inbox State Events
    
    func onLoading(_ inbox: InboxUI) {
        print("Loading inbox...")
    }
    
    func onSuccess(_ inbox: InboxUI) {
        print("Inbox loaded successfully")
        AnalyticsService.track("inbox_loaded")
    }
    
    func onError(_ inbox: InboxUI, _ error: Error) {
        print("Inbox error: \(error)")
        errorMessage = error.localizedDescription
        showError = true
    }
    
    // MARK: - Content Card Events
    
    func onCardCreated(_ card: ContentCardUI) {
        print("Card created: \(card.id)")
    }
    
    func onCardDisplayed(_ card: ContentCardUI) {
        AnalyticsService.trackImpression(cardId: card.id)
    }
    
    func onCardInteracted(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool {
        AnalyticsService.trackInteraction(cardId: card.id, interactionId: interactionId)
        
        if let url = actionURL, url.scheme == "myapp" {
            handleDeepLink(url)
            return true
        }
        
        return false
    }
    
    func onCardDismissed(_ card: ContentCardUI) {
        print("Card dismissed: \(card.id)")
        AnalyticsService.track("card_dismissed", properties: ["card_id": card.id])
    }
    
    private func handleDeepLink(_ url: URL) {
        // Your deep link handling logic
        print("Handling deep link: \(url)")
    }
}
```

## Handling Actionable URLs

The `onCardInteracted` method provides control over how URLs are handled when users interact with content cards. Here are common patterns:

### Pattern 1: Handle All URLs

```swift
func onCardInteracted(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool {
    guard let url = actionURL else { return false }
    
    // Handle all URLs in your app
    navigateToURL(url)
    return true // Prevent SDK from opening URL
}
```

### Pattern 2: Selective Handling

```swift
func onCardInteracted(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool {
    guard let url = actionURL else { return false }
    
    // Only handle specific URL schemes
    if url.scheme == "myapp" || url.scheme == "http" || url.scheme == "https" {
        handleURL(url)
        return true
    }
    
    // Let SDK handle other schemes
    return false
}
```

### Pattern 3: Analytics + Default Behavior

```swift
func onCardInteracted(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool {
    // Track interaction but let SDK handle URL
    AnalyticsService.trackInteraction(
        cardId: card.id,
        interactionId: interactionId,
        url: actionURL
    )
    
    return false // Let SDK open the URL
}
```

## Best Practices

1. **Avoid Heavy Work in Event Handlers**: Event handlers are called synchronously on the main thread. Keep event handlers lightweight and dispatch heavy work to background queues.

2. **Handle Errors Gracefully**: Provide user-friendly error messages and retry options:
   ```swift
   func onError(_ inbox: InboxUI, _ error: Error) {
       showAlert(title: "Unable to load inbox", message: "Please try again later.")
   }
   ```

3. **Log for Debugging**: Use event handlers to log state transitions during development:
   ```swift
   func onSuccess(_ inbox: InboxUI) {
       #if DEBUG
       print("Inbox loaded successfully")
       #endif
   }
   ```

## Next Steps

- [Displaying Inbox](displaying-inbox.md) - Learn how to fetch and display the Inbox
- [Customizing Your Inbox](customizing-inbox.md) - Customize appearance, spacing, and views
