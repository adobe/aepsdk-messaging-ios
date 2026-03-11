# Live Activity Troubleshooting

This guide helps you diagnose and resolve common issues when implementing Live Activities with the AEP Messaging SDK.

## Common Issues and Solutions

### 1. Live Activity Not Starting

#### Symptoms
- `Activity.request()` throws an error
- Live Activity doesn't appear on device
- App crashes when trying to start Live Activity

#### Possible Causes and Solutions

**Permission Denied**
```swift
// Error: ActivityError.denied
// Solution: Check Live Activity capability and permissions

// 1. Verify capability is added
// In Xcode: Target > Signing & Capabilities > + Capability > Live Activity

// 2. Check Info.plist
<key>NSSupportsLiveActivities</key>
<true/>

// 3. Request permission at runtime
if #available(iOS 16.1, *) {
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
        if granted {
            print("Notification permission granted")
        } else {
            print("Notification permission denied")
        }
    }
}
```

**Live Activity Unavailable**
```swift
// Error: ActivityError.unavailable
// Solution: Check device and iOS version support

@available(iOS 16.1, *)
class LiveActivityCompatibilityChecker {
    
    static func checkCompatibility() -> Bool {
        // Check iOS version
        guard #available(iOS 16.1, *) else {
            print("Live Activities require iOS 16.1 or later")
            return false
        }
        
        // Check device support (iPhone 14 Pro+ for Dynamic Island)
        let device = UIDevice.current
        let model = device.model
        
        if model.contains("iPhone") {
            // Check for Dynamic Island support
            let screenBounds = UIScreen.main.bounds
            let hasDynamicIsland = screenBounds.height > 844 // iPhone 14 Pro height
            return hasDynamicIsland
        }
        
        return true // iPad and other devices support Lock Screen Live Activities
    }
}
```

**Registration Not Called**
```swift
// Error: Live Activity type not registered
// Solution: Ensure registration happens before starting activities

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize AEP Core first
        MobileCore.setLogLevel(.trace)
        
        let extensions = [AEPMessaging.self]
        
        MobileCore.registerExtensions(extensions) {
            // Register Live Activity types early
            if #available(iOS 16.1, *) {
                Messaging.registerLiveActivity(FoodDeliveryLiveActivityAttributes.self)
                print("Live Activity type registered successfully")
            }
        }
        
        return true
    }
}
```

### 2. Live Activity Not Updating

#### Symptoms
- Content doesn't change when calling `activity.update()`
- Updates are not reflected on device
- No error messages but no visual changes

#### Possible Causes and Solutions

**Content State Not Changed**
```swift
// Issue: Content state is identical to current state
// Solution: Ensure content state actually changes

@available(iOS 16.1, *)
func updateLiveActivity(_ activity: Activity<FoodDeliveryLiveActivityAttributes>, status: String) {
    let currentState = activity.contentState
    let newContentState = FoodDeliveryLiveActivityAttributes.ContentState(
        orderStatus: status,
        estimatedDeliveryTime: currentState.estimatedDeliveryTime,
        driverLocation: currentState.driverLocation,
        progressPercentage: calculateProgress(for: status)
    )
    
    // Check if content actually changed
    guard newContentState != currentState else {
        print("Content state unchanged, skipping update")
        return
    }
    
    Task {
        await activity.update(using: newContentState)
        print("Live Activity updated successfully")
    }
}
```

**Update Frequency Too High**
```swift
// Issue: Updates are being throttled by iOS
// Solution: Implement update frequency limiting

@available(iOS 16.1, *)
class LiveActivityUpdater {
    
    private var lastUpdateTime: Date = Date()
    private let minimumUpdateInterval: TimeInterval = 30 // 30 seconds
    
    func updateLiveActivity(_ activity: Activity<FoodDeliveryLiveActivityAttributes>, status: String) {
        let now = Date()
        
        // Avoid excessive updates
        guard now.timeIntervalSince(lastUpdateTime) >= minimumUpdateInterval else {
            print("Skipping update - too frequent (last update: \(lastUpdateTime))")
            return
        }
        
        let newContentState = FoodDeliveryLiveActivityAttributes.ContentState(
            orderStatus: status,
            estimatedDeliveryTime: activity.contentState.estimatedDeliveryTime,
            driverLocation: activity.contentState.driverLocation,
            progressPercentage: calculateProgress(for: status)
        )
        
        Task {
            await activity.update(using: newContentState)
            lastUpdateTime = now
            print("Live Activity updated at: \(now)")
        }
    }
}
```

