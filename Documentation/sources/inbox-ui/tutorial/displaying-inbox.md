# Displaying Inbox

This tutorial explains how to fetch and display an Inbox in your application.

## Pre-requisites

[Integrate and register AEPMessaging extension](https://developer.adobe.com/client-sdks/edge/adobe-journey-optimizer/#implement-extension-in-mobile-app) in your app.

## Overview

The Inbox is a pre-built UI component that displays content cards in a unified container. Unlike individual content cards, the Inbox automatically manages loading states, error handling, empty states, and card layout based on server-side configuration from [Adobe Journey Optimizer](https://business.adobe.com/products/journey-optimizer/adobe-journey-optimizer.html).


## Get InboxUI

To display an Inbox, call `getInboxUI` with your configured surface. This API returns an `InboxUI` object immediately, which manages its own state transitions automatically.

```swift
let inboxSurface = Surface(path: "inbox")
let inboxUI = Messaging.getInboxUI(for: inboxSurface)
```

When created, the `InboxUI` begins fetching inbox settings and content cards, transitioning through loading, loaded (with or without cards), or error states as needed.

> Note - The Inbox automatically handles layout (vertical/horizontal), styling, and unread indicators based on server-side configuration from Adobe Journey Optimizer campaigns.

## Display Inbox in SwiftUI

The simplest way to display an Inbox in SwiftUI is to use the `InboxUI.view` property:

```swift
import SwiftUI
import AEPMessaging

struct InboxPage: View {
    
    let inboxUI: InboxUI
    
    init() {
        let inboxSurface = Surface(path: "inbox")
        inboxUI = Messaging.getInboxUI(for: inboxSurface)
    }
    
    var body: some View {
        NavigationView {
            inboxUI.view
                .navigationTitle("Inbox")
        }
        .onAppear {
            // Fetch content cards when the view appears
            let inboxSurface = Surface(path: "inbox")
            Messaging.updatePropositionsForSurfaces([inboxSurface])
        }
    }
}
```

Refer to the [MessagingDemoAppSwiftUI](../../../../TestApps/MessagingDemoAppSwiftUI/) for a complete example of displaying an Inbox in a SwiftUI application.

## Display Inbox in UIKit

To display an Inbox in UIKit, use `UIHostingController` to wrap the SwiftUI `InboxUI.view`:

```swift
import UIKit
import SwiftUI
import AEPMessaging

class InboxViewController: UIViewController {
    
    var inboxUI: InboxUI!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Inbox"
        
        // Create the InboxUI
        let inboxSurface = Surface(path: "inbox")
        inboxUI = Messaging.getInboxUI(for: inboxSurface)
        
        // Wrap the SwiftUI view in a UIHostingController
        let hostingController = UIHostingController(rootView: inboxUI.view)
        
        // Add the hosting controller as a child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // Set up constraints to make the view fill the container
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Fetch content cards
        Messaging.updatePropositionsForSurfaces([inboxSurface])
    }
}
```

## Refreshing Inbox Data

The Inbox provides multiple ways to refresh content cards:

### 1. Pull-to-Refresh (SwiftUI)

Enable pull-to-refresh functionality to allow users to refresh content by pulling down on the Inbox:

```swift
let inboxSurface = Surface(path: "inbox")
let inboxUI = Messaging.getInboxUI(for: inboxSurface)

// Enable pull-to-refresh
inboxUI.isPullToRefreshEnabled = true
```

When a user pulls to refresh:
1. The Inbox calls `updatePropositionsForSurfaces` to fetch the latest content from the server
2. After the update completes, it calls `getPropositionsForSurfaces` to retrieve the updated content
3. The UI refreshes with the new content cards

> Note - Pull-to-refresh is disabled by default. Set `isPullToRefreshEnabled = true` to enable it.

### 2. Programmatic Refresh

You can programmatically refresh the Inbox using the `refresh()` method:

```swift
// Refresh the inbox programmatically
inboxUI.refresh()
```

This is useful for:
- Refreshing on button taps
- Auto-refreshing at intervals
- Refreshing after specific app events

### Handling Refresh Events

To be notified when a refresh completes (for both pull-to-refresh and programmatic refresh), use the `InboxEventListening` protocol:

```swift
// Implement InboxEventListening to handle refresh completion
func onSuccess(_ inbox: InboxUI) {
    print("Inbox refreshed successfully")
}

func onError(_ inbox: InboxUI, _ error: Error) {
    print("Failed to refresh inbox: \(error)")
}
```

See [Listening to Inbox Events](listening-inbox-events.md) for more details on event handling.


## Best Practices

1. **Fetch Early**: Call `updatePropositionsForSurfaces` when your app launches or when the user navigates to the Inbox screen to ensure fresh content is available.

2. **Surface Naming**: Use descriptive surface paths that match your Adobe Journey Optimizer campaign configuration (e.g., `Surface(path: "inbox")`, `Surface(path: "home_feed")`).

3. **Reuse InboxUI**: Keep the `InboxUI` instance alive as long as the Inbox view is visible. The `InboxUI` maintains state and efficiently updates when content changes.

4. **Handle Multiple Surfaces**: If your app has multiple Inboxes (e.g., notifications, promotions), create separate `InboxUI` instances with different surfaces:

```swift
// Notifications inbox
let notificationsInboxUI = Messaging.getInboxUI(for: Surface(path: "notifications"))

// Promotions inbox
let promotionsInboxUI = Messaging.getInboxUI(for: Surface(path: "promotions"))
```

## Next Steps

- [Listening to Inbox Events](listening-inbox-events.md) - Learn how to respond to user interactions
- [Customizing Your Inbox](customizing-inbox.md) - Customize appearance, spacing, and views

