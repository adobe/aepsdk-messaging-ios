# Live Activity Best Practices

This guide provides best practices for implementing Live Activities with the AEP Messaging SDK, ensuring optimal performance, user experience, and maintainability.

## Design Principles

### 1. User-Centric Design

**Focus on Value**
- Only show Live Activities that provide genuine value to users
- Ensure content is relevant and timely
- Respect user preferences and privacy

**Clear Communication**
- Use concise, actionable language
- Provide clear status updates
- Include relevant context and details

### 2. Performance Optimization

**Efficient Updates**
- Update content only when necessary
- Batch updates when possible
- Avoid excessive update frequency

**Resource Management**
- End Live Activities promptly when no longer needed
- Monitor memory and battery usage
- Implement proper cleanup procedures

## Implementation Best Practices

### Live Activity Attributes Design

#### 1. Clear Structure

```swift
@available(iOS 16.1, *)
struct FoodDeliveryLiveActivityAttributes: LiveActivityAttributes {
    var liveActivityData: LiveActivityData
    
    // Static attributes (unchanged during lifecycle)
    let restaurantName: String
    let orderNumber: String
    let orderType: String // "delivery", "pickup"
    
    // Dynamic attributes (can be updated)
    struct ContentState: Codable, Hashable {
        var orderStatus: String
        var estimatedDeliveryTime: Date?
        var driverLocation: String?
        var progressPercentage: Int
    }
}
```

#### 2. Meaningful Identifiers

```swift
// Good: Descriptive and unique
let attributes = FoodDeliveryLiveActivityAttributes(
    liveActivityData: LiveActivityData(liveActivityID: "order_2024_001_12345"),
    restaurantName: "Pizza Hut",
    orderNumber: "PH-2024-001"
)

// Good: Channel with clear purpose
let attributes = AirplaneTrackingAttributes(
    liveActivityData: LiveActivityData(channelID: "flight_AA123_SFO_MIA"),
    arrivalAirport: "SFO",
    departureAirport: "MIA"
)
```

#### 3. Proper Data Types

```swift
struct ContentState: Codable, Hashable {
    // Use appropriate data types
    var status: String // "ordered", "preparing", "on_way", "delivered"
    var progress: Int // 0-100 percentage
    var estimatedTime: Date? // Optional for flexibility
    var location: String? // Optional location updates
}
```

### Registration and Initialization

#### 1. Early Registration

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize AEP Core first
        MobileCore.setLogLevel(.trace)
        
        let extensions = [AEPMessaging.self]
        
        MobileCore.registerExtensions(extensions) {
            // Register Live Activity types early
            if #available(iOS 16.1, *) {
                Messaging.registerLiveActivity(FoodDeliveryLiveActivityAttributes.self)
                Messaging.registerLiveActivity(GameScoreLiveActivityAttributes.self)
                Messaging.registerLiveActivity(AirplaneTrackingAttributes.self)
            }
        }
        
        return true
    }
}
```

#### 2. Error Handling

```swift
@available(iOS 16.1, *)
class LiveActivityManager {
    
    func startLiveActivity() throws -> Activity<FoodDeliveryLiveActivityAttributes> {
        let attributes = FoodDeliveryLiveActivityAttributes(
            liveActivityData: LiveActivityData(liveActivityID: "order_12345"),
            restaurantName: "Pizza Hut",
            orderNumber: "PH-2024-001"
        )
        
        let contentState = FoodDeliveryLiveActivityAttributes.ContentState(
            orderStatus: "Ordered",
            estimatedDeliveryTime: Date().addingTimeInterval(30 * 60),
            driverLocation: nil,
            progressPercentage: 0
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            return activity
        } catch ActivityError.denied {
            throw LiveActivityError.permissionDenied
        } catch ActivityError.unavailable {
            throw LiveActivityError.notSupported
        } catch {
            throw LiveActivityError.unknown(error)
        }
    }
}

enum LiveActivityError: Error {
    case permissionDenied
    case notSupported
    case unknown(Error)
}
```

### Content Management

#### 1. Update Frequency

```swift
@available(iOS 16.1, *)
class LiveActivityUpdater {
    
    private var lastUpdateTime: Date = Date()
    private let minimumUpdateInterval: TimeInterval = 30 // 30 seconds
    
    func updateLiveActivity(_ activity: Activity<FoodDeliveryLiveActivityAttributes>, status: String) {
        let now = Date()
        
        // Avoid excessive updates
        guard now.timeIntervalSince(lastUpdateTime) >= minimumUpdateInterval else {
            print("Skipping update - too frequent")
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
        }
    }
    