**Activity Ended**
```swift
// Issue: Trying to update an ended activity
// Solution: Check activity state before updating

@available(iOS 16.1, *)
func updateLiveActivity(_ activity: Activity<FoodDeliveryLiveActivityAttributes>, status: String) {
    // Check if activity is still active
    guard activity.activityState == .active else {
        print("Cannot update ended activity: \(activity.activityState)")
        return
    }
    
    let newContentState = FoodDeliveryLiveActivityAttributes.ContentState(
        orderStatus: status,
        estimatedDeliveryTime: activity.contentState.estimatedDeliveryTime,
        driverLocation: activity.contentState.driverLocation,
        progressPercentage: calculateProgress(for: status)
    )
    
    Task {
        await activity.update(using: newContentState)
    }
}
```

### 3. Push Tokens Not Received

#### Symptoms
- Push-to-start tokens not collected
- Update tokens not available
- Remote Live Activity triggering not working

#### Possible Causes and Solutions

**iOS Version Too Low**
```swift
// Issue: Push-to-start tokens require iOS 17.2+
// Solution: Check iOS version and provide fallback

@available(iOS 16.1, *)
class TokenManager {
    
    static func checkTokenSupport() {
        if #available(iOS 17.2, *) {
            print("Push-to-start tokens supported")
        } else {
            print("Push-to-start tokens require iOS 17.2+")
            // Implement fallback for older iOS versions
            implementFallbackForOlderiOS()
        }
    }
    
    private static func implementFallbackForOlderiOS() {
        // Use regular push notifications to trigger Live Activities
        // Or show in-app notifications instead
    }
}
```

**Registration Not Successful**
```swift
// Issue: Live Activity type not properly registered
// Solution: Verify registration and add error handling

@available(iOS 16.1, *)
class LiveActivityRegistrationManager {
    
    static func registerLiveActivityType<T: LiveActivityAttributes>(_ type: T.Type) {
        do {
            Messaging.registerLiveActivity(type)
            print("Successfully registered Live Activity type: \(T.self)")
        } catch {
            print("Failed to register Live Activity type: \(error)")
            // Implement fallback or retry logic
        }
    }
    
    static func verifyRegistration<T: LiveActivityAttributes>(_ type: T.Type) -> Bool {
        // Add verification logic here
        // This could check if the type is properly registered
        return true
    }
}
```

### 4. Widget Not Displaying

#### Symptoms
- Live Activity widget doesn't appear
- Widget shows but content is incorrect
- Widget crashes or shows errors

#### Possible Causes and Solutions

**Widget Extension Not Added**
```swift
// Issue: Missing widget extension target
// Solution: Add widget extension to project

// 1. In Xcode: File > New > Target
// 2. Choose "Widget Extension"
// 3. Name it "LiveActivityWidget"
// 4. Ensure "Include Live Activity" is checked
```

**Widget Implementation Issues**
```swift
// Issue: Widget implementation errors
// Solution: Proper widget implementation

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

### 5. Memory and Performance Issues

#### Symptoms
- App becomes slow or crashes
- High memory usage
- Battery drain

#### Possible Causes and Solutions

**Too Many Active Activities**
```swift
// Issue: Multiple activities not being cleaned up
// Solution: Implement activity lifecycle management

@available(iOS 16.1, *)
class LiveActivityLifecycleManager {
    
    private var activeActivities: [String: Activity<FoodDeliveryLiveActivityAttributes>] = [:]
    private let maxActiveActivities = 5
    
    func startActivity(orderID: String) throws {
        // Check limit
        guard activeActivities.count < maxActiveActivities else {
            throw LiveActivityError.tooManyActiveActivities
        }
        
        let activity = try startLiveActivity(orderID: orderID)
        activeActivities[orderID] = activity
    }
    
