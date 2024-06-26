# PushTrackingStatus

Enum representing the status of push tracking.

Returned in the optional closure passed to the `handleNotificationResponse` API:

```swift
Messaging.handleNotificationResponse(response) { trackingStatus in
    // handle PushTrackingStatus values
}
```

### Definition

```swift
@objc(AEPPushTrackingStatus)
public enum PushTrackingStatus: Int {
    case trackingInitiated
    case noDatasetConfigured
    case noTrackingData
    case invalidMessageId
    case unknownError
}
```

| Enum                    | Description                       |
| ----------------------- | --------------------------------- |
| `trackingInitiated`     | All required data is available and tracking has been initiated. |
| `noDatasetConfigured`   | Tracking was not initiated because no tracking dataset has been configured. |
| `noTrackingData`        | Tracking was not initiated because the notification does not contain tracking data. |
| `invalidMessageId`      | Tracking was not initiated because the message id is invalid. |
| `unknownError`          | Tracking was not initiated because of an unknown error. |