    private func calculateProgress(for status: String) -> Int {
        switch status {
        case "ordered": return 10
        case "preparing": return 30
        case "on_way": return 70
        case "delivered": return 100
        default: return 0
        }
    }
}
```

#### 2. Content Validation

```swift
@available(iOS 16.1, *)
class ContentValidator {
    
    static func validateContentState(_ contentState: FoodDeliveryLiveActivityAttributes.ContentState) -> Bool {
        // Validate required fields
        guard !contentState.orderStatus.isEmpty else {
            print("Error: Order status cannot be empty")
            return false
        }
        
        // Validate progress percentage
        guard contentState.progressPercentage >= 0 && contentState.progressPercentage <= 100 else {
            print("Error: Progress percentage must be between 0 and 100")
            return false
        }
        
        // Validate estimated time
        if let estimatedTime = contentState.estimatedDeliveryTime {
            guard estimatedTime > Date() else {
                print("Error: Estimated delivery time must be in the future")
                return false
            }
        }
        
        return true
    }
}
```

### Lifecycle Management

#### 1. Proper Cleanup

```swift
@available(iOS 16.1, *)
class LiveActivityLifecycleManager {
    
    private var activeActivities: [String: Activity<FoodDeliveryLiveActivityAttributes>] = [:]
    
    func startActivity(orderID: String) throws {
        let activity = try startLiveActivity(orderID: orderID)
        activeActivities[orderID] = activity
    }
    
    func endActivity(orderID: String) {
        guard let activity = activeActivities[orderID] else {
            print("Activity not found for order: \(orderID)")
            return
        }
        
        let finalContentState = FoodDeliveryLiveActivityAttributes.ContentState(
            orderStatus: "Delivered",
            estimatedDeliveryTime: nil,
            driverLocation: nil,
            progressPercentage: 100
        )
        
        Task {
            await activity.end(using: finalContentState, dismissalPolicy: .immediate)
            activeActivities.removeValue(forKey: orderID)
            print("Ended Live Activity for order: \(orderID)")
        }
    }
    
    func cleanupExpiredActivities() {
        let now = Date()
        
        for (orderID, activity) in activeActivities {
            // End activities older than 2 hours
            if now.timeIntervalSince(activity.contentState.estimatedDeliveryTime ?? now) > 2 * 60 * 60 {
                endActivity(orderID: orderID)
            }
        }
    }
}
```

#### 2. State Persistence

```swift
@available(iOS 16.1, *)
class LiveActivityStateManager {
    
    private let userDefaults = UserDefaults.standard
    private let activeActivitiesKey = "active_live_activities"
    
    func saveActiveActivity(_ activity: Activity<FoodDeliveryLiveActivityAttributes>) {
        var activeActivities = getActiveActivities()
        activeActivities[activity.attributes.orderNumber] = [
            "orderID": activity.attributes.liveActivityData.liveActivityID ?? "",
            "startTime": Date().timeIntervalSince1970,
            "status": activity.contentState.orderStatus
        ]
        
        userDefaults.set(activeActivities, forKey: activeActivitiesKey)
    }
    
    func getActiveActivities() -> [String: [String: Any]] {
        return userDefaults.dictionary(forKey: activeActivitiesKey) as? [String: [String: Any]] ?? [:]
    }
    
    func removeActiveActivity(orderNumber: String) {
        var activeActivities = getActiveActivities()
        activeActivities.removeValue(forKey: orderNumber)
        userDefaults.set(activeActivities, forKey: activeActivitiesKey)
    }
}
```

## Channel Best Practices

### 1. Channel Design

```swift
// Good: Clear naming convention
let channelID = "sports_nba_lakers_warriors_2024_01_15"
let channelID = "weather_alert_california_severe_storm"
let channelID = "news_breaking_politics_election_results"

// Avoid: Unclear or generic names
let channelID = "channel1"
let channelID = "update"
```

### 2. Channel Management

```swift
@available(iOS 16.1, *)
class ChannelManager {
    
    private var activeChannels: [String: Activity<AirplaneTrackingAttributes>] = [:]
    private let maxActiveChannels = 10
    
    func startChannel(channelID: String, flightInfo: FlightInfo) throws {
        // Check channel limit
        guard activeChannels.count < maxActiveChannels else {
            throw ChannelError.tooManyActiveChannels
        }
        
        // Check if channel already exists
        guard activeChannels[channelID] == nil else {
            throw ChannelError.channelAlreadyExists
        }
        
        let attributes = AirplaneTrackingAttributes(
            liveActivityData: LiveActivityData(channelID: channelID),
            arrivalAirport: flightInfo.arrivalAirport,
            departureAirport: flightInfo.departureAirport,
            arrivalTerminal: flightInfo.arrivalTerminal
        )
        
        let contentState = AirplaneTrackingAttributes.ContentState(
            journeyProgress: 0,
            estimatedArrivalTime: flightInfo.estimatedArrival,
            currentLocation: "Flight scheduled"
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            activeChannels[channelID] = activity
        } catch {
            throw ChannelError.failedToStart(error)
        }
    }
    