    func endActivity(orderID: String) {
        guard let activity = activeActivities[orderID] else { return }
        
        let finalContentState = FoodDeliveryLiveActivityAttributes.ContentState(
            orderStatus: "Delivered",
            estimatedDeliveryTime: nil,
            driverLocation: nil,
            progressPercentage: 100
        )
        
        Task {
            await activity.end(using: finalContentState, dismissalPolicy: .immediate)
            activeActivities.removeValue(forKey: orderID)
        }
    }
    
    func cleanupExpiredActivities() {
        let now = Date()
        
        for (orderID, activity) in activeActivities {
            // End activities older than 2 hours
            if let estimatedTime = activity.contentState.estimatedDeliveryTime,
               now.timeIntervalSince(estimatedTime) > 2 * 60 * 60 {
                endActivity(orderID: orderID)
            }
        }
    }
}

enum LiveActivityError: Error {
    case tooManyActiveActivities
}
```

**Excessive Updates**
```swift
// Issue: Too many updates causing performance issues
// Solution: Implement update throttling

@available(iOS 16.1, *)
class LiveActivityUpdateThrottler {
    
    private var updateCounts: [String: Int] = [:]
    private let maxUpdatesPerMinute = 10
    
    func shouldUpdate(orderID: String) -> Bool {
        let currentCount = updateCounts[orderID] ?? 0
        return currentCount < maxUpdatesPerMinute
    }
    
    func recordUpdate(orderID: String) {
        updateCounts[orderID] = (updateCounts[orderID] ?? 0) + 1
        
        // Reset count after 1 minute
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            self.updateCounts[orderID] = 0
        }
    }
}
```

## Debug Tools and Techniques

### 1. Enable Debug Logging

```swift
// Enable detailed logging
MobileCore.setLogLevel(.trace)

// Look for these log messages:
// "Registered Live Activity push-to-start token task"
// "Registered Live Activity updates task"
// "Dispatching Live Activity start event"
// "Dispatching Live Activity update token event"
```

### 2. Debug Information Collection

```swift
@available(iOS 16.1, *)
class LiveActivityDebugger {
    
    static func collectDebugInfo() -> [String: Any] {
        var debugInfo: [String: Any] = [:]
        
        // Device information
        debugInfo["device_model"] = UIDevice.current.model
        debugInfo["ios_version"] = UIDevice.current.systemVersion
        debugInfo["app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        // Live Activity support
        debugInfo["live_activity_supported"] = #available(iOS 16.1, *)
        debugInfo["push_to_start_supported"] = #available(iOS 17.2, *)
        
        // Permission status
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            debugInfo["notification_authorization"] = settings.authorizationStatus.rawValue
        }
        
        // Active activities count
        if #available(iOS 16.1, *) {
            Task {
                let activities = Activity<FoodDeliveryLiveActivityAttributes>.activities
                debugInfo["active_activities_count"] = activities.count
            }
        }
        
        return debugInfo
    }
    
    static func printDebugInfo() {
        let debugInfo = collectDebugInfo()
        print("Live Activity Debug Info:")
        for (key, value) in debugInfo {
            print("  \(key): \(value)")
        }
    }
}
```

### 3. Testing Tools

```swift
@available(iOS 16.1, *)
class LiveActivityTester {
    
    static func testLiveActivityLifecycle() {
        print("Testing Live Activity lifecycle...")
        
        // Test start
        do {
            let activity = try startTestLiveActivity()
            print("✓ Live Activity started successfully")
            
            // Test update
            Task {
                await activity.update(using: createTestContentState(status: "Testing"))
                print("✓ Live Activity updated successfully")
                
                // Test end
                await activity.end(using: createTestContentState(status: "Test Complete"), dismissalPolicy: .immediate)
                print("✓ Live Activity ended successfully")
            }
        } catch {
            print("✗ Live Activity test failed: \(error)")
        }
    }
    
    private static func startTestLiveActivity() throws -> Activity<FoodDeliveryLiveActivityAttributes> {
        let attributes = FoodDeliveryLiveActivityAttributes(
            liveActivityData: LiveActivityData(liveActivityID: "test_activity_\(Date().timeIntervalSince1970)"),
            restaurantName: "Test Restaurant",
            orderNumber: "TEST-001"
        )
        
        let contentState = createTestContentState(status: "Test Started")
        
        return try Activity.request(
            attributes: attributes,
            contentState: contentState,
            pushType: nil
        )
    }
    
