# Getting Started with Live Activities

This guide walks you through setting up Live Activities with the AEP Messaging SDK, from basic configuration to implementing your first Live Activity.

## Prerequisites

Before implementing Live Activities, ensure you have:

- iOS 16.1+ deployment target
- Xcode 15+ for development
- AEP Core and Messaging extensions installed
- Apple Developer account with Live Activity capability

## Setup

### 1. Add Live Activity Capability

1. Open your Xcode project
2. Select your app target
3. Go to **Signing & Capabilities**
4. Click **+ Capability**
5. Add **Live Activity** capability

### 2. Configure Info.plist

Add the following keys to your `Info.plist`:

```xml
<key>NSSupportsLiveActivities</key>
<true/>
<key>NSSupportsLiveActivitiesFrequentUpdates</key>
<true/>
```

### 3. Import Required Frameworks

Add these imports to your main app file:

```swift
import ActivityKit
import AEPCore
import AEPMessaging
import AEPMessagingLiveActivity
```

## Basic Implementation

### Step 1: Define Your Live Activity Attributes

Create a struct that conforms to `LiveActivityAttributes`:

```swift
@available(iOS 16.1, *)
struct FoodDeliveryLiveActivityAttributes: LiveActivityAttributes {
    // Required: Adobe Experience Platform data
    var liveActivityData: LiveActivityData
    
    // Static attributes (unchanged during activity lifecycle)
    var restaurantName: String
    var orderNumber: String
    
    // Dynamic attributes (can be updated)
    struct ContentState: Codable, Hashable {
        var orderStatus: String
        var estimatedDeliveryTime: Date?
        var driverLocation: String?
    }
}
```

### Step 2: Register with the SDK

Register your Live Activity type with the SDK in your app's initialization:

```swift
import AEPCore
import AEPMessaging

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize AEP Core
        MobileCore.setLogLevel(.trace)
        
        let extensions = [
            AEPMessaging.self
        ]
        
        MobileCore.registerExtensions(extensions) {
            // Register Live Activity type
            if #available(iOS 16.1, *) {
                Messaging.registerLiveActivity(FoodDeliveryLiveActivityAttributes.self)
            }
        }
        
        return true
    }
}
```

### Step 3: Start a Live Activity

Create and start a Live Activity:

```swift
@available(iOS 16.1, *)
func startFoodDeliveryActivity() {
    // Create attributes
    let attributes = FoodDeliveryLiveActivityAttributes(
        liveActivityData: LiveActivityData(liveActivityID: "order_12345"),
        restaurantName: "Pizza Hut",
        orderNumber: "PH-2024-001"
    )
    
    // Create initial content state
    let contentState = FoodDeliveryLiveActivityAttributes.ContentState(
        orderStatus: "Ordered",
        estimatedDeliveryTime: Date().addingTimeInterval(30 * 60), // 30 minutes
        driverLocation: nil
    )
    
    // Request the Live Activity
    do {
        let activity = try Activity.request(
            attributes: attributes,
            contentState: contentState,
            pushType: nil
        )
        print("Live Activity started: \(activity.id)")
    } catch {
        print("Failed to start Live Activity: \(error)")
    }
}
```

### Step 4: Update Live Activity Content

Update the Live Activity with new information:

```swift
@available(iOS 16.1, *)
func updateFoodDeliveryStatus(activity: Activity<FoodDeliveryLiveActivityAttributes>, status: String) {
    let newContentState = FoodDeliveryLiveActivityAttributes.ContentState(
        orderStatus: status,
        estimatedDeliveryTime: Date().addingTimeInterval(15 * 60), // 15 minutes
        driverLocation: "Driver is 5 minutes away"
    )
    
    Task {
        await activity.update(using: newContentState)
    }
}
```

### Step 5: End the Live Activity

End the Live Activity when the delivery is complete:

```swift
@available(iOS 16.1, *)
func endFoodDeliveryActivity(activity: Activity<FoodDeliveryLiveActivityAttributes>) {
    let finalContentState = FoodDeliveryLiveActivityAttributes.ContentState(
        orderStatus: "Delivered",
        estimatedDeliveryTime: nil,
        driverLocation: nil
    )
    
    Task {
        await activity.end(using: finalContentState, dismissalPolicy: .immediate)
    }
}
```

## Live Activity Widget Implementation

### Create the Widget Extension

1. In Xcode, go to **File > New > Target**
2. Choose **Widget Extension**
3. Name it `LiveActivityWidget`
4. Ensure **Include Live Activity** is checked

### Implement the Widget

```swift
import WidgetKit
import SwiftUI
import ActivityKit

struct FoodDeliveryLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FoodDeliveryLiveActivityAttributes.self) { context in
            // Lock screen/banner UI
            VStack {
                HStack {
                    Image(systemName: "car.fill")
                        .foregroundColor(.green)
                    Text(context.attributes.restaurantName)
                        .font(.headline)
                    Spacer()
                    Text(context.attributes.orderNumber)
                        .font(.caption)
                }
                
                HStack {
                    Text(context.state.orderStatus)
                        .font(.subheadline)
                    Spacer()
                    if let eta = context.state.estimatedDeliveryTime {
                        Text(eta, style: .time)
                            .font(.caption)
                    }
                }
            }
            .padding()
        } dynamicIsland: { context in
            // Dynamic Island UI
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.attributes.restaurantName)
                    } icon: {
                        Image(systemName: "car.fill")
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Label {
                        Text(context.state.orderStatus)
                    } icon: {
                        Image(systemName: "clock.fill")
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Order #\(context.attributes.orderNumber)")
                        .font(.caption)
                }
            } compactLeading: {
                Image(systemName: "car.fill")
                    .foregroundColor(.green)
            } compactTrailing: {
                Text(context.state.orderStatus)
                    .font(.caption2)
            } minimal: {
                Image(systemName: "car.fill")
                    .foregroundColor(.green)
            }
        }
    }
}
```

## Testing Live Activities

### Using the Simulator

1. Run your app in the iOS Simulator
2. Start a Live Activity from your app
3. The Live Activity will appear in the Dynamic Island (if supported)
4. Use the simulator's **Device > Lock** to see the Lock Screen view

### Using a Physical Device

1. Deploy to a physical iOS device
2. Ensure the device supports Dynamic Island (iPhone 14 Pro or later)
3. Test both Dynamic Island and Lock Screen appearances

## Next Steps

- **[API Reference](api-reference.md)** - Explore the complete API documentation
- **[Token Management](token-management.md)** - Learn about push token handling
- **[Event Tracking](event-tracking.md)** - Understand how events are tracked
- **[Best Practices](best-practices.md)** - Follow implementation guidelines 