    func endChannel(channelID: String) {
        guard let activity = activeChannels[channelID] else { return }
        
        let finalContentState = AirplaneTrackingAttributes.ContentState(
            journeyProgress: 100,
            estimatedArrivalTime: Date(),
            currentLocation: "Flight completed"
        )
        
        Task {
            await activity.end(using: finalContentState, dismissalPolicy: .immediate)
            activeChannels.removeValue(forKey: channelID)
        }
    }
}

enum ChannelError: Error {
    case tooManyActiveChannels
    case channelAlreadyExists
    case failedToStart(Error)
}
```

## Testing Best Practices

### 1. Unit Testing

```swift
class LiveActivityTests: XCTestCase {
    
    func testContentStateValidation() {
        // Valid content state
        let validState = FoodDeliveryLiveActivityAttributes.ContentState(
            orderStatus: "Preparing",
            estimatedDeliveryTime: Date().addingTimeInterval(30 * 60),
            driverLocation: "Driver is 5 minutes away",
            progressPercentage: 50
        )
        
        XCTAssertTrue(ContentValidator.validateContentState(validState))
        
        // Invalid content state
        let invalidState = FoodDeliveryLiveActivityAttributes.ContentState(
            orderStatus: "",
            estimatedDeliveryTime: nil,
            driverLocation: nil,
            progressPercentage: 150
        )
        
        XCTAssertFalse(ContentValidator.validateContentState(invalidState))
    }
    
    func testUpdateFrequency() {
        let updater = LiveActivityUpdater()
        let activity = // ... create test activity
        
        // First update should succeed
        updater.updateLiveActivity(activity, status: "Preparing")
        
        // Second update within minimum interval should be skipped
        updater.updateLiveActivity(activity, status: "On the way")
        
        // Verify only one update was made
        // ... assertion logic
    }
}
```

### 2. Integration Testing

```swift
class LiveActivityIntegrationTests: XCTestCase {
    
    func testLiveActivityLifecycle() {
        let manager = LiveActivityLifecycleManager()
        
        // Test start
        XCTAssertNoThrow(try manager.startActivity(orderID: "test_order_123"))
        
        // Test update
        XCTAssertNoThrow(manager.updateActivity(orderID: "test_order_123", status: "Preparing"))
        
        // Test end
        XCTAssertNoThrow(manager.endActivity(orderID: "test_order_123"))
    }
}
```

## Performance Optimization

### 1. Memory Management

```swift
@available(iOS 16.1, *)
class LiveActivityMemoryManager {
    
    private var activityReferences: [String: WeakActivityReference] = [:]
    
    func storeActivity(_ activity: Activity<FoodDeliveryLiveActivityAttributes>, for orderID: String) {
        activityReferences[orderID] = WeakActivityReference(activity)
    }
    
    func getActivity(for orderID: String) -> Activity<FoodDeliveryLiveActivityAttributes>? {
        return activityReferences[orderID]?.activity
    }
    
    func cleanupWeakReferences() {
        activityReferences = activityReferences.filter { $0.value.activity != nil }
    }
}

class WeakActivityReference {
    weak var activity: Activity<FoodDeliveryLiveActivityAttributes>?
    
    init(_ activity: Activity<FoodDeliveryLiveActivityAttributes>) {
        self.activity = activity
    }
}
```

### 2. Update Batching

```swift
@available(iOS 16.1, *)
class LiveActivityUpdateBatcher {
    
    private var pendingUpdates: [String: FoodDeliveryLiveActivityAttributes.ContentState] = [:]
    private var updateTimer: Timer?
    
    func scheduleUpdate(orderID: String, contentState: FoodDeliveryLiveActivityAttributes.ContentState) {
        pendingUpdates[orderID] = contentState
        
        // Start timer if not already running
        if updateTimer == nil {
            updateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                self.processPendingUpdates()
            }
        }
    }
    
    private func processPendingUpdates() {
        for (orderID, contentState) in pendingUpdates {
            // Process update
            updateActivity(orderID: orderID, contentState: contentState)
        }
        
        pendingUpdates.removeAll()
        updateTimer = nil
    }
}
```

## Security Best Practices

### 1. Data Validation

```swift
class LiveActivitySecurityValidator {
    