    private static func createTestContentState(status: String) -> FoodDeliveryLiveActivityAttributes.ContentState {
        return FoodDeliveryLiveActivityAttributes.ContentState(
            orderStatus: status,
            estimatedDeliveryTime: Date().addingTimeInterval(30 * 60),
            driverLocation: "Test location",
            progressPercentage: 50
        )
    }
}
```

## Error Handling Patterns

### 1. Comprehensive Error Handling

```swift
@available(iOS 16.1, *)
class LiveActivityErrorHandler {
    
    static func handleStartError(_ error: Error) {
        switch error {
        case ActivityError.denied:
            print("Live Activity permission denied")
            showPermissionAlert()
        case ActivityError.unavailable:
            print("Live Activity unavailable on this device")
            showUnsupportedDeviceAlert()
        case ActivityError.duplicate:
            print("Live Activity already exists")
            // Handle duplicate case
        default:
            print("Unknown Live Activity error: \(error)")
            showGenericErrorAlert()
        }
    }
    
    static func handleUpdateError(_ error: Error) {
        print("Live Activity update failed: \(error)")
        // Implement retry logic or fallback
    }
    
    private static func showPermissionAlert() {
        // Show alert to user about enabling Live Activities
    }
    
    private static func showUnsupportedDeviceAlert() {
        // Show alert about device compatibility
    }
    
    private static func showGenericErrorAlert() {
        // Show generic error alert
    }
}
```

### 2. Retry Logic

```swift
@available(iOS 16.1, *)
class LiveActivityRetryManager {
    
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 2.0
    
    func startLiveActivityWithRetry(orderID: String, retryCount: Int = 0) {
        do {
            let activity = try startLiveActivity(orderID: orderID)
            print("Live Activity started successfully")
        } catch {
            if retryCount < maxRetries {
                print("Retrying Live Activity start (attempt \(retryCount + 1))")
                DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                    self.startLiveActivityWithRetry(orderID: orderID, retryCount: retryCount + 1)
                }
            } else {
                print("Failed to start Live Activity after \(maxRetries) attempts")
                handleStartFailure(error)
            }
        }
    }
    
    private func handleStartFailure(_ error: Error) {
        // Implement fallback behavior
        // e.g., show in-app notification instead
    }
}
```

## Platform-Specific Issues

### iOS Version Compatibility

| iOS Version | Live Activity Support | Push-to-Start Tokens | Dynamic Island |
|-------------|----------------------|---------------------|----------------|
| iOS 16.1+ | ✅ Full Support | ❌ Not Available | ✅ Lock Screen Only |
| iOS 16.2+ | ✅ Full Support | ❌ Not Available | ✅ Lock Screen + Content Updates |
| iOS 17.2+ | ✅ Full Support | ✅ Available | ✅ Full Support |

### Device Compatibility

- **iPhone 14 Pro+**: Full Dynamic Island support
- **iPhone 14 and earlier**: Lock Screen Live Activities only
- **iPad**: Lock Screen Live Activities only
- **Mac**: No Live Activity support

## Getting Help

### 1. Check Documentation
- Review the [Getting Started](getting-started.md) guide
- Consult the [API Reference](api-reference.md)
- Read the [Best Practices](best-practices.md)

### 2. Enable Debug Logging
```swift
MobileCore.setLogLevel(.trace)
```

### 3. Use Debug Tools
```swift
LiveActivityDebugger.printDebugInfo()
LiveActivityTester.testLiveActivityLifecycle()
```

### 4. Common Log Messages

**Successful Operations:**
- `"Registered Live Activity push-to-start token task"`
- `"Registered Live Activity updates task"`
- `"Dispatching Live Activity start event"`

**Error Messages:**
- `"Live Activity permission denied"`
- `"Live Activity unavailable on this device"`
- `"Failed to start Live Activity"`

### 5. Contact Support
If you continue to experience issues:
1. Collect debug information using `LiveActivityDebugger.collectDebugInfo()`
2. Enable trace logging
3. Test with the provided test tools
4. Contact Adobe Support with the collected information 