    static func validateLiveActivityData(_ data: LiveActivityData) -> Bool {
        // Validate Live Activity ID format
        if let liveActivityID = data.liveActivityID {
            guard liveActivityID.count <= 100 else { return false }
            guard liveActivityID.matches(pattern: "^[a-zA-Z0-9_-]+$") else { return false }
        }
        
        // Validate channel ID format
        if let channelID = data.channelID {
            guard channelID.count <= 100 else { return false }
            guard channelID.matches(pattern: "^[a-zA-Z0-9_-]+$") else { return false }
        }
        
        return true
    }
    
    static func sanitizeContentState(_ contentState: FoodDeliveryLiveActivityAttributes.ContentState) -> FoodDeliveryLiveActivityAttributes.ContentState {
        return FoodDeliveryLiveActivityAttributes.ContentState(
            orderStatus: sanitizeString(contentState.orderStatus),
            estimatedDeliveryTime: contentState.estimatedDeliveryTime,
            driverLocation: sanitizeString(contentState.driverLocation),
            progressPercentage: max(0, min(100, contentState.progressPercentage))
        )
    }
    
    private static func sanitizeString(_ string: String?) -> String? {
        guard let string = string else { return nil }
        return string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
```

### 2. Access Control

```swift
class LiveActivityAccessController {
    
    private let userPermissions: [String: Set<String>] = [
        "admin": ["read", "write", "delete"],
        "user": ["read", "write"],
        "guest": ["read"]
    ]
    
    func canStartLiveActivity(userRole: String) -> Bool {
        return userPermissions[userRole]?.contains("write") ?? false
    }
    
    func canUpdateLiveActivity(userRole: String) -> Bool {
        return userPermissions[userRole]?.contains("write") ?? false
    }
    
    func canEndLiveActivity(userRole: String) -> Bool {
        return userPermissions[userRole]?.contains("delete") ?? false
    }
}
```

## Monitoring and Analytics

### 1. Performance Monitoring

```swift
class LiveActivityPerformanceMonitor {
    
    static func trackStartTime(_ startTime: Date) {
        Analytics.track("live_activity_start_performance", properties: [
            "start_time": startTime.timeIntervalSince1970,
            "device_model": UIDevice.current.model,
            "ios_version": UIDevice.current.systemVersion
        ])
    }
    
    static func trackUpdatePerformance(_ updateTime: Date, updateCount: Int) {
        Analytics.track("live_activity_update_performance", properties: [
            "update_time": updateTime.timeIntervalSince1970,
            "update_count": updateCount,
            "memory_usage": getMemoryUsage()
        ])
    }
    
    private static func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? Double(info.resident_size) / 1024 / 1024 : 0
    }
}
```

### 2. Error Tracking

```swift
class LiveActivityErrorTracker {
    
    static func trackError(_ error: Error, context: String) {
        Analytics.track("live_activity_error", properties: [
            "error_type": String(describing: type(of: error)),
            "error_message": error.localizedDescription,
            "context": context,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    static func trackPermissionDenied() {
        Analytics.track("live_activity_permission_denied", properties: [
            "timestamp": Date().timeIntervalSince1970
        ])
    }
}
```

## Platform Compatibility

### 1. Version Checking

```swift
@available(iOS 16.1, *)
class LiveActivityCompatibilityChecker {
    
    static func checkCompatibility() -> CompatibilityStatus {
        if #available(iOS 17.2, *) {
            return .fullSupport
        } else if #available(iOS 16.1, *) {
            return .basicSupport
        } else {
            return .notSupported
        }
    }
    
    static func getSupportedFeatures() -> [String] {
        var features: [String] = ["Basic Live Activities"]
        
        if #available(iOS 17.2, *) {
            features.append("Push-to-Start Tokens")
        }
        
        if #available(iOS 16.2, *) {
            features.append("Content Updates")
        }
        
        return features
    }
}

enum CompatibilityStatus {
    case fullSupport
    case basicSupport
    case notSupported
}
```

### 2. Graceful Degradation

```swift
class LiveActivityFallbackManager {
    
    static func handleUnsupportedFeature() {
        // Fallback to push notifications
        sendPushNotification(title: "Update Available", body: "Check the app for the latest information")
    }
    
    static func handlePermissionDenied() {
        // Show in-app notification
        showInAppMessage(title: "Live Activities Disabled", 
                        body: "Enable Live Activities in Settings to get real-time updates")
    }
}
```

## Summary

Following these best practices will help you:

1. **Create Reliable Live Activities** - Proper error handling and validation
2. **Optimize Performance** - Efficient updates and resource management
3. **Ensure Security** - Data validation and access control
4. **Maintain Code Quality** - Clear structure and comprehensive testing
5. **Provide Great UX** - User-centric design and graceful degradation

Remember to adapt these practices to your specific use case and requirements while maintaining the core principles of performance, security, and user experience